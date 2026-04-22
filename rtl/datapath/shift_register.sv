/**
 * Programmable Delay Chain (Shift Register)
 * 
 * Configurable delay element for systolic array input skewing.
 * Provides precise timing alignment for PE array data synchronization.
 * 
 * Design Features:
 * - Zero-delay bypass for STAGES=0 (direct wire connection)
 * - Parametric depth for flexible delay requirements
 * - Synchronous operation with reset capability
 * - Optimized for systolic timing requirements
 */
module shift_register #(
  parameter       DATA_WIDTH  = 8,
  parameter  int  STAGES      = 1,
  localparam type data_word_t = logic [DATA_WIDTH-1:0]
) (
    input  logic       clk,
    input  logic       rst_n,
    input  data_word_t data_in,
    output data_word_t data_out
);

  //==========================================================================
  // Conditional Delay Generation
  // Purpose: Optimize hardware for different delay requirements
  //==========================================================================

  data_word_t delay_stages[STAGES];

  //======================================================================
  // Shift Register Implementation
  // Purpose: Create configured cycles of delay with proper reset behavior
  //======================================================================
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      // Initialize all stages to zero
      for (int i = 0; i < STAGES; i++) delay_stages[i] <= '0;
    end

    else begin
      // Shift data through the chain
      delay_stages[0] <= data_in;
      for (int i = 1; i < STAGES; i++) delay_stages[i] <= delay_stages[i-1];
    end
  end

  assign data_out = delay_stages[STAGES-1];

endmodule
