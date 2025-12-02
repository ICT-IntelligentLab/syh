`timescale 1ns / 1ps


module tb_ip_clk_wiz();

reg   sys_clk;
reg   sys_rst_n;
wire clk_100M;
wire clk_100M_180degree;
wire clk_50M;
wire clk_25M;
wire locked  ; 

initial begin
    sys_clk=1'b0;
    sys_rst_n=1'b0;
    #200 
    sys_rst_n=1'b1;
end

always #10 sys_clk=~sys_clk;

ip_clk_wiz ip_clk_wiz_u(
    .sys_clk  (sys_clk),
    .sys_rst_n(sys_rst_n),
    .clk_out1 (clk_100M),
    .clk_out2 (clk_100M_180degree),
    .clk_out3 (clk_50M),
    .clk_out4 (clk_25M),
    .locked   (locked)
);
endmodule
