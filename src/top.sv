module top(
    input  logic       sys_clock      ,
    input  logic       rst            ,

    input  logic       img_scale_sw   ,
    input  logic       pir_sensor     ,         //PIR - passive infrared

    // Vga I/O
    output logic       Hsync          ,
    output logic       Vsync          ,

    output logic [3:0] vgaRed         ,
    output logic [3:0] vgaGreen       ,
    output logic [3:0] vgaBlue        , 

    // Camera OV7670 I/O
    input  logic       ov7670_pclk    ,         //pixel clock
    input  logic       ov7670_vsync   ,         //camera verical sync
    input  logic       ov7670_href    ,         //camera horizontal sync
    input  logic [7:0] ov7670_data    ,         //camera data
    output logic       ov7670_xclk    ,         //camera clock
    output logic       ov7670_reset   ,
    output logic       ov7670_pwdn    ,
    output logic       ov7670_sio_c   ,         // SCCB clock
    inout  logic       ov7670_sio_d   ,         // SCCB bidirectional data
    output logic       config_finished          //camera initialization complete
);
    //VGA 640x480 PARAM
    localparam H_ACTIVE_VIDEO = 640;
    localparam H_SYNC_PULSE   = 96 ;
    localparam H_FRONT_PORCH  = 16 ;
    localparam H_BACK_PORCH   = 48 ;

    localparam V_ACTIVE_VIDEO = 480;
    localparam V_SYNC_PULSE   = 2  ;
    localparam V_FRONT_PORCH  = 10 ;
    localparam V_BACK_PORCH   = 33 ;

    //==================================================

    logic clk_25MHz;
    logic rst_n    ;

    //VGA SIGNALS
    logic [9:0] h_count;
    logic [9:0] v_count;

    logic video_on;

    //Semnale Interne de Conectare
    logic       sccb_ready;
    logic       sccb_start;
    logic [7:0] sccb_addr ;
    logic [7:0] sccb_data ;

    logic       sio_d_out ;
    logic       sio_d_oe  ;

    // Port A RAM Signals (Write - Clock: PCLK)
    logic [16:0] wr_addr; // 17 bits to cover 76,800 addresses (320x240)
    logic [7:0 ] wr_data; // Pixel converted to 8-bit grayscale
    logic        wr_en  ;

    // Port B RAM Signals (Read - Clock: 25 MHz)
    logic [16:0] rd_addr;
    logic [7:0 ] rd_data; 

    logic pclk_buf;

    logic freeze_frame;

    //==================================================
    //logic final_we;
    //assign final_we = wr_en & ~freeze_frame;

    assign rst_n = ~rst;

    // Camera control pins static state
    assign ov7670_reset = 1'b1; // Active low reset disabled
    assign ov7670_pwdn  = 1'b0; // Powered on

    assign ov7670_xclk = clk_25MHz;

    always_ff @(posedge pclk_buf)begin
        if (ov7670_vsync) freeze_frame <= pir_sensor;
    end

    vga_controller#(
        // VGA timing parameters for 640x480 60Hz
        .H_ACTIVE_VIDEO (H_ACTIVE_VIDEO),
        .H_SYNC_PULSE   (H_SYNC_PULSE  ),
        .H_FRONT_PORCH  (H_FRONT_PORCH ),
        .H_BACK_PORCH   (H_BACK_PORCH  ),

        .V_ACTIVE_VIDEO (V_ACTIVE_VIDEO),
        .V_SYNC_PULSE   (V_SYNC_PULSE  ),
        .V_FRONT_PORCH  (V_FRONT_PORCH ),
        .V_BACK_PORCH   (V_BACK_PORCH  )
    )vga_controller_i(
        .clk      (clk_25MHz),
        .rst_n    (rst_n    ),

        .hsync    (Hsync    ),
        .vsync    (Vsync    ),
        
        .h_count  (h_count  ),
        .v_count  (v_count  ),

        .video_on (video_on )
    );

    vga_img_display#(
        .H_ACTIVE_VIDEO (H_ACTIVE_VIDEO),
        .V_ACTIVE_VIDEO (V_ACTIVE_VIDEO)
    )vga_img_display_i(
        .clk        (clk_25MHz   ),

        .scale_img  (img_scale_sw),
        .pir_sensor (freeze_frame),
    
        .x_pos      (h_count     ),
        .y_pos      (v_count     ),
    
        .video_on   (video_on    ),
        .vsync      (Vsync       ),
    
        .red        (vgaRed      ),
        .green      (vgaGreen    ),
        .blue       (vgaBlue     ),
    
        .pixel_data (rd_data     ),
        .rd_addr    (rd_addr     )
    );

    // --- Camera I2C/SCCB Initializer ---
    ov7670_sccb sccb_i (
        .clk      (clk_25MHz   ),        
        .rst_n    (rst_n       ),   
        .start    (sccb_start  ),   
        .reg_addr (sccb_addr   ),
        .reg_data (sccb_data   ),
        .ready    (sccb_ready  ),   
        .sio_c    (ov7670_sio_c),   
        .sio_d    (ov7670_sio_d)
    );

    // --- Camera Capture Module ---
    ov7670_init init_i (
        .clk           (clk_25MHz      ),        
        .rst_n         (rst_n          ),      
        .sccb_ready    (sccb_ready     ), 
        .sccb_start    (sccb_start     ), 
        .sccb_reg_addr (sccb_addr      ),  
        .sccb_reg_data (sccb_data      ),  
        .done          (config_finished)
    );

    ov7670_capture ov7670_capture_i(
        .pclk           (pclk_buf       ),       
        .camera_ready   (config_finished), 

        .vsync          (ov7670_vsync   ),
        .href           (ov7670_href    ),
        .d              (ov7670_data    ),

        .bram_addr      (wr_addr        ),     
        .bram_data_grey (wr_data        ),            
        .bram_we        (wr_en          )
    );

    // --- Dual-Port RAM Frame Buffer ---
    frame_buffer fb_i (
        // Port A: Write (Sync with camera clock PCLK)
        .clka  (pclk_buf      ),                  // Port A Write Clock
        .wea   (~freeze_frame ),                  // Port A Write Enable
        .addra (wr_addr       ),                  // Port A Address
        .dina  (wr_data       ),                  // Port A Pixel Data input
        
        // Port B: Read (sync with VGA 25 MHz clock)
        .clkb  (clk_25MHz     ),                  // Port B Read Clock
        .addrb (rd_addr       ),                  // Port B Address
        .doutb (rd_data       )                   // Port B Pixel Data output
    );      


    // --- Clock Generator (100MHz to 25MHz) ---
    clk_vga_wrapper clk_vga_wrapper_i(
        .clk_out1_0 (clk_25MHz),
        .reset      (rst_n    ),
        .sys_clock  (sys_clock)
    );

    BUFG pclk_bufg_inst(
        .I(ov7670_pclk),
        .O(pclk_buf   )
    );


endmodule