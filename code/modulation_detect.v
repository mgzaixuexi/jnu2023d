`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/13 10:52:47
// Design Name: 
// Module Name: modulation_detect
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


module modulation_detect
    #(
    parameter   addr_2M = 100   ,  //2MHZ频点位置
    parameter   addr_2M_high   = 201, //2MHZ后100频点位置
	parameter 	compare_num1 = 100//比较阈值，噪声最大值
    )
	(
    input 			   	clk,
    input 			   	rst_n,
	input 				en,//使能，上升沿有效，fft取模数据写入ram完成再拉高
	input 				key,//启动按键，重置识别
    input 		[15:0] 	rd_data,
    output reg 	[7:0] 	rd_addr,
    output reg 	[2:0]	mode_type,
    output reg 			valid
    );

//状态参数
parameter idle  = 7'b0_000_001;
parameter find1 = 7'b0_000_010;
parameter find2 = 7'b0_000_100;
parameter find3 = 7'b0_001_000;
parameter find4 = 7'b0_010_000;
parameter judge = 7'b0_100_000;
parameter done  = 7'b1_000_000;

reg [7:0] 	state;
reg [7:0] 	next_state;	
reg 		en_d0;
reg 		en_d1;
reg 		key_d0;
reg 		key_d1;
reg [4:0]	flag;
reg [15:0]	wave_data1;
reg [15:0]	wave_data2;
reg [15:0]	wave_data3;
reg [15:0]	wave_data4;
reg [7:0]	data_addr1;
reg [7:0]	data_addr2;
reg [7:0]	data_addr3;
reg [7:0]	data_addr4;

wire [15:0]	wave_data1x8;
wire [15:0]	wave_data2x8;
wire [7:0] 	data_addr12a;

assign wave_data1x8 = wave_data1<<3;
assign wave_data2x8 = wave_data2<<3;
assign data_addr12a = (data_addr1 + data_addr2)>>1;
	
always @(posedge clk or negedge  rst_n)begin
	if(~rst_n)begin
	en_d0 <= 0;
	en_d1 <= 0;
	key_d0 <= 1;
	key_d1 <= 1;
	end
	else begin
	en_d0 <= en;
	en_d1 <= en_d0;
	key_d0 <= key;
	key_d1 <= key_d0;
	end
end
	
//三段式状态机
always @(posedge clk or negedge  rst_n)
	if(~rst_n)
	state <= idle;
	else 
	state <= next_state;

always @(*) begin
    next_state = idle;
	case(state)
		idle:	if(en_d0 & ~en_d1)//检测上升沿启动
					next_state = find1;
				else 
					next_state = idle;
		find1:	if(flag[0])
					next_state = find2;
				else 
					next_state = find1;
		find2:	if(flag[1])
					next_state = find3;	
			    else 
		        	next_state = find2;
		find3:	if(flag[2])
			    	next_state = find4;
		        else 
		        	next_state = find3;
		find4:	if(flag[3])
			    	next_state = judge;
		        else 
		        	next_state = find4;
		judge:  if(flag[4])
			    	next_state = done;
		        else 
		        	next_state = judge;
		done	:if(~key_d0 & key_d1)//按键下降沿重置识别
					next_state = idle;
				else 
					next_state = done;
		default:next_state = idle;
	endcase
end
	
always @(posedge clk or negedge  rst_n)
	if(~rst_n)begin
		flag <= 0;
		rd_addr <= 0;
		wave_data1 <= 0;
		wave_data2 <= 0;
		wave_data3 <= 0;
		wave_data4 <= 0;
		data_addr1 <= 0;
		data_addr2 <= 0;
		data_addr3 <= 0;
		data_addr4 <= 0;
		mode_type <= 0;
		valid <= 0;
	end
	else 
		case(state)
			idle:	begin
						flag <= 0;
						rd_addr <= 0;
						wave_data1 <= 0;
						wave_data2 <= 0;
						wave_data3 <= 0;
						wave_data4 <= 0;
						data_addr1 <= 0;
						data_addr2 <= 0;
						data_addr3 <= 0;
						data_addr4 <= 0;
						mode_type <=0;
						valid <= 0;
					end
			find1:	begin
			        if((rd_addr <= addr_2M_high) && (flag[0]==0))
			        	rd_addr <= rd_addr + 1'b1;
			        else if((rd_addr > addr_2M_high) && (flag[0]==0)) begin
			            rd_addr <= 0;
			            flag[0] <= 1;
			            end
					else begin
						rd_addr <= rd_addr;
						flag[0] <= flag[0];
						end
			        if((rd_data > wave_data1) && (flag[0]==0) && (rd_addr != addr_2M))begin
			        	wave_data1 <= rd_data;
			        	data_addr1 <= rd_addr;
			        	end
					else begin
						wave_data1 <= wave_data1;
						data_addr1 <= data_addr1;
						end
					end
			find2:	begin
			        if((rd_addr <= addr_2M_high) && (flag[1]==0))
			        	rd_addr <= rd_addr + 1'b1;
			        else if((rd_addr > addr_2M_high) && (flag[1]==0)) begin
			            rd_addr <= 0;
			            flag[1] <= 1;
			            end
			        else begin
			        	rd_addr <= rd_addr;
			        	flag[1] <= flag[1];
			        	end
			        if((rd_data > wave_data2) && (flag[1]==0) && (rd_addr != addr_2M) && (rd_addr != data_addr1))begin
			        	wave_data2 <= rd_data;
			        	data_addr2 <= rd_addr;
			        	end
			        else begin
			        	wave_data2 <= wave_data2;
			        	data_addr2 <= data_addr2;
			        	end
			        end
			find3:	begin
			        if((rd_addr <= addr_2M_high) && (flag[2]==0))
			        	rd_addr <= rd_addr + 1'b1;
			        else if((rd_addr > addr_2M_high) && (flag[2]==0)) begin
			            rd_addr <= 0;
			            flag[2] <= 1;
			            end
			        else begin
			        	rd_addr <= rd_addr;
			        	flag[2] <= flag[2];
			        	end
			        if((rd_data > wave_data3) && (flag[2]==0) && (rd_addr != addr_2M) && (rd_addr != data_addr1) && (rd_addr != data_addr2))begin
			        	wave_data3 <= rd_data;
			        	data_addr3 <= rd_addr;
			        	end
			        else begin
			        	wave_data3 <= wave_data3;
			        	data_addr3 <= data_addr3;
			        	end
			        end			
			find4:	begin
			        if((rd_addr <= addr_2M_high) && (flag[3]==0))
			        	rd_addr <= rd_addr + 1'b1;
			        else if((rd_addr > addr_2M_high) && (flag[3]==0)) begin
			            rd_addr <= addr_2M;
			            flag[3] <= 1;
			            end
			        else begin
			        	rd_addr <= rd_addr;
			        	flag[3] <= flag[3];
			        	end
			        if((rd_data > wave_data4) && (flag[3]==0) && (rd_addr != addr_2M) && (rd_addr != data_addr1) && (rd_addr != data_addr2) && (rd_addr != data_addr3))begin
			        	wave_data4 <= rd_data;
			        	data_addr4 <= rd_addr;
			        	end
			        else begin
			        	wave_data4 <= wave_data4;
			        	data_addr4 <= data_addr4;
			        	end
			        end	
			judge:	begin
					if((wave_data3 > compare_num1) && (wave_data4 > compare_num1))begin
						mode_type <= 3'b010;
						flag[4] <= 1;
						end
					else if((wave_data1x8 >= rd_data) && (wave_data2x8 >= rd_data))
							if(data_addr12a == rd_addr)begin
								mode_type <= 3'b001;
								flag[4] <= 1;
								end
							else begin
								mode_type <= 3'b100;
								flag[4] <= 1;
								end
					else begin
						mode_type <= 3'b100;
						flag[4] <= 1;
						end
					end
			done:	valid <= 1;
			default:begin
						flag <= 0;
						rd_addr <= 0;
						wave_data1 <= 0;
						wave_data2 <= 0;
						wave_data3 <= 0;
						wave_data4 <= 0;
						data_addr1 <= 0;
						data_addr2 <= 0;
						data_addr3 <= 0;
						data_addr4 <= 0;
						mode_type <=0;
						valid <= 0;
					end
		endcase		
					
endmodule
