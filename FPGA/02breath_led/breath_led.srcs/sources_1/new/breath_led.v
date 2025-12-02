module breath_led(
	input sys_clk,//时钟
	input sys_rst_n,//复位
	
	output led
);
	reg [15:0] period_cnt;//计数器周期
	reg [15:0] duty_cycle;//占空比
	reg        inc_dec_flag;//递增递减标志位
	
	
	assign led=(period_cnt>=duty_cycle)?1'b1:1'b0;
always @(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)//如果复位
		period_cnt<=16'd0;
	else if(period_cnt==16'd50000)
		period_cnt<=16'd0;
	else
		period_cnt<=period_cnt+1'b1;
	end
always @(posedge sys_clk or negedge sys_rst_n)begin   
	if(!sys_rst_n)begin
		duty_cycle<=16'd0;
		inc_dec_flag<=1'b0;//假使等于0的时候递增
		end
	else begin
	if(period_cnt==16'd50000)begin
		if(inc_dec_flag==1'b0)begin
			if(duty_cycle==16'd50000)
			inc_dec_flag<=1'b1;
			else
			duty_cycle<=duty_cycle+16'd500;
		end
		else begin
			if(duty_cycle==16'd0)
			inc_dec_flag<=1'b0;
			else
			duty_cycle<=duty_cycle-16'd500;
			end
		end
	end
end

endmodule