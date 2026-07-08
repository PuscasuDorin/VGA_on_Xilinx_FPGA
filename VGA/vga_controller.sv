module vga_controller(
    input clk         ,
    input rst_n       ,

    output hsync      ,
    output vsync      ,

    output [7:0] red  ,
    output [7:0] green,
    output [7:0] blue       
);

    // VGA timing parameters for 640x480 @ 60Hz
    parameter H_ACTIVE_VIDEO = 640;
    parameter H_SYNC_PULSE = 96;
    parameter H_FRONT_PORCH = 16;
    parameter H_BACK_PORCH = 48;
    parameter H_TOTAL = H_SYNC_PULSE + H_BACK_PORCH + H_ACTIVE_VIDEO + H_FRONT_PORCH;

    parameter V_ACTIVE_VIDEO = 480;
    parameter V_SYNC_PULSE = 2;
    parameter V_FRONT_PORCH = 10;
    parameter V_BACK_PORCH = 33;
    parameter V_TOTAL = V_SYNC_PULSE + V_BACK_PORCH + V_ACTIVE_VIDEO + V_FRONT_PORCH;

    reg [9:0] h_count; // Horizontal pixel counter
    reg [9:0] v_count; // Vertical line counter
    wire h_count_rst;
    wire v_count_rst;

    // Horizontal and vertical sync signals
    assign hsync = ~((h_count >= (H_ACTIVE_VIDEO + H_FRONT_PORCH)) & (h_count < (H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_PULSE))); // Active low
    assign vsync = ~((v_count >= (V_ACTIVE_VIDEO + V_FRONT_PORCH)) & (v_count < (V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_PULSE))); // Active low



    // RGB output logic
    assign red   = (h_count < H_ACTIVE_VIDEO && v_count < V_ACTIVE_VIDEO) && rst_n ? 8'hFF : 8'h00; // Red color during active video
    assign green = (h_count < H_ACTIVE_VIDEO && v_count < V_ACTIVE_VIDEO) && rst_n ? 8'h00 : 8'h00; // Green color during active video
    assign blue  = (h_count < H_ACTIVE_VIDEO && v_count < V_ACTIVE_VIDEO) && rst_n ? 8'h00 : 8'h00; // Blue color during active video

    // Horizontal and vertical counters
    assign h_count_rst = (h_count == H_TOTAL - 1);
    assign v_count_rst = (v_count == V_TOTAL - 1);

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)      h_count <= 0          ; else
        if(h_count_rst) h_count <= 0          ; else
                        h_count <= h_count + 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)                      v_count <= 0          ; else
        if(h_count_rst &&  v_count_rst) v_count <= 0          ; else
        if(h_count_rst && !v_count_rst) v_count <= v_count + 1;
    end

endmodule
