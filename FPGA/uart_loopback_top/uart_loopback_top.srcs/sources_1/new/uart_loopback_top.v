module uart_lookback_top(
	input 				sys_clk,
	input 				sys_rst_n,
	
	input 				uart_rxd,
	output				uart_txd


);
	wire				uart_en;
	wire		[7:0]	uart_din;
	wire		[7:0]	uart_data;
	wire				uart_done;
	wire				uart_tx_busy;
	
uart_recv uart_recv_u(

			.sys_clk    	(sys_clk),
			.sys_rst_n  	(sys_rst_n),
			.uart_rxd   	(uart_rxd),
							
			.uart_done  	(uart_done),
			.uart_data  	(uart_data)					
);

uart_send uart_send_u(


			.sys_clk		(sys_clk),
            .sys_rst_n      (sys_rst_n),
            .uart_en        (uart_en),
            .uart_din       (uart_din),
            .uart_txd       (uart_txd),
            .uart_tx_busy   (uart_tx_busy)

);	

uart_loop uart_loop_u(
			
			.sys_clk		(sys_clk),
            .sys_rst_n      (sys_rst_n),
            .recv_done      (uart_done),
            .recv_date      (uart_data),
            .tx_busy        (uart_tx_busy),
            
            .send_en        (uart_en),
            .send_date      (uart_din)




);
endmodule