`timescale 1ns / 1ps

module vga_img_display #(
    parameter H_ACTIVE_VIDEO = 640,
    parameter V_ACTIVE_VIDEO = 480
)(
    input  logic        clk,
    input  logic [9:0]  x_pos,       // h_count directly from the VGA controller (0-639)
    input  logic [9:0]  y_pos,       // v_count directly from the VGA controller (0-479)
    input  logic        video_on,    // active video region enable signal
    input  logic        vsync,       // vertical synchronization signal (optional)

    input  logic [7:0] pixel_data,  // Pixel received from BRAM
    output logic [16:0] rd_addr,     // 17-bit address sent to BRAM (0-76799)

    input  logic        sw,

    // 4-bit colors physically sent to the Basys 3 board VGA DAC
    output logic [3:0]  red,
    output logic [3:0]  green,
    output logic [3:0]  blue
);
    logic scale_img;
    logic in_image_bounds;

    logic [9:0] x_scaled;
    logic [9:0] y_scaled ;
    // Detect if we are inside the 320x240 image boundaries
    //wire in_image_bounds = (x_pos >= 160 && x_pos < 480) && 
    //                       (y_pos >= 120 && y_pos < 360);

    
    assign scale_img = sw; //1 - 640x480 ; 0 - 320x240

    // Detect if we are inside the 320x240 image boundaries
    assign in_image_bounds = (x_pos >= 0 + (160 * !scale_img) && x_pos < 640 - (160 * !scale_img)) && 
                            (y_pos >= 0 + (120 * !scale_img) && y_pos < 480 - (120 * !scale_img));

    // Divide physical screen coordinates by 2 (right shift by 1 bit)
    assign x_scaled = x_pos >> scale_img; 
    assign y_scaled = y_pos >> scale_img; 

    // Calculate linear address in BRAM (320x240 virtual resolution)
    assign rd_addr = sw ? ((y_scaled * 17'd320) + x_scaled) : (((y_pos - 10'd120) * 17'd320) + (x_pos - 10'd160));

    //Extract the 4 most significant bits from the grayscale value received from BRAM
    logic [3:0] grey_4bit = pixel_data[7:4];

    // Color display logic
    always_ff @(posedge clk) begin
        if (video_on && in_image_bounds ) begin
            // To obtain shades of gray, the color channels must be IDENTICAL
            if(square) begin
                red = 4'hF;
            end else begin
                red   = grey_4bit;
            end
            green = grey_4bit;
            blue  = grey_4bit;
        end else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end

/*
    localparam SHAPE_HALF_SIZE = 50;

    logic triangle;
    logic square;
    
    logic frame_tick;  

    //SQUARE MOTION REGISTERS
    logic [9:0] box_x; //moving objext x coord
    logic [9:0] box_y; //moving objext y coord
    logic       dir_x; // 0 = Left, 1 = Right
    logic       dir_y; // 0 = Up, 1 = Down
    logic [2:0] speed; //object speed in space

    //TRIANGLE COORDINATES
    // Top:            X = 320, Y = 140
    // Bottom-left:    X = 220, Y = 340
    // Bottom-right:   X = 420, Y = 340
    // Slope 2/1: for every 1 pixel horizontally, move 2 pixels vertically  
    assign triangle = (y_pos >= 140) && (y_pos < 340)    && 
                      (y_pos >= 170 + 2 * (320 - x_pos)) &&
                      (y_pos >= 170 + 2 * (x_pos - 320)); 

    assign square = (x_pos >= box_x - SHAPE_HALF_SIZE && x_pos < box_x + SHAPE_HALF_SIZE) && 
                    (y_pos >= box_y - SHAPE_HALF_SIZE && y_pos < box_y + SHAPE_HALF_SIZE);


    assign speed = (sw[0]) ? 3 : 1;

    // Detect the falling edge of vsync (occurs once per completed frame)
    logic vsync_reg;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) vsync_reg <= 1'b1;
        else        vsync_reg <= vsync;
    end

    assign frame_tick = (vsync_reg && !vsync); // Falling edge detector

    //SQUARE MOTION AND BOUNCE
    // Edge bounce logic
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                           dir_x <= 1'b1; else
        if(frame_tick && box_x <= SHAPE_HALF_SIZE + speed + 1)               dir_x <= 1'b1; else
        if(frame_tick && box_x + SHAPE_HALF_SIZE + speed >= H_ACTIVE_VIDEO ) dir_x <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          dir_y <= 1'b1; else
        if(frame_tick && box_y <= SHAPE_HALF_SIZE + speed + 1)              dir_y <= 1'b1; else
        if(frame_tick && box_y + SHAPE_HALF_SIZE + speed >= V_ACTIVE_VIDEO) dir_y <= 1'b0;
    end

    // Move the box
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)               box_x <= 10'd10   ; else
        if(frame_tick && dir_x)  box_x <= box_x + speed; else
        if(frame_tick && ~dir_x) box_x <= box_x - speed;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)               box_y <= 10'd10       ; else
        if(frame_tick && dir_y)  box_y <= box_y + speed; else
        if(frame_tick && ~dir_y) box_y <= box_y - speed;
    end

    //RGB output logic 
    assign red   = (video_on && square) ? 4'hF : 4'h0             ;              
    assign green = (video_on)           ? 4'hF : 4'h0;
    assign blue  = (video_on && square) ? 4'hF : 4'h0;
*/
  assign square = (x_pos >=  220 && x_pos < 420) && 
                  (y_pos >= 140 && y_pos < 340);

endmodule