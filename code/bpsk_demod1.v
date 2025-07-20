`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/18 17:05:00
// Design Name: 
// Module Name: bpsk_demod1
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


module bpsk_demod1(
	input 				clk_32m,
	input 				rst_n,
	input 				en,   
	input				mode,
	input 	   [9:0]	ad_data,    
	output reg [9:0] 	demod_out,
	output reg [7:0] 	freq        
    );

wire clk_50k;
wire clk_500;
	
reg signed [79:0] bpsk_wave_d;	
reg signed [9:0] bpsk_wave;
reg [3:0] delay_cnt;

wire signed [9:0] bpsk_wave_180deg;
wire signed [19:0] wave_high_t;

wire fir_valid;

reg wave;
reg wave_d0;
reg code;
reg code_d0;
reg [12:0] freq_cnt_t;
reg [12:0] freq_cnt;
reg flag;

sample_clk_div m0_sample_clk_div(
	.clk(clk),
	.rst_n(rst_n),
	.clk_50k(clk_50k),
	.clk_500(clk_500)
);

always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		bpsk_wave <= 0;
	else 
		bpsk_wave <= ad_data + 512;

always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		bpsk_wave_d <= 0;
	else 
		bpsk_wave_d <= {bpsk_wave[9:0] , bpsk_wave_d[79:10]};
		
assign bpsk_wave_180deg = bpsk_wave_d[9:0];
		
mult_gen_10x10 m1_mult_gen_10x10 (
	.CLK(clk_32m),  // input wire CLK
	.A(bpsk_wave),      // input wire [9 : 0] A
	.B(bpsk_wave_180deg),      // input wire [9 : 0] B
	.P(wave_high_t)      // output wire [19 : 0] P
);

always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		wave <= 0;
	else if((wave_high_t >= 50) && (wave == 0))
		wave <= 1;
	else if((wave_high_t <= -50) && (wave == 1))
		wave <= 0;
	else 
		wave <= wave;
		
always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)begin
		wave_d0 <= 0;
		code_d0 <= 0;
		end
	else begin
		wave_d0 <= wave;
		code_d0 <= code;
		end
		
always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		code <=0;
	else if((~wave_d0) & wave)
		code <= ~code;
	else 
		code <= code;
		
always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		demod_out <= 0;
	else if(en)
		if(~mode)
			demod_out <= ad_data;
		else begin
			if(code)
				demod_out <= 10'h3ff;
			else 
				demod_out <= 0;
			end
	else demod_out <= 0;
	
always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)begin
		freq_cnt_t <= 0;
		flag <= 0;
		end
	else if((~code_d0 & code) || (code_d0 & ~code))begin
		freq_cnt_t <= 0;
		flag <= 0;
		end
	else if(freq_cnt_t > 5500)begin
		freq_cnt_t <= freq_cnt_t;
		flag <= 1;
		end
	else begin
		freq_cnt_t <= freq_cnt_t + 1'b1;
		flag <= flag;
		end
		
always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		freq_cnt <= 13'h1fff;
	else if((~code_d0 & code) || (code_d0 & ~code))
		if((freq_cnt_t <= freq_cnt) && (flag != 1))
			freq_cnt <= freq_cnt_t;
		else 
			freq_cnt <= freq_cnt;
	else 
		freq_cnt <= freq_cnt;
	
always@(posedge clk_32m or negedge rst_n)
	if(~rst_n)
		freq <= 0;
	else if((freq_cnt>=3100)&&(freq_cnt <= 3300))
		freq <= 10;
	else if((freq_cnt>=3900)&&(freq_cnt <= 4100))
		freq <= 8;
	else if((freq_cnt>=5233)&&(freq_cnt <= 5433))
		freq <= 6;
	else 
		freq <= freq;
 	
endmodule
