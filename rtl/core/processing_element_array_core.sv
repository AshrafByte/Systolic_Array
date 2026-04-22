/**
 * Processing Element Array Grid
 * 
 * NxN matrix of systolic processing elements with internal interconnections.
 * Implements the core computational engine for matrix multiplication.
 * 
 * Architecture Details:
 * - Bidirectional data flow: A data horizontal, B data vertical
 * - Internal PE interconnection mesh for systolic operation
 * - Boundary injection of input data streams
 * - Parallel result extraction from all PE accumulators
 * 
 * Data Flow Topology:
 * - Left boundary: A matrix column data injection
 * - Top boundary: B matrix row data injection  
 * - Internal mesh: PE-to-PE systolic data propagation
 * - Result matrix: Accumulated values from each PE
 */
module processing_element_array_core #(
  parameter  int  N_SIZE        = 5,
  parameter  int  DATA_WIDTH    = 8,
  localparam type data_word_t   = logic [    DATA_WIDTH - 1 : 0],
  localparam type result_word_t = logic [2 * DATA_WIDTH - 1 : 0]
) (
    input  logic         clk,
    input  logic         rst_n,
    input  data_word_t   row_data      [N_SIZE],
    input  data_word_t   col_data      [N_SIZE],
    output result_word_t pe_results_out[N_SIZE][N_SIZE]
);

  //==========================================================================
  // Internal Systolic Interconnection Arrays
  // Purpose: Create mesh network for PE-to-PE data flow
  //==========================================================================

  // Horizontal data flow wires (A matrix data)
  // Extra column for output termination: [N_SIZE][N_SIZE+1]
  data_word_t horizontal_bus[  N_SIZE][N_SIZE+1];

  // Vertical data flow wires (B matrix data)  
  // Extra row for output termination: [N_SIZE+1][N_SIZE]
  data_word_t vertical_bus  [N_SIZE+1][  N_SIZE];

  //==========================================================================
  // Boundary Data Injection
  // Purpose: Connect external inputs to PE array edges
  //==========================================================================
  generate
    for (genvar i = 0; i < N_SIZE; i++) begin : boundary_connections
      // Left boundary: Inject A matrix column data (horizontal flow)
      assign horizontal_bus[i][0] = col_data[i];

      // Top boundary: Inject B matrix row data (vertical flow)
      assign vertical_bus[0][i]   = row_data[i];
    end
  endgenerate

  //==========================================================================
  // PE Array Grid Instantiation
  // Purpose: Create NxN processing elements with systolic interconnections
  //==========================================================================
  generate
    for (genvar row = 0; row < N_SIZE; row++) begin : pe_row_generation
      for (genvar col = 0; col < N_SIZE; col++) begin : pe_col_generation

        // Individual PE instantiation with mesh connections
        processing_element #(
          .data_word_t  (data_word_t),
          .result_word_t(result_word_t)
        ) pe_instance (
          // Clock and reset
          .clk  (clk),
          .rst_n(rst_n),
          // Systolic data inputs (from mesh)
          .a_in (horizontal_bus[row][col]),  // From left neighbor
          .b_in (vertical_bus[row][col]),    // From top neighbor

          // Systolic data outputs (to mesh)
          .a_out(horizontal_bus[row][col+1]),  // To right neighbor
          .b_out(vertical_bus[row+1][col]),    // To bottom neighbor

          // Accumulated result output
          .sum_out(pe_results_out[row][col])  // To result matrix
        );
      end
    end
  endgenerate

endmodule
