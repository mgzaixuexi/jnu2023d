`timescale 1ns / 1ps

module ask_demod_tb;

reg clk_8192k;
reg clk_30M;
reg rst_n;
// 输入接口
reg [9:0] ad_data;  // 输入数据（实部）

//输出
wire bit_out;
wire bit_valid;
wire [3:0] bit_rate_kbps;
wire [7:0] freq;

ask_demod u_ask_demod (
    .clk(clk_8192k),       // 
    .clk_30M(clk_30M),       // 抽样时钟
    .rst_n(rst_n),     // 异步复位（低有效）
    .en(1'b1),        // 使能信号（高有效）
    .ad_data(ad_data),   // 10位ADC输入（AM信号）
    
    .bit_out(bit_out),       // 解调输出的比特
    .bit_valid(bit_valid),     // 比特有效信号
    .bit_rate_kbps(bit_valid), 
    .freq(freq)       // 调制频率（单位kHz，1~5）
);
// 生成8192kHz时钟（周期≈122ns）
initial begin
    clk_8192k = 0;
    forever #61 clk_8192k = ~clk_8192k;  // 半周期=61ns
end
// 生成30M时钟（周期≈33.33ns）
initial begin
    clk_30M = 0;
    forever #17 clk_30M = ~clk_30M;  // 半周期=17ns
end
// 读取文件中的数据
reg [9:0] mem [0:81920];
integer i;
reg file_loaded = 0;     // 文件加载完成标志

initial begin
    // 初始化
    clk_8192k = 0;
    rst_n = 0;

    
    // 复位
    #100;
    rst_n = 1;

    // 读取数据文件（注意文件格式）
    $readmemb("D:/vivado/project/ti/jnu2023d_test/code/sim/ask_signal_6bit.txt", mem);
    file_loaded = 1;     // 文件加载完成标志
    // 读取测试数据文件
    if(file_loaded)begin
        for (i = 0; i < 81920; ) begin
            @(posedge clk_8192k);
                ad_data <= mem[i];
                i <= (i<81919)?i + 1:0;
        end
    end
    // 等待FFT处理完成（根据实际情况调整延时）
    #2000000;
	$finish;
end

endmodule