/**
 * Systolic Array Matrix Multiplier
 * 
 * High-performance NxN matrix multiplication using systolic array architecture.
 * Implements C = A × B where A columns flow right, B rows flow down.
 * 
 * Key Features:
 * - Input skewing network for proper timing alignment
 * - Self-accumulating processing elements in NxN grid
 * - FSM-controlled computation phases
 * - Sequential row output with valid signaling
 * 
 * Architecture Components:
 * 1. Input Skewing Network: Progressive delay chains for data synchronization
 * 2. Computation Controller: Three-phase FSM managing operation timing
 * 3. PE Array Grid: NxN processing elements performing matrix multiplication
 * 4. Output Row Multiplexer: Sequential result extraction and streaming
 * 
 * Performance: Results ready at cycle N_SIZE+2 after input completion
 */
module systolic_array #(
  parameter  int  DATA_WIDTH    = 8,
  parameter  int  N_SIZE        = 3,
  localparam type data_word_t   = logic [  DATA_WIDTH-1:0],
  localparam type result_word_t = logic [2*DATA_WIDTH-1:0]

) (
    input logic clk,
    input logic rst_n,
    input logic valid_in,

    input data_word_t matrix_a_in[N_SIZE],
    input data_word_t matrix_b_in[N_SIZE],

    output logic         valid_out,
    output result_word_t matrix_c_out[N_SIZE]
);

  //==========================================================================
  // Type Definitions
  //==========================================================================
  typedef logic [$clog2(N_SIZE)-1:0] row_sel_t;

  //==========================================================================
  // Internal Signal Declarations
  //==========================================================================

  // Skewed input data after delay elements
  data_word_t   skewed_a_data[N_SIZE];
  data_word_t   skewed_b_data[N_SIZE];

  // PE array computation results
  result_word_t pe_results   [N_SIZE] [N_SIZE];

  // Controller interface signals
  row_sel_t     row_select;



  //==========================================================================
  // Computation Controller
  // Purpose: Orchestrate systolic array operation phases
  //==========================================================================
  systolic_controller #(
    .N_SIZE(N_SIZE)
  ) ctrl (
    .clk      (clk),
    .rst_n    (rst_n),
    .valid_in (valid_in),
    .valid_out(valid_out),
    .row_sel  (row_select)

  );

  //==========================================================================
  // Input Skewing Network
  // Purpose: Align input data timing for proper systolic operation
  //==========================================================================
  input_skewing_network #(
    .N_SIZE(N_SIZE)
  ) input_skew (
    .clk          (clk),
    .rst_n        (rst_n),
    .valid_in     (valid_in),
    .a_columns_in (matrix_a_in),
    .b_rows_in    (matrix_b_in),
    .a_columns_out(skewed_a_data),
    .b_rows_out   (skewed_b_data)
  );

  //==========================================================================
  // Processing Element Grid
  // Purpose: Perform matrix multiplication via systolic computation
  //==========================================================================
  processing_element_array #(
    .N_SIZE(N_SIZE)
  ) pe_grid (
    .clk           (clk),
    .rst_n         (rst_n),
    .row_data      (skewed_b_data),
    .col_data      (skewed_a_data),
    .pe_results_out(pe_results)
  );

  //==========================================================================
  // Output Row Multiplexer
  // Purpose: Select and output one result row per cycle
  //==========================================================================
  row_selector #(
    .N_SIZE(N_SIZE)
  ) row_mux (
    .sel     (row_select),
    .data_in (pe_results),
    .data_out(matrix_c_out)
  );

endmodule
