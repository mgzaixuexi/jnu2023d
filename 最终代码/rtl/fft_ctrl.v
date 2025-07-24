module fft_ctrl(
	input 	clk,
	input 	rst_n,
	input 	[1:0] key,
	input 	fft_shutdown,
	output 	reg fft_valid
);

parameter delay = 50_000;

reg [15:0] cnt;

//延迟1ms防止fft因为切换时钟出问题
always @(posedge clk or negedge rst_n)
	if(~rst_n)
		cnt <= 0;
	else if((~key[0]) || (~key[1]))
		cnt <= 1;
	else if(cnt >= delay - 1)
		cnt <= 0;
	else if(cnt >= 1)
		cnt <= cnt + 1'b1;
	else 
		cnt <= cnt;

always @(posedge clk or negedge rst_n)begin
	if(~rst_n)
		fft_valid <= 0;
	else if(cnt >= delay - 1)//按键按下，启动fft
		fft_valid <= 1;
	else if(fft_shutdown)
		fft_valid <= 0;//ram写入完成，重置fft
	else 
		fft_valid <= fft_valid;
end
endmodule