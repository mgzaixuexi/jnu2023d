`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/22 22:45:25
// Design Name: 
// Module Name: fm_demod_new
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


module fm_demod_new(
	input clk,
	input rst_n,
	input en,
	input mode,
	input [9:0] ad_data,
	output [9:0]   demod_out,
	output [7:0]	mf,
	output [7:0] 	delta_f,
	output [7:0] 	mod_freq
    );

	
wire 		   i_valid ;	
wire signed [15:0]    i_data_i	;
wire signed [15:0]    i_data_q	;

wire valid1;
wire valid2;
wire signed [9:0] wave_cos;
wire signed [9:0] wave_sin;
		
reg signed [9:0] ad_data_signed;

wire signed [19:0] wave_i;
wire signed [19:0] wave_q;

always@(posedge clk or negedge rst_n)
	if(~rst_n)
		ad_data_signed <= 0;
	else 
		ad_data_signed <= ad_data + 512;
		
dds_compiler_0 dds_compiler_cos (
  .aclk(clk),                                  // input wire aclk
  .s_axis_config_tvalid(en),  // input wire s_axis_config_tvalid
  .s_axis_config_tdata(0),    // input wire [15 : 0] s_axis_config_tdata
  .m_axis_data_tvalid(valid1),      // output wire m_axis_data_tvalid
  .m_axis_data_tdata(wave_cos)        // output wire [15 : 0] m_axis_data_tdata
);

dds_compiler_0 dds_compiler_sin (
  .aclk(clk),                                  // input wire aclk
  .s_axis_config_tvalid(en),  // input wire s_axis_config_tvalid
  .s_axis_config_tdata(16384),    // input wire [15 : 0] s_axis_config_tdata
  .m_axis_data_tvalid(valid2),      // output wire m_axis_data_tvalid
  .m_axis_data_tdata(wave_sin)        // output wire [15 : 0] m_axis_data_tdata
);
	
mult_gen_10x10 mult_gen_10x10_i (
  .CLK(clk),  // input wire CLK
  .A(ad_data_signed),      // input wire [9 : 0] A
  .B(wave_cos),      // input wire [9 : 0] B
  .P(wave_i)      // output wire [19 : 0] P
);

mult_gen_10x10 mult_gen_10x10_q (
  .CLK(clk),  // input wire CLK
  .A(ad_data_signed),      // input wire [9 : 0] A
  .B(wave_sin),      // input wire [9 : 0] B
  .P(wave_q)      // output wire [19 : 0] P
);

wire fir_ready1;
wire fir_ready2; 
wire fir_valid1;
wire fir_valid2;

wire signed [39:0] wave_i_low;
wire signed [39:0] wave_q_low;

fir_compiler_0 fir_compiler_01 (
  .aclk(clk),                              // input wire aclk
  .s_axis_data_tvalid(valid1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(fir_ready1),  // output wire s_axis_data_tready
  .s_axis_data_tdata((fir_ready1 ? wave_i : 0)),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(fir_valid1),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(wave_i_low)    // output wire [39 : 0] m_axis_data_tdata
);

fir_compiler_0 fir_compiler_02 (
  .aclk(clk),                              // input wire aclk
  .s_axis_data_tvalid(valid2),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(fir_ready2),  // output wire s_axis_data_tready
  .s_axis_data_tdata((fir_ready2 ? wave_q : 0)),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(fir_valid2),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(wave_q_low)    // output wire [39 : 0] m_axis_data_tdata
);
	
assign i_valid = fir_valid1 & fir_valid2; 
assign i_data_i = wave_i_low >>> 24; 
assign i_data_q = wave_q_low >>> 24; 
	
fm_demod uu_fm_demod(
    .clk (clk)            ,
    .rst (~rst_n)            ,
    
    .i_valid (i_valid)        ,
    .i_data_i (i_data_i)       ,
    .i_data_q (i_data_q)       ,
    .o_rdy   (o_rdy)    ,
    .o_data  (o_data)  

);	

wire signed [9:0] o_data_t;
wire signed [39:0] demod_out_t;
wire fir_ready3;

assign o_data_t = o_data[14:5];

fir_compiler_0 u_fir_compiler_0 (
  .aclk(clk_32m),                              // input wire aclk
  .s_axis_data_tvalid(en),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(fir_ready3),  // output wire s_axis_data_tready
  .s_axis_data_tdata((fir_ready3 ? {{14{o_data_t[9]}},o_data_t} : 0)),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(demod_out_t)    // output wire [39 : 0] m_axis_data_tdata
);

assign demod_out = (demod_out_t <<<18) + 512;

endmodule
