`timescale 1ns / 1ps

module fifo_rd(
input                   clk,
input                   rst_n,

input                   almost_empty,//读将空
input                   almost_full,//写将满

output reg              fifo_rd_en//读使能

    );
reg             almost_full_d0;//用来存放当前时刻状态
reg             almost_full_d1;//用来存放前一状态
reg      [1:0]  state;
reg      [3:0]  dly_cnt;
wire            syn;//上升沿
assign syn=~almost_full_d1&almost_full_d0;//syn为1时是almost_full上升沿
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        almost_full_d0<=1'b0;
        almost_full_d1<=1'b0;
    end
    else begin
        almost_full_d0<=almost_full;
        almost_full_d1<=almost_full_d0;
    end
end
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        fifo_rd_en<=1'b0;
        state<=2'd0;
        dly_cnt<=4'd0;//延时计数器，因为FIFO内部数据需要准备时间，所以要设置一个延时
    end
    else begin
    case(state)
            2'd0:begin
                    if(syn)
                    state<=2'd1;//如果抓取到上升沿，就进入状态机的下一状态
                    else
                    state<=state;
                 end
            2'd1:begin
                    if(dly_cnt==4'd10)begin//第二状态是时延       
                    dly_cnt<=4'd0;
                    state<=2'd2;
                    end
                    else
                    dly_cnt<=dly_cnt+1'b1;
                 end
            2'd2:begin
                    if(almost_empty)begin//即将读空
                    fifo_rd_en<=1'b0;
                    state<=2'd1;
                    end
                    else 
                    fifo_rd_en<=1'b1;
                  end
    default:state<=2'd0;
    endcase
    end
end
                    
                    
        
        
    
    
    
endmodule
