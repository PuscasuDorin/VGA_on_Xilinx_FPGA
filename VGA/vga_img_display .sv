module vga_img_display#(
    parameter H_ACTIVE_VIDEO = 640,
    parameter V_ACTIVE_VIDEO = 480
)(
    //input logic        clk     ,
    //input logic        rst_n   ,

    //input logic  [1:0] sw      ,

    input  logic [9:0] x_pos   , // Current VGA pixel X position
    input  logic [9:0] y_pos   , // Current VGA pixel Y position
    input  logic       video_on, // 1 inside active area, 0 in blanking
    input  logic       vsync   , // Vertical sync pulse from controller

    input  logic [7:0] pixel_data,  // Read from Frame Buffer
    output logic [16:0] read_addr,   // Address to read from Frame Buffer

    output logic [3:0] red     ,
    output logic [3:0] green   ,
    output logic [3:0] blue
);

localparam X_START = 160; 
    localparam Y_START = 120; 
    localparam IMG_W   = 320;
    localparam IMG_H   = 240;

    wire in_image_window = (x_pos >= X_START && x_pos < X_START + IMG_W) &&
                           (y_pos >= Y_START && y_pos < Y_START + IMG_H);

    wire [9:0] rel_x = x_pos - X_START;
    wire [9:0] rel_y = y_pos - Y_START;

    assign read_addr = (in_image_window) ? (rel_y * IMG_W + rel_x) : 17'd0;

    // Expandăm de la RGB332 (8 biți) înapoi la RGB444 (12 biți)
    logic [3:0] exp_r, exp_g, exp_b;
    assign exp_r = {pixel_data[7:5], pixel_data[7]}; // Replicăm MSB-ul pentru un 4-bit curat
    assign exp_g = {pixel_data[4:2], pixel_data[4]};
    assign exp_b = {pixel_data[1:0], pixel_data[1:0]};

    assign red   = (video_on) ? (in_image_window ? exp_r : 4'h0) : 4'h0;
    assign green = (video_on) ? (in_image_window ? exp_g : 4'h0) : 4'h0;
    assign blue  = (video_on) ? (in_image_window ? exp_b : 4'h0) : 4'h0;
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
endmodule