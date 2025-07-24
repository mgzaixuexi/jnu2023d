`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/21 16:07:20
// Design Name: 
// Module Name: key_debounce
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


module key_debounce(
    input clk,
    input rst_n,
    input [2:0] key,
    output reg [2:0] key_value
    );
    
parameter waittime = 1_000_000;

reg [19:0] cnt;
reg flag;

always@ (posedge clk or negedge rst_n)
    if(~rst_n)begin
    cnt<=0;
    flag<=0;
    end
    else if(~key)
        if(flag)
        cnt<=0;
        else if(cnt==waittime-1)begin
        flag<=1;
		cnt<=0;
		end
        else cnt<=cnt+ 1'b1;
    else begin
    cnt<=0;
    flag<=0;
    end
    
always@ (posedge clk or negedge rst_n)
    if(~rst_n)
    key_value<=3'b111;
    else if(cnt==waittime-1)
    key_value<=key;
    else key_value<=3'b111;
    
endmodule
