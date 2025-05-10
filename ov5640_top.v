module ov5640_top(
    input                 sys_clk      ,  //系统时钟
    input                 sys_rst_n    ,  //系统复位，低电平有效
    //摄像头接口                       
    input                 cam_pclk     ,  //cmos 数据像素时钟
    input                 cam_vsync    ,  //cmos 场同步信号
    input                 cam_href     ,  //cmos 行同步信号
    input   [7:0]         cam_data     ,  //cmos 数据
    output                cam_rst_n    ,  //cmos 复位信号，低电平有效
    output                cam_pwdn     ,  //电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                cam_scl      ,  //cmos SCCB_SCL线
    inout                 cam_sda      ,  //cmos SCCB_SDA线       
//    // DDR3                            
//    inout   [15:0]        ddr3_dq      ,  //DDR3 数据
//    inout   [1:0]         ddr3_dqs_n   ,  //DDR3 dqs负
//    inout   [1:0]         ddr3_dqs_p   ,  //DDR3 dqs正  
//    output  [13:0]        ddr3_addr    ,  //DDR3 地址   
//    output  [2:0]         ddr3_ba      ,  //DDR3 banck 选择
//    output                ddr3_ras_n   ,  //DDR3 行选择
//    output                ddr3_cas_n   ,  //DDR3 列选择
//    output                ddr3_we_n    ,  //DDR3 读写选择
//    output                ddr3_reset_n ,  //DDR3 复位
//    output  [0:0]         ddr3_ck_p    ,  //DDR3 时钟正
//    output  [0:0]         ddr3_ck_n    ,  //DDR3 时钟负
//    output  [0:0]         ddr3_cke     ,  //DDR3 时钟使能
//    output  [0:0]         ddr3_cs_n    ,  //DDR3 片选
//    output  [1:0]         ddr3_dm      ,  //DDR3_dm
//    output  [0:0]         ddr3_odt     ,  //DDR3_odt									                            
//    //hdmi接口                             
//    output                tmds_clk_p   ,  // TMDS 时钟通道
//    output                tmds_clk_n   ,
//    output  [2:0]         tmds_data_p  ,  // TMDS 数据通道
//    output  [2:0]         tmds_data_n  ,
//    output                tmds_oen        // TMDS 输出使能

      output  [3:0]         led
    );     
                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS分辨率--行
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS分辨率--列	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; //CMOS分辨率--行
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;    										   
							   
//wire define                          
wire         clk_50m                   ;  //50mhz时钟
wire         locked                    ;  //时钟锁定信号
wire         rst_n                     ;  //全局复位 								    
wire         cam_init_done             ;  //摄像头初始化完成
wire         i2c_done                  ;  //I2C寄存器配置完成信号
wire         i2c_dri_clk               ;  //I2C操作时钟								    
wire         wr_en                     ;  //DDR3控制器模块写使能
wire  [15:0] wr_data                   ;  //DDR3控制器模块写数据
wire         rdata_req                 ;  //DDR3控制器模块读使能
wire  [15:0] rd_data                   ;  //DDR3控制器模块读数据
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

//待时钟锁定后产生复位结束信号
assign  rst_n = sys_rst_n & locked;

//系统初始化完成：DDR3初始化完成
assign  led = cam_init_done;

pll u_pll(
    .refclk (sys_clk),
    .reset  (~sys_rst_n),
    .lock   (locked),
    .clk0_out(clk_50m)
    
    
    );

 //ov5640 驱动
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk ),
    .cam_vsync         (cam_vsync),
    .cam_href          (cam_href ),
    .cam_data          (cam_data ),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn ),
    .cam_scl           (cam_scl  ),
    .cam_sda           (cam_sda  ),
    
    .capture_start     (init_calib_complete),
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


endmodule
