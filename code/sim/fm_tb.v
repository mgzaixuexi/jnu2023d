`timescale 1ns / 1ps

module fm_demod_tb;

    // 参数定义
    parameter CLK_PERIOD = 20;      // 50MHz时钟周期(20ns)
    parameter SAMPLE_RATE = 50_000_000; // 50MHz采样�?
    parameter CARRIER_FREQ = 2_000_000; // 载频2MHz
    parameter MOD_FREQ = 5_000;     // 调制频率5kHz
    parameter MOD_INDEX = 5;        // 调制指数(β=3)


    // 信号定义
    reg [9:0] fm_input;            // 10位无符号FM输入
    wire [9:0] demod_out;          // 10位解调输�?
    reg clk_50m;         // 50MHz系统时钟
    reg clk_100m;
    reg rst_n;           // 异步低电平复�?
    reg [9:0] ad_data;  // FM输入信号
    wire [9:0]rd_data1;
    wire [9:0]rd_data2;
    wire [5:0]rd_addr1;
    wire [5:0]rd_addr2;

    wire  [3:0] mf;  // 调频系数(调制指数)
    wire [15:0] delta_f;     // �?大频�?(Hz)
    wire  [18:0] mod_freq;  //调制频率

    // 测试变量
    real carrier_phase = 0;
    real mod_phase = 0;
    integer file_out;
    reg clk_50k;
    reg clk_8m;
    // 时钟生成
    initial begin
        clk_50m = 0;
        forever #(CLK_PERIOD/2) clk_50m = ~clk_50m;

    end

    initial begin
        clk_50k = 0;
        forever #(20000/2) clk_50k = ~clk_50k;

    end
// 时钟生成
    initial begin
        clk_100m = 0;
        forever #(CLK_PERIOD/4) clk_100m = ~clk_100m;
    end
    // 时钟生成
    initial begin
        clk_8m = 0;
        forever #(62) clk_8m = ~clk_8m;
    end
//ROM存储波形
rom_50x10b u_rom_50x10b1 (
    .clka     (clk_100m),  // input wire clka
    .addra    (rd_addr1 ),  // input wire [5 : 0] addra
    .douta    (rd_data1 )   // output wire [9 : 0] douta
    );

    //ROM存储波形
rom_50x10b1 u_rom_50x10b2 (
    .clka     (clk_100m),  // input wire clka
    .addra    (rd_addr2 ),  // input wire [5 : 0] addra
    .douta    (rd_data2 )   // output wire [9 : 0] douta
    );
reg clk_8192k;
reg clk_81920k;
reg clk_40960k;
    // 实例化被测设�?
    fm_demod_n u_fm_demod (
    . clk_8192k(clk_8192k),         // 50MHz系统时钟
    . clk_81920k(clk_81920k),
    . clk_8m(clk_8m),
    . clk_50k(clk_50k),
    . rst_n(rst_n),           // 异步低电平复�?
    .  ad_data(ad_data),  // FM输入信号
    . rd_data1(rd_data1),
    .rd_data2(rd_data2),
    . rd_addr1(rd_addr1),
    . rd_addr2(rd_addr2),

    .  demod_out(demod_out),  // 解调输出信号
    . mf(mf),  // 调频系数(调制指数)
    . delta_f(delta_f),     // �?大频�?(Hz)
    .  mod_freq(mod_freq)  //调制频率
    );

    // 读取文件中的数据
reg [9:0] mem [0:8192];
integer i;
reg file_loaded = 0;     // 文件加载完成标志

// // 生成81920kHz时钟（周期≈12ns�?
initial begin
    clk_8192k = 0;
    forever #61 clk_8192k = ~clk_8192k;  // 半周�?=61ns
end

initial begin
    clk_81920k = 0;
    forever #6 clk_81920k = ~clk_81920k;  // 半周�?=61ns
end

initial begin
    clk_40960k = 0;
    forever #12 clk_40960k = ~clk_40960k;  // 半周�?=61ns
end
    // 复位生成
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    // 读取数据文件（注意文件格式）
    $readmemb("E:/diansai/jnu2023d/code/sim/FM_signal_2MHz_5kHz.txt", mem);
    file_loaded = 1;     // 文件加载完成标志
    // 读取测试数据文件
    if(file_loaded)begin
        for (i = 0; i < 8192-1; ) begin
            @(posedge clk_81920k);
                ad_data <= mem[i];
                if(i==8191-1) i<=0;else i<= i+1;
        end
    end

    end

    // // FM信号生成
    // always @(posedge clk_50m or negedge rst_n) begin
    //     if (!rst_n) begin
    //         carrier_phase <= 0;
    //         mod_phase <= 0;
    //         fm_input <= 512;  // 复位时输出中�?
    //     end else begin
    //         // 更新调制信号相位
    //         mod_phase <= mod_phase + 2.0 * 3.1415926 * MOD_FREQ / SAMPLE_RATE;
            
    //         // 更新载波相位（带频率调制�?
    //         carrier_phase <= carrier_phase + 
    //             2.0 * 3.1415926 * CARRIER_FREQ / SAMPLE_RATE + 
    //             MOD_INDEX * $sin(mod_phase);
            
    //         // 生成10位无符号输出�?512为零点）
    //         fm_input <= 512 + $floor(511 * $sin(carrier_phase));
            
    //         // 确保输出�?0-1023范围�?
    //         if (fm_input > 1023) fm_input <= 1023;
    //         if (fm_input < 0) fm_input <= 0;
    //     end
    // end


    // 测试控制和结�?
    initial begin
        #1000; // 等待复位
        
        // 打印测试信息
        $display("Starting FM demodulator test:");
        $display("Carrier: 2MHz, Mod Frequency: 5kHz, Mod Index: 3");
        
        // 运行足够长时间以捕获多个调制周期
        #(20 * 1_000_000); // 20ms (100个调制周�?)
        
        // 分析结果
        $display("Test completed");
        $display("Expected demod output range: ~%d to ~%d", 
                 512 - (MOD_INDEX * 511 * MOD_FREQ / (CARRIER_FREQ/10)), 
                 512 + (MOD_INDEX * 511 * MOD_FREQ / (CARRIER_FREQ/10)));
        
     
    end



endmodule