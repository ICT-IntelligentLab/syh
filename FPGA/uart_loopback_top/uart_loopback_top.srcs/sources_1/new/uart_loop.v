module uart_loop(
	input 				sys_clk,
	input 				sys_rst_n,
	input				recv_done,
	input [7:0]			recv_date,
	input				tx_busy,
	
	output	reg			send_en,
	output	reg [7:0] 	send_date



);

	reg 			recv_done_d0;
	reg 			recv_done_d1;	
	reg             tx_ready;
	wire			recv_done_flag;
	
	assign	recv_done_flag=recv_done_d0&~recv_done_d1;
	
always @(posedge sys_clk or negedge sys_rst_n)begin//抓取上升沿，确认接收完成
	if(!sys_rst_n)begin
		recv_done_d0<=1'b0;
		recv_done_d1<=1'b0;
	end
	else begin
		recv_done_d0<=recv_done;
		recv_done_d1<=recv_done_d0;
	end
end

always @(posedge sys_clk or negedge sys_rst_n)begin//抓取上升沿，确认接收完成
	if(!sys_rst_n)begin
		send_en<=1'b0;
	    send_date<=8'b0;
		tx_ready<=1'b0;
	end
	else begin
		if(recv_done_flag)begin
			tx_ready<=1'b1;//只是tx_ready拉高，数据准备好，但是send没有拉高，这样在下一次数据传输的时�?�到了这�?步�?�send�?1清零
			send_en<=1'b0;
            send_date<=recv_date;
		end
		else if ((~tx_busy)&&tx_ready)begin
			tx_ready<=1'b0;
		    send_en<=1'b1;
		end
	end
end		
			

endmodule