`timescale 1ns / 1ps

module am_demod_tb;

reg clk_8192k;
reg rst_n;
// 输入接口
reg [9:0] ad_data;  // 输入数据（实部）
//输出
wire [9:0] demod_out;
wire [7:0] ma;
wire [7:0] freq;

am_demod u_am_demod (
    .clk(clk_8192k),       // 
    .rst_n(rst_n),     // 异步复位（低有效）
    .en(1'b1),        // 使能信号（高有效）
    .ad_data(ad_data),   // 10位ADC输入（AM信号）
    
    .demod_out(demod_out), // 解调输出（基带信号）
    .ma(ma),        // 调制度（0-100，表示0% ~ 100%）
    .freq(freq)       // 调制频率（单位kHz，1~5）
);
// 生成8192kHz时钟（周期≈122ns）
initial begin
    clk_8192k = 0;
    forever #61 clk_8192k = ~clk_8192k;  // 半周期=61ns
end

// 读取文件中的数据
reg [9:0] mem [0:8192];
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
    $readmemb("D:/vivado/project/ti/jnu2023d_test/code/sim/AM_signal_2MHz_5kHz.txt", mem);
    file_loaded = 1;     // 文件加载完成标志
    // 读取测试数据文件
    if(file_loaded)begin
        for (i = 0; i < 8192; ) begin
            @(posedge clk_8192k);
                ad_data <= mem[i];
                i <= (i<8191)?i + 1:0;
        end
    end
    // 等待FFT处理完成（根据实际情况调整延时）
    #2000000;
	$finish;
end

endmodule