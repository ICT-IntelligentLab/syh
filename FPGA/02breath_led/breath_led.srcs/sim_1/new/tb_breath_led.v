`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/20 16:51:01
// Design Name: 
// Module Name: tb_breath_led
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_breath_led(

    );
    reg sys_clk;
    reg sys_rst_n;
    wire led;
    
initial begin
   sys_clk=1'b0;
   sys_rst_n=1'b0;
   #60 sys_rst_n=1'b1;
  end
  always #10 sys_clk=~sys_clk;
    
    
    
breath_led u_breath_led(


    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
           
    .led (led)     
);
endmodule