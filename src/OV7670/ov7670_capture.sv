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

    logic       cycle; 
    logic [7:0] first_byte; // Îl păstrăm doar ca buffer gol pentru primul ciclu
    
    // Signals for rising edge detection of VSYNC (new frame start)
    logic vsync_prev;
    wire  frame_start;

    always_ff @(posedge pclk) begin
        vsync_prev <= vsync;
    end
    
    assign frame_start = vsync_prev && !vsync;

// Capture and write logic
    always_ff @(posedge pclk) begin
        if (vsync) begin
            bram_addr <= '0;
            cycle     <= 1'b0;
            bram_we   <= 1'b0;
        end else if (camera_ready) begin
            bram_we <= 1'b0;
            
            if (href) begin
                cycle <= ~cycle;
                
                if (cycle == 1'b0) begin
                    // CICLUL 1: Camera ne dă octetul Y (Luminanța)
                    // Îl salvăm în 'first_byte' pentru a-l scrie la următorul pas
                    first_byte <= d; 
                end else begin
                    // CICLUL 2: Camera ne dă U sau V. ÎL IGNORĂM.
                    // În schimb, trimitem către BRAM octetul Y salvat anterior!
                    bram_data_grey <= first_byte;
                    bram_we        <= 1'b1;     
                    
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