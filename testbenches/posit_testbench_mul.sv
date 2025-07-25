module mul_posit_top_tb;
// This module is a testbench for Add/Sub operations with .csv scoreboard generated from Posit C++

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

  // Task to read from .csv file and apply inputs
  task apply_inputs_from_csv;
    integer file, result_file, r, error_count, cycle;
    reg [posit_width-1:0] a_in, b_in, expected_result;
    reg [255:0] line; // Line buffer for fgets
    reg [posit_width-1:0] a_queue[0:4]; // Circular queue for `a`
    reg [posit_width-1:0] b_queue[0:4]; // Circular queue for `b`
    reg [posit_width-1:0] expected_result_queue[0:4]; // Circular queue for expected results
    integer queue_index;
    string mismatch_log[0:499]; // Store up to 500 mismatch messages
    integer mismatch_index = 0;

    
    begin
        file = $fopen("/home/dongyunlee/Desktop/starc-posit-arith/bfp-master/posit_8_1_multiply_500_samples.csv", "r");
    	result_file = $fopen("/home/dongyunlee/Desktop/starc-posit-arith/Posit-Verilog/simulation_mul_result.csv", "w");
        if (file == 0) begin
            $display("Failed to open input file.");
            $finish;
        end
        if (result_file == 0) begin
            $display("Failed to open result file.");
            $finish;
        end

        // Write header to the result file
        $fwrite(result_file, "Cycle,a,b,Expected Result,Simulation Result,Status\n");

        // Initialize variables
        error_count = 0;
        cycle = 0;
        queue_index = 0;

        // Skip the header line
        r = $fgets(line, file);

        while (!$feof(file)) begin
            r = $fgets(line, file); // Read a line into the buffer
            if (r > 0) begin
                // Parse the line for a, b, and expected_result
                r = $sscanf(line, "%b,%b,%b", a_in, b_in, expected_result);
                if (r == 3) begin
                    // Apply inputs
                    a = a_in;
                    b = b_in;
                    opcode = 2'b10; // Addition opcode
                    start = 1;

                    // Store inputs and expected result in the circular queue
                    a_queue[queue_index] = a_in;
                    b_queue[queue_index] = b_in;
                    expected_result_queue[queue_index] = expected_result;

                    // Wait for one clock cycle
                    @(posedge clk);
                    start = 0;

                    // Compare the result from 4 cycles earlier
                    if (cycle >= 4) begin
                        if (result !== expected_result_queue[(queue_index + 1) % 5]) begin
                            $display("Mismatch at cycle %0d: a = %b, b = %b, expected = %b, got = %b",
                                     cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                                     expected_result_queue[(queue_index + 1) % 5], result);
                            $fwrite(result_file, "%0d,%b,%b,%b,%b,Mismatch\n",
                                    cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                                    expected_result_queue[(queue_index + 1) % 5], result);
                            error_count = error_count + 1;
                            mismatch_log[mismatch_index] = 
                            $sformatf("Mismatch at cycle %0d: a = %b, b = %b, expected = %b, got = %b",
                                      cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                                      expected_result_queue[(queue_index + 1) % 5], result);
                            mismatch_index++;
                    
                        end else begin
                            $display("Pass at cycle %0d: a = %b, b = %b, result = %b",
                                     cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], result);
                            $fwrite(result_file, "%0d,%b,%b,%b,%b,Pass\n",
                                    cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                                    expected_result_queue[(queue_index + 1) % 5], result);
                        end
                    end
    
                    // Increment the queue index in a circular manner
                    queue_index = (queue_index + 1) % 5;
                    cycle = cycle + 1;
                end else begin
                    $display("Failed to parse line: %s", line);
                end
            end
        end
                // Process remaining results after the last input
        repeat (4) begin
            @(posedge clk);
            if (cycle >= 4) begin
                if (result !== expected_result_queue[(queue_index + 1) % 5]) begin
                    $display("Mismatch at cycle %0d: a = %b, b = %b, expected = %b, got = %b",
                             cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                             expected_result_queue[(queue_index + 1) % 5], result);
                    $fwrite(result_file, "%0d,%b,%b,%b,%b,Mismatch\n",
                            cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                            expected_result_queue[(queue_index + 1) % 5], result);
                    error_count = error_count + 1;
                    mismatch_log[mismatch_index] = 
                    $sformatf("Mismatch at cycle %0d: a = %b, b = %b, expected = %b, got = %b",
                              cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                              expected_result_queue[(queue_index + 1) % 5], result);
                    mismatch_index++;
            
                end else begin
                    $display("Pass at cycle %0d: a = %b, b = %b, result = %b",
                             cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], result);
                    $fwrite(result_file, "%0d,%b,%b,%b,%b,Pass\n",
                            cycle, a_queue[(queue_index + 1) % 5], b_queue[(queue_index + 1) % 5], 
                            expected_result_queue[(queue_index + 1) % 5], result);
                end
            end
            cycle = cycle + 1;
            queue_index = (queue_index + 1) % 5;
        end
        $fclose(file);
        $fwrite(result_file, "Test completed with %0d errors.\n", error_count);
        $fclose(result_file);
        
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
    opcode = 2'b10;
    a = 0;
    b = 0;
    repeat (2) @ (posedge clk);
    reset = 0;
    repeat (2) @ (posedge clk);
    start = 1;

    // Apply inputs from the CSV file
    apply_inputs_from_csv();

    repeat (10) @ (posedge clk);
    // End simulation
    $finish;
  end
endmodule
