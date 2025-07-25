// this module is to find the shift amount between two posit numbers before performing arithmetic operations
// the shift amount is the difference between the scaling factors of the two numbers
// the scaling factor plays same role as the effective exponent from posit-cpp library

module posit_scalar #(
  parameter posit_width = 8,  // posit size
  parameter es = 1,           // es size
  localparam regime_width = $clog2(posit_width) + 1,  // regime bit width
  localparam frac_width = posit_width - es - 3, // maximum fraction width
  localparam scale_width = es + regime_width, // scaling factor width
  localparam signed [scale_width-1:0] max_sf = (1 << es) * (posit_width - 2) // maximum scaling factor
  )(
  input clk,
  input reset,  // asynchronous reset
  input en,    // enable signal
  input [1:0] opcode, // 00: addition, 01: subtraction, 10: multiplication, 11: division
  input a_zero_in, b_zero_in,
  input a_sign, b_sign,
  input [regime_width - 1 : 0] a_regime, b_regime,
  input [es - 1 : 0] a_exponent, b_exponent,
  input [frac_width - 1 : 0] a_fraction, b_fraction,
  input [posit_width - 1 : 0] a_abs, b_abs,
  input a_exception, b_exception,

  output reg greater_sign, smaller_sign,
  output reg [frac_width - 1 : 0] greater_fraction, smaller_fraction,
  output reg [scale_width - 1 : 0] shift, greater_sf,
  output reg a_zero_out, b_zero_out,
  output reg greater_is_a,
  output reg exception_flag
);

// internal variables
wire a_greater_b;
wire a_b_sf_same;
wire a_b_frac_same;
wire a_b_sign_dif;
wire sum_zero;
wire signed [scale_width - 1 : 0] ZERO_SF;
wire [scale_width - 1 : 0] a_sf, b_sf, a_abs_sf, b_abs_sf;
wire [scale_width * 2 : 0] mul_result_sf, div_result_sf;
wire a_zero_temp, b_zero_temp;

function [scale_width - 1 : 0] MaxMin_sf (input [scale_width * 2 : 0] in); 
    
    begin
        MaxMin_sf = ($signed(in) >  max_sf) ? max_sf :
                  ($signed(in) < -max_sf) ? -max_sf : in;
    end 
endfunction

assign a_zero_temp = a_zero_in;
assign b_zero_temp = b_zero_in;

assign a_greater_b = (a_abs > b_abs) ? 1'b1 : 1'b0; // if a is greater than b, a_gr_b is 1
                                          
// compute scaling factor. equivalent to effective exponent
assign a_sf = (a_regime << es) + a_exponent; // RESOLVED [BUG] has a problem with calculating sf. needs to be -2 instead of -1 
assign b_sf = (b_regime << es) + b_exponent;
assign mul_result_sf = $signed(a_sf) + $signed(b_sf);
assign div_result_sf = $signed(a_sf) - $signed(b_sf);

// compute if the sum is zero
assign a_b_sf_same = (a_sf == b_sf) ? 1'b1 : 1'b0;
assign a_b_frac_same = (a_fraction == b_fraction) ? 1'b1 : 1'b0;
assign a_b_sign_dif = (a_sign != b_sign) ? 1'b1 : 1'b0;
assign sum_zero = (a_b_sf_same & a_b_frac_same & a_b_sign_dif & (opcode != 2'b01) ) || 
                    (a_b_sf_same & a_b_frac_same & (opcode == 2'b01) & (a_sign == b_sign));
assign ZERO_SF = -(((posit_width - 1) << es) + 1);

// compute absolute scaling factor. basically doing twos complement of scaling factor
assign a_abs_sf = ({(scale_width){a_sf[scale_width - 1]}} ^ a_sf[scale_width - 1: 0]) + a_sf[scale_width - 1];
assign b_abs_sf = ({(scale_width){b_sf[scale_width - 1]}} ^ b_sf[scale_width - 1: 0]) + b_sf[scale_width - 1];

always @(posedge clk or posedge reset) begin
  if (reset) begin
    greater_fraction <= 0;
    smaller_fraction <= 0;
    shift <= 0;
    greater_sf <= 0;
    greater_sign <= 0;
    smaller_sign <= 0;
    a_zero_out <= 0;
    b_zero_out <= 0;
    exception_flag <= 0;
    greater_is_a <= 0;
  end
  else if (en) begin
    a_zero_out <= a_zero_temp;
    b_zero_out <= b_zero_temp;
    exception_flag <= a_exception | b_exception; 
    greater_is_a <= a_greater_b;
    // opcode : 1x multiplication or division
      if (opcode[1]) begin
          if (opcode[0]) begin  // opcode : 11 division 
//              greater_sf <= a_sf - b_sf;
                greater_sf <= MaxMin_sf(div_result_sf);
          end
          else begin  // opcode : 10 multiplication
              greater_sf <= MaxMin_sf(mul_result_sf);
          end
          greater_sign <= a_sign;
          smaller_sign <= b_sign;
          greater_fraction <= a_fraction;
          smaller_fraction <= b_fraction;
      end
      else begin
          // opcode : 0x addition or subtraction
          if (sum_zero) begin
              greater_fraction <= 0;
              smaller_fraction <= 0;
              greater_sign <= 0;
              smaller_sign <= 0;
              greater_sf <= ZERO_SF;
          end
          else if (a_greater_b) begin // a is greater than b
              greater_fraction <= a_fraction;
              smaller_fraction <= b_fraction;
              greater_sign <= a_sign;
              smaller_sign <= b_sign;
              greater_sf <= a_sf;
              if (!a_sf[scale_width - 1] & !b_sf[scale_width - 1]) begin    // both are positive scaling factors which means both values are greater than 1
                  shift <= a_sf - b_sf;  // since a is greater than b, shift is a - b
              end
              else if (!a_sf[scale_width - 1] & b_sf[scale_width - 1]) begin  // a is positive and b is negative which means b value is less than 1
                  shift <= a_abs_sf + b_abs_sf; 
              end
              else begin
                  shift <= b_abs_sf - a_abs_sf; // both negative (the case of a negative and b positive is not possible. this would mean a value is in between 0 and 1 and b value is greater than 1 which does not make sense)
              end
          end
          else begin  // b is greater than a
              greater_sign <= b_sign;
              smaller_sign <= a_sign;
              greater_fraction <= b_fraction;
              smaller_fraction <= a_fraction;
              greater_sf <= b_sf;
              if(!a_sf[scale_width - 1] & !b_sf[scale_width - 1]) begin // both are positive sf
                shift <= b_sf - a_sf;
              end
              else if (a_sf[scale_width - 1] & !b_sf[scale_width - 1]) begin // a is negative and b is positive
                shift <= a_abs_sf + b_abs_sf;
              end
              else begin
                shift <= a_abs_sf - b_abs_sf; // both negative. same as above, a negative and b positive is not possible
              end          
              
          end
      end
    end
  end
endmodule