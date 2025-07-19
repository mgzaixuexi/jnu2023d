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
	parameter 	compare_num1 = 100,//比较阈值，噪声最大值,随便写的
	parameter 	compare_num2 = compare_num1*2
    )
	(
    input 			   	clk,
    input 			   	rst_n,
	input 				en,//使能，上升沿有效，fft取模数据写入ram完成再拉高
	input 		[1:0]	key,//启动按键，重置识别
    input 		[15:0] 	rd_data,
    output reg 	[7:0] 	rd_addr,
    output reg 	[2:0]	mode_type,
    output reg 			valid,
	output reg			mode
    );

//状态参数
parameter idle  = 4'b0001;
parameter find  = 4'b0010;
parameter judge = 4'b0100;
parameter done  = 4'b1000;

reg [3:0] 	state;
reg [3:0] 	next_state;	
reg 		en_d0;
reg 		en_d1;
reg 		key0_d0;
reg 		key0_d1;
reg 		key1_d0;
reg 		key1_d1;
reg [5:0]	flag;
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
wire [7:0] 	data_addr34a;

assign wave_data1x8 = wave_data1<<3;
assign wave_data2x8 = wave_data2<<3;
assign data_addr12a = (data_addr1 + data_addr2)>>1;
assign data_addr34a = (data_addr3 + data_addr4)>>1;
	
always @(posedge clk or negedge  rst_n)begin
	if(~rst_n)begin
		en_d0 <= 0;
		en_d1 <= 0;
		key0_d0 <= 1;
		key0_d1 <= 1;
		key1_d0 <= 1;
		key1_d1 <= 1;
	end
	else begin
		en_d0 <= en;
		en_d1 <= en_d0;
		key0_d0 <= key[0];
		key0_d1 <= key0_d0;
		key1_d0 <= key[1];
		key1_d1 <= key1_d0;
	end
end
	
always @(posedge clk or negedge  rst_n)
	if(~rst_n)
		mode <= 0;
	else if(~key0_d0 & key0_d1)
		mode <= 0;
	else if(~key1_d0 & key1_d1)
		mode <= 1;
	else 
		mode <= mode;

		
	
	
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
					next_state = find;
				else 
					next_state = idle;
		find:	if(flag[4])
		        	next_state = judge;
		        else 
		        	next_state = find;
		judge:  if(flag[5])
			    	next_state = done;
		        else 
		        	next_state = judge;
		done	:if((~key0_d0 & key0_d1) || (~key1_d0 & key1_d1))//按键下降沿重置识别
					next_state = idle;
				else 
					next_state = done;
		default:next_state = idle;
	endcase
end
	
always @(posedge clk or negedge  rst_n)
	if(~rst_n)begin
		flag <= 1;
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
						if(~mode)
							flag <= 6'b000_001;
						else
							flag <= 6'b000_100;
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
			find:	begin
					if(flag[4])
						rd_addr <= addr_2M;
			        else if(rd_addr <= addr_2M_high)
			        	rd_addr <= rd_addr + 1'b1;
			        else if(rd_addr > addr_2M_high) begin
			            rd_addr <= 0;
			            flag <= {flag[4:0], 1'b0};
			            end
					else begin
						rd_addr <= rd_addr;
						flag <= flag;
						end
					case(flag)
						6'b000_001:	if((rd_data > wave_data1) && (rd_addr != addr_2M))begin
						            	wave_data1 <= rd_data;
						            	data_addr1 <= rd_addr;
						            	end
						            else begin
						            	wave_data1 <= wave_data1;
						            	data_addr1 <= data_addr1;
						            	end
						6'b000_010:	if((rd_data > wave_data2) && (rd_addr != addr_2M) && (rd_addr != data_addr1))begin
						            	wave_data2 <= rd_data;
						            	data_addr2 <= rd_addr;
						            	end
						            else begin
						            	wave_data2 <= wave_data2;
						            	data_addr2 <= data_addr2;
						            	end
						6'b000_100:	if((rd_data > wave_data3) && (rd_addr != addr_2M) && (rd_addr != data_addr1) && (rd_addr != data_addr2))begin
						            	wave_data3 <= rd_data;
						            	data_addr3 <= rd_addr;
						            	end
						            else begin
						            	wave_data3 <= wave_data3;
						            	data_addr3 <= data_addr3;
						            	end		
						6'b001_000:	if((rd_data > wave_data4) && (rd_addr != addr_2M) && (rd_addr != data_addr1) && (rd_addr != data_addr2) && (rd_addr != data_addr3))begin
						            	wave_data4 <= rd_data;
						            	data_addr4 <= rd_addr;
						            	end
						            else begin
						            	wave_data4 <= wave_data4;
						            	data_addr4 <= data_addr4;
						            	end
						default:	begin
										wave_data1 <= wave_data1;
										wave_data2 <= wave_data2;
										wave_data3 <= wave_data3;
										wave_data4 <= wave_data4;
										data_addr1 <= data_addr1;
										data_addr2 <= data_addr2;
										data_addr3 <= data_addr3;
										data_addr4 <= data_addr4;
									end
					endcase	
					end
			judge:	begin
					case(mode)
						1'b0:	if((wave_data3 > compare_num1) && (wave_data4 > compare_num1))
									if(data_addr34a == addr_2M)begin
										mode_type <= 3'b010;
										flag <= {flag[4:0], 1'b0};
										end
									else begin
										mode_type <= 3'b100;
										flag <= {flag[4:0], 1'b0};
										end
								else if((wave_data1x8 >= rd_data) && (wave_data2x8 >= rd_data) && (rd_data > wave_data1))
										if(data_addr12a == addr_2M)begin
											mode_type <= 3'b001;
											flag <= {flag[4:0], 1'b0};
											end
										else begin
											mode_type <= 3'b100;
											flag <= {flag[4:0], 1'b0};
											end
								else begin
									mode_type <= 3'b100;
									flag <= {flag[4:0], 1'b0};
									end
						1'b1:	if(rd_data > wave_data3)begin
									mode_type <= 3'b001;
									flag <= {flag[4:0], 1'b0};
									end
								else if((wave_data3-wave_data4) >= compare_num2)begin
									mode_type <= 3'b010;
									flag <= {flag[4:0], 1'b0};
									end
								else begin
									mode_type <= 3'b100;
									flag <= {flag[4:0], 1'b0};
						            end
						default:begin
									mode_type <= mode_type;
									flag <= flag;
								end
					endcase			
					end
			done:	valid <= 1;
			default:begin
						if(~mode)
							flag <= 6'b000_001;
						else
							flag <= 6'b000_100;
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
