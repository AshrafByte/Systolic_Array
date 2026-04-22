/**
 * Input Skewing Network
 * 
 * Dedicated timing alignment module for systolic array input synchronization.
 * Implements progressive delay chains to ensure proper data arrival timing at PE array.
 * 
 * Skewing Strategy:
 * - Element 'i' receives 'i' cycles of delay
 * - Creates diagonal wavefront of data arrival across PE grid
 * - Enables simultaneous computation start across all PEs
 * - Prevents data collision and ensures correct matrix multiplication
 * 
 * Data Flow Control:
 * - Valid-gated inputs prevent spurious accumulation
 * - Zero injection when valid_in is deasserted
 * - Synchronized A and B data stream alignment
 */
module input_skewing_network #(
    parameter N_SIZE = 5,
    parameter DATA_WIDTH = 8,
    localparam type data_word_t = logic [DATA_WIDTH-1:0]
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       valid_in,
    input  data_word_t a_columns_in  [N_SIZE],
    input  data_word_t b_rows_in     [N_SIZE],
    output data_word_t a_columns_out [N_SIZE],
    output data_word_t b_rows_out    [N_SIZE]
);

    //==========================================================================
    // Progressive Delay Chain Generation
    // Purpose: Create incrementally delayed versions of input data
    //==========================================================================
    generate
        for (genvar i = 0; i < N_SIZE; i++) begin : skewing_elements

            // Valid-gated input data to prevent spurious computation
            data_word_t gated_a_input, gated_b_input;
            assign gated_a_input = valid_in ? a_columns_in[i] : '0;
            assign gated_b_input = valid_in ? b_rows_in[i]    : '0;

            if (i == 0) begin
                assign a_columns_out[0] = gated_a_input;
                assign b_rows_out[0]    = gated_b_input;
            end

            else begin
                // A matrix column delay chain (for horizontal PE distribution)
                shift_register #(
                    .STAGES         (i)
                ) a_delay_chain (
                    .clk            (clk),
                    .rst_n          (rst_n),
                    .data_in        (gated_a_input),
                    .data_out       (a_columns_out[i])
                );

                // B matrix row delay chain (for vertical PE distribution)
                shift_register #(
                    .STAGES         (i)
                ) b_delay_chain (
                    .clk            (clk),
                    .rst_n          (rst_n),
                    .data_in        (gated_b_input),
                    .data_out       (b_rows_out[i])
                );
            end
        end
    endgenerate

endmodule
