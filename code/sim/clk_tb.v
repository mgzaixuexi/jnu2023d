`timescale 1ns / 1ps

module clk_div_2m_tb();

reg  clk_50m;    // 50MHz时钟
reg  rst_n;      // 复位信号
wire clk_2m;     // 2MHz输出

reg clk_50m;
reg rst_n;


//初始化系统时钟、全局复位
 initial begin
 clk_50m = 1'b1;
 rst_n <= 1'b0;
 #20
 rst_n <= 1'b1;
 end

 //clk_50m:模拟系统时钟，每10ns电平翻转一次，周期为20ns，频率为50MHz
 always #10 clk_50m = ~clk_50m;

// 实例化被测模块
clk_div_2m uut (
    .clk_32m(clk_50m),
    .rst_n(rst_n),
    .clk_2m(clk_2m)
);




endmodule