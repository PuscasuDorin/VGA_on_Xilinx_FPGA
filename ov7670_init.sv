module ov7670_init (
    input clk,
    input rst_n,

    input sio_c
    input sio_d
);

logic [6:0] counter = 0; 
logic s_clk;

always @(posedge clk) begin
    if (counter == 125) begin
        counter <= 0;
        s_clk <= ~s_clk;
    end else begin
        counter <= counter + 1;
    end
end

assign SIO_C = s_clk;

endmodule