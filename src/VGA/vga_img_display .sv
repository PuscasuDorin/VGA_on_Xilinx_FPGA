`timescale 1ns / 1ps

module vga_img_display #(
    parameter H_ACTIVE_VIDEO = 640,
    parameter V_ACTIVE_VIDEO = 480
)(
    input  logic        clk       ,

    input  logic        scale_img ,         //1 - 640x480 ; 0 - 320x240
    input  logic        pir_sensor,

    input  logic [9:0 ] x_pos     ,         // h_count directly from the VGA controller (0-639)
    input  logic [9:0 ] y_pos     ,         // v_count directly from the VGA controller (0-479)
    input  logic        video_on  ,         // active video region enable signal
    input  logic        vsync     ,         // vertical synchronization signal (optional)

    input  logic [7:0 ] pixel_data,         // Pixel received from BRAM
    output logic [16:0] rd_addr   ,         // 17-bit address sent to BRAM (0-76799)

    output logic [3:0]  red       ,         //vga red
    output logic [3:0]  green     ,         //vga green
    output logic [3:0]  blue                //vga blue
);
    // Camera resolution parameters
    localparam H_CAMERA = 320;
    localparam V_CAMERA = 240;

    // Red warning box coordinates
    localparam BOX_X_START    = 230;
    localparam BOX_Y_START    = 200;
    localparam BOX_WIDTH      = 180; // 410 - 230 = 180 pixels wide
    localparam BOX_HEIGHT     = 80 ;  // 280 - 200 = 80 pixels high

    // 'INTRUDER' text position and grid parameters
    localparam TEXT_X_START   = 232;
    localparam TEXT_Y_START   = 210;
    localparam TOTAL_CHAR_W   = 22 ;  // Total width of a letter + gap (total_letter_px = 22px - 1px_l_gap - 1px_r_gap
    localparam CHAR_ACTIVE_W  = 20 ;   // Drawable width of the letter (leaves a 2px gap)

    // Calculate offsets to center the camera image on the screen
    localparam CENTER_OFFSET_X = (H_ACTIVE_VIDEO - H_CAMERA) >> 1; // (640 - 320) / 2 = 160
    localparam CENTER_OFFSET_Y = (V_ACTIVE_VIDEO - V_CAMERA) >> 1; // (480 - 240) / 2 = 120

    //==================================================

    logic       in_image_bounds    ;
  
    logic [9:0] x_scaled           ;
    logic [9:0] y_scaled           ;
            
    // DITHERING variables            
    logic [3:0] bayer_value        ;
    logic [8:0] pixel_sum          ;  // 9 biți pentru a preveni overflow-ul
    logic [3:0] grey_4bit          ;

    //'INTRUDER' text variables
    logic       I                  ;
    logic       N                  ;
    logic       T                  ;
    logic       R                  ;
    logic       U                  ;
    logic       D                  ;
    logic       E                  ;
      
    logic       text_pixel_on      ;
      
    logic [9:0] x_start            ; 
    logic [9:0] y_start            ; 
      
    logic [9:0] x_rel              ;  //x relative possition
    logic [9:0] y_rel              ;  //y relative possition

    logic [4:0] lx                 ;  // Local x-coordinate inside the letter's bounding box
    logic [5:0] ly                 ;  // Local x-coordinate inside the letter's bounding box
    logic [2:0] idx                ;  // Index of the current letter along the x-axis (0 to 7)

    //==================================================

    // Detect if we are inside the image boundaries (scales dynamically based on the switch; 640x480 or 320x240)
    assign in_image_bounds = (x_pos >= 0 + (CENTER_OFFSET_X * !scale_img) && x_pos < H_ACTIVE_VIDEO - (CENTER_OFFSET_X * !scale_img)) && 
                             (y_pos >= 0 + (CENTER_OFFSET_Y * !scale_img) && y_pos < V_ACTIVE_VIDEO - (CENTER_OFFSET_Y * !scale_img));

    // Divide physical screen coordinates by 2
    assign x_scaled = x_pos >> scale_img; 
    assign y_scaled = y_pos >> scale_img; 

    // Calculate linear address in BRAM based on the scaling mode | Address = (Y * Image_Width) + X
    assign rd_addr = scale_img ? ((y_scaled * H_CAMERA) + x_scaled) : (((y_pos - CENTER_OFFSET_Y) * H_CAMERA) + (x_pos - CENTER_OFFSET_X));



    // --- DITHERING IMPLEMENTATION (2x2 Bayer Matrix) ---
    // Generate an ordered mathematical "noise" based on the pixel's screen position.
    // Use only the LSB of x_pos and y_pos to form a 2x2 repeating grid.
    always_comb begin
        case ({y_pos[0], x_pos[0]})
            2'b00: bayer_value = 4'd0 ;
            2'b01: bayer_value = 4'd8 ;
            2'b10: bayer_value = 4'd12;
            2'b11: bayer_value = 4'd4 ;
        endcase
    end

    // Add the Bayer "noise" to the raw 8-bit pixel received from BRAM
    assign pixel_sum = pixel_data + bayer_value;

    // Extract the top 4 bits, carefully handling overflow (clipping to pure white)
    always_comb begin
        if (pixel_sum > 9'd255) grey_4bit = 4'hF          ; else        // If overflow occurs, force maximum White
                                grey_4bit = pixel_sum[7:4];              // Otherwise keep the upper 4 bits
    end

    // Color display logic
    always_ff @(posedge clk) begin
        if (video_on && in_image_bounds ) begin
            if((red_square || text_pixel_on) && pir_sensor) red = 4'hF       ; else 
                                                            red = grey_4bit  ;
            if(text_pixel_on && pir_sensor                ) green = 4'hF     ; else
                                                            green = grey_4bit;
            if(text_pixel_on && pir_sensor                ) blue = 4'hF      ; else
                                                            blue  = grey_4bit;
        end else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end

    assign red_square = ((x_pos >= BOX_X_START - (100 * scale_img) && (x_pos < (BOX_X_START + BOX_WIDTH ) + (100 * scale_img))) && 
                         (y_pos >= BOX_Y_START - (30  * scale_img) && (y_pos < (BOX_Y_START + BOX_HEIGHT) + (30  * scale_img)))   );

    // Calculate the top-left corner of the entire text block
    assign x_start = TEXT_X_START - (88 * scale_img);
    assign y_start = TEXT_Y_START - (30 * scale_img);

    assign x_rel = x_pos - x_start; // Always positive when inside the text area
    assign y_rel = y_pos - y_start; // Always positive when inside the text area

    // Local coordinates mapping (adjusts dynamically based on scaling)
    assign lx  = (x_rel % (TOTAL_CHAR_W + (TOTAL_CHAR_W * scale_img))) / (scale_img + 1);       
    assign ly  = y_rel / (scale_img + 1);                                                           
    assign idx = x_rel / (TOTAL_CHAR_W + (TOTAL_CHAR_W * scale_img));                           
    
    // I (idx = 0)
    assign I = (idx == 0) && ((ly <= 3) || (ly >= 56) || (lx >= 8 && lx <= 11));

    // N (idx = 1)
    assign N = (idx == 1) && ((lx <= 3) || (lx >= 16) || (ly >= 3*lx && ly <= 3*lx + 6));

    // T (idx = 2)
    assign T = (idx == 2) && ((ly <= 3) || (lx >= 8 && lx <= 11));

    // R (idx = 3 și idx = 7)
    assign R = (idx == 3 || idx == 7) && (
        (lx <= 3) || 
        (ly <= 3) || 
        (ly >= 28 && ly <= 31) || 
        (lx >= 16 && ly <= 31) || 
        (ly >= 31 && lx >= 3 + (ly - 31) / 2 && lx <= 6 + (ly - 31) / 2)
    );

    // U (idx = 4)
    assign U = (idx == 4) && ((lx <= 3 && ly <= 56) || (lx >= 16 && ly <= 56) || (ly >= 56));

    // D (idx = 5)
    assign D = (idx == 5) && (
        (lx <= 3) || 
        (ly <= 3 && lx <= 15) || 
        (ly >= 56 && lx <= 15) || 
        (lx >= 16 && ly >= 4 && ly <= 55)
    );

    // E (idx = 6)
    assign E = (idx == 6) && (
        (lx <= 3) || 
        (ly <= 3) || 
        (ly >= 28 && ly <= 31 && lx <= 15) || 
        (ly >= 56)
    );

    // Define the bounding box specifically for the text area
    assign in_text_area = (x_pos >= 232 - (88 * scale_img) && x_pos < 408 + (88 * scale_img)) && 
                          (y_pos >= 210 - (30 * scale_img) && y_pos < 270 + (30 * scale_img));
    
    // The pixel is drawn white only if we are inside a specific letter bounds.
    assign text_pixel_on = in_text_area && (lx < CHAR_ACTIVE_W) && (I | N | T | R | U | D | E);

endmodule