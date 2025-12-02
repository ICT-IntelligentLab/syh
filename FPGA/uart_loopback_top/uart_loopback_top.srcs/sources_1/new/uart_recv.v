module uart_recv(

	input 			sys_clk,
	input 			sys_rst_n,
	input 			uart_rxd,
	
	output reg		uart_done,
	output reg [7:0]uart_data


);

	parameter		CLK_FREQ=50_000_000;
	parameter		uart_bps=115200;
	parameter		BPS_cnt=CLK_FREQ/uart_bps;
	
	reg	[7:0]		rx_date;
	reg 			uart_rxd_d0;//uart_rxd当前时刻
	reg 			uart_rxd_d1;//uart_rxd上一时刻
	reg 			rx_flag;
	reg	[8:0]		clk_cnt;
	reg [3:0]		rx_cnt;//rx数据个数计数,最多数到9
	wire 			start_flag;//uart_rxd下降沿	
	
	assign start_flag=~uart_rxd_d0&uart_rxd_d1;
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		uart_rxd_d0<=1'b0;
		uart_rxd_d1<=1'b0;
	end
	else begin
		uart_rxd_d0<=uart_rxd;
		uart_rxd_d1<=uart_rxd_d0;
	end
end

always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		rx_flag<=1'b0;
	else begin
		if(start_flag)
			rx_flag<=1'b1;
		else if ((rx_cnt==4'd9)&&(clk_cnt==BPS_cnt/2))
			rx_flag<=1'b0;
		else
			rx_flag<=rx_flag;
	end
end

always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		clk_cnt<=9'd0;
	else if(rx_flag)begin
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
		rx_cnt<=4'd0;
	else if (rx_flag)begin
		if(clk_cnt==BPS_cnt-1'b1)
		rx_cnt<=rx_cnt+4'd1;
		else
		rx_cnt<=rx_cnt;
	end
	else
		rx_cnt<=4'd0;
end
		
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		rx_date<=8'd0;		
	else if (rx_flag)begin
		if(clk_cnt==BPS_cnt/2)begin
			case(rx_cnt)
				4'd1:rx_date[0]	<=uart_rxd_d1;
				4'd2:rx_date[1] <=uart_rxd_d1;
				4'd3:rx_date[2] <=uart_rxd_d1;
				4'd4:rx_date[3] <=uart_rxd_d1;
				4'd5:rx_date[4] <=uart_rxd_d1;
				4'd6:rx_date[5] <=uart_rxd_d1;
				4'd7:rx_date[6] <=uart_rxd_d1;
				4'd8:rx_date[7] <=uart_rxd_d1;
			default:;
			endcase
		end
		else
			rx_date<=rx_date;
	end
	else
		rx_date<=8'd0;
end

always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		uart_done<=1'b0;
		uart_data<=8'd0;
	end
	else if (rx_cnt==4'd9)begin
		uart_done<=1'b1;
		uart_data<=rx_date;
	end
	else begin
		uart_done<=1'b0;
        uart_data<=8'd0;
	end
end


endmodule