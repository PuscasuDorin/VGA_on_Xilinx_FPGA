module vga_img_display(
    input  logic [9:0] x_pos   ,
    input  logic [9:0] y_pos   ,

    input  logic       video_on,

    output logic [3:0] red     ,
    output logic [3:0] green   ,
    output logic [3:0] blue
);

    logic in_square;

    assign in_square = (x_pos >= 220 && x_pos < 420) && (y_pos >= 140 && y_pos < 340);

    //RGB output logic 
    assign red   = (video_on) ? 4'hF : 4'h0; // Atât pătratul cât și fundalul au Roșu maxim
    assign green = (video_on && in_square) ? 4'hF : 4'h0; // Doar pătratul are Verde
    assign blue  = 4'h0;

endmodule