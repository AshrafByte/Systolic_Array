/**
 * Systolic Array Matrix Multiplier Testbench
 */

module systolic_array_tb;
  timeunit 1ns / 100ps;

  //==========================================================================
  // Test Configuration Parameters
  //==========================================================================
  parameter int N_SIZE = 3;
  parameter type data_word_t = logic [1:0];
  parameter type result_word_t = logic [(2*$bits(data_word_t))-1:0];
  localparam int CLK_PERIOD = 10;

  //==========================================================================
  // Testbench Signals
  //==========================================================================
  logic         clk;
  logic         rst_n;
  logic         valid_in;
  data_word_t   matrix_a_in   [N_SIZE];  // Unpacked array for A columns
  data_word_t   matrix_b_in   [N_SIZE];  // Unpacked array for B rows
  logic         valid_out;
  result_word_t matrix_c_out  [N_SIZE];  // Unpacked array for C rows

  // Test monitoring variables
  int           test_case = 0;
  int           errors = 0;

  result_word_t actual_matrix [N_SIZE]                                  [N_SIZE];

  //==========================================================================
  // Clock Generation
  //==========================================================================
  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
  end

  //==========================================================================
  // DUT Instantiation
  //==========================================================================
  systolic_array #(
    .N_SIZE(N_SIZE)
  ) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .valid_in    (valid_in),
    .matrix_a_in (matrix_a_in),
    .matrix_b_in (matrix_b_in),
    .valid_out   (valid_out),
    .matrix_c_out(matrix_c_out)
  );

  //==========================================================================
  // Timeout Protection
  //==========================================================================
  initial begin
    #1000;  // Wait 1000ns max
    $error("ERROR: Simulation timeout! Test did not complete in expected time.");
    $finish;
  end

  //==========================================================================
  // Main Test Sequence
  //==========================================================================
  initial begin
    // Waveform dumping setup
    $dumpfile("systolic_array_waves.vcd");
    $dumpvars(0, systolic_array_tb);

    $display("=================================================================");
    $display("SYSTOLIC ARRAY MATRIX MULTIPLIER VERIFICATION");
    $display("=================================================================");
    $display("Configuration: %0dx%0d matrices, %0d-bit data width", N_SIZE, N_SIZE,
             $bits(data_word_t));
    $display("Waveform will be saved to: systolic_array_waves.vcd\n");

    // Run test cases using tasks
    run_basic_multiplication_test();
    $display("=====================\n");

    equal_matrix_test();
    $display("=====================\n");

    run_identity_matrix_test();
    $display("=====================\n");

    run_zero_matrix_test();
    $display("=====================\n");

    // Uncomment to run detailed debugging test
    // run_debug_test();
    // $display("=====================\n");

    // Final summary
    print_final_summary();

    $display("Waveform dumping completed.");
    $finish;
  end


  //==========================================================================
  // TASKS - Modular Test Components
  //==========================================================================

  // Test Cases
  // Testcase1: Run basic multiplication test
  task automatic run_basic_multiplication_test();
    data_word_t   a_cols  [     3][N_SIZE];
    data_word_t   b_rows  [     3][N_SIZE];
    result_word_t expected[N_SIZE][N_SIZE];
    begin
      test_case++;
      $display("=================================================================");
      $display("TEST CASE %0d: Basic Matrix Multiplication", test_case);
      $display("=================================================================");


      // Matrix A = [1 0 2]    Matrix B = [2 1 0]
      //            [3 1 0]               [1 2 1]
      //            [2 3 1]               [0 1 2]

      // Set up input data (A fed by columns, B fed by rows)
      a_cols[0] = '{1, 3, 2};  // Column 0 of A
      a_cols[1] = '{0, 1, 3};  // Column 1 of A  
      a_cols[2] = '{2, 0, 1};  // Column 2 of A

      b_rows[0] = '{2, 1, 0};  // Row 0 of B
      b_rows[1] = '{1, 2, 1};  // Row 1 of B
      b_rows[2] = '{0, 1, 2};  // Row 2 of B

      $display("Input Analysis:");
      $display("  A columns: [1,3,2], [0,1,3], [2,0,1]");
      $display("  B rows:    [2,1,0], [1,2,1], [0,1,2]");
      $display("  Expected C[0][1] = 1*1 + 0*2 + 2*1 = 3");
      $display("  Expected C[2][1] = 2*1 + 3*2 + 1*1 = 9");

      // Expected result C = A × B
      // C = [2  3  4]
      //     [7  5  1]
      //     [7  9  5]
      expected[0] = '{2, 3, 4};
      expected[1] = '{7, 5, 1};
      expected[2] = '{7, 9, 5};

      reset_dut();

      // Start PE monitoring for debugging (optional - uncomment to enable)
      // start_pe_monitoring(15);  // Monitor for 15 cycles

      feed_matrix_data(a_cols[0], b_rows[0], a_cols[1], b_rows[1], a_cols[2], b_rows[2]);
      capture_results("Basic Multiplication");
      check_results(expected, "Basic Multiplication");

      // Single-shot PE state debug (uncomment to see current state)
      // debug_pe_array_state();
    end
  endtask

  // Testcase 2: equal matrixt  
  task automatic equal_matrix_test();
    data_word_t   a_cols  [     3][N_SIZE];
    data_word_t   b_rows  [     3][N_SIZE];
    result_word_t expected[N_SIZE][N_SIZE];
    begin
      test_case++;
      $display("=================================================================");
      $display("TEST CASE %0d: Equal Matrix Test", test_case);
      $display("=================================================================");


      // Simplified test focusing on column 1
      // Matrix A = [1 1 1]    Matrix B = [1 1 1]
      //            [1 1 1]               [1 1 1]
      //            [1 1 1]               [1 1 1]

      a_cols[0]   = '{1, 1, 1};  // Column 0 of A
      a_cols[1]   = '{1, 1, 1};  // Column 1 of A  
      a_cols[2]   = '{1, 1, 1};  // Column 2 of A

      b_rows[0]   = '{1, 1, 1};  // Row 0 of B
      b_rows[1]   = '{1, 1, 1};  // Row 1 of B
      b_rows[2]   = '{1, 1, 1};  // Row 2 of B

      // Expected result: Each element should be 1*1 + 1*1 + 1*1 = 3
      expected[0] = '{3, 3, 3};
      expected[1] = '{3, 3, 3};
      expected[2] = '{3, 3, 3};

      $display("Simple test: All 1s should give all 3s");

      reset_dut();

      feed_matrix_data(a_cols[0], b_rows[0], a_cols[1], b_rows[1], a_cols[2], b_rows[2]);
      capture_results("Equal Matrix test");
      check_results(expected, "Equal Matrix test");
    end
  endtask

  // Testcase 3: Run identity matrix test
  task automatic run_identity_matrix_test();
    data_word_t   a_cols  [     3][N_SIZE];
    data_word_t   b_rows  [     3][N_SIZE];
    result_word_t expected[N_SIZE][N_SIZE];
    begin
      test_case++;
      $display("=================================================================");
      $display("TEST CASE %0d: Identity Matrix Test", test_case);
      $display("=================================================================");

      // Matrix A = [1 0 0]    Matrix B = [1 0 0]  
      //            [0 1 0]               [0 1 0]
      //            [0 0 1]               [0 0 1]

      a_cols[0]   = '{1, 0, 0};  // Column 0 of A (identity)
      a_cols[1]   = '{0, 1, 0};  // Column 1 of A (identity)
      a_cols[2]   = '{0, 0, 1};  // Column 2 of A (identity)

      b_rows[0]   = '{1, 0, 0};  // Row 0 of B (identity)
      b_rows[1]   = '{0, 1, 0};  // Row 1 of B (identity)
      b_rows[2]   = '{0, 0, 1};  // Row 2 of B (identity)

      // Expected result: I × I = I
      expected[0] = '{1, 0, 0};
      expected[1] = '{0, 1, 0};
      expected[2] = '{0, 0, 1};

      reset_dut();
      feed_matrix_data(a_cols[0], b_rows[0], a_cols[1], b_rows[1], a_cols[2], b_rows[2]);
      capture_results("Identity Matrix");
      check_results(expected, "Identity Matrix");
    end
  endtask

  // Testcase 4: Run zero matrix test
  task automatic run_zero_matrix_test();
    data_word_t   a_cols  [     3][N_SIZE];
    data_word_t   b_rows  [     3][N_SIZE];
    result_word_t expected[N_SIZE][N_SIZE];
    begin
      test_case++;
      $display("=================================================================");
      $display("TEST CASE %0d: Zero Matrix Test", test_case);
      $display("=================================================================");

      // Matrix A = [0 0 0]    Matrix B = [1 2 3]
      //            [0 0 0]               [1 2 3]  
      //            [0 0 0]               [1 2 3]

      a_cols[0]   = '{0, 0, 0};  // Column 0 of A (zero)
      a_cols[1]   = '{0, 0, 0};  // Column 1 of A (zero)
      a_cols[2]   = '{0, 0, 0};  // Column 2 of A (zero)

      b_rows[0]   = '{1, 2, 3};  // Row 0 of B 
      b_rows[1]   = '{1, 2, 3};  // Row 1 of B
      b_rows[2]   = '{1, 2, 3};  // Row 2 of B

      // Expected result: 0 × B = 0
      expected[0] = '{0, 0, 0};
      expected[1] = '{0, 0, 0};
      expected[2] = '{0, 0, 0};

      reset_dut();
      feed_matrix_data(a_cols[0], b_rows[0], a_cols[1], b_rows[1], a_cols[2], b_rows[2]);
      capture_results("Zero Matrix");
      check_results(expected, "Zero Matrix");
    end
  endtask

  // Testcase 5: Detailed Debug Test with PE Monitoring
  task automatic run_debug_test();
    data_word_t   a_cols  [     3][N_SIZE];
    data_word_t   b_rows  [     3][N_SIZE];
    result_word_t expected[N_SIZE][N_SIZE];
    begin
      test_case++;
      $display("=================================================================");
      $display("TEST CASE %0d: Detailed Debug Test with PE Monitoring", test_case);
      $display("=================================================================");


      a_cols[0]   = '{1, 1, 1};
      a_cols[1]   = '{1, 1, 1};
      a_cols[2]   = '{1, 1, 1};

      b_rows[0]   = '{1, 1, 1};
      b_rows[1]   = '{1, 1, 1};
      b_rows[2]   = '{1, 1, 1};

      expected[0] = '{3, 3, 3};
      expected[1] = '{3, 3, 3};
      expected[2] = '{3, 3, 3};

      reset_dut();

      $display("Starting cycle-by-cycle PE monitoring...");
      start_pe_monitoring(20);  // Monitor for 20 cycles

      feed_matrix_data(a_cols[0], b_rows[0], a_cols[1], b_rows[1], a_cols[2], b_rows[2]);
      capture_results("Debug Test");
      check_results(expected, "Debug Test");
    end
  endtask
  //////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Task: Reset the DUT
  task automatic reset_dut();
    begin
      $display("Resetting DUT...");
      rst_n    = 0;
      valid_in = 0;
      for (int i = 0; i < N_SIZE; i++) begin
        matrix_a_in[i] = '0;
        matrix_b_in[i] = '0;
      end
      repeat (3) @(posedge clk);
      rst_n = 1;
      @(posedge clk);
      $display("Reset completed");
    end
  endtask

  // Task: Feed matrix data (A columns, B rows)
  task automatic feed_matrix_data(
      input data_word_t a_col0[N_SIZE], input data_word_t b_row0[N_SIZE],
      input data_word_t a_col1[N_SIZE], input data_word_t b_row1[N_SIZE],
      input data_word_t a_col2[N_SIZE], input data_word_t b_row2[N_SIZE]);
    begin
      $display("Feeding matrix data over %0d cycles...", N_SIZE);

      // Wait for clock negedge, then setup data before next posedge
      @(negedge clk);
      #(CLK_PERIOD / 2 - 0.1);
      // Clk Edge 0 - Setup data before clock edge
      for (int i = 0; i < N_SIZE; i++) begin
        matrix_a_in[i] = a_col0[i];
        matrix_b_in[i] = b_row0[i];
      end
      valid_in = 1;
      @(posedge clk);
      #0.1;  // Small delay to ensure cycle_counter is updated
      $display("CLK Edge %0d: A_col0=[%0d,%0d,%0d], B_row0=[%0d,%0d,%0d]", dut.ctrl.cycle_counter,
               matrix_a_in[0], matrix_a_in[1], matrix_a_in[2], matrix_b_in[0], matrix_b_in[1],
               matrix_b_in[2]);

      // Clk Edge 1 - Setup data before clock edge
      @(negedge clk);
      #(CLK_PERIOD / 2 - 0.1);
      for (int i = 0; i < N_SIZE; i++) begin
        matrix_a_in[i] = a_col1[i];
        matrix_b_in[i] = b_row1[i];
      end
      @(posedge clk);
      #0.1;  // Small delay to ensure cycle_counter is updated
      $display("CLK Edge %0d: A_col1=[%0d,%0d,%0d], B_row1=[%0d,%0d,%0d]", dut.ctrl.cycle_counter,
               matrix_a_in[0], matrix_a_in[1], matrix_a_in[2], matrix_b_in[0], matrix_b_in[1],
               matrix_b_in[2]);

      // Clk Edge 2 - Setup data before clock edge
      @(negedge clk);
      #(CLK_PERIOD / 2 - 0.1);
      for (int i = 0; i < N_SIZE; i++) begin
        matrix_a_in[i] = a_col2[i];
        matrix_b_in[i] = b_row2[i];
      end
      @(posedge clk);
      #0.1;  // Small delay to ensure cycle_counter is updated
      $display("CLK Edge %0d: A_col2=[%0d,%0d,%0d], B_row2=[%0d,%0d,%0d]", dut.ctrl.cycle_counter,
               matrix_a_in[0], matrix_a_in[1], matrix_a_in[2], matrix_b_in[0], matrix_b_in[1],
               matrix_b_in[2]);

      // Stop input - Setup invalid state before clock edge
      @(negedge clk);
      #(CLK_PERIOD / 2 - 0.1);
      valid_in = 0;
      for (int i = 0; i < N_SIZE; i++) begin
        matrix_a_in[i] = '0;
        matrix_b_in[i] = '0;
      end
    end
  endtask

  // Task: Wait for and capture results
  task automatic capture_results(input string test_name);
    int row_count = 0;
    begin
      $display("Waiting for results from %s...", test_name);

      repeat (15) begin  // Wait up to 15 cycles for results
        @(posedge clk);
        if (valid_out) begin
          $display("CLK Edge %0d: [HIGH VALID_OUT] Row %0d = [%0d,%0d,%0d]", dut.ctrl.cycle_counter,
                   row_count, matrix_c_out[0], matrix_c_out[1], matrix_c_out[2]);

          // Store actual results
          for (int j = 0; j < N_SIZE; j++) begin
            actual_matrix[row_count][j] = matrix_c_out[j];
          end

          row_count++;
          if (row_count >= N_SIZE) break;  // Got all rows
        end
      end

      if (row_count < N_SIZE) begin
        $error("%s: Only received %0d out of %0d result rows!", test_name, row_count, N_SIZE);
        errors++;
      end
    end
  endtask

  // Task: Check results against expected values
  task automatic check_results(input result_word_t expected[N_SIZE][N_SIZE],
                               input string test_name);
    bit test_passed = 1;
    begin
      $display("Checking results for %s:", test_name);

      // Print expected vs actual matrices for debugging
      $display("Expected matrix:");
      for (int i = 0; i < N_SIZE; i++) begin
        $display("  Row %0d: [%0d,%0d,%0d]", i, expected[i][0], expected[i][1], expected[i][2]);
      end

      $display("Actual matrix:");
      for (int i = 0; i < N_SIZE; i++) begin
        $display("  Row %0d: [%0d,%0d,%0d]", i, actual_matrix[i][0], actual_matrix[i][1],
                 actual_matrix[i][2]);
      end

      for (int i = 0; i < N_SIZE; i++) begin
        for (int j = 0; j < N_SIZE; j++) begin
          if (actual_matrix[i][j] !== expected[i][j]) begin
            $error("MISMATCH at C[%0d][%0d]: expected=%0d, actual=%0d", i, j, expected[i][j],
                   actual_matrix[i][j]);
            test_passed = 0;
            errors++;
          end
        end
      end

      if (test_passed) begin
        $display("%s PASSED", test_name);
      end
      else begin
        $error("%s FAILED", test_name);
      end
    end
  endtask

  // Task: Debug PE Array - Display all accumulator and output signals
  task automatic debug_pe_array_state();
    begin
      $display("\n=================================================================");
      $display("PE ARRAY DEBUG STATE @ Cycle %0d", dut.ctrl.cycle_counter);
      $display("=================================================================");

      // Display PE Accumulator Values (Internal registers)
      $display("PE ACCUMULATOR VALUES:");
      $display("     Col0    Col1    Col2");
      $display("R0: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[0].pe_col_generation[0].pe_instance.accumulator,
               dut.pe_grid.pe_row_generation[0].pe_col_generation[1].pe_instance.accumulator,
               dut.pe_grid.pe_row_generation[0].pe_col_generation[2].pe_instance.accumulator);
      $display("R1: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[1].pe_col_generation[0].pe_instance.accumulator,
               dut.pe_grid.pe_row_generation[1].pe_col_generation[1].pe_instance.accumulator,
               dut.pe_grid.pe_row_generation[1].pe_col_generation[2].pe_instance.accumulator);
      $display("R2: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[2].pe_col_generation[0].pe_instance.accumulator,
               dut.pe_grid.pe_row_generation[2].pe_col_generation[1].pe_instance.accumulator,
               dut.pe_grid.pe_row_generation[2].pe_col_generation[2].pe_instance.accumulator);

      $display("\nPE OUTPUT RESULTS (sum_out -> pe_results_out):");
      $display("     Col0    Col1    Col2");
      $display("R0: %4d    %4d    %4d", dut.pe_results[0][0], dut.pe_results[0][1],
               dut.pe_results[0][2]);
      $display("R1: %4d    %4d    %4d", dut.pe_results[1][0], dut.pe_results[1][1],
               dut.pe_results[1][2]);
      $display("R2: %4d    %4d    %4d", dut.pe_results[2][0], dut.pe_results[2][1],
               dut.pe_results[2][2]);

      // Display PE Input Data (A and B data flowing through)
      $display("\nPE A-DATA INPUTS (Horizontal Flow):");
      $display("     Col0    Col1    Col2");
      $display("R0: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[0].pe_col_generation[0].pe_instance.a_in,
               dut.pe_grid.pe_row_generation[0].pe_col_generation[1].pe_instance.a_in,
               dut.pe_grid.pe_row_generation[0].pe_col_generation[2].pe_instance.a_in);
      $display("R1: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[1].pe_col_generation[0].pe_instance.a_in,
               dut.pe_grid.pe_row_generation[1].pe_col_generation[1].pe_instance.a_in,
               dut.pe_grid.pe_row_generation[1].pe_col_generation[2].pe_instance.a_in);
      $display("R2: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[2].pe_col_generation[0].pe_instance.a_in,
               dut.pe_grid.pe_row_generation[2].pe_col_generation[1].pe_instance.a_in,
               dut.pe_grid.pe_row_generation[2].pe_col_generation[2].pe_instance.a_in);

      $display("\nPE B-DATA INPUTS (Vertical Flow):");
      $display("     Col0    Col1    Col2");
      $display("R0: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[0].pe_col_generation[0].pe_instance.b_in,
               dut.pe_grid.pe_row_generation[0].pe_col_generation[1].pe_instance.b_in,
               dut.pe_grid.pe_row_generation[0].pe_col_generation[2].pe_instance.b_in);
      $display("R1: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[1].pe_col_generation[0].pe_instance.b_in,
               dut.pe_grid.pe_row_generation[1].pe_col_generation[1].pe_instance.b_in,
               dut.pe_grid.pe_row_generation[1].pe_col_generation[2].pe_instance.b_in);
      $display("R2: %4d    %4d    %4d",
               dut.pe_grid.pe_row_generation[2].pe_col_generation[0].pe_instance.b_in,
               dut.pe_grid.pe_row_generation[2].pe_col_generation[1].pe_instance.b_in,
               dut.pe_grid.pe_row_generation[2].pe_col_generation[2].pe_instance.b_in);

      // Display Control Signals
      $display("\nCONTROL SIGNALS:");

      $display("  valid_in       = %b", valid_in);
      $display("  valid_out      = %b", valid_out);
      $display("  controller_state = %s", dut.ctrl.current_state.name());
      $display("  cycle_counter  = %0d", dut.ctrl.cycle_counter);
      $display("  row_select     = %0d", dut.row_select);

      // Display Skewed Input Data
      $display("\nSKEWED INPUT DATA:");
      $display("  A_skewed: [%0d,%0d,%0d]", dut.skewed_a_data[0], dut.skewed_a_data[1],
               dut.skewed_a_data[2]);
      $display("  B_skewed: [%0d,%0d,%0d]", dut.skewed_b_data[0], dut.skewed_b_data[1],
               dut.skewed_b_data[2]);

      // Display Final Output
      $display("\nFINAL MATRIX OUTPUT:");
      $display("  matrix_c_out: [%0d,%0d,%0d]", matrix_c_out[0], matrix_c_out[1], matrix_c_out[2]);

    end
  endtask

  // Task: Continuous PE monitoring (call this to start cycle-by-cycle monitoring)
  task automatic start_pe_monitoring(input int num_cycles);
    begin
      $display("\n>>> STARTING %0d CYCLES OF PE MONITORING <<<", num_cycles);
      fork
        begin
          repeat (num_cycles) begin
            @(posedge clk);
            debug_pe_array_state();
          end
        end
      join_none
    end
  endtask

  // Task: Print final test summary
  task automatic print_final_summary();
    begin
      $display("=================================================================");
      $display("FINAL TEST SUMMARY");
      $display("=================================================================");
      $display("Total test cases run: %0d", test_case);
      $display("Total errors found: %0d", errors);

      if (errors == 0) begin
        $display("ALL TESTS PASSED! Systolic array is working correctly.");
      end
      else begin
        $error("%0d ERRORS DETECTED! Please review the failures above.", errors);
      end
      $display("=================================================================\n\n");
    end
  endtask

endmodule

