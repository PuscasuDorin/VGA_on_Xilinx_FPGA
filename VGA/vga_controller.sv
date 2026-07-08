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
    parameter H_SYNC_PULSE = 96;
    parameter H_BACK_PORCH = 48;
    parameter H_ACTIVE_VIDEO = 640;
    parameter H_FRONT_PORCH = 16;
    parameter H_TOTAL = H_SYNC_PULSE + H_BACK_PORCH + H_ACTIVE_VIDEO + H_FRONT_PORCH;

    parameter V_SYNC_PULSE = 2;
    parameter V_BACK_PORCH = 33;
    parameter V_ACTIVE_VIDEO = 480;
    parameter V_FRONT_PORCH = 10;
    parameter V_TOTAL = V_SYNC_PULSE + V_BACK_PORCH + V_ACTIVE_VIDEO + V_FRONT_PORCH;

    reg [9:0] h_count; // Horizontal pixel counter
    reg [9:0] v_count; // Vertical line counter

    // Horizontal and vertical sync signals
    assign hsync = ~((h_count >= (H_ACTIVE_VIDEO + H_FRONT_PORCH)) & (h_count < (H_ACTIVE_VIDEO + H_FRONT_PORCH + H_SYNC_PULSE))); // Active low
    assign vsync = ~((v_count >= (V_ACTIVE_VIDEO + V_FRONT_PORCH)) & (v_count < (V_ACTIVE_VIDEO + V_FRONT_PORCH + V_SYNC_PULSE))); // Active low



    // RGB output logic
    assign red   = (h_count < H_ACTIVE_VIDEO && v_count < V_ACTIVE_VIDEO) && rst_n ? 8'hFF : 8'h00; // Red color during active video
    assign green = (h_count < H_ACTIVE_VIDEO && v_count < V_ACTIVE_VIDEO) && rst_n ? 8'h00 : 8'h00; // Green color during active video
    assign blue  = (h_count < H_ACTIVE_VIDEO && v_count < V_ACTIVE_VIDEO) && rst_n ? 8'h00 : 8'h00; // Blue color during active video

    // Horizontal and vertical counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

endmodule
