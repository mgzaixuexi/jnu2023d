`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 02:09:02
// Design Name: 
// Module Name: 2psk_demod
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


module bpsk_demod(
	input 				clk,//50mhz
	input 				clk_8192k,
	input 				rst_n,
	input 				en,      
	input 	   [9:0]	ad_data,       
	output reg [9:0] 	demod_out,
	output reg [7:0] 	freq          
	);
	
reg signed [9:0] bpsk_wave;

wire signed [9:0] wave_c;
wire signed [19:0] wave_c_t;

wire signed [9:0] wave_d;
wire signed [19:0] wave_d_t;

wire signed [9:0] wave_e;
wire signed [15:0] wave_e_t;

wire signed [9:0] wave_f;
wire signed [15:0] wave_f_t;

wire signed [9:0] wave_g;
wire signed [19:0] wave_g_t;

wire signed [31:0] v_g;

wire signed [9:0] carrier_wave;
wire signed [9:0] carrier_wave_90deg;

wire clk_50k;
wire clk_500;
wire lock;


sample_clk_div u_sample_clk_div(
	.clk(clk),
	.rst_n(rst_n),
	.clk_50k(clk_50k),
	.clk_500(clk_500)
);


always@(posedge clk_8192k or negedge rst_n)
	if(~rst_n)
		bpsk_wave <= 0;
	else 
		bpsk_wave <= ad_data + 512;

//相位锁定完后输出		
always@(posedge clk_8192k or negedge rst_n)
	if(~rst_n)
		demod_out <= 0;
	else if(lock)
		demod_out <= (wave_e<<<1) + 512;
	else 
		demod_out <= 0;
		
mult_gen_10x10 mult_up (
	.CLK(clk_8192k),  // input wire CLK
	.A(bpsk_wave),      // input wire [9 : 0] A
	.B(carrier_wave),      // input wire [9 : 0] B
	.P(wave_c_t)      // output wire [19 : 0] P
);

mult_gen_10x10 mult_down (
	.CLK(clk_8192k),  // input wire CLK
	.A(bpsk_wave),      // input wire [9 : 0] A
	.B(carrier_wave_90deg),      // input wire [9 : 0] B
	.P(wave_d_t)      // output wire [19 : 0] P
);
	
assign wave_c = wave_c_t>>>10;
assign wave_d = wave_d_t>>>10;
	
fir_low_10khz fir_up (
	.aclk(clk_50k),                              // input wire aclk
	.s_axis_data_tvalid(en),  // input wire s_axis_data_tvalid
	.s_axis_data_tready(),  // output wire s_axis_data_tready
	.s_axis_data_tdata(wave_c),    // input wire [15 : 0] s_axis_data_tdata
	.m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
	.m_axis_data_tdata(wave_e_t)    // output wire [15 : 0] m_axis_data_tdata
);

fir_low_10khz fir_down (
	.aclk(clk_50k),                              // input wire aclk
	.s_axis_data_tvalid(en),  // input wire s_axis_data_tvalid
	.s_axis_data_tready(),  // output wire s_axis_data_tready
	.s_axis_data_tdata(wave_d),    // input wire [15 : 0] s_axis_data_tdata
	.m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
	.m_axis_data_tdata(wave_f_t)    // output wire [15 : 0] m_axis_data_tdata
);

assign wave_e = wave_e_t;
assign wave_f = wave_f_t;

mult_gen_10x10 mult_med (
	.CLK(clk_8192k),  // input wire CLK
	.A(wave_e),      // input wire [9 : 0] A
	.B(wave_f),      // input wire [9 : 0] B
	.P(wave_g_t)      // output wire [19 : 0] P
);

assign wave_g = wave_g_t>>>10;

fir_loop_500hz fir_loop_500hz (
  .aclk(clk_500),                              // input wire aclk
  .s_axis_data_tvalid(en),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(),  // output wire s_axis_data_tready
  .s_axis_data_tdata(wave_g),    // input wire [15 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(v_g)    // output wire [31 : 0] m_axis_data_tdata
);

vco u_vco(
	.clk_8192k(clk_8192k),
	.clk_500(clk_500),
	.rst_n(rst_n),
	.en(en), 
	.v_g(v_g<<<2),
	.carrier_wave(carrier_wave),
	.carrier_wave_90deg(carrier_wave_90deg),
	.lock(lock)
);

endmodule
