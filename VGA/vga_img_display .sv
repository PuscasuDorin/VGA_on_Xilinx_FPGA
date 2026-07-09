module vga_img_display(
    input  logic [9:0] x_pos   ,
    input  logic [9:0] y_pos   ,

    input  logic       video_on,

    output logic [3:0] red     ,
    output logic [3:0] green   ,
    output logic [3:0] blue
);

    logic in_square;
    logic in_triangle;

    assign in_square = (x_pos >= 220 && x_pos < 420) && (y_pos >= 140 && y_pos < 340);
    
    //TRIANGLE COORDINATES
    // Top:            X = 320, Y = 140
    // Bottom-left:    X = 220, Y = 340
    // Bottom-right:   X = 420, Y = 340
    // Slope 2/1: for every 1 pixel horizontally, move 2 pixels vertically  
    assign in_triangle = (y_pos >= 140) && (y_pos < 340)    && 
                         (y_pos >= 170 + 2 * (320 - x_pos)) &&
                         (y_pos >= 170 + 2 * (x_pos - 320)); 

    //RGB output logic 
    assign red   = (video_on) ? 4'hF : 4'h0             ;              
    assign green = (video_on && in_triangle) ? 4'hF : 4'h0;
    assign blue  = 4'h0;
    

endmodule