`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 03:40:18
// Design Name: 
// Module Name: vco
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


module vco(
	input 					clk_8192k,
	input 					clk_500,
	input					rst_n,
	input 					en, 
	input  signed [31:0] 	v_g,
	output signed [9:0] 	carrier_wave,
	output signed [9:0] 	carrier_wave_90deg,
	output reg				lock
    );
	
parameter phrase_90deg = 16'd16_384;
parameter phrase_constant = 10_430; 
	
reg [15:0] phrase_ctrl;

wire [45:0] mult_result_t;
wire [45:0]mult_result_unsigned;
wire [45:0] mult_result;

assign mult_result_unsigned = (mult_result[45]) ?  {mult_result[45],(~mult_result[44:0]+1'b1)} : mult_result;
assign mult_result = mult_result_unsigned[31:16];

mult_gen_31x14 u_mult_gen_31x14 (
  .CLK(clk_500),  // input wire CLK
  .A(v_g),      // input wire [31 : 0] A
  .P(mult_result_t)      // output wire [45 : 0] P
);
	
	
always@(posedge clk_500 or negedge rst_n)
	if(~rst_n)
		phrase_ctrl <= 0;
	else if(en)
		if(mult_result[45])
			phrase_ctrl <= phrase_ctrl - mult_result;
		else
			phrase_ctrl <= phrase_ctrl + mult_result;
	else 
		phrase_ctrl <= phrase_ctrl;
		
//相位差小于1°时相干载波相位锁定完毕
always@(posedge clk_500 or negedge rst_n)
	if(~rst_n)
		lock <= 0;
	else if(mult_result <= 182)
		lock <= 1;
	else 
		lock <= 0;
	
dds_carrier_2m dds_0deg (
  .aclk(clk_8192k),                                  // input wire aclk
  .s_axis_config_tvalid(en),  // input wire s_axis_config_tvalid
  .s_axis_config_tdata(phrase_ctrl),    // input wire [15 : 0] s_axis_config_tdata
  .m_axis_data_tvalid(),      // output wire m_axis_data_tvalid
  .m_axis_data_tdata(carrier_wave)        // output wire [15 : 0] m_axis_data_tdata
);

dds_carrier_2m dds_90deg (
  .aclk(clk_8192k),                                  // input wire aclk
  .s_axis_config_tvalid(en),  // input wire s_axis_config_tvalid
  .s_axis_config_tdata(phrase_ctrl + phrase_90deg),    // input wire [15 : 0] s_axis_config_tdata
  .m_axis_data_tvalid(),      // output wire m_axis_data_tvalid
  .m_axis_data_tdata(carrier_wave_90deg)        // output wire [15 : 0] m_axis_data_tdata
);
	
endmodule
