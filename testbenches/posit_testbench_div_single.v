module div_single_posit_top_tb;
// This module is a testbench for simulating single operation for div


  parameter posit_width = 8;
  parameter es = 1;

  // Testbench variables
  reg clk, reset, start;
  reg [1:0] opcode;
  reg [posit_width-1:0] a, b;
  wire done, zero;
  wire [posit_width-1:0] result;


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

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
  end

  // Testbench sequence
  initial begin
    // Reset
    reset = 1;
    start = 0;
    opcode = 2'b11; // division
    a = 0;
    b = 0;
    repeat (2) @ (posedge clk);
    reset = 0;
    repeat (2) @ (posedge clk);
    start = 1;
//    @(posedge clk);
//    a = 8'b00000000;
//    b = 8'b00000000;
    a = 8'b00100010;
    b = 8'b10110111;
    
    @(posedge clk);

//    a = 8'b10000000;
//    b = 8'b11011011;
    
//    @(posedge clk);

//    a = 8'b00000000;
//    b = 8'b00000000;
    
    wait (done);
    repeat (2) @ (posedge clk);

    $finish;
  end

endmodule
