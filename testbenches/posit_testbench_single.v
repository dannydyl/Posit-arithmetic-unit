module add_sub_single_posit_top_tb;
// This module is a testbench for simulating single operation for Add/Sub

  // Parameters
  parameter posit_width = 8;
  parameter es = 1;

  // Testbench variables
  reg clk, reset, start;
  reg [1:0] opcode;
  reg [posit_width-1:0] a, b;
  wire done, zero;
  wire [posit_width-1:0] result;

  // Instantiate the module under test
  posit_top #(
    .posit_width(posit_width),
    .es(es)
  ) dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .opcode(opcode),
    .a(a),
    .b(b),
    .done(done),
    .zero(zero),
    .result(result)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
  end

  // Testbench sequence
  initial begin
    // Reset
    reset = 1;
    start = 0;
    opcode = 2'b01;
    a = 0;
    b = 0;
    repeat (2) @ (posedge clk);
    reset = 0;
    repeat (2) @ (posedge clk);
    start = 1;

//    a = 8'b00000000;
//    b = 8'b00000000;
    a = 8'b00000000;
    b = 8'b11001101;
    
    @(posedge clk);

//    a = 8'b10000000;
//    b = 8'b11011011;
//    a = 8'b00000000;
//    b = 8'b00000000;
    
    #100;
    

    // End simulation
    $finish;
  end

endmodule
