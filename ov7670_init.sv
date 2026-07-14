module ov7670_init (
    input  logic       clk,         // 25.175 MHz Main Clock
    input  logic       rst_n,       // Active-low asynchronous reset
    input  logic       start,       // Pulse to start a write transfer
    input  logic [7:0] reg_addr,    // Target OV7670 Register Address
    input  logic [7:0] reg_data,    // Data byte to write
    output logic       ready,       // High when idle and ready for next command
    output logic       sio_c,       // SIO_C clock output to camera
    inout  wire        sio_d        // Bidirectional SIO_D line to camera
);
localparam DEVICE_ADDR = 8'h42; //Device Write Address

//FSM STATES
localparam S_IDLE     = 0;
localparam S_START    = 1;
localparam S_TRANSMIT = 2;
localparam S_STOP     = 3;
localparam S_DONE     = 4;

// Internal control signals for SIO_D tri-state
logic sio_d_out_en;
logic sio_d_out;

//FSM variables
logic [1:0]  sub_step;      // Tracks the 4 ticks of each bit (0 to 3)
logic [4:0]  bit_index;     // Tracks the active bit (0 to 26 for 3 phases of 9 bits)
logic [26:0] tx_shift_reg;  // Combined 27-bit packet

// Identify ACK/Don't-Care bits (bit 8, 17, and 26)
logic is_ack_bit;

//400 KHz clock variables
logic [5:0] tick_counter;
logic       tick_400k;

assign sio_d = (sio_d_out_en) ? sio_d_out : 1'bZ;

assign is_ack_bit = (bit_index == 8 || bit_index == 17 || bit_index == 26);


//400 KHz clock 25.125MHz/400KHz = 62
always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)             tick_counter <= 0               ; else
    if(tick_counter == 62) tick_counter <= 0               ; else
                           tick_counter <= tick_counter + 1;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n)             tick_400k <= 0; else
    if(tick_counter == 62) tick_400k <= 1; else
                           tick_400k <= 0;
end


// ===================================================================
// 1. FSM State and Sequencer Counters
// ===================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state     <= S_IDLE;
        sub_step  <= 2'd0;
        bit_index <= 5'd0;
    end else if (tick_400k) begin
        case (state)
            S_IDLE: begin
                if (start) begin
                    state     <= S_START;
                    sub_step  <= 2'd0;
                    bit_index <= 5'd0;
                end
            end
            
            S_START: begin
                sub_step <= sub_step + 1;
                if (sub_step == 2'd3) begin
                    state <= S_TRANSMIT;
                end
            end
            
            S_TRANSMIT: begin
                sub_step <= sub_step + 1;
                if (sub_step == 2'd3) begin
                    if (bit_index == 26) begin
                        state <= S_STOP;
                    end else begin
                        bit_index <= bit_index + 1;
                    end
                end
            end
            
            S_STOP: begin
                sub_step <= sub_step + 1;
                if (sub_step == 2'd3) begin
                    state <= S_DONE;
                end
            end
            
            S_DONE: begin
                state <= S_IDLE;
            end
            
            default: state <= S_IDLE;
        endcase
    end
end


// ===================================================================
// 2. Data Shift Register (Load and Hold)
// ===================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        tx_shift_reg <= 27'd0;
    end else if (tick_400k) begin
        if (state == IDLE && start) begin
            // Pack: [Device Write Address] + [Reg Address] + [Reg Data]
            tx_shift_reg <= {DEVICE_ADDR, 1'b1, reg_addr, 1'b1, reg_data, 1'b1}; //1'b1 added to make 9 bits/write
        end
    end
end


// ===================================================================
// 3. SIO_C (Clock) Line Control
// ===================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sio_c <= 1'b1;
    end else if (tick_400k) begin
        case (state)     
            S_START: begin
                case (sub_step)
                    2'd0, 2'd1, 2'd2: sio_c <= 1'b1;
                    2'd3:             sio_c <= 1'b0; // Pull SIO_C low at the end
                endcase
            end
            
            S_TRANSMIT: begin
                case (sub_step)
                    2'd0, 2'd3: sio_c <= 1'b0; // Low phase
                    2'd1, 2'd2: sio_c <= 1'b1; // High phase (Data read window)
                endcase
            end
            
            S_STOP: begin
                case (sub_step)
                    2'd0:             sio_c <= 1'b0;
                    2'd1, 2'd2, 2'd3: sio_c <= 1'b1; // Bring SIO_C back high for stop
                endcase
            end

            // S_IDLE, S_DONE, and any unexpected/corrupted states
            default: sio_c <= 1'b1;
        endcase
    end
end


// ===================================================================
// 4. SIO_D (Data) and Output Enable (OE) Control
// ===================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sio_d_out <= 1'b1;
        sio_d_oe  <= 1'b1;
    end else if (tick_400k) begin
        case (state)       
            S_START: begin
                sio_d_oe <= 1'b1;
                case (sub_step)
                    2'd0:             sio_d_out <= 1'b1;
                    2'd1, 2'd2, 2'd3: sio_d_out <= 1'b0; // Drop SIO_D for Start Condition
                endcase
            end
            
            S_TRANSMIT: begin
                // Update data only at the start of each bit (sub_step 0)
                if (sub_step == 2'd0) begin
                    if (is_ack_bit) begin
                        sio_d_oe <= 1'b0; // Release bus (High-Z) for the ACK phase
                    end else begin
                        sio_d_oe  <= 1'b1;
                        sio_d_out <= tx_shift_reg[26 - bit_index];
                    end
                end
            end
            
            S_STOP: begin
                sio_d_oe <= 1'b1;
                case (sub_step)
                    2'd0, 2'd1: sio_d_out <= 1'b0;
                    2'd2, 2'd3: sio_d_out <= 1'b1; // Rise SIO_D to 1 for Stop Condition
                endcase
            end

            // S_IDLE, S_DONE, and any unexpected/corrupted states
            default: begin
                sio_d_out <= 1'b1;
                sio_d_oe  <= 1'b1;
            end
        endcase
    end
end


// ===================================================================
// 5. Ready Status Flag Control
// ===================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ready <= 1'b1;
    end else if (tick_400k) begin
        case (state)
            S_IDLE: begin
                if (start) ready <= 1'b0;
                else       ready <= 1'b1;
            end
            
            S_DONE: begin
                ready <= 1'b1;
            end

            default: begin
                ready <= 1'b0; // Busy in all other active states
            end
        endcase
    end
end

endmodule