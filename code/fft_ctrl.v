module fft_ctrl(
	input 	clk,
	input 	rst_n,
	input 	key,
	input 	fft_shutdown,
	output 	reg fft_valid
);

reg 		key0_d0;
reg 		key0_d1;
reg 		key1_d0;
reg 		key1_d1;

wire start1;
wire start2;

assign start1 = ~key0_d0 & key0_d1 ;//下降沿检测
assign start2 = ~key1_d0 & key1_d1 ;

always @(posedge clk or negedge  rst_n)begin
	if(~rst_n)begin
		key0_d0 <= 1;
		key0_d1 <= 1;
		key1_d0 <= 1;
		key1_d1 <= 1;
	end
	else begin
		key0_d0 <= key[0];
		key0_d1 <= key0_d0;
		key1_d0 <= key[1];
		key1_d1 <= key1_d0;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(~rst_n)
		fft_valid <= 0;
	else if((start1) || (start2))//按键按下，启动fft
		fft_valid <= 1;
	else if(fft_shutdown)
		fft_valid <= 0;//ram写入完成，重置fft
	else 
		fft_valid <= fft_valid;
end
endmodule