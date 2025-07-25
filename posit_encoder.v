module posit_encoder#(
  parameter posit_width = 8,
  parameter es = 1,
  localparam frac_width = posit_width - es - 3, // maximum fraction width 
  localparam regime_width = $clog2(posit_width) + 1,  // regime bit width
  localparam scale_width = es + regime_width, // scaling factor width
  localparam long_width = 2 * posit_width, // double the posit width
  localparam signed [scale_width-1:0] max_sf = (1 << es) * (posit_width - 2), // maximum scaling factor
  localparam [posit_width-1:0] NaR = {1'b1, {(posit_width - 1){1'b0}}} // sign bit 1, rest all 0s
)(
  input clk,
  input reset,
  input en,
  input sign,
  input [posit_width - 1 : 0] frac,
  input [scale_width - 1 : 0] sf,
  input exception,
  input zero_in,

  output reg [posit_width - 1 : 0] ans,
  output reg zero,
  output reg ready,
  output reg exception_flag
);

wire [scale_width - 1 : 0] abs_sf;
wire [es - 1 : 0] exp;
wire [regime_width - 1 : 0] regime, reg_shift;
wire [1:0] reg_pre;
wire [long_width - 1 : 0] temp_long_ans, temp_shift;
wire sticky, guard, round, nom;
wire [posit_width - 1 : 0] temp_ans;


// max regime case
//assign reg_shift = (regime == {(regime_width){1'b1}}) ? regime : regime - 1; // old regime max

//assign sf = ($signed(sf) >  max_sf) ? max_sf :
//                  ($signed(sf) < -max_sf) ? -max_sf : sf;

// get absolute scaling factor
assign abs_sf = ({(scale_width){sf[scale_width - 1]}} ^ sf[scale_width - 1 : 0]) + sf[scale_width - 1];

// get exponent and regime value
assign exp = (sf[scale_width - 1]) ? sf[es - 1 : 0] : abs_sf[es - 1 : 0]; // dont understand this part, it seems switched
assign regime = (sf[scale_width - 1]) ? ~(sf >> es) + 1'b1 : abs_sf >> es; 

// prepare to shift in regime
// Determine regime prefix bits based on the sign of the scaling factor.
// According to the Posit format, the regime field is a run of 1s or 0s terminated by the opposite bit.
// - For positive scaling factor (sf[MSB] = 0), regime starts with '1' → use prefix 2'b10
//   Example regime: 10xxxx → k = 0, 110xxxx → k = +1, 1110xxxx → k = +2 ...
// - For negative scaling factor (sf[MSB] = 1), regime starts with '0' → use prefix 2'b01
//   Example regime: 01xxxx → k = -1, 001xxxx → k = -2 ...
assign reg_pre = (sf[scale_width - 1]) ? 2'b01 : 2'b10; 
assign temp_long_ans[long_width - 1 : 0] = {reg_pre, exp, frac[posit_width - 2 : 0], {(posit_width-es-1){1'b0}}}; 

assign temp_shift = (sf[scale_width - 1]) ? $signed(temp_long_ans) >>> (regime - 1) : $signed(temp_long_ans) >>> regime; // temp shifted long answer

// noramlizing bits
assign guard = temp_shift[posit_width];
assign round = temp_shift[posit_width - 1]; 
assign sticky = |temp_shift[posit_width - 2 : 0];
//assign nom = guard & (round | sticky | temp_shift[posit_width]);
assign nom = guard & (round | sticky);
//assign sticky = |temp_shift[posit_width - 1 : 0];
//assign nom = (temp_shift[posit_width + 1] & (temp_shift[posit_width] | sticky)); // Round up if guard=1 AND (round=1 OR sticky=1)

//assign nom = (temp_shift[posit_width + 1] & (temp_shift[posit_width] | sticky)); // Round up if guard=1 AND (round=1 OR sticky=1)
//assign nom = ((temp_shift[posit_width+1] & temp_shift[posit_width]) | (temp_shift[posit_width] & (temp_shift[posit_width-1:0] | sticky))); // original line

assign temp_ans = {1'b0, temp_shift[long_width-1:posit_width+1]}; // + nom for rounding

always @(posedge clk or posedge reset) begin
  if (reset) begin
    ans <= 0;
    zero <= 0;
    ready <= 0;
    exception_flag <= 0;
  end else if (en) begin
    ans <= ({(posit_width){sign}} ^ temp_ans) + sign;
    zero <= ~|temp_ans;
    ready <= 1'b1;
    if(exception) begin
      ans <= NaR;
    end else if (zero_in) begin
      ans <= 0;
    end
    exception_flag <= exception;
  end else begin
    ready <= 0;
  end
end

endmodule