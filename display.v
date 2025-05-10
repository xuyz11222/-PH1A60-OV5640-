
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

module display(
     input         sysclk_i,
     input         rst_n,                    //按键复位，低电平有效
     
    //摄像头接口                       
    input                 cam_pclk     ,  //cmos 数据像素时钟
    input                 cam_vsync    ,  //cmos 场同步信号
    input                 cam_href     ,  //cmos 行同步信号
    input   [7:0]         cam_data     ,  //cmos 数据
    output                cam_rst_n    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl      ,  //cmos SCCB_SCL线
    inout                 cam_sda      ,  //cmos SCCB_SDA线  
     
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
    output [ 1:0] sdram_dqm,                //SDRAM 数据掩码
    output  [3:0]     led ,
    output HDMI_CLK_P,
    output [2:0]HDMI_TX_P
);

wire clk_25m; 
wire vid_rst,vid_clk,vid_vs,vid_hs,vid_de;
wire pclkx1,pclkx5,locked;

wire [7 :0]	rgb_r ,rgb_g ,rgb_b;
assign vid_clk = pclkx1;
assign vid_rst = locked;


reg	[7:0]	rst_cnt=0;	
always @(posedge sysclk_i)
begin
	if (rst_cnt[7])
		rst_cnt <=  rst_cnt;
	else
		rst_cnt <= rst_cnt+1'b1;
end


clk_hdmi_pll clk_hdmi_pll_inst(
.refclk(sysclk_i),
.reset(!rst_cnt[7]),
.lock(locked),
.clk0_out(clk_25m),
.clk1_out(pclkx1),
.clk2_out(pclkx5)
); 

//wire define
wire        clk_50m;                        //SDRAM 读写测试时钟
wire        clk_100m;                       //SDRAM 控制器时钟
wire        clk_100m_shift;                 //相位偏移时钟
     
wire        wr_en;                          //SDRAM 写端口:写使能
wire [15:0] wr_data;                        //SDRAM 写端口:写入的数据
wire        rd_en;                          //SDRAM 读端口:读使能
wire [15:0] rd_data;                        //SDRAM 读端口:读出的数据
wire        sdram_init_done;                //SDRAM 初始化完成信号

wire        sdram_locked;                         //PLL输出有效标志
wire        sys_rst_n;                      //系统复位信号
wire        error_flag;                     //读写测试错误标志
wire        viq_req;

//*****************************************************
//**                    main code
//***************************************************** 

//待PLL输出稳定之后，停止系统复位
assign sys_rst_n = rst_n & sdram_locked;

assign  led[0] = cam_init_done;
assign  led[1] = cmos_frame_valid;

//例化PLL, 产生各模块所需要的时钟
pll_clk u_pll_clk(
    .refclk             (sysclk_i),
    .reset             (~rst_n),
    
    .clk0_out                 (clk_50m),
    .clk1_out                 (clk_100m),
    .clk2_out                 (clk_100m_shift),
    .lock             (sdram_locked)
    );
    
parameter  V_CMOS_DISP = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS分辨率--列	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; //CMOS分辨率--行
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;    										   
							   
//wire define                          
						    
wire         cam_init_done             ;  //摄像头初始化完成
wire         i2c_done                  ;  //I2C寄存器配置完成信号
wire         i2c_dri_clk               ;  //I2C操作时钟								    

wire         rdata_req                 ;  //DDR3控制器模块读使能

wire         cmos_frame_valid          ;  //数据有效使能信号
wire         init_calib_complete       ;  //DDR3初始化完成init_calib_complete
wire         sys_init_done             ;  //系统初始化完成(DDR初始化+摄像头初始化)
wire         clk_200m                  ;  //ddr3参考时钟
wire         cmos_frame_vsync          ;  //输出帧有效场同步信号
wire         cmos_frame_href           ;  //输出帧有效行同步信号 
wire  [10:0] pixel_xpos                ;  //像素点横坐标
wire  [10:0] pixel_ypos                ;  //像素点纵坐标        
wire  [15:0] post_rgb                  ;  //处理后的图像数据
wire         post_frame_vsync          ;  //处理后的场信号
wire         post_frame_de             ;  //处理后的数据有效使能 


//*****************************************************
//**                    main code
//*****************************************************



 //ov5640 驱动
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (sys_rst_n),

    .cam_pclk          (cam_pclk ),
    .cam_vsync         (cam_vsync),
    .cam_href          (cam_href ),
    .cam_data          (cam_data ),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn ),
    .cam_scl           (cam_scl  ),
    .cam_sda           (cam_sda  ),
    
    .capture_start     (sdram_init_done),
    .cmos_h_pixel      (H_CMOS_DISP),
    .cmos_v_pixel      (V_CMOS_DISP),
    .total_h_pixel     (TOTAL_H_PIXEL),
    .total_v_pixel     (TOTAL_V_PIXEL),
    .cmos_frame_vsync  (cmos_frame_vsync),
    .cmos_frame_href   (cmos_frame_href),
    .cmos_frame_valid  (cmos_frame_valid),
    .cmos_frame_data   (wr_data),
    
    .cam_init_done     (cam_init_done)
    );   
    
    wire                   wr_clk 	         ;
    wire     [23:0]        wr_min_addr       ;
    wire     [23:0]        wr_max_addr       ;
    wire     [ 9:0]        wr_len	         ;
    wire                   wr_load	         ;
                                   
    wire                   rd_clk 	         ;
    wire     [23:0]        rd_min_addr       ;
    wire     [23:0]        rd_max_addr       ;
    wire     [ 9:0]        rd_len 	         ;
    wire                   rd_load	         ;
      
    
    //SDRAM 控制器写端口	
    wire        sdram_wr_req	;	//写SDRAM请求信号
    wire        sdram_wr_ack	;	//写SDRAM响应信号
    wire [23:0] sdram_wr_addr	;//SDRAM写操作的地址
    wire [ 9:0] sdram_wr_burst  ; //写sdram时数据突发长度
    wire [15:0] sdram_din	    ;//写入SDRAM的数据
    
	//SDRAM 控制器读端口	
    wire        sdram_rd_req	;	//读SDRAM请求信号
    wire        sdram_rd_ack	;	//读SDRAM响应信号
    wire [23:0] sdram_rd_addr	;//SDRAM写操作的地址
    wire [ 9:0] sdram_rd_burst  ; //读sdram时数据突发长度
    wire [15:0] sdram_dout	    ;//从SDRAM读出的数据
    
 assign   wr_clk 	   =  	cam_pclk		    ;
 assign   wr_en		   =    cmos_frame_valid	;
 assign   wr_min_addr  =    24'd0			    ;
 assign   wr_vs        =    cmos_frame_vsync    ;
 assign   wr_len	   =    10'd512			    ;
 assign   wr_load	   =  	~sys_rst_n	        ;
                                               
 assign   rd_clk 	   =    vid_clk		        ;
 assign   rd_en        =    viq_req				;	
 assign   rd_min_addr  =    24'd0			    ;
 assign   rd_vs        =    vid_vs              ;
 assign   rd_len 	   =    10'd512		        ;
 assign   rd_load	   =    ~sys_rst_n	        ;
 
 
 
 
          
          
sdram_fifo_ctrl u_sdram_fifo_ctrl(
	.clk_ref			(clk_100m),			//SDRAM控制器时钟
	.rst_n				(sys_rst_n),			//系统复位

    //用户写端口
	.clk_write 			(wr_clk),    	    //写端口FIFO: 写时钟
	.wrf_wrreq			(wr_en),			//写端口FIFO: 写请求
	.wrf_din			(wr_data),		    //写端口FIFO: 写数据	
	.wr_min_addr	    (wr_min_addr),		//写SDRAM的起始地址
	.wr_vs		        (wr_vs),		//写SDRAM的结束地址
	.wr_length			(wr_len),		    //写SDRAM时的数据突发长度
	.wr_load			(wr_load),			//写端口复位: 复位写地址,清空写FIFO    
    
    //用户读端口
	.clk_read			(rd_clk),     	    //读端口FIFO: 读时钟
	.rdf_rdreq			(rd_en),			//读端口FIFO: 读请求
	.rdf_dout			(rd_data),		    //读端口FIFO: 读数据
	.rd_min_addr		(rd_min_addr),	    //读SDRAM的起始地址
	.rd_vs		        (rd_vs),		//读SDRAM的结束地址
	.rd_length			(rd_len),		    //从SDRAM中读数据时的突发长度
	.rd_load			(rd_load),			//读端口复位: 复位读地址,清空读FIFO
   
	//用户控制端口	
	.sdram_read_valid	(1'b1), //sdram 读使能
	.sdram_init_done	(sdram_init_done),	//sdram 初始化完成标志

    //SDRAM 控制器写端口
	.sdram_wr_req		(sdram_wr_req),		//sdram 写请求
	.sdram_wr_ack		(sdram_wr_ack),	    //sdram 写响应
	.sdram_wr_addr		(sdram_wr_addr),	//sdram 写地址
	.sdram_din			(sdram_din),		//写入sdram中的数据
       
    //SDRAM 控制器读端口
	.sdram_rd_req		(sdram_rd_req),		//sdram 读请求
	.sdram_rd_ack		(sdram_rd_ack),	    //sdram 读响应
	.sdram_rd_addr		(sdram_rd_addr),    //sdram 读地址
	.sdram_dout			(sdram_dout)		//从sdram中读出的数据
    );

 


//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
	.ref_clk			(clk_100m),			//sdram	控制器参考时钟
	.out_clk			(clk_100m_shift),	//用于输出的相位偏移时钟
	.rst_n		        (sys_rst_n),		//系统复位
    

	.sdram_init_done	(sdram_init_done), //SDRAM 初始化完成标志
    
    //SDRAM 控制器写端口
	.sdram_wr_req		(sdram_wr_req),		//sdram 写请求
	.sdram_wr_ack		(sdram_wr_ack),	    //sdram 写响应
	.sdram_wr_addr		(sdram_wr_addr),	//sdram 写地址
	.sdram_din			(sdram_din),		//写入sdram中的数据
    .sdram_wr_burst     (wr_len),
       
    //SDRAM 控制器读端口
	.sdram_rd_req		(sdram_rd_req),		//sdram 读请求
	.sdram_rd_ack		(sdram_rd_ack),	    //sdram 读响应
	.sdram_rd_addr		(sdram_rd_addr),    //sdram 读地址
	.sdram_dout			(sdram_dout) ,	//从sdram中读出的数据
    .sdram_rd_burst     (rd_len),
    
	//SDRAM 芯片接口
	.sdram_clk			(sdram_clk),        //SDRAM 芯片时钟
	.sdram_cke			(sdram_cke),        //SDRAM 时钟有效
	.sdram_cs_n			(sdram_cs_n),       //SDRAM 片选
	.sdram_ras_n		(sdram_ras_n),      //SDRAM 行有效
	.sdram_cas_n		(sdram_cas_n),      //SDRAM 列有效
	.sdram_we_n			(sdram_we_n),       //SDRAM 写有效
	.sdram_ba			(sdram_ba),         //SDRAM Bank地址
	.sdram_addr			(sdram_addr),       //SDRAM 行/列地址
	.sdram_data			(sdram_data),       //SDRAM 数据
	.sdram_dqm			(sdram_dqm)         //SDRAM 数据掩码
    );

uihdmitx #
(
.FAMILY("PH1")			
)
uihdmitx_inst
(
.RSTn_i(locked),
.HS_i(vid_hs),
.VS_i(vid_vs),
.DE_i(vid_de),
.RGB_i({rgb_r,rgb_g,rgb_b}),
.PCLKX1_i(pclkx1),
.PCLKX5_i(pclkx5),
.HDMI_CLK_P(HDMI_CLK_P),
//.HDMI_CLK_N(HDMI_CLK_N),
.HDMI_TX_P(HDMI_TX_P)
//.HDMI_TX_N(HDMI_TX_N)
);


uivtc#
(
.H_ActiveSize(1024), 
.H_FrameSize(1024+24+136+160), 
.H_SyncStart(1024+24), 
.H_SyncEnd(1024+24+136),
.V_ActiveSize(768),
.V_FrameSize(768+3+6+29), 
.V_SyncStart(768+3),
.V_SyncEnd (768+3+6) 
)
uivtc_inst
(
.vtc_rstn_i(vid_rst),
.vtc_clk_i(vid_clk),
.vtc_vs_o(vid_vs),
.vtc_hs_o(vid_hs),
.vtc_de_o(vid_de),
.vtc_req_o(viq_req)	
);

assign rgb_r ={rd_data[15:11],3'b0};
assign rgb_g ={rd_data[10: 5],2'b0};
assign rgb_b ={rd_data[ 4: 0],3'b0};
//
//uitpg uitpg_inst	
//(
//.tpg_clk_i(vid_clk),
//.tpg_vs_i(vid_vs),
//.tpg_hs_i(vid_hs),
//.tpg_de_i(vid_de),
//.tpg_vs_o(),
//.tpg_hs_o(),
//.tpg_de_o(),	
//.tpg_data_o({rgb_r,rgb_g,rgb_b})		
//);

endmodule