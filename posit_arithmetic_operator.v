module posit_arithmetic_operator #(
  parameter posit_width = 8,  // posit size
  parameter es = 1,           // es size
  // local parameters
  localparam regime_width = $clog2(posit_width) + 1,  // regime bit width
  localparam frac_width = posit_width - es - 3, // maximum fraction width
  localparam scale_width = es + regime_width, // scaling factor width
  localparam long_width = posit_width * 2, // double the posit width
  localparam d_width = posit_width - es, // for division
  localparam index_width = $clog2(long_width+1)
  )(
  input clk,
  input reset,
  input en,   // enable signal
  input [1:0] opcode, // 00: addition, 01: subtraction, 10: multiplication, 11: division
  input a_zero_in, b_zero_in,
  input greater_sign, smaller_sign,
  input [frac_width - 1 : 0] greater_fraction, smaller_fraction,
  input [scale_width - 1: 0] shift, greater_sf,
  input greater_is_a,
  input exception,

  output reg [posit_width - 1 : 0] result_frac,
  output reg result_sign,
  output reg [scale_width - 1 : 0] result_sf,
  output hold,
  output reg zero,
  output reg exception_flag
);

wire add_sign;
wire [long_width - 1 : 0] add_long_gr, add_long_sm, add_long_result, long_result;
wire [posit_width - 1 : 0] mul_a, mul_b;
wire [long_width - 1 : 0] mul_long_result;
wire [d_width - 1 : 0] div_n, div_d, div_q, div_r;
wire lt_flag, div_en, div_done;
wire [index_width - 1 : 0] index;
wire [scale_width - 1 : 0] temp_result_sf0, temp_result_sf1, temp_result_sf2;
wire a_zero_temp, b_zero_temp, smaller_frac_zero, greater_frac_zero;

assign a_zero_temp = a_zero_in;
assign b_zero_temp = b_zero_in;
assign smaller_frac_zero = ~|smaller_fraction;
assign greater_frac_zero = ~|greater_fraction;

assign add_sign = smaller_sign ^ opcode[0]; // smaller_sign XOR opcode[0]. if the sign is different, then subtraction

// adding hidden bit & shifting
// MSB 0 bit is for carry bit
assign add_long_gr = {2'b01, greater_fraction, {(long_width - frac_width - 2){1'b0}}};   // adding hidden bit 01
assign add_long_sm = {2'b01, smaller_fraction, {(long_width - frac_width - 2){1'b0}}} >> shift; // shifting smaller fraction

// perform operation
// same sign: addition, different sign: subtraction
// performed in absolute value
assign add_long_result = (greater_sign == add_sign) ? add_long_gr + add_long_sm : add_long_gr - add_long_sm;

// multiplication
assign mul_a = {1'b1, greater_fraction, {(posit_width - frac_width - 1){1'b0}}};
assign mul_b = {1'b1, smaller_fraction, {(posit_width - frac_width - 1){1'b0}}};
assign mul_long_result = mul_a * mul_b;

// division
assign lt_flag = greater_is_a ? (((greater_fraction < smaller_fraction) && (&opcode[1:0])) ? 1'b1 : 1'b0) : 1'b0; // if greater is less than smaller, then lt_flag is 1
assign div_n = {1'b1, greater_fraction, 2'b0};
assign div_d = (lt_flag) ? {2'b01, smaller_fraction, 1'b0} : {1'b1, smaller_fraction, 2'b0};
assign div_en = en && opcode[1] && opcode[0] && !div_done;
assign hold = en && (opcode == 2'b11) && !div_done;

divider #(d_width) div (
  .clk(clk),
  .reset(reset),
  .en(div_en),
  .num(div_n),
  .den(div_d),
  .q(div_q),
  .r(div_r),
  .done(div_done)
);

assign long_result = (!opcode[1]) ? add_long_result : (!opcode[0]) ? mul_long_result : {div_q, {(long_width - d_width){1'b0}}};

// to find the first 1 bit for normalization
CLZ #(long_width) count_leading_bit (
  .in(long_result),
  .index(index) // index is the bit position of the first bit 1, not the counts of zeros
);

assign temp_result_sf0 = greater_sf + 1 - lt_flag;
assign temp_result_sf1 = greater_sf - lt_flag;
assign temp_result_sf2 = (&opcode) ? greater_sf - lt_flag : greater_sf - (long_width - index - 2) - lt_flag;

reg s0, s1, s2;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    result_frac <= 0;
    result_sign <= 0;
    result_sf <= 0;
    exception_flag <= 0;
    zero <= 0;
  end else if (en) begin
    exception_flag <= exception;
    zero <= 0; 
    result_sign <=
                    opcode[1] ? (greater_sign ^ smaller_sign):                                 // mul/div
                   (opcode==2'b01 && greater_sign==smaller_sign) ? 
                        (greater_is_a ? greater_sign : ~greater_sign):                       // true subtraction
                   (opcode==2'b01 && greater_sign!=smaller_sign) ?
                        (greater_is_a ? greater_sign : smaller_sign):                       // subtract opposite signs → sign=minuend (a_sign)
                        greater_sign;                                                       // addition default
          

    // handling zero operation
    if(a_zero_temp | b_zero_temp) begin
        if(opcode[1]) begin
            result_frac <= 0;
            result_sign <= 0;
            result_sf <= 0;
            zero <= a_zero_temp | b_zero_temp;
        end 
        else begin
            //result_frac <= {2'b01, greater_fraction, {(long_width - frac_width - 2){1'b0}}};
            result_frac <= {1'b0, greater_fraction, {(posit_width - frac_width-1){1'b0}}};
            result_sign <= (a_zero_temp && opcode == 2'b01) ? ~greater_sign : greater_sign;
            result_sf <= greater_sf;
        end 
    end
    
    else if (index == (long_width - 1)) begin // if there is a carry bit
      // the most significant 7bits goes into the most significant 7 bits of the result
      result_frac[posit_width - 1 : 1] <= long_result[long_width - 1 : (long_width - posit_width + 1)];
      // if there is any 1 in the rest of long_result bits, then put 1 in LSB of the result. THIS is called "sticky bit"
      result_frac[0] <= |long_result[(long_width - posit_width) : 0];
      // result_sf <= greater_sf + 1 - lt_flag;   // increment the scaling factor. should be lt_flag for division later
      result_sf <= temp_result_sf0; // fixed sync problem with this 
      s0 <= 1;
    end

    else if (index == (long_width - 2)) begin // if the second MSB is 1
      result_frac[posit_width - 1 : 1] <= long_result[long_width - 2 : (long_width - posit_width)];
      result_frac[0] <= |long_result[(long_width -  posit_width - 1) : 0];
      result_sf <= temp_result_sf1;
      s1 <= 1;
    end

    else begin // if the first 1 bit it at the right side in long_result
//      result_frac <= long_result[index -: posit_width]; 
      result_frac <= long_result[(index < posit_width - 1 ? (posit_width - 1) : index) -: posit_width];
      result_frac[0] <= |(long_result << (posit_width + (long_width - index)));
      result_sf <= temp_result_sf2;   
      s2 <= 1;
    end
  end
end

endmodule