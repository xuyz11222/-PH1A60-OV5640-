
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2019/12/17
*Module Name:
*File Name:
*Description: 
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 1.0
*Signal description
*1) _i input
*2) _o output
*3) _n activ low
*4) _dg debug signal 
*5) _r delay or register
*6) _s state mechine
*********************************************************************/
`timescale 1ns / 1ns

module uitpg
(
input			tpg_clk_i,
input			tpg_vs_i,
input           tpg_hs_i,
input           tpg_de_i,	
output			tpg_vs_o,
output          tpg_hs_o,
output          tpg_de_o,	
output [23:0]	tpg_data_o
);

reg[8:0] fcnt = 9'd0;
reg tpg_vs_r = 1'b0;
reg tpg_hs_r = 1'b0;

always @(posedge tpg_clk_i)begin
    tpg_vs_r <= tpg_vs_i;
    tpg_hs_r <= tpg_hs_i;
end

reg [11:0]v_cnt = 12'd0;
reg [11:0]h_cnt = 12'd0;
always @(posedge tpg_clk_i)
  if(tpg_vs_i) 
	v_cnt <= 12'd0; 
  else if((!tpg_hs_r)&&tpg_hs_i) 
	v_cnt <= v_cnt + 1'b1; 
	
always @(posedge tpg_clk_i)
  if(tpg_de_i)
	h_cnt <= h_cnt + 1'b1; 
  else 
    h_cnt <= 12'd0; 
      
reg [7:0] grid_data = 8'd0;
always @(posedge tpg_clk_i)begin
	if((v_cnt[4]==1'b1) ^ (h_cnt[4]==1'b1))
	   grid_data <= 8'h00;
	else
	   grid_data <= 8'hff;
end

reg[23:0]color_bar = 24'd0;
always @(posedge tpg_clk_i)
begin
	if(h_cnt==260)
	color_bar	<=	24'hff0000;
	else if(h_cnt==420)
	color_bar	<=	24'h00ff00;
	else if(h_cnt==580)
	color_bar	<=	24'h0000ff;
	else if(h_cnt==740)
	color_bar	<=	24'hff00ff;
	else if(h_cnt==900)
	color_bar	<=	24'hffff00;
	else if(h_cnt==1060)
	color_bar	<=	24'h00ffff;
	else if(h_cnt==1220)
	color_bar	<=	24'hffffff;
	else if(h_cnt==1380)
	color_bar	<=	24'h000000;
	else
	color_bar	<=	color_bar;
end

reg[10:0]dis_mode = 10'd0;
always @(posedge tpg_clk_i)
    if((!tpg_vs_r)&&tpg_vs_i) dis_mode <= dis_mode + 1'b1;

reg[7:0]  r_reg = 8'd0;
reg[7:0]  g_reg = 8'd0;
reg[7:0]  b_reg = 8'd0;

always @(posedge tpg_clk_i)
begin
    case(dis_mode[10:7])
        4'd0:begin
			r_reg <= 0; 
			b_reg <= 0;
			g_reg <= 0;
		end
        4'd1:begin
			r_reg <= 8'b11111111;               //白
            g_reg <= 8'b11111111;
            b_reg <= 8'b11111111;
		end
        4'd2,4'd3:begin
			r_reg <= 8'b11111111;              //红
            g_reg <= 0;
            b_reg <= 0;  
		end			  
        4'd4,4'd5:begin
			r_reg <= 0;                         //绿
            g_reg <= 8'b11111111;
            b_reg <= 0; 
		end					  
        4'd6:begin     
			r_reg <= 0;                         //蓝
            g_reg <= 0;
            b_reg <= 8'b11111111;
		end
        4'd7,4'd8:begin     
			r_reg <= grid_data;                 //方格
            g_reg <= grid_data;
            b_reg <= grid_data;
		end					  
        4'd9:begin    
			r_reg <= h_cnt[7:0];                //水平渐变
            g_reg <= h_cnt[7:0];
            b_reg <= h_cnt[7:0];
		end
        4'd10,4'd11:begin     
			r_reg <= v_cnt[7:0];                 //垂直渐变
            g_reg <= v_cnt[7:0];
            b_reg <= v_cnt[7:0];
		end
        4'd12:begin     
			r_reg <= v_cnt[7:0];                 //红垂直渐变
            g_reg <= 0;
            b_reg <= 0;
		end
        4'd13:begin     
			r_reg <= 0;                          //绿垂直渐变
            g_reg <= h_cnt[7:0];
            b_reg <= 0;
		end
        4'd14:begin     
			r_reg <= 0;                          //蓝垂直渐变
            g_reg <= 0;
            b_reg <= h_cnt[7:0];			
		end
        4'd15:begin     
			r_reg <= color_bar[23:16];           //彩条
            g_reg <= color_bar[15:8];
            b_reg <= color_bar[7:0];			
		end				  
        endcase
end

assign tpg_data_o = {r_reg,g_reg,b_reg};
assign tpg_vs_o = tpg_vs_i;
assign tpg_hs_o = tpg_hs_i;
assign tpg_de_o = tpg_de_i;  

endmodule
