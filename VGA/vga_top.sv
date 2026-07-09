module vga_top(
    input  logic sys_clock     ,
    input  logic rst         ,

    output logic Hsync         ,
    output logic Vsync         ,

    output logic [3:0] vgaRed  ,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);


localparam H_ACTIVE_VIDEO = 640;
localparam H_SYNC_PULSE   = 96 ;
localparam H_FRONT_PORCH  = 16 ;
localparam H_BACK_PORCH   = 48 ;

localparam V_ACTIVE_VIDEO = 480;
localparam V_SYNC_PULSE   = 2  ;
localparam V_FRONT_PORCH  = 10 ;
localparam V_BACK_PORCH   = 33 ;

logic clk_25MHz;
logic rst_n    ;

assign rst_n = ~rst;

vga_controller#(
    // VGA timing parameters for 640x480 @ 60Hz
    .H_ACTIVE_VIDEO(H_ACTIVE_VIDEO),
    .H_SYNC_PULSE  (H_SYNC_PULSE  ),
    .H_FRONT_PORCH (H_FRONT_PORCH ),
    .H_BACK_PORCH  (H_BACK_PORCH  ),
    .V_ACTIVE_VIDEO(V_ACTIVE_VIDEO),
    .V_SYNC_PULSE  (V_SYNC_PULSE  ),
    .V_FRONT_PORCH (V_FRONT_PORCH ),
    .V_BACK_PORCH  (V_BACK_PORCH  )
)vga_controller(
    .clk  (clk_25MHz),
    .rst_n(rst_n    ),

    .hsync(Hsync    ),
    .vsync(Vsync    ),

    .red  (vgaRed   ),
    .green(vgaGreen ),
    .blue (vgaBlue  )      
);

clk_vga_wrapper clk_vga_wrapper_i(
    .clk_out1_0 (clk_25MHz),
    .reset      (rst_n    ),
    .sys_clock  (sys_clock)
);

endmodule