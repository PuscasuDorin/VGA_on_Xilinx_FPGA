module ov7670_capture (
    input  logic        pclk           ,                                                        // Camera Pixel Clock (PCLK)
    input  logic        vsync          ,                                                        // Camera Vertical Sync (VSYNC)
    input  logic        href           ,                                                        // Camera Horizontal Reference (HREF)
    input  logic [7:0 ]  d             ,                                                        // 8-bit camera data bus (D[7:0])
    input  logic        camera_ready   ,                                                        // Initialization module complete signal (done)
    
    output logic [16:0] bram_addr      ,                                                        // BRAM write address (0 - 76799)
    output logic [7:0 ]  bram_data_grey,                                                        // 8-bit grayscale data sent to BRAM
    output logic        bram_we                                                                 // BRAM Write Enable
);

    logic       cycle     ; 
    logic [7:0] first_byte;
    

    // 1. CYCLE COUNTER: Toggles between 0 and 1 while reading active pixels
    always_ff @(posedge pclk) begin
        if (vsync               ) cycle <= 1'b0  ; else                                         // Reset cycle between frames
        if (camera_ready && href) cycle <= ~cycle; else                                         // Toggle cycle for every byte received
        if (camera_ready        ) cycle <= 1'b0  ;                                              // Reset cycle during horizontal blanking
    end

    // 2. FIRST BYTE BUFFER: Stores the Y (Luminance) byte (CYCLE = 0)
    always_ff @(posedge pclk) begin
        if (vsync                                  ) first_byte <= '0; else
        if (camera_ready && href && (cycle == 1'b0)) first_byte <= d ;                          //save Y (Luminance) in 'first_byte'.           
    end

    // 3. GREY DATA OUTPUT: Forwards the saved Y byte to BRAM (CYCLE = 1)
    always_ff @(posedge pclk) begin
        if (vsync                                  ) bram_data_grey <= '0        ; else
        if (camera_ready && href && (cycle == 1'b1)) bram_data_grey <= first_byte;             // Send the previously saved Y byte to the BRAM (ignore U or V because they'r not needed)
    end

    // 4. WRITE ENABLE (BRAM_WE): Generates a 1-clock pulse to save the pixel
    always_ff @(posedge pclk) begin
        if (vsync                                  ) bram_we <= 1'b0; else                     // Disable writing between frames
        if (camera_ready && href && (cycle == 1'b1)) bram_we <= 1'b1; else                     // Enable BRAM write on the second byte
        if (camera_ready                           ) bram_we <= 1'b0;                          // Keep disabled otherwise
    end

    // 5. MEMORY ADDRESS: Increments linearly for each saved pixel
    always_ff @(posedge pclk) begin
        if (vsync                  ) bram_addr <= '0              ; else                       // Reset address to 0 at the start of a new frame
        if (camera_ready         && 
            href                 && 
            (cycle == 1'b1)      &&
            (bram_addr < 17'd76799)) bram_addr <= bram_addr + 1'b1;                            // Increment address only when a complete pixel is written
    end

endmodule