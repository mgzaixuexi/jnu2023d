`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/27 14:50:55
// Design Name: 
// Module Name: ram_wr_ctrl
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

module ram_wr_ctrl
#(
	parameter addr_2Mlow = 1900, //2MHz前100频点地址
	parameter   addr_2M_high   = 2100 //2MHZ后100频点位置
)
(
	input 			 	 clk,//fft时钟
	input			 	 rst_n,//复位，接（rst_n&key）key是启动键
	input  	   [15:0]    data_modulus,    
    input            	 data_valid,//取模数据有效信号
	output     [15:0]	 wr_data,
	output 	   [7:0]	 wr_addr,
	output 			 	 wr_en,//写使能
	output reg 			 wr_done,//ram写完成信号，也是识别模块使能信号
	output  			 fft_shutdown//关闭fft，高有效
);

reg [11:0] wr_addr_t;

assign wr_data = data_modulus;
assign wr_en = (wr_addr_t >= addr_2M_high + 3) ? 1'b0 : 1'b1;//ram写使能，写完之前都置高
assign fft_shutdown = wr_done;
assign wr_addr = (wr_addr_t >= addr_2Mlow) ? (wr_addr_t - addr_2Mlow) : 0;

always @(posedge clk or negedge rst_n)
    if (!rst_n)begin
		wr_addr_t <= 0;
		wr_done <= 0;
	end
	else if (wr_addr_t >= addr_2M_high + 3)begin//ram写完了，拉高写完成信号
		wr_done <= 1;
		wr_addr_t <= wr_addr_t;
	end
	else if(data_valid)
		wr_addr_t <= wr_addr_t + 1'b1;
	else begin
		wr_addr_t <= wr_addr_t;
		wr_done <= wr_done;
	end
	

		
endmodule
	
	