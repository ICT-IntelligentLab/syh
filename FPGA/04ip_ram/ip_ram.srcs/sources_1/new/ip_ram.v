`timescale 1ns / 1ps


module ip_ram(
        input  sys_clk      ,
        input  sys_rst_n    
    );
wire ram_en;
wire rw;
wire [4:0]ram_addr;
wire [7:0]ram_wr_date;
wire [7:0]douta;
ram_rw  ram_rw_u(
        .clk        (sys_clk) ,                 
        .rst_n      (sys_rst_n) ,               
                             
        .ram_en     (ram_en) , 
        .rw         (rw) ,     
        .ram_addr   (ram_addr) , 
        .ram_wr_date(ram_wr_date) 
);  
    
ram_1 your_instance_name (
  .clka(sys_clk),    // input wire clka
  .ena(ram_en),      // input wire ena
  .wea(rw),      // input wire [0 : 0] wea
  .addra(ram_addr),  // input wire [4 : 0] addra
  .dina(ram_wr_date),    // input wire [7 : 0] dina
  .douta(douta)  // output wire [7 : 0] douta
);

ila_0 ila_0_u(
	.clk(sys_clk), // input wire clk


	.probe0(ram_en), // input wire [0:0]  probe0  
	.probe1(rw), // input wire [0:0]  probe1 
	.probe2(ram_addr), // input wire [4:0]  probe2 
	.probe3(ram_wr_date), // input wire [7:0]  probe3 
	.probe4(douta) // input wire [7:0]  probe4
);
endmodule
