module ov7670_sccb (
    input  logic       clk,                                                                    // 25.175 MHz Main Clock
    input  logic       rst_n,                                                                  // Active-low asynchronous reset
    input  logic       start,                                                                  // Pulse to start a write transfer
    input  logic [7:0] reg_addr,                                                               // Target OV7670 Register Address
    input  logic [7:0] reg_data,                                                               // Data byte to write
    output logic       ready,                                                                  // High when idle and ready for next command
    output logic       sio_c,                                                                  // SIO_C clock output to camera
    inout  logic       sio_d                                                                   // Bidirectional SIO_D line to camera
);
    localparam DEVICE_ADDR = 8'h42;                                                            //Device Write Address

    //FSM STATES
    typedef enum logic [2:0] {
        S_IDLE    ,
        S_START   ,
        S_TRANSMIT,
        S_STOP    ,
        S_DONE
    } state_t;

    state_t state;

    // Internal control signals for SIO_D tri-state
    logic sio_d_out_en;
    logic sio_d_out   ;

    //FSM variables
    logic [1:0]  sub_step    ;                                                                  // Tracks the 4 ticks of each bit (0 to 3)
    logic [4:0]  bit_index   ;                                                                  // Tracks the active bit (0 to 26 for 3 phases of 9 bits)
    logic [26:0] tx_shift_reg;                                                                  // Combined 27-bit packet

    logic is_ack_bit;                                                                           // Identify ACK/Don't-Care bits (bit 8, 17, and 26)

    //400 KHz clock variables
    logic [5:0] tick_counter;
    logic       tick_400k   ;

    assign sio_d = (sio_d_out_en) ? sio_d_out : 1'bZ;                                           //use sio_d_out one way (just to transmit)

    assign is_ack_bit = ((bit_index == 8) || (bit_index == 17) || (bit_index == 26));           // 8-camera addr; 17-settigns addr; 26-data  

    assign ready = ((state == S_IDLE) && (!start));                                             // High when idle and ready for next command

//400 KHz clock divider: 25.175MHz / 400KHz = ~63 de perioade
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n            ) tick_counter <= '0              ; else 
        if(tick_counter == 62) tick_counter <= '0              ; else
                               tick_counter <= tick_counter + 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n            ) tick_400k <= 0; else 
        if(tick_counter == 62) tick_400k <= 1; else
                               tick_400k <= 0;
    end


// 1. FSM STATE (state) - Controls the main state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                    )                                  state <= S_IDLE    ; else
        if ((state == S_IDLE) && start)                                  state <= S_START   ; else

        if (tick_400k                 ) begin
            case (state)
                S_START   : if ((sub_step == 2'd3)                     ) state <= S_TRANSMIT;

                S_TRANSMIT: if ((sub_step == 2'd3) && (bit_index == 26)) state <= S_STOP    ;

                S_STOP    : if ((sub_step == 2'd3)                     ) state <= S_DONE    ;

                S_DONE    :                                              state <= S_IDLE    ;

                default   :                                              state <= S_IDLE    ;
            endcase
        end
    end


// 2. SUB-STEP COUNTER (sub_step) - Internal frequency divider (4 steps)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                                  ) sub_step <= 2'd0           ; else
        if ((state == S_IDLE) && start              ) sub_step <= 2'd0           ; else
        if (tick_400k && ((state == S_START   ) || 
                          (state == S_TRANSMIT) || 
                          (state == S_STOP    )    )) sub_step <= sub_step + 1'b1;
    end


// 3. BIT INDEX COUNTER (bit_index) - Counts transmitted bits
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                    ) bit_index <= 5'd0            ; else
        if ((state == S_IDLE) && start) bit_index <= 5'd0            ; else
        if (tick_400k             && 
            (state == S_TRANSMIT) && 
            (sub_step == 2'd3)    &&
            (bit_index != 26)         ) bit_index <= bit_index + 1'b1;
    end


// 4. DATA SHIFT REGISTER (tx_shift_reg)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                    ) tx_shift_reg <= 27'd0                                              ; else
        if ((state == S_IDLE) && start) tx_shift_reg <= {DEVICE_ADDR, 1'b1, reg_addr, 1'b1, reg_data, 1'b1};
    end


// 5. SIO_C (CLOCK) LINE CONTROL
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n   )                                                    sio_c <= 1'b1; else
        if (tick_400k) begin
            case (state)     
                S_START   : if (sub_step == 2'd3                        ) sio_c <= 1'b0; else 
                                                                          sio_c <= 1'b1;
                
                S_TRANSMIT: if ((sub_step == 2'd0) || (sub_step == 2'd3)) sio_c <= 1'b0; else
                                                                          sio_c <= 1'b1;
                
                S_STOP    : if (sub_step == 2'd0                        ) sio_c <= 1'b0; else
                                                                          sio_c <= 1'b1;

                default   :                                               sio_c <= 1'b1;
            endcase
        end
    end


// 6. OUTPUT ENABLE CONTROL (sio_d_out_en) - Tristate buffer control
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                                 ) sio_d_out_en <= 1'b1; else
        if (tick_400k && ((state == S_TRANSMIT) && 
                          (sub_step == 2'd0)    && 
                           is_ack_bit             )) sio_d_out_en <= 1'b0; else
        if (tick_400k                              ) sio_d_out_en <= 1'b1;                                          //High-Z at ACK bits
    end


// 7. SIO_D (DATA) LINE CONTROL
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n   )                                             sio_d_out <= 1'b1; else
        if (tick_400k) begin
            case (state)       
                S_START   : if (sub_step == 2'd0                 ) sio_d_out <= 1'b1                        ; else 
                                                                   sio_d_out <= 1'b0                        ;

                S_TRANSMIT: if ((sub_step == 2'd0) && !is_ack_bit) sio_d_out <= tx_shift_reg[26 - bit_index];  

                S_STOP    : if (sub_step <= 2'd1                 ) sio_d_out <= 1'b0                        ; else  // sub_step 0 și 1
                                                                   sio_d_out <= 1'b1                        ;       // sub_step 2 și 3   

                default   :                                        sio_d_out <= 1'b1                        ;
            endcase
        end
    end

endmodule


/*
  Each transmitted bit is divided into 4 sub-steps (0 to 3) driven by tick_400k
  to ensure proper I2C/SCCB setup and hold timing:

  - sub_step 0: SIO_C = 0 | SIO_D data bit is updated (Setup phase, clock is LOW).
  - sub_step 1: SIO_C = 1 | SIO_C goes HIGH; SIO_D data line remains stable.
  - sub_step 2: SIO_C = 1 | SIO_C stays HIGH; camera samples/reads the bit.
  - sub_step 3: SIO_C = 0 | SIO_C goes LOW; bit period ends, preparing for next bit.
*/