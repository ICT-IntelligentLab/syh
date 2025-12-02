`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 18:02:46
// Design Name: 
// Module Name: ram_rw
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


module ram_rw(
        input clk,
        input rst_n,
      
        output reg ram_en,//ram使能
        output reg rw,     //读写切换
        output reg [4:0]ram_addr, //地址，32块地址
        output reg [7:0]ram_wr_date//写入的数据，8位，因为每一个寄存器地址存储的数据是8位的
);



reg [5:0] rw_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    ram_en<=1'b0;
    else
    ram_en<=1'b1;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    rw_cnt<=6'd0;//因为要按位挨个比较，所以这里写6'd0，而不是1'b0，因为后者只有一位，所以比较的时候只比较一位，换言之赋值语句左右两边位宽一致
    else if(rw_cnt==6'd63)
    rw_cnt<=6'd0;
    else
    rw_cnt<=rw_cnt+6'd1;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    ram_wr_date<=8'd0;
    else if((rw_cnt<=6'd31)&&ram_en)
    ram_wr_date<=ram_wr_date+8'd1;
    else
    ram_wr_date<=ram_wr_date;
end//定义写入数据是多少

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    rw<=1'b1;
    else if((rw_cnt<=6'd31)&&ram_en)
    rw<=1'b1;
    else
    rw<=1'b0;
end//定义读写状态

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
    ram_addr<=5'd0;
    else
    ram_addr<=rw_cnt[4:0];
end   

endmodule