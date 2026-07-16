module ov7670_capture (
    input  logic        pclk,             // Camera Pixel Clock (PCLK)
    input  logic        vsync,            // Camera Vertical Sync (VSYNC)
    input  logic        href,             // Camera Horizontal Reference (HREF)
    input  logic [7:0]  d,                // 8-bit camera data bus (D[7:0])
    input  logic        camera_ready,     // Initialization module complete signal (done)
    
    output logic [16:0] bram_addr,        // BRAM write address (0 - 76799)
    output logic [7:0]  bram_data_grey,   // 8-bit grayscale data sent to BRAM
    output logic        bram_we           // BRAM Write Enable
);

    // Register for pixel reconstruction (2 bytes/pixel)
    logic [7:0] first_byte;
    logic       cycle; // 0 = first byte, 1 = second byte
    
    // Signals for rising edge detection of VSYNC (new frame start)
    logic vsync_prev;
    wire  frame_start;

    always_ff @(posedge pclk) begin
        vsync_prev <= vsync;
    end
    
    // A new frame starts when VSYNC falls (transition from 1 to 0)
    assign frame_start = vsync_prev && !vsync;

    // Combinational signal declarations (outside of any always block)
    logic [4:0]  r_5;
    logic [5:0]  g_6;
    logic [4:0]  b_5;
    
    logic [7:0]  r_8;
    logic [7:0]  g_8;
    logic [7:0]  b_8;
    
    logic [15:0] grey_sum;
    logic [7:0]  grey_val;

    // Combinational assignments for calculating grayscale value
    // Standard RGB565: R (5 bits), G (6 bits), B (5 bits)
    assign r_5 = first_byte[7:3];
    assign g_6 = {first_byte[2:0], d[7:5]};
    assign b_5 = d[4:0];
    
    // Extend components to 8 bits by duplicating MSB into LSB
    assign r_8 = {r_5, r_5[4:2]};
    assign g_8 = {g_6, g_6[5:4]};
    assign b_8 = {b_5, b_5[4:2]};
   
    // FPGA optimized formula: Grey = (R*77 + G*150 + B*29) / 256
    assign grey_sum = (r_8 * 8'd77) + (g_8 * 8'd150) + (b_8 * 8'd29);
    assign grey_val = grey_sum[15:8]; // Fast division by 256

    // Capture and write logic
    always_ff @(posedge pclk or posedge vsync) begin
        if (vsync) begin
            bram_addr <= '0;
            cycle     <= 1'b0;
            bram_we   <= 1'b0;
        end else if (camera_ready) begin
            bram_we <= 1'b0;
            
            if (href) begin
                cycle <= ~cycle;
                
                if (cycle == 1'b0) begin
                    first_byte <= d; // Store the first byte
                end else begin
                    // Second byte is ready. Send the calculated value to BRAM
                    bram_data_grey <= grey_val;
                    bram_we        <= 1'b1;     // Activate write enable
                    
                    if (bram_addr < 17'd76799) begin
                        bram_addr <= bram_addr + 1'b1;
                    end
                end
            end else begin
                cycle <= 1'b0;
            end
        end
    end

endmodule