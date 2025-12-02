module uart_send(

	input 			sys_clk,
	input 			sys_rst_n,
	input			uart_en,//发送使能
	input [7:0]		uart_din,//要发送的数据
	output	reg		uart_txd,//串行线发送的数据引脚，只有一位
	output			uart_tx_busy




);

	parameter		CLK_FREQ=50_000_000;
	parameter		uart_bps=115200;
	parameter		BPS_cnt=CLK_FREQ/uart_bps;
	
	reg [7:0]		tx_date;//临时寄存器储存发送数据
	reg				tx_flag;//发送状态标志
	reg 			uart_en_d0;//当前
	reg 			uart_en_d1;//上一
	reg	[8:0]		clk_cnt;
	reg [3:0]		tx_cnt;
	wire			en_flag;

assign en_flag=uart_en_d0&~uart_en_d1;//uart_en上升沿
assign uart_tx_busy=tx_flag;
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		uart_en_d0<=1'b0;
		uart_en_d1<=1'b0;
	end
	else begin
		uart_en_d0<=uart_en;
		uart_en_d1<=uart_en_d0;
	end
end

always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_flag<=1'b0;
		tx_date<=8'b0;
	end
	else if (en_flag)begin
		tx_flag<=1'b1;
		tx_date<=uart_din;
	end
	else if((tx_cnt==4'd9)&&(clk_cnt==BPS_cnt-1))begin
		tx_flag<=1'b0;
		tx_date<=8'b0;
	end
	else begin
		tx_date<=tx_date;
		tx_flag<=tx_flag;
	end
end
    
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		clk_cnt<=9'd0;
	else if(tx_flag)begin
		if(clk_cnt<BPS_cnt-1'b1)
		clk_cnt<=clk_cnt+9'd1;
		else
		clk_cnt<=9'd0;
		end
	else
		clk_cnt<=9'd0;
end



always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		tx_cnt<=4'd0;
	else if (tx_flag)begin
		if(clk_cnt==BPS_cnt-1'b1)
		tx_cnt<=tx_cnt+4'd1;
		else
		tx_cnt<=tx_cnt;
	end
	else
		tx_cnt<=4'd0;
end

always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		uart_txd<=1'b1;
	else if (tx_flag)begin
		case(tx_cnt)
			4'd0:uart_txd<=1'b0;
	    	4'd1:uart_txd<=tx_date[0];
	    	4'd2:uart_txd<=tx_date[1];
	    	4'd3:uart_txd<=tx_date[2];
	    	4'd4:uart_txd<=tx_date[3];
	    	4'd5:uart_txd<=tx_date[4];
	    	4'd6:uart_txd<=tx_date[5];
	    	4'd7:uart_txd<=tx_date[6];
	    	4'd8:uart_txd<=tx_date[7];
			4'd9:uart_txd<=1'b1;
	    default:;
	    endcase
	end
	else
		uart_txd<=1'b1;
end
	

endmodule