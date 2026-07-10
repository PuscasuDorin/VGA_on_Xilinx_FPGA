module vga_img_display#(
    parameter H_ACTIVE_VIDEO = 640,
    parameter V_ACTIVE_VIDEO = 480
)(
    input logic        clk     ,
    input logic        rst_n   ,

    input  logic [9:0] x_pos   , // Current VGA pixel X position
    input  logic [9:0] y_pos   , // Current VGA pixel Y position

    input  logic       video_on, // 1 inside active area, 0 in blanking
    input  logic       vsync   , // Vertical sync pulse from controller

    output logic [3:0] red     ,
    output logic [3:0] green   ,
    output logic [3:0] blue
);
    localparam BOX_SIZE = 100;

    logic in_triangle;
    logic in_square;
    
    logic frame_tick;  

    //SQUARE MOTION REGISTERS
    logic [9:0] box_x; 
    logic [9:0] box_y; 
    logic       dir_x; // 0 = Left, 1 = Right
    logic       dir_y; // 0 = Up, 1 = Down


    //TRIANGLE COORDINATES
    // Top:            X = 320, Y = 140
    // Bottom-left:    X = 220, Y = 340
    // Bottom-right:   X = 420, Y = 340
    // Slope 2/1: for every 1 pixel horizontally, move 2 pixels vertically  
    assign in_triangle = (y_pos >= 140) && (y_pos < 340)    && 
                         (y_pos >= 170 + 2 * (320 - x_pos)) &&
                         (y_pos >= 170 + 2 * (x_pos - 320)); 

    assign in_square = (x_pos >= box_x && x_pos < box_x + BOX_SIZE) && 
                     (y_pos >= box_y && y_pos < box_y + BOX_SIZE);



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
        if(~rst_n)                                             dir_x <= 1'b1; else
        if(frame_tick && box_x == 1)                           dir_x <= 1'b1; else
        if(frame_tick && box_x + BOX_SIZE == H_ACTIVE_VIDEO-2) dir_x <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)                                             dir_y <= 1'b1; else
        if(frame_tick && box_y == 1)                           dir_y <= 1'b1; else
        if(frame_tick && box_y + BOX_SIZE == V_ACTIVE_VIDEO-2) dir_y <= 1'b0;
    end

    // Move the box
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)               box_x <= 10'd10   ; else
        if(frame_tick && dir_x)  box_x <= box_x + 1; else
        if(frame_tick && ~dir_x) box_x <= box_x - 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)               box_y <= 10'd10   ; else
        if(frame_tick && dir_y)  box_y <= box_y + 1; else
        if(frame_tick && ~dir_y) box_y <= box_y - 1;
    end

    //RGB output logic 
    assign red   = (video_on && in_square) ? 4'hF : 4'h0             ;              
    assign green = (video_on)              ? 4'hF : 4'h0;
    assign blue  = (video_on && in_square) ? 4'hF : 4'h0;

endmodule