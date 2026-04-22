/**
 * Output Row Multiplexer  
 * 
 * Parallel-to-serial row selector for matrix result output.
 * Extracts one complete row from NxN PE result matrix per selection cycle.
 * 
 * Operation Principle:
 * - Input: Complete NxN matrix of accumulated results
 * - Selection: Row index determines which row to output
 * - Output: Selected row as N-element array
 * - Bounds checking: Invalid selections return zero
 * 
 * Usage in Systolic Array:
 * - Controller sequences through row indices 0 to N-1
 * - Each cycle outputs next row of result matrix
 * - Enables pipelined result streaming
 */
module row_selector #(
  parameter  int  N_SIZE        = 5,
  parameter  int  DATA_WIDTH    = 8,
  localparam type row_sel_t     = logic [$clog2(N_SIZE)-1:0],
  localparam type result_word_t = logic [2*DATA_WIDTH - 1:0]
) (
    input  row_sel_t     sel,
    input  result_word_t data_in [N_SIZE][N_SIZE],
    output result_word_t data_out[N_SIZE]
);

  //==========================================================================
  // Row Selection Logic
  // Purpose: Extract one row from matrix based on selection index
  //==========================================================================
  always_comb begin
    result_word_t selected_value;

    for (int col = 0; col < N_SIZE; col++) begin
      // Select row if index is valid, otherwise output zero
      selected_value = (sel < N_SIZE) ? data_in[sel][col] : '0;
      data_out[col]  = selected_value;
    end
  end

endmodule
