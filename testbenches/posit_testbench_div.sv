module div_posit_top_tb;
// This module is a testbench for division operations with .csv scoreboard generated from Posit C++

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

   task apply_inputs_from_csv;
    integer file, result_file, r, error_count, cycle, mismatch_index;
    reg [posit_width-1:0] a_in, b_in, expected_result;
    reg [255:0] line;
    string mismatch_log[0:499];

    begin
      file        = $fopen("/home/dongyunlee/Desktop/starc-posit-arith/bfp-master/posit_8_1_divide_500_samples.csv", "r");
      result_file = $fopen("/home/dongyunlee/Desktop/starc-posit-arith/Posit-Verilog/simulation_div_result.csv", "w");
      if (file == 0 || result_file == 0) begin
        $display("Failed to open I/O files.");
        $finish;
      end

      $fwrite(result_file, "Cycle,a,b,Expected Result,Simulation Result,Status\n");
      error_count    = 0;
      cycle          = 0;
      mismatch_index = 0;

      // skip header
      r = $fgets(line, file);

      while (!$feof(file)) begin
        r = $fgets(line, file);
        if (r > 0 && $sscanf(line, "%b,%b,%b", a_in, b_in, expected_result) == 3) begin

          // drive one-cycle start
          a      = a_in;
          b      = b_in;
          opcode = 2'b11;
          start  = 1;
          @(posedge clk);
          start  = 0;

          // wait for done
          wait (done);
          @(posedge clk);  // sample result next cycle

          // compare & log
          if (result !== expected_result) begin
            $display("Mismatch at cycle %0d: a = %b, b = %b, expected = %b, got = %b",
                     cycle, a_in, b_in, expected_result, result);
            $fwrite(result_file, "%0d,%b,%b,%b,%b,Mismatch\n",
                    cycle, a_in, b_in, expected_result, result);
            error_count = error_count + 1;
            mismatch_log[mismatch_index] = $sformatf(
              "Mismatch at cycle %0d: a = %b, b = %b, expected = %b, got = %b",
              cycle, a_in, b_in, expected_result, result
            );
            mismatch_index = mismatch_index + 1;
          end else begin
            $display("Pass at cycle %0d: a = %b, b = %b, result = %b",
                     cycle, a_in, b_in, result);
            $fwrite(result_file, "%0d,%b,%b,%b,%b,Pass\n",
                    cycle, a_in, b_in, expected_result, result);
          end

          cycle = cycle + 1;
        end
      end

      $fwrite(result_file, "Test completed with %0d errors.\n", error_count);
      $fclose(file);
      $fclose(result_file);

      // your mismatch-dump block
      if (mismatch_index > 0) begin
        $display("\n==== MISMATCHES ====");
        for (int i = 0; i < mismatch_index; i++) begin
          $display("%s", mismatch_log[i]);
        end
        $display("====================\n");
      end

      if (error_count > 0) begin
        $display("Test completed with %0d errors.", error_count);
      end else begin
        $display("Test completed successfully with no errors.");
      end
    end
  endtask


  // Testbench sequence
  initial begin
    reset = 1;
    start = 0;
    opcode = 2'b11;
    a = 0;
    b = 0;
    repeat (2) @ (posedge clk);
    reset = 0;
    repeat (2) @ (posedge clk);
    start = 1;

    // Apply inputs from the CSV file
    apply_inputs_from_csv();

    repeat (10) @ (posedge clk);
    $finish;
  end
endmodule
