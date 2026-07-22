module ov7670_init (
    input  logic       clk,           // 25.175 MHz Main Clock
    input  logic       rst_n,         // Active-low reset
    input  logic       sccb_ready,    // Input from ov7670_sccb (ready)
    
    output logic       sccb_start,    // Output to ov7670_sccb (start)
    output logic [7:0] sccb_reg_addr, // Output to ov7670_sccb (reg_addr)
    output logic [7:0] sccb_reg_data, // Output to ov7670_sccb (reg_data)
    output logic       done           // Goes high when configuration finishes successfully
);

    // Total number of registers in the new initialization table
    localparam TOTAL_REGS = 15;

    // Finite State Machine (FSM)
    typedef enum logic [2:0] {
        S_RESET_DELAY, // Wait ~30ms after the camera software reset command
        S_FETCH,       // Fetch the next register from ROM
        S_START_WRITE, // Generate the start pulse for SCCB
        S_WAIT_READY,  // Wait for the SCCB module to finish transmission (ready == 1)
        S_NEXT,        // Move to the next register or finish
        S_DONE         // Initialization finished
    } state_t;

    state_t state;

    // Pointer to the current register in ROM
    logic [4:0] reg_ptr;

    // Timer for reset delay (~30 ms at 25.175 MHz clock)
    // 25.175 MHz * 30 ms = 755,250 clock cycles
    logic [19:0] delay_counter;
    localparam DELAY_30MS = 20'd755250;

    // Structure for storing (Address, Value) pairs
    typedef struct packed {
        logic [7:0] addr;
        logic [7:0] data;
    } reg_t;

    // ROM containing camera configuration (Native QVGA, RGB565)
    reg_t rom_regs [TOTAL_REGS];
    
    always_comb begin
        // 1. Mandatory software reset (wait ~30ms after this step)
        rom_regs[0]  = '{addr: 8'h12, data: 8'h80}; // COM7: Full Reset
        
        // 2. Format and resolution (QVGA, RGB565)
        rom_regs[1]  = '{addr: 8'h12, data: 8'h10}; // COM7: QVGA + RGB
        rom_regs[2]  = '{addr: 8'h40, data: 8'hC0}; // COM15: RGB565 standard, full range
        rom_regs[3]  = '{addr: 8'h3A, data: 8'h04}; // TSLB: Bit alignment
        
        // 3. Enable internal hardware scaling in the camera (VGA -> QVGA)
        rom_regs[4]  = '{addr: 8'h0C, data: 8'h08}; // COM3: Enable internal scaling
        rom_regs[5]  = '{addr: 8'h3E, data: 8'h19}; // COM14: Enable PCLK clock scaling
        rom_regs[6]  = '{addr: 8'h72, data: 8'h11}; // SCALING_DCWCTR: Vertical/horizontal decimation
        rom_regs[7]  = '{addr: 8'h73, data: 8'hF1}; // SCALING_PCLK_DIV: Pixel clock divider
        
        // 4. Pixel clock frequency (CLKRC divided by 2 for stability)
        rom_regs[8]  = '{addr: 8'h11, data: 8'h01}; // CLKRC: Internal clock prescaler
        
        // 5. Window positioning correction (Image alignment optimized for scaling)
        rom_regs[9]  = '{addr: 8'h17, data: 8'h16}; // HSTART
        rom_regs[10] = '{addr: 8'h18, data: 8'h04}; // HSTOP
        rom_regs[11] = '{addr: 8'h32, data: 8'hA4}; // HREF
        rom_regs[12] = '{addr: 8'h19, data: 8'h02}; // VSTART
        rom_regs[13] = '{addr: 8'h1A, data: 8'h7A}; // VSTOP
        rom_regs[14] = '{addr: 8'h03, data: 8'h0A}; // VREF
        //rom_regs[15] = '{addr: 8'h41, data: 8'h38}; // COM16: Activează Denoise și Edge Enhancement
        //rom_regs[15] = '{addr: 8'h56, data: 8'h39}; // Contrast
        //rom_regs[16] = '{addr: 8'h1E, data: 8'h10}; // Mirror
        //om_regs[17] = '{addr: 8'h55, data: 8'h20}; // Brightness
        //rom_regs[18] = '{addr: 8'h57, data: 8'h50}; // Contrast center
    end

    // FSM for controlling register writes
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state         <= S_FETCH;
            reg_ptr       <= 0;
            sccb_start    <= 1'b0;
            sccb_reg_addr <= 8'h00;
            sccb_reg_data <= 8'h00;
            delay_counter <= 0;
            done          <= 1'b0;
        end else begin
            case (state)
                
                S_FETCH: begin
                    sccb_reg_addr <= rom_regs[reg_ptr].addr;
                    sccb_reg_data <= rom_regs[reg_ptr].data;
                    state         <= S_START_WRITE;
                end

                S_START_WRITE: begin
                    if (sccb_ready) begin
                        sccb_start <= 1'b1; // Generate the start pulse
                        state      <= S_WAIT_READY;
                    end
                end

                S_WAIT_READY: begin
                    sccb_start <= 1'b0; // Immediately pull down start
                    // Wait for SCCB to take the command and become ready again
                    if (sccb_ready && !sccb_start) begin
                        // If we wrote the Reset register (which is the first one, at index 0),
                        // enter the 30ms delay so that the sensor restarts stably.
                        if (reg_ptr == 0) begin
                            delay_counter <= 0;
                            state         <= S_RESET_DELAY;
                        end else begin
                            state         <= S_NEXT;
                        end
                    end
                end

                S_RESET_DELAY: begin
                    if (delay_counter >= DELAY_30MS) begin
                        state <= S_NEXT;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                S_NEXT: begin
                    if (reg_ptr == TOTAL_REGS - 1) begin
                        state <= S_DONE;
                    end else begin
                        reg_ptr <= reg_ptr + 1;
                        state   <= S_FETCH;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1; // Signals the main module that initialization has finished
                    state <= S_DONE; // Locks the FSM here until the next global Reset
                end

                default: state <= S_FETCH;
            endcase
        end
    end

endmodule