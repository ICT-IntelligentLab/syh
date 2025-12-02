module led_twinkle(
	input sys_clk,
	input sys_rst_n, //n代表低电平有效
	
	output [1:0] led
	

);
reg [25:0] cnt ;

assign led=(cnt<26'd2500_0000)?2'b01:2'b10;

always @(posedge sys_clk or negedge sys_rst_n )begin
	if(!sys_rst_n)
		cnt<=26'd0;
	else if (cnt<26'd5000_0000)  //26代表二进制是26位，后面的5000——0000是d十进制，方便观看书写
		cnt=cnt+1'b1;
	else
		cnt<=26'd0;
end

ila_0  ila_0_u(
	.clk(sys_clk), // input wire clk


	.probe0(led), // input wire [1:0]  probe0  
	.probe1(cnt) // input wire [25:0]  probe1
);
endmodule
