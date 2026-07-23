module ov7670_init (
    input  logic       clk          ,                                                          // 25.175 MHz Main Clock
    input  logic       rst_n        ,                                                          // Active-low reset
    input  logic       sccb_ready   ,                                                          // Input from ov7670_sccb (ready)
    
    output logic       sccb_start   ,                                                          // Output to ov7670_sccb (start)
    output logic [7:0] sccb_reg_addr,                                                          // Output to ov7670_sccb (reg_addr)
    output logic [7:0] sccb_reg_data,                                                          // Output to ov7670_sccb (reg_data)
    output logic       done                                                                    // Goes high when configuration finishes successfully
);
    
    localparam TOTAL_REGS = 15;                                                                // Total number of registers in the new initialization table

    localparam DELAY_30MS = 20'd755250;                                                        // 25.175 MHz * 30 ms = 755,250 clock cycles


    logic [4:0] reg_ptr;                                                                       // Pointer to the current register in ROM
   
    logic [19:0] delay_counter;                                                                // Timer for reset delay (~30 ms at 25.175 MHz clock)


    // Finite State Machine (FSM)
    typedef enum logic [2:0] {
        S_RESET_DELAY,                                                                         // Wait ~30ms after the camera software reset command
        S_FETCH      ,                                                                         // Fetch the next register from ROM
        S_START_WRITE,                                                                         // Generate the start pulse for SCCB
        S_WAIT_READY ,                                                                         // Wait for the SCCB module to finish transmission (ready == 1)
        S_NEXT       ,                                                                         // Move to the next register or finish
        S_DONE                                                                                 // Initialization finished
    } state_t;

    state_t state;    

    // Structure for storing (Address, Value) pairs
    typedef struct packed {
        logic [7:0] addr;
        logic [7:0] data;
    } reg_t;

    // ROM containing camera configuration (Native QVGA, YUV422)
    reg_t rom_regs [TOTAL_REGS];

    
    always_comb begin
        // 1. Mandatory software reset (wait ~30ms after this step)
        rom_regs[0]  = '{addr: 8'h12, data: 8'h80};                                             // COM7: Full Reset
        
        // 2. Format and resolution (QVGA, RGB565)
        rom_regs[1]  = '{addr: 8'h12, data: 8'h10};                                             // COM7: QVGA + YUV
        rom_regs[2]  = '{addr: 8'h40, data: 8'hC0};                                             // COM15: YUV
        rom_regs[3]  = '{addr: 8'h3A, data: 8'h04};                                             // TSLB: Bit alignment
        
        // 3. Enable internal hardware scaling in the camera (VGA -> QVGA)
        rom_regs[4]  = '{addr: 8'h0C, data: 8'h08};                                             // COM3: Enable internal scaling
        rom_regs[5]  = '{addr: 8'h3E, data: 8'h19};                                             // COM14: Enable PCLK clock scaling
        rom_regs[6]  = '{addr: 8'h72, data: 8'h11};                                             // SCALING_DCWCTR: Vertical/horizontal decimation
        rom_regs[7]  = '{addr: 8'h73, data: 8'hF1};                                             // SCALING_PCLK_DIV: Pixel clock divider
        
        // 4. Pixel clock frequency (CLKRC divided by 2 for stability)
        rom_regs[8]  = '{addr: 8'h11, data: 8'h01};                                             // CLKRC: Internal clock prescaler
        
        // 5. Window positioning correction (Image alignment optimized for scaling)
        rom_regs[9]  = '{addr: 8'h17, data: 8'h16};                                             // HSTART
        rom_regs[10] = '{addr: 8'h18, data: 8'h04};                                             // HSTOP
        rom_regs[11] = '{addr: 8'h32, data: 8'hA4};                                             // HREF
        rom_regs[12] = '{addr: 8'h19, data: 8'h02};                                             // VSTART
        rom_regs[13] = '{addr: 8'h1A, data: 8'h7A};                                             // VSTOP
        rom_regs[14] = '{addr: 8'h03, data: 8'h0A};                                             // VREF

        //rom_regs[15] = '{addr: 8'h41, data: 8'h38};                                           // COM16: Activează Denoise și Edge Enhancement
        //rom_regs[15] = '{addr: 8'h56, data: 8'h39};                                           // Contrast
        //rom_regs[16] = '{addr: 8'h1E, data: 8'h10};                                           // Mirror
        //om_regs[17] = '{addr: 8'h55, data: 8'h20};                                            // Brightness
        //rom_regs[18] = '{addr: 8'h57, data: 8'h50};                                           // Contrast center
    end

    // FSM for controlling register writes
// 1. STATE MACHINE (Next State Logic)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) state <= S_FETCH; else
        case (state)
            S_FETCH      :                                                  state <= S_START_WRITE;
            
            S_START_WRITE: if (sccb_ready                                 ) state <= S_WAIT_READY ;
            
            S_WAIT_READY : if (sccb_ready && !sccb_start && (reg_ptr == 0)) state <= S_RESET_DELAY; else
                           if (sccb_ready && !sccb_start                  ) state <= S_NEXT       ;
                               
            S_RESET_DELAY: if (delay_counter >= DELAY_30MS                ) state <= S_NEXT       ;
            
            S_NEXT       : if (reg_ptr == (TOTAL_REGS - 1)                ) state <= S_DONE       ; else
                                                                            state <= S_FETCH      ;
                           
            S_DONE       :                                                  state <= S_DONE       ;
            
            default      :                                                  state <= S_FETCH      ;
        endcase
    end

    // 2. ROM REGISTER POINTER (reg_ptr)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                                            ) reg_ptr <= '0         ; else
        if ((state == S_NEXT) && (reg_ptr != (TOTAL_REGS - 1))) reg_ptr <= reg_ptr + 1;
    end

    // 3. SCCB START PULSE (sccb_start)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                                )  sccb_start <= 1'b0; else
        if ((state == S_START_WRITE) && sccb_ready)  sccb_start <= 1'b1; else                       // Generate start pulse
        if (state == S_WAIT_READY                 )  sccb_start <= 1'b0;                            // Pull down immediately
    end

    // 4. FETCH DATA & ADDRESS FROM ROM (sccb_reg_addr, sccb_reg_data)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sccb_reg_addr <= 8'h00;
            sccb_reg_data <= 8'h00;
        end else if (state == S_FETCH) begin
            sccb_reg_addr <= rom_regs[reg_ptr].addr;
            sccb_reg_data <= rom_regs[reg_ptr].data;
        end
    end

    // 5. DELAY COUNTER (delay_counter) - Used only for the first register (Reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n                     )  delay_counter <= '0; else
        if ((state == S_WAIT_READY) && 
            sccb_ready              &&
            !sccb_start             &&
            (reg_ptr == 0)              ) delay_counter <= '0; else
        if ((state == S_RESET_DELAY) &&
            (delay_counter < DELAY_30MS)) delay_counter <= delay_counter + 1;
    end

    // 6. DONE FLAG (done) - Signals the main module that initialization has finished
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)          done <= 1'b0; else
        if (state == S_DONE) done <= 1'b1;
    end

endmodule