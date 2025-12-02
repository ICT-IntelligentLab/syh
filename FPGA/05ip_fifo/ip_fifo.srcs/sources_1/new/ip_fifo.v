`timescale 1ns / 1ps


module ip_fifo(
    input sys_clk,
    input sys_rst_n
    );
    wire        almost_empty;
    wire        almost_full;
    wire        fifo_wr_en;
    wire [7:0]  fifo_wr_date;
    wire        fifo_rd_en;
    wire [7:0]  dout;
    wire        full;
    wire        empty;
    wire [7:0]  rd_data_count;
    wire [7:0]  wr_data_count;
    
fifo_wr  fifo_wr_u(
    .clk          (sys_clk),
    .rst_n        (sys_rst_n),     
    .almost_empty (almost_empty),
    .almost_full  (almost_full),           
    .fifo_wr_en   (fifo_wr_en),
    .fifo_wr_date (fifo_wr_date)
);
fifo_rd  fifo_rd_u(
    .clk            (sys_clk),        
    .rst_n          (sys_rst_n), 
    .almost_empty   (almost_empty), 
    .almost_full    (almost_full),   
    .fifo_rd_en     (fifo_rd_en)

); 
    
    
   fifo_generator_0 fifo_generator_0 (
  .wr_clk(sys_clk),                // input wire wr_clk
  .rd_clk(sys_clk),                // input wire rd_clk
  .din(fifo_wr_date),                      // input wire [7 : 0] din
  .wr_en(fifo_wr_en),                  // input wire wr_en
  .rd_en(fifo_rd_en),                  // input wire rd_en
  .dout(dout),                    // output wire [7 : 0] dout
  .full(full),                    // output wire full
  .almost_full(almost_full),      // output wire almost_full
  .empty(empty),                  // output wire empty
  .almost_empty(almost_empty),    // output wire almost_empty
  .rd_data_count(rd_data_count),  // output wire [7 : 0] rd_data_count
  .wr_data_count(wr_data_count)  // output wire [7 : 0] wr_data_count
);


ila_0 ila_fifo (
	.clk(sys_clk), // input wire clk


	.probe0(fifo_wr_en), // input wire [0:0]  probe0  
	.probe1(fifo_rd_en), // input wire [0:0]  probe1 
	.probe2(almost_empty), // input wire [0:0]  probe2 
	.probe3(empty), // input wire [0:0]  probe3 
	.probe4(rd_data_count), // input wire [7:0]  probe4 
	.probe5(wr_data_count), // input wire [7:0]  probe5 
	.probe6(dout), // input wire [7:0]  probe6 
	.probe7(fifo_wr_date), // input wire [7:0]  probe7 
	.probe8(full), // input wire [0:0]  probe8 
	.probe9(almost_full) // input wire [0:0]  probe9
);

endmodule
