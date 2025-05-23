//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_test
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM 控制器顶层模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2018/3/18 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module	sdram_top(
	input         ref_clk,                  //sdram 控制器参考时钟
	input         out_clk,                  //用于输出的相位偏移时钟
	input         rst_n,                    //系统复位
    
    	//SDRAM 控制器写端口	
    input         sdram_wr_req,		//写SDRAM请求信号
    output        sdram_wr_ack,		//写SDRAM响应信号
    input  [23:0] sdram_wr_addr,	//SDRAM写操作的地址
    input  [ 9:0] sdram_wr_burst,   //写sdram时数据突发长度
    input  [15:0] sdram_din,	    //写入SDRAM的数据
    
	//SDRAM 控制器读端口	
    input         sdram_rd_req,		//读SDRAM请求信号
    output        sdram_rd_ack,		//读SDRAM响应信号
    input  [23:0] sdram_rd_addr,	//SDRAM写操作的地址
    input  [ 9:0] sdram_rd_burst,   //读sdram时数据突发长度
    output [15:0] sdram_dout,	    //从SDRAM读出的数据
    
    output	      sdram_init_done,  //SDRAM 初始化完成标志
    

    
	//SDRAM 芯片接口
	output        sdram_clk,                //SDRAM 芯片时钟
	output        sdram_cke,                //SDRAM 时钟有效
	output        sdram_cs_n,               //SDRAM 片选
	output        sdram_ras_n,              //SDRAM 行有效
	output        sdram_cas_n,              //SDRAM 列有效
	output        sdram_we_n,               //SDRAM 写有效
	output [ 1:0] sdram_ba,                 //SDRAM Bank地址
	output [12:0] sdram_addr,               //SDRAM 行/列地址
	inout  [15:0] sdram_data,               //SDRAM 数据
	output [ 1:0] sdram_dqm                 //SDRAM 数据掩码
    );



//*****************************************************
//**                    main code
//***************************************************** 
assign	sdram_clk = out_clk;                //将相位偏移时钟输出给sdram芯片
assign	sdram_dqm = 2'b00;                  //读写过程中均不屏蔽数据线
			

//SDRAM控制器
sdram_controller u_sdram_controller(
	.clk				(ref_clk),			//sdram 控制器时钟
	.rst_n				(rst_n),			//系统复位
    
	//SDRAM 控制器写端口	
	.sdram_wr_req		(sdram_wr_req), 	//sdram 写请求
	.sdram_wr_ack		(sdram_wr_ack), 	//sdram 写响应
	.sdram_wr_addr		(sdram_wr_addr), 	//sdram 写地址
	.sdram_wr_burst		(sdram_wr_burst),		    //写sdram时数据突发长度
	.sdram_din  		(sdram_din),    	//写入sdram中的数据
    
    //SDRAM 控制器读端口
	.sdram_rd_req		(sdram_rd_req), 	//sdram 读请求
	.sdram_rd_ack		(sdram_rd_ack),		//sdram 读响应
	.sdram_rd_addr		(sdram_rd_addr), 	//sdram 读地址
	.sdram_rd_burst		(sdram_rd_burst),		    //读sdram时数据突发长度
	.sdram_dout		    (sdram_dout),   	//从sdram中读出的数据
    
	.sdram_init_done	(sdram_init_done),	//sdram 初始化完成标志

	//SDRAM 芯片接口
	.sdram_cke			(sdram_cke),		//SDRAM 时钟有效
	.sdram_cs_n			(sdram_cs_n),		//SDRAM 片选
	.sdram_ras_n		(sdram_ras_n),		//SDRAM 行有效	
	.sdram_cas_n		(sdram_cas_n),		//SDRAM 列有效
	.sdram_we_n			(sdram_we_n),		//SDRAM 写有效
	.sdram_ba			(sdram_ba),			//SDRAM Bank地址
	.sdram_addr			(sdram_addr),		//SDRAM 行/列地址
	.sdram_data			(sdram_data)		//SDRAM 数据	
    );
    
endmodule 