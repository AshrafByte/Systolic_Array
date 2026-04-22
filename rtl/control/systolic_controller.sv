/**
 * Systolic Array Computation Controller
 * 
 * Three-phase FSM orchestrating matrix multiplication:
 * 1. IDLE: Wait for input data stream
 * 2. INPUT: Accept N_SIZE cycles of input data
 * 3. COMPUTE: Generate N_SIZE output results
 * 
 * Timing Architecture:
 * - Phase transitions triggered by cycle counters
 * - Accumulator clearing synchronized to computation start
 * - Output window generation for result availability
 * - Row selection sequencing for multi-cycle output
 */
module systolic_controller #(
  parameter  int  N_SIZE        = 5,
  localparam type row_sel_t     = logic [    $clog2(N_SIZE)-1:0],
  localparam type cycle_count_t = logic [$clog2(2*N_SIZE+1)-1:0],
  localparam type input_count_t = logic [  $clog2(N_SIZE+1)-1:0]
) (
    input  logic     clk,
    input  logic     rst_n,
    input  logic     valid_in,
    output logic     valid_out,
    output row_sel_t row_sel
);

  //==========================================================================
  // Type Definitions
  //==========================================================================
  typedef enum logic [1:0] {
    IDLE,
    INPUT,
    COMPUTE
  } fsm_state_t;

  //==========================================================================
  // State Machine Registers
  //==========================================================================
  fsm_state_t current_state, next_state;
  cycle_count_t cycle_counter;  // Global cycle counter
  input_count_t input_counter;  // Input data counter

  //==========================================================================
  // State Machine Sequential Logic
  // Purpose: Manage state transitions and counter updates
  //==========================================================================
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      // Reset to known state
      current_state <= IDLE;
      cycle_counter <= 0;
      input_counter <= 0;
    end
    else begin
      current_state <= next_state;

      // Counter management per state
      case (current_state)
        IDLE: begin
          cycle_counter <= 0;
          if (valid_in)  // Start new computation cycle
            input_counter <= 1;
          else  // Stay idle
            input_counter <= 0;
        end

        INPUT: begin
          // Count valid input cycles
          if (valid_in) input_counter <= input_counter + 1;
          cycle_counter <= cycle_counter + 1;
        end

        COMPUTE: begin
          // Continue counting during computation
          cycle_counter <= cycle_counter + 1;
        end

        default: begin
          cycle_counter <= 0;
          input_counter <= 0;
        end
      endcase
    end
  end

  //==========================================================================
  // State Machine Combinational Logic  
  // Purpose: Determine next state based on current conditions
  //==========================================================================
  always_comb begin
    next_state = current_state;

    case (current_state)
      IDLE: if (valid_in) next_state = INPUT;

      INPUT: if (input_counter >= N_SIZE) next_state = COMPUTE;

      COMPUTE: if (cycle_counter >= 2 * N_SIZE - 1) next_state = IDLE;

      default: next_state = IDLE;
    endcase
  end

  //==========================================================================
  // Output Control Signal Generation
  // Purpose: Generate control signals for PE array and output multiplexer
  //=========================================================================

  // Output window: Results ready from cycle N_SIZE+2 to 2*N_SIZE+1
  logic output_window_active;
  assign output_window_active = (cycle_counter >= N_SIZE + 1 && cycle_counter <= 2 * N_SIZE);

  // Row selector: Sequence through output rows during valid window
  assign row_sel              = output_window_active ? row_sel_t'(cycle_counter - N_SIZE - 1) : '0;

  // Output valid signal generation
  assign valid_out            = output_window_active;

endmodule
