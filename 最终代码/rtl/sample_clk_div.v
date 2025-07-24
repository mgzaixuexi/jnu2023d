`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/16 03:17:49
// Design Name: 
// Module Name: sample_clk_div
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


module sample_clk_div(
	input 		clk,
	input 		rst_n,
	output 	    clk_50k,
	output      clk_500
    );
	
reg [15:0] clk_cnt1;
reg [8:0] clk_cnt2;
reg clk_50k_t;
reg clk_500_t;

always @(posedge clk or negedge rst_n)
    if(~rst_n)
		clk_cnt1<=0;
    else if(clk_cnt1==50_000-1)
		clk_cnt1<=0;
    else 
		clk_cnt1<=clk_cnt1+1'b1;
		
always @(posedge clk or negedge rst_n)
    if(~rst_n)
		clk_cnt2<=0;
    else if(clk_cnt2==500-1)
		clk_cnt2<=0;
    else 
		clk_cnt2<=clk_cnt2+1'b1;
	
always @(posedge clk or negedge rst_n)   
    if(~rst_n)
		clk_50k_t<=0;
    else if(clk_cnt2==500-1)
		clk_50k_t<=~clk_50k_t;
    else 
		clk_50k_t<=clk_50k_t;
		
always @(posedge clk or negedge rst_n)   
    if(~rst_n)
		clk_500_t<=0;
    else if(clk_cnt1==50_000-1)
		clk_500_t<=~clk_500_t;
    else 
		clk_500_t<=clk_500_t;
      

BUFG BUFG_inst1 (
	.O(clk_500), // 1-bit output: Clock output
    .I(clk_500_t)  // 1-bit input: Clock input
   );
   
BUFG BUFG_inst2 (
    .O(clk_50k), // 1-bit output: Clock output
    .I(clk_50k_t)  // 1-bit input: Clock input
   );
	
endmodule
