module posit_top#(
  parameter posit_width = 8, // posit size
  parameter es = 2, // es size
  localparam regime_width = $clog2(posit_width) + 1, // regime bit width
  localparam frac_width = posit_width - es - 3, // maximum fraction width
  localparam scale_width = es + regime_width // scaling factor width
)(
  input clk, 
  input reset,
  input start,
  input [1:0] opcode, // 00: addition, 01: subtraction, 10: multiplication, 11: division.
  input [posit_width - 1 : 0] a, b,

  output done, zero,
  output [posit_width - 1 : 0] result
);

reg ctrl_extrac, ctrl_scalar, ctrl_op, ctrl_enc;

wire a_zero_extrac, b_zero_extrac, a_zero_scalar, b_zero_scalar, zero_arith;

wire a_sign, b_sign;
wire [regime_width - 1 : 0] a_regime, b_regime;
wire [es - 1 : 0] a_exponent, b_exponent;
wire [frac_width - 1 : 0] a_fraction, b_fraction;
wire [posit_width - 1 : 0] a_abs, b_abs;
wire a_exception, b_exception, exception_flag_s, exception_flag_arith, greater_is_a;

wire greater_sign, smaller_sign;
wire [frac_width - 1 : 0] greater_fraction, smaller_fraction;
wire [scale_width - 1 : 0] shift, greater_sf;

wire hold;
wire [posit_width - 1 : 0] result_frac;
wire result_sign;
wire [scale_width - 1 : 0] result_sf;

posit_extraction #(.posit_width(posit_width), .es(es)) a_posit_extraction_inst (
  .clk(clk),
  .reset(reset),
  .en(ctrl_extrac),
  .posit(a),
  .sign(a_sign),
  .regime(a_regime),
  .exponent(a_exponent),
  .fraction(a_fraction),
  .abs_posit(a_abs),
  .zero(a_zero_extrac),
  .exception_flag(a_exception)
);

posit_extraction #(.posit_width(posit_width), .es(es)) b_posit_extraction_inst (
  .clk(clk),
  .reset(reset),
  .en(ctrl_extrac),
  .posit(b),
  .sign(b_sign),
  .regime(b_regime),
  .exponent(b_exponent),
  .fraction(b_fraction),
  .abs_posit(b_abs),
  .zero(b_zero_extrac),
  .exception_flag(b_exception)
);

posit_scalar #( .posit_width(posit_width), .es(es)) posit_scalar_inst (
  .clk(clk),
  .reset(reset),
  .en(ctrl_scalar),
  .opcode(opcode),
  .a_sign(a_sign),
  .b_sign(b_sign),
  .a_regime(a_regime),
  .b_regime(b_regime),
  .a_exponent(a_exponent),
  .b_exponent(b_exponent),
  .a_fraction(a_fraction),
  .b_fraction(b_fraction),
  .a_abs(a_abs),
  .b_abs(b_abs),
  .a_zero_in(a_zero_extrac),
  .b_zero_in(b_zero_extrac),
  .a_exception(a_exception),
  .b_exception(b_exception),
  .greater_sign(greater_sign),
  .smaller_sign(smaller_sign),
  .greater_fraction(greater_fraction),
  .smaller_fraction(smaller_fraction),
  .shift(shift),
  .greater_sf(greater_sf),
  .a_zero_out(a_zero_scalar),
  .b_zero_out(b_zero_scalar),
  .greater_is_a(greater_is_a),
  .exception_flag(exception_flag_s) 
);


posit_arithmetic_operator #(
  .posit_width(posit_width),
  .es(es)
) posit_arithmetic_operator_inst (
  .clk(clk),
  .reset(reset),
  .en(ctrl_op),
  .opcode(opcode), // this opcode should be passed from previous module. leaving as it is for now since we are testing only one operation at a time.
  .a_zero_in(a_zero_scalar),
  .b_zero_in(b_zero_scalar),
  .greater_sign(greater_sign),
  .smaller_sign(smaller_sign),
  .greater_fraction(greater_fraction),
  .smaller_fraction(smaller_fraction),
  .shift(shift),
  .greater_sf(greater_sf),
  .greater_is_a(greater_is_a),
  .exception(exception_flag_s),
  .result_frac(result_frac),
  .result_sign(result_sign),
  .result_sf(result_sf),
  .hold(hold),
  .zero(zero_arith),
  .exception_flag(exception_flag_arith)
);

posit_encoder #( .posit_width(posit_width), .es(es)) posit_encoder_inst (
  .clk(clk),
  .reset(reset),
  .en(ctrl_enc),
  .sign(result_sign),
  .frac(result_frac),
  .sf(result_sf),
  .exception(exception_flag_arith),
  .zero_in(zero_arith),
  .ans(result),
  .zero(zero),
  .ready(done),
  .exception_flag(exception_flag)
);

reg start_temp;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    ctrl_extrac <= 0;
    ctrl_scalar <= 0;
    ctrl_op <= 0;
    ctrl_enc <= 0;
    start_temp <= 0;
  end else begin
  start_temp <= start;
    if (start) begin // start && ~(a_zero && b_zero)
      ctrl_extrac <= start;
    end else begin
      ctrl_extrac <= 0;
    end
    
    if (ctrl_extrac) begin
        ctrl_scalar <= ctrl_extrac;
    end else begin
        ctrl_scalar <= 0;
    end
    
    if (opcode == 2'b11 && ctrl_op == 1 && hold) begin
      ctrl_enc <= 0;
    end else begin
      ctrl_op <= ctrl_scalar;
      ctrl_enc <= ctrl_op;
    end
  end
end

endmodule