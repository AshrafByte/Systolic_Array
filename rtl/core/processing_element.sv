/**
 * Systolic Processing Element (PE)
 * 
 * Core computational unit performing multiply-accumulate operations.
 * Implements systolic data flow with self-contained accumulation.
 * 
 * Functional Behavior:
 * - Continuous data pass-through for systolic flow
 * - Conditional accumulation based on enable signal  
 * - Independent horizontal and vertical data paths
 * - Reset-to-zero accumulator initialization
 * 
 * Data Flow Pattern:
 * - A data: Flows horizontally (left → right)
 * - B data: Flows vertically (top → bottom)  
 * - Accumulation: sum += a_input × b_input
 */
module processing_element #(
  parameter      DATA_WIDTH    = 8,
  parameter type data_word_t   = logic [    DATA_WIDTH-1:0],
  parameter type result_word_t = logic [2 * DATA_WIDTH-1:0]
) (
    input  logic         clk,
    input  logic         rst_n,
    input  data_word_t   a_in,
    input  data_word_t   b_in,
    output data_word_t   a_out,
    output data_word_t   b_out,
    output result_word_t sum_out
);

  //==========================================================================
  // Internal Storage Elements
  //==========================================================================
  data_word_t   a_register;  // A data pipeline register
  data_word_t   b_register;  // B data pipeline register
  result_word_t product;
  result_word_t accumulator;  // MAC accumulator

  //==========================================================================
  // PE Core Logic
  // Purpose: Implement systolic data flow with MAC operation
  //==========================================================================
  assign product = a_in * b_in;

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      // Initialize all registers to zero
      a_register  <= '0;
      b_register  <= '0;
      accumulator <= '0;
    end
    else begin
      // Systolic data flow: Always pass data through
      a_register  <= a_in;
      b_register  <= b_in;

      // Conditional accumulation: Only when enabled
      accumulator <= accumulator + product;
    end
  end

  //==========================================================================
  // Output Port Assignments
  //==========================================================================
  assign a_out   = a_register;  // Horizontal data flow continuation
  assign b_out   = b_register;  // Vertical data flow continuation  
  assign sum_out = accumulator;  // Current accumulated result

endmodule
