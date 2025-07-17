//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           lcd_display
// Created by:          正点原子
// Created date:        2023年5月18日14:17:02
// Version:             V1.0
// Descriptions:        RGB LCD显示模块
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lcd_display(
    input             lcd_pclk,                 //lcd驱动时钟
    input             sys_rst_n,                //复位信号
    input      [31:0] data_in  ,
    input      [31:0] bcd_data ,
    
    input      [10:0] pixel_xpos,               //像素点横坐标
    input      [10:0] pixel_ypos,               //像素点纵坐标
    output reg [23:0] pixel_data,               //像素点数据,
    output     [31:0] data_out
);

//parameter define
localparam CHAR_POS_X  = 11'd1;                 //字符区域起始点横坐标
localparam CHAR_POS_Y  = 11'd1;                 //字符区域起始点纵坐标
localparam CHAR_WIDTH  = 11'd144;               //字符区域宽度
localparam CHAR_HEIGHT = 11'd32;                //字符区域高度

localparam WHITE  = 24'b11111111_11111111_11111111;     //背景色，白色
localparam BLACK  = 24'b00000000_00000000_00000000;     //字符颜色，黑色
localparam BLUE   = 24'hE0FFFF; //背景色，浅蓝色 
localparam Snow   = 24'hFFFAFA; //背景色，雪色 
localparam Coral  = 24'hFF7F50; //背景色，珊瑚红
localparam Red    = 24'hFF0000; //背景色，红色
localparam Tangerine = 24'hF28500; //背景色，橘色
localparam Ivy_Green = 24'h36BF36; //背景色，常春藤绿

// 按钮参数定义
// 按钮参数定义（基于800x480屏幕）
localparam BUTTON_WIDTH = 120;     // 按钮宽度
localparam BUTTON_HEIGHT = 60;     // 按钮高度
// 按钮1位置（左侧）
localparam BUTTON1_X = 100;
localparam BUTTON1_Y = 400;        // 靠近屏幕底部
// 按钮2位置（中间）
localparam BUTTON2_X = 340;
localparam BUTTON2_Y = 400;
// 按钮3位置（右侧）
localparam BUTTON3_X = 580;
localparam BUTTON3_Y = 400;
// 标签字符位置（基于按钮位置）
localparam CHAR_WIDTH_BUTTON = 16;        // 字符宽度
//localparam CHAR_HEIGHT = 32;       // 字符高度已经declare
// 标签位置（按钮内居中）
localparam LABEL_X1_X = BUTTON1_X + (BUTTON_WIDTH - 2*CHAR_WIDTH_BUTTON)/2;
localparam LABEL_X2_X = BUTTON2_X + (BUTTON_WIDTH - 2*CHAR_WIDTH_BUTTON)/2;
localparam LABEL_X3_X = BUTTON3_X + (BUTTON_WIDTH - 2*CHAR_WIDTH_BUTTON)/2;
localparam LABEL_Y = BUTTON1_Y + (BUTTON_HEIGHT - CHAR_HEIGHT)/2;
// 区域参数定义（每个按钮上方）
localparam REGION_HEIGHT = CHAR_HEIGHT;   // 区域高度
localparam REGION_GAP = 40;               // 区域与按钮的垂直间距
// 区域1位置（按钮1上方）
localparam REGION1_X = BUTTON1_X;
localparam REGION1_Y = BUTTON1_Y - REGION_GAP - REGION_HEIGHT;
// 区域2位置（按钮2上方）
localparam REGION2_X = BUTTON2_X;
localparam REGION2_Y = BUTTON2_Y - REGION_GAP - REGION_HEIGHT;
// 区域3位置（按钮3上方）
localparam REGION3_X = BUTTON3_X;
localparam REGION3_Y = BUTTON3_Y - REGION_GAP - REGION_HEIGHT;

// 标签位置（区域内居中）// 数字位置（在区域右侧）Y1 1
localparam REGION_LABEL_X1 = REGION1_X + 20;
localparam REGION_LABEL_X2 = REGION2_X + 20;
localparam REGION_LABEL_X3 = REGION3_X + 20;
localparam REGION_LABEL_Y = REGION1_Y;
localparam DIGIT_X1 = REGION1_X + BUTTON_WIDTH - CHAR_WIDTH_BUTTON - 10;
localparam DIGIT_X2 = REGION2_X + BUTTON_WIDTH - CHAR_WIDTH_BUTTON - 10;
localparam DIGIT_X3 = REGION3_X + BUTTON_WIDTH - CHAR_WIDTH_BUTTON - 10;
localparam DIGIT_Y = REGION1_Y;


// 按钮和标签颜色
localparam BUTTON_COLOR = Ivy_Green;   // 按钮蓝色
localparam LABEL_COLOR = BLACK;    // 标签黑色
localparam BACK_COLOR = Coral;    // 背景颜色珊瑚红
localparam Char_COLOR = BLACK;    // 字符颜色黑色
localparam REGION_COLOR = Red;         // 区域背景色
localparam REGION_LABEL_COLOR = BLACK;  // 区域标签颜色

//按键监测
// 新增触摸点位置检测逻辑
wire [10:0] touch_x = data_in[26:16];  // 提取触摸点X坐标（11位）
wire [10:0] touch_y = data_in[10:0];   // 提取触摸点Y坐标（11位）

// 检测触摸点是否在按钮区域内
wire button1_active = (touch_x >= BUTTON1_X) && (touch_x < BUTTON1_X + BUTTON_WIDTH) &&
                      (touch_y >= BUTTON1_Y) && (touch_y < BUTTON1_Y + BUTTON_HEIGHT);
wire button2_active = (touch_x >= BUTTON2_X) && (touch_x < BUTTON2_X + BUTTON_WIDTH) &&
                      (touch_y >= BUTTON2_Y) && (touch_y < BUTTON2_Y + BUTTON_HEIGHT);
wire button3_active = (touch_x >= BUTTON3_X) && (touch_x < BUTTON3_X + BUTTON_WIDTH) &&
                      (touch_y >= BUTTON3_Y) && (touch_y < BUTTON3_Y + BUTTON_HEIGHT);




//reg define
reg  [511:0]  char  [11:0] ;                //字符数组

//wire define
wire   [3:0]              bcd_data0    ;  // Y轴坐标个位数
wire   [3:0]              bcd_data1    ;  // Y轴坐标十位数
wire   [3:0]              bcd_data2    ;  // Y轴坐标百位数

wire   [3:0]              bcd_data3    ;  // X轴坐标个位数
wire   [3:0]              bcd_data4    ;  // X轴坐标十位数
wire   [3:0]              bcd_data5    ;  // X轴坐标百位数
wire   [3:0]              bcd_data6    ;  // X轴坐标千位数

//*****************************************************
//**                    main code
//*****************************************************
assign  bcd_data6 = bcd_data[31:28] ;   // X轴坐标千位数
assign  bcd_data5 = bcd_data[27:24] ;   // X轴坐标百位数
assign  bcd_data4 = bcd_data[23:20] ;   // X轴坐标十位数
assign  bcd_data3 = bcd_data[19:16] ;   // X轴坐标个位数

assign  bcd_data2 = bcd_data[11:8]  ;   // Y轴坐标百位数
assign  bcd_data1 = bcd_data[7:4]   ;   // Y轴坐标十位数
assign  bcd_data0 = bcd_data[3:0]   ;   // Y轴坐标个位数

 //给字符数组赋值，用于存储字模数据
always @(posedge lcd_pclk) begin
    char[0]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'hC0,8'h06,8'h20,
                  8'h0C,8'h30,8'h18,8'h18,8'h18,8'h18,8'h18,8'h08,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,
                  8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h18,8'h08,8'h18,8'h18,
                  8'h18,8'h18,8'h0C,8'h30,8'h06,8'h20,8'h03,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "0"
    char[1]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'h01,8'h80,
                  8'h1F,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,
                  8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,
                  8'h01,8'h80,8'h01,8'h80,8'h03,8'hC0,8'h1F,8'hF8,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "1"
    char[2]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h07,8'hE0,8'h08,8'h38,
                  8'h10,8'h18,8'h20,8'h0C,8'h20,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h00,8'h0C,8'h00,8'h18,8'h00,8'h18,
                  8'h00,8'h30,8'h00,8'h60,8'h00,8'hC0,8'h01,8'h80,8'h03,8'h00,8'h02,8'h00,8'h04,8'h04,8'h08,8'h04,
                  8'h10,8'h04,8'h20,8'h0C,8'h3F,8'hF8,8'h3F,8'hF8,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "2"
    char[3]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h07,8'hC0,8'h18,8'h60,
                  8'h30,8'h30,8'h30,8'h18,8'h30,8'h18,8'h30,8'h18,8'h00,8'h18,8'h00,8'h18,8'h00,8'h30,8'h00,8'h60,
                  8'h03,8'hC0,8'h00,8'h70,8'h00,8'h18,8'h00,8'h08,8'h00,8'h0C,8'h00,8'h0C,8'h30,8'h0C,8'h30,8'h0C,
                  8'h30,8'h08,8'h30,8'h18,8'h18,8'h30,8'h07,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "3"
    char[4]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h60,8'h00,8'h60,
                  8'h00,8'hE0,8'h00,8'hE0,8'h01,8'h60,8'h01,8'h60,8'h02,8'h60,8'h04,8'h60,8'h04,8'h60,8'h08,8'h60,
                  8'h08,8'h60,8'h10,8'h60,8'h30,8'h60,8'h20,8'h60,8'h40,8'h60,8'h7F,8'hFC,8'h00,8'h60,8'h00,8'h60,
                  8'h00,8'h60,8'h00,8'h60,8'h00,8'h60,8'h03,8'hFC,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "4"
    char[5]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h0F,8'hFC,8'h0F,8'hFC,
                  8'h10,8'h00,8'h10,8'h00,8'h10,8'h00,8'h10,8'h00,8'h10,8'h00,8'h10,8'h00,8'h13,8'hE0,8'h14,8'h30,
                  8'h18,8'h18,8'h10,8'h08,8'h00,8'h0C,8'h00,8'h0C,8'h00,8'h0C,8'h00,8'h0C,8'h30,8'h0C,8'h30,8'h0C,
                  8'h20,8'h18,8'h20,8'h18,8'h18,8'h30,8'h07,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "5"
    char[6]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h01,8'hE0,8'h06,8'h18,
                  8'h0C,8'h18,8'h08,8'h18,8'h18,8'h00,8'h10,8'h00,8'h10,8'h00,8'h30,8'h00,8'h33,8'hE0,8'h36,8'h30,
                  8'h38,8'h18,8'h38,8'h08,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h18,8'h0C,
                  8'h18,8'h08,8'h0C,8'h18,8'h0E,8'h30,8'h03,8'hE0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "6"
    char[7]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1F,8'hFC,8'h1F,8'hFC,
                  8'h10,8'h08,8'h30,8'h10,8'h20,8'h10,8'h20,8'h20,8'h00,8'h20,8'h00,8'h40,8'h00,8'h40,8'h00,8'h40,
                  8'h00,8'h80,8'h00,8'h80,8'h01,8'h00,8'h01,8'h00,8'h01,8'h00,8'h01,8'h00,8'h03,8'h00,8'h03,8'h00,
                  8'h03,8'h00,8'h03,8'h00,8'h03,8'h00,8'h03,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "7"
    char[8]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h07,8'hE0,8'h0C,8'h30,
                  8'h18,8'h18,8'h30,8'h0C,8'h30,8'h0C,8'h30,8'h0C,8'h38,8'h0C,8'h38,8'h08,8'h1E,8'h18,8'h0F,8'h20,
                  8'h07,8'hC0,8'h18,8'hF0,8'h30,8'h78,8'h30,8'h38,8'h60,8'h1C,8'h60,8'h0C,8'h60,8'h0C,8'h60,8'h0C,
                  8'h60,8'h0C,8'h30,8'h18,8'h18,8'h30,8'h07,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "8"
    char[9]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h07,8'hC0,8'h18,8'h20,
                  8'h30,8'h10,8'h30,8'h18,8'h60,8'h08,8'h60,8'h0C,8'h60,8'h0C,8'h60,8'h0C,8'h60,8'h0C,8'h60,8'h0C,
                  8'h70,8'h1C,8'h30,8'h2C,8'h18,8'h6C,8'h0F,8'h8C,8'h00,8'h0C,8'h00,8'h18,8'h00,8'h18,8'h00,8'h10,
                  8'h30,8'h30,8'h30,8'h60,8'h30,8'hC0,8'h0F,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00} ; // "9"
    char[10]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h7C,8'h3E,8'h18,8'h08,
                  8'h18,8'h10,8'h0C,8'h10,8'h0C,8'h20,8'h06,8'h20,8'h06,8'h40,8'h03,8'h40,8'h03,8'h80,8'h01,8'h80,
                  8'h01,8'h80,8'h01,8'h80,8'h01,8'hC0,8'h02,8'hC0,8'h02,8'h60,8'h04,8'h60,8'h04,8'h70,8'h08,8'h30,
                  8'h08,8'h30,8'h18,8'h18,8'h10,8'h1C,8'h7C,8'h3E,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}; // "X"
    char[11]  <= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h7E,8'h3E,8'h38,8'h08,
                  8'h18,8'h08,8'h18,8'h10,8'h0C,8'h10,8'h0C,8'h10,8'h0C,8'h20,8'h06,8'h20,8'h06,8'h20,8'h03,8'h40,
                  8'h03,8'h40,8'h03,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,
                  8'h01,8'h80,8'h01,8'h80,8'h01,8'h80,8'h07,8'hE0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}; // "Y"
end

//给不同的区域赋值不同的像素数据
always @(posedge lcd_pclk or negedge sys_rst_n) begin
    if (!sys_rst_n)  begin
        pixel_data <= Char_COLOR;
    end
    else if((pixel_xpos >= CHAR_POS_X - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*1 - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data6][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1)) % 16) - 1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end    
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*1 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*2 -1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data5][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1)) % 16) - 1'b1])
            pixel_data <= Char_COLOR;         //显示字符为黑色
        else
            pixel_data <= BLUE;          //显示字符区域背景为白色
    end
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*2 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*3 - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data4][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1))%16) - 1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*3 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*4 - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data3][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1)) % 16) - 1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*4 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*5 - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[10][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1))%16) - 1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end 
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*5 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*6 - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data2][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1))%16) -1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*6 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*7- 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data1][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos)*16 - ((pixel_xpos - (CHAR_POS_X -1'b1))%16) -1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*7 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH/9*8 - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[bcd_data0][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1)) % 16) -1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end
    else if((pixel_xpos >= CHAR_POS_X + CHAR_WIDTH/9*8 - 1'b1) && (pixel_xpos < CHAR_POS_X + CHAR_WIDTH - 1'b1)
         && (pixel_ypos >= CHAR_POS_Y) && (pixel_ypos < CHAR_POS_Y + CHAR_HEIGHT)) begin
        if(char[11][(CHAR_HEIGHT + CHAR_POS_Y - pixel_ypos) * 16 - ((pixel_xpos - (CHAR_POS_X -1'b1)) % 16) - 1'b1])
            pixel_data <= Char_COLOR;
        else
            pixel_data <= BLUE;
    end 
    // 按钮1区域
    else if ((pixel_xpos >= BUTTON1_X) && (pixel_xpos < BUTTON1_X + BUTTON_WIDTH) &&
            (pixel_ypos >= BUTTON1_Y) && (pixel_ypos < BUTTON1_Y + BUTTON_HEIGHT)) begin
            pixel_data <= BUTTON_COLOR;
        
        // 绘制标签"X1"
        if ((pixel_xpos >= LABEL_X1_X) && (pixel_xpos < LABEL_X1_X + 2*CHAR_WIDTH_BUTTON) &&
            (pixel_ypos >= LABEL_Y) && (pixel_ypos < LABEL_Y + CHAR_HEIGHT)) begin
            
            // 第一个字符"X"
            if (pixel_xpos < LABEL_X1_X + CHAR_WIDTH_BUTTON) begin
                if (char[10][(CHAR_HEIGHT + LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - LABEL_X1_X) % CHAR_WIDTH_BUTTON) - 1]) begin
                    pixel_data <= LABEL_COLOR;
                end
            end 
            // 第二个字符"1"
            else if (pixel_xpos < LABEL_X1_X + 2*CHAR_WIDTH_BUTTON) begin
                if (char[1][(CHAR_HEIGHT + LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - LABEL_X1_X - CHAR_WIDTH_BUTTON) % CHAR_WIDTH_BUTTON) - 1]) begin
                    pixel_data <= LABEL_COLOR;
                end
            end
        end
    end
    // 按钮2区域
    else if ((pixel_xpos >= BUTTON2_X) && (pixel_xpos < BUTTON2_X + BUTTON_WIDTH) &&
            (pixel_ypos >= BUTTON2_Y) && (pixel_ypos < BUTTON2_Y + BUTTON_HEIGHT)) begin
        pixel_data <= BUTTON_COLOR;
        
        // 绘制标签"X2"
        if ((pixel_xpos >= LABEL_X2_X) && (pixel_xpos < LABEL_X2_X + 2*CHAR_WIDTH_BUTTON) &&
            (pixel_ypos >= LABEL_Y) && (pixel_ypos < LABEL_Y + CHAR_HEIGHT)) begin
            
            if (pixel_xpos < LABEL_X2_X + CHAR_WIDTH_BUTTON) begin
                if (char[10][(CHAR_HEIGHT + LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - LABEL_X2_X) % CHAR_WIDTH_BUTTON) - 1]) begin
                    pixel_data <= LABEL_COLOR;
                end
            end 
            else if (pixel_xpos < LABEL_X2_X + 2*CHAR_WIDTH_BUTTON) begin
                if (char[2][(CHAR_HEIGHT + LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - LABEL_X2_X - CHAR_WIDTH_BUTTON) % CHAR_WIDTH_BUTTON) - 1]) begin
                    pixel_data <= LABEL_COLOR;
                end
            end
        end
    end

    // 按钮3区域
    else if ((pixel_xpos >= BUTTON3_X) && (pixel_xpos < BUTTON3_X + BUTTON_WIDTH) &&
            (pixel_ypos >= BUTTON3_Y) && (pixel_ypos < BUTTON3_Y + BUTTON_HEIGHT)) begin
        pixel_data <= BUTTON_COLOR;
        
        // 绘制标签"X3"
        if ((pixel_xpos >= LABEL_X3_X) && (pixel_xpos < LABEL_X3_X + 2*CHAR_WIDTH_BUTTON) &&
            (pixel_ypos >= LABEL_Y) && (pixel_ypos < LABEL_Y + CHAR_HEIGHT)) begin
            
            if (pixel_xpos < LABEL_X3_X + CHAR_WIDTH_BUTTON) begin
                if (char[10][(CHAR_HEIGHT + LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - LABEL_X3_X) % CHAR_WIDTH_BUTTON) - 1]) begin
                    pixel_data <= LABEL_COLOR;
                end
            end 
            else if (pixel_xpos < LABEL_X3_X + 2*CHAR_WIDTH_BUTTON) begin
                if (char[3][(CHAR_HEIGHT + LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - LABEL_X3_X - CHAR_WIDTH_BUTTON) % CHAR_WIDTH_BUTTON) - 1]) begin
                    pixel_data <= LABEL_COLOR;
                end
            end
        end
    end
    // 区域1（按钮1上方）显示Y1    
    else if((pixel_xpos >= REGION1_X) && (pixel_xpos < REGION1_X + BUTTON_WIDTH)
         && (pixel_ypos >= REGION1_Y) && (pixel_ypos < REGION1_Y + REGION_HEIGHT)) begin
        pixel_data <= REGION_COLOR;
        
        // 绘制标签"Y1"
        if ((pixel_xpos >= REGION_LABEL_X1) && (pixel_xpos < REGION_LABEL_X1 + 2*CHAR_WIDTH_BUTTON)
         && (pixel_ypos >= REGION_LABEL_Y) && (pixel_ypos < REGION_LABEL_Y + CHAR_HEIGHT)) begin
            
            // 第一个字符"Y"
            if (pixel_xpos < REGION_LABEL_X1 + CHAR_WIDTH_BUTTON) begin
                if (char[11][(CHAR_HEIGHT + REGION_LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - REGION_LABEL_X1) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end 
            // 第二个字符"1"
            else if (pixel_xpos < REGION_LABEL_X1 + 2*CHAR_WIDTH_BUTTON) begin
                if (char[1][(CHAR_HEIGHT + REGION_LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - REGION_LABEL_X1 - CHAR_WIDTH_BUTTON) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end         
        end
        // 添加：在区域右侧显示数字"1"
        else if ((pixel_xpos >= DIGIT_X1) && (pixel_xpos < DIGIT_X1 + CHAR_WIDTH_BUTTON)
            && (pixel_ypos >= DIGIT_Y) && (pixel_ypos < DIGIT_Y + CHAR_HEIGHT)) begin
            if (button1_active) begin
                if (char[1][(CHAR_HEIGHT + DIGIT_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - DIGIT_X1) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end else begin
                if (char[0][(CHAR_HEIGHT + DIGIT_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - DIGIT_X1) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end
        end           
    end
    
    // 区域2（按钮2上方）显示Y2
    else if((pixel_xpos >= REGION2_X) && (pixel_xpos < REGION2_X + BUTTON_WIDTH)
         && (pixel_ypos >= REGION2_Y) && (pixel_ypos < REGION2_Y + REGION_HEIGHT)) begin
        pixel_data <= REGION_COLOR;
        
        // 绘制标签"Y2"
        if ((pixel_xpos >= REGION_LABEL_X2) && (pixel_xpos < REGION_LABEL_X2 + 2*CHAR_WIDTH_BUTTON)
         && (pixel_ypos >= REGION_LABEL_Y) && (pixel_ypos < REGION_LABEL_Y + CHAR_HEIGHT)) begin
            
            // 第一个字符"Y"
            if (pixel_xpos < REGION_LABEL_X2 + CHAR_WIDTH_BUTTON) begin
                if (char[11][(CHAR_HEIGHT + REGION_LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - REGION_LABEL_X2) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end 
            // 第二个字符"2"
            else if (pixel_xpos < REGION_LABEL_X2 + 2*CHAR_WIDTH_BUTTON) begin
                if (char[2][(CHAR_HEIGHT + REGION_LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - REGION_LABEL_X2 - CHAR_WIDTH_BUTTON) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end
        end
    end
    
    // 区域3（按钮3上方）显示Y3
    else if((pixel_xpos >= REGION3_X) && (pixel_xpos < REGION3_X + BUTTON_WIDTH)
         && (pixel_ypos >= REGION3_Y) && (pixel_ypos < REGION3_Y + REGION_HEIGHT)) begin
        pixel_data <= REGION_COLOR;
        
        // 绘制标签"Y3"
        if ((pixel_xpos >= REGION_LABEL_X3) && (pixel_xpos < REGION_LABEL_X3 + 2*CHAR_WIDTH_BUTTON)
         && (pixel_ypos >= REGION_LABEL_Y) && (pixel_ypos < REGION_LABEL_Y + CHAR_HEIGHT)) begin
            
            // 第一个字符"Y"
            if (pixel_xpos < REGION_LABEL_X3 + CHAR_WIDTH_BUTTON) begin
                if (char[11][(CHAR_HEIGHT + REGION_LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - REGION_LABEL_X3) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end 
            // 第二个字符"3"
            else if (pixel_xpos < REGION_LABEL_X3 + 2*CHAR_WIDTH_BUTTON) begin
                if (char[3][(CHAR_HEIGHT + REGION_LABEL_Y - pixel_ypos) * 16 - 
                        ((pixel_xpos - REGION_LABEL_X3 - CHAR_WIDTH_BUTTON) % CHAR_WIDTH_BUTTON) - 1]) 
                    pixel_data <= REGION_LABEL_COLOR;
            end
        end
    end

    else begin
        pixel_data <= BACK_COLOR;              //绘制屏幕背景为白色
    end
end
endmodule 
//这份代码左上角前四个数字动态显示触碰屏幕位置的横坐标，然后是字符X，然后是3个数字动态显示触碰屏幕位置的纵坐标，然后是字符Y。
//这份代码还设置三个按钮X1,X2,X3，按钮正上方三个的区域，对应第一个区域左边标上Y1，区域右边标上数字1.第二个区域左边标上Y2，第三个区域左边标上Y2，
//现在要求第一个区域的右边那个1，希望变成动态的0或1，1代表触碰屏幕位置在按钮X1位置。否则为0.
//注意，输入变量data_in是bcd_data在bcd变换之前的值，data_in前16位代表屏幕位置的横坐标，后16位触碰屏幕位置的纵坐标，显示屏的尺寸是800*480.
//请编写代码，注意代码还是放在lcd_display里面，但是希望显示的时候只显示你这次新加（或删改）的代码内容