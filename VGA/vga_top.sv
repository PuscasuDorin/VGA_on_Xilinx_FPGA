module vga_top(
    input  logic       sys_clock,
    input  logic       rst      ,

    input  logic [1:0] sw       ,

    // Vga I/O
    output logic       Hsync    ,
    output logic       Vsync    ,

    output logic [3:0] vgaRed  ,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue ,

    // Camera OV7670 I/O
    input  logic       ov7670_pclk,
    input  logic       ov7670_vsync,
    input  logic       ov7670_href,
    input  logic [7:0] ov7670_data,
    output logic       ov7670_xclk,
    output logic       ov7670_reset,
    output logic       ov7670_pwdn,
    output logic       ov7670_sioc,
    inout  logic       ov7670_siod,
    output logic       config_finished
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

logic [9:0] h_count;
logic [9:0] v_count;

logic video_on;

assign rst_n = ~rst;

// Camera control pins static state
assign ov7670_reset = 1'b1; // Active low reset disabled
assign ov7670_pwdn  = 1'b0; // Powered on

assign ov7670_xclk = clk_25MHz;

// Memory Interconnect Wires
    logic [16:0] fb_write_addr;
    logic [11:0] fb_write_data;
    logic        fb_write_enable;
    
    logic [16:0] fb_read_addr;
    logic [11:0] fb_read_data;

vga_controller#(
    // VGA timing parameters for 640x480 @ 60Hz
    .H_ACTIVE_VIDEO (H_ACTIVE_VIDEO),
    .H_SYNC_PULSE   (H_SYNC_PULSE  ),
    .H_FRONT_PORCH  (H_FRONT_PORCH ),
    .H_BACK_PORCH   (H_BACK_PORCH  ),

    .V_ACTIVE_VIDEO (V_ACTIVE_VIDEO),
    .V_SYNC_PULSE   (V_SYNC_PULSE  ),
    .V_FRONT_PORCH  (V_FRONT_PORCH ),
    .V_BACK_PORCH   (V_BACK_PORCH  )
)vga_controller_i(
    .clk     (clk_25MHz),
    .rst_n   (rst_n    ),

    .hsync   (Hsync    ),
    .vsync   (Vsync    ),
      
    .h_count (h_count  ),
    .v_count (v_count  ),

    .video_on(video_on )
);

vga_img_display#(
    .H_ACTIVE_VIDEO (H_ACTIVE_VIDEO),
    .V_ACTIVE_VIDEO (V_ACTIVE_VIDEO)
)vga_img_display_i(
    //.clk      (clk_25MHz),
    //.rst_n    (rst_n    ),

    //.sw       (sw       ),

    .x_pos    (h_count ),
    .y_pos    (v_count ),

    .video_on (video_on),
    .vsync    (Vsync    ),

    .red      (vgaRed  ),
    .green    (vgaGreen),
    .blue     (vgaBlue ),

    .pixel_data (fb_read_data),
    .read_addr  (fb_read_addr)
);

// --- Camera Capture Module ---
ov7670_capture capture_i (
    .pclk  (ov7670_pclk),
    .rst_n (rst_n),
    .vsync (ov7670_vsync),
    .href  (ov7670_href),
    .d     (ov7670_data),
    .addr  (fb_write_addr),
    .dout  (fb_write_data),
    .we    (fb_write_enable)
);

// --- Dual-Port RAM Frame Buffer ---
frame_buffer fb_i (
    .clka  (ov7670_pclk),      // Port A Write Clock
    .wea   (fb_write_enable),  // Port A Write Enable
    .addra (fb_write_addr),    // Port A Address
    .dina  (fb_write_data),    // Port A Pixel Data input
    
    .clkb  (clk_25MHz),        // Port B Read Clock
    .addrb (fb_read_addr),     // Port B Address
    .doutb (fb_read_data)      // Port B Pixel Data output
    );

// --- Camera I2C/SCCB Initializer ---
ov7670_init init_i (
    .clk             (clk_25MHz),
    .rst_n           (rst_n),
    .sioc            (ov7670_sioc),
    .siod            (ov7670_siod),
    .config_finished (config_finished)
);

// --- Clock Generator (100MHz to 25MHz) ---
clk_vga_wrapper clk_vga_wrapper_i(
    .clk_out1_0 (clk_25MHz),
    .reset      (rst_n    ),
    .sys_clock  (sys_clock)
);

endmodule