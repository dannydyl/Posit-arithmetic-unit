`timescale 1ns/1ps

module posit_extraction #(
  parameter posit_width = 8,  // posit size
  parameter es = 1,           // es size  
  // parameters
  localparam frac_width = posit_width - es - 3, // maximum fraction width 
  localparam regime_width = $clog2(posit_width) + 1  // regime bit width
  )(
  input clk,
  input reset,
  input en,
  input [posit_width - 1 : 0] posit,

  output reg sign,
  output reg [regime_width - 1 : 0] regime,
  output reg [es - 1 : 0] exponent,
  output reg [frac_width - 1 : 0] fraction,
  output reg [posit_width - 1 : 0] abs_posit,
  output reg zero,
  output reg exception_flag
);

// internal variables
wire [posit_width - 2 : 0] twos_comp; // twos complement of bits without sign bit so 7 bit width
wire [posit_width - 2 : 0] abs_regime;
wire [regime_width - 1: 0] index;
wire [regime_width - 2 : 0] zero_count;
wire [posit_width - 4 : 0] temp;
wire temp_sign, zero_temp, exception_temp;


assign zero_temp = ~|posit;
assign temp_sign = posit[posit_width - 1];
assign exception_temp = posit[posit_width - 1] & ~(|posit[posit_width - 2 : 0]); // equivalent to  => (sign bit) AND ( NOT(posit[6] OR posit[5] ... OR posit[0]))

// if the sign bit is 1 then XOR the posit bits with all 1s and add 1 which is the sign bit
// if the sign bit is 0 then twos_comp is the same as the posit
assign twos_comp = ({(posit_width){posit[posit_width - 1]}} ^ posit[posit_width - 1 : 0]) + posit[posit_width - 1];

// absolute regime is for CLZ
// if the first bit of regime bit is 1, then bitwise to make it start with 0
assign abs_regime = {(posit_width - 1){twos_comp[posit_width - 2]}} ^ twos_comp[posit_width - 2 : 0];

// index is the position (index) of the first 1 in the regime
// posit_width - index - 2 gives the count of zeros
// even if the regime bit starts with '1', the important thing is the count of leading bits, despite the '1' or '0'
assign zero_count = posit_width - index - 2;

// temp contains exponent + fraction bits
assign temp = twos_comp[posit_width - 4 : 0] << (zero_count - 1);

CLZ #(posit_width - 1) count_leading_bit (
  .in(abs_regime),
  .index(index)
);

always @(posedge clk or posedge reset) begin
  if (reset || !en) begin
    sign <= 0;
    regime <= 0;
    exponent <= 0;
    fraction <= 0;
    abs_posit <= 0;
    zero <= 0;
    exception_flag <= 0;
  end else if (en) begin
    sign <= temp_sign;
    regime <= (twos_comp[posit_width - 2]) ? zero_count - 1 : -zero_count; // depending on twos_comp's MSB
    exponent <= temp[posit_width - 4 : frac_width];
    fraction <= temp[frac_width - 1 : 0];
    abs_posit <= twos_comp;
    // the case for exception flag high is when sign bit is 1 and all the rest bits are 0. for example, 10000000
    zero <= zero_temp;
    exception_flag <= exception_temp;
  end
end

endmodule