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
    wire clk_32m;
    wire clk_8m;
      clk_wiz_0 instance_name
   (
    // Clock out ports
    .clk_out1(clk_32m),     // output clk_out1
    .clk_out2(clk_8m),     // output clk_out2
    // Status and control signals
    .reset(~rst_n), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_50m));      // input clk_in1

    // 时钟生成
    initial begin
        clk_50m = 0;
        forever #(CLK_PERIOD/2) clk_50m = ~clk_50m;

    end

    initial begin
        clk_50k = 0;
        forever #(2000/2) clk_50k = ~clk_50k;

    end
// 时钟生成
    initial begin
        clk_100m = 0;
        forever #(CLK_PERIOD/4) clk_100m = ~clk_100m;
    end
    // // 时钟生成
    // initial begin
    //     clk_32m = 0;
    //     forever #(15) clk_32m = ~clk_32m;
    // end

reg clk_8192k;
reg clk_81920k;
reg clk_40960k;
reg clk_320k;
    // 实例化被测设�?
    fm_demod_n u_fm_demod (
    . clk_32m(clk_32m),
    . rst_n(rst_n),           // 异步低电平复�?
    .  ad_data(ad_data),  // FM输入信号

    .  demod_out(demod_out),  // 解调输出信号
    . mf(mf),  // 调频系数(调制指数)
    . delta_f(delta_f),     // �?大频�?(Hz)
    .  mod_freq(mod_freq)  //调制频率
    );

    // 读取文件中的数据

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

reg [5:0]clk_cnt;
always @(posedge clk_32m) begin
    if(~rst_n) 
        begin
            clk_320k<=0;
            clk_cnt<=0;
        end
    else 
        begin
            clk_cnt<=clk_cnt+1;
            if(clk_cnt==50-1)
                begin
                    clk_320k<=~clk_320k;
                    clk_cnt<=0;
                end

        end
end
reg [9:0] mem [0:320000];
    // 复位生成
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    // 读取数据文件（注意文件格式）
    $readmemb("E:/diansai/jnu2023d/code/sim/fm_modulation_binary_data.txt", mem); //读取FM数据
    // $readmemb("E:/diansai/jnu2023d/code/sim/fsk_10bit_binary.txt", mem); //读取FSK数据
    file_loaded = 1;     // 文件加载完成标志
    // 读取测试数据文件
    if(file_loaded)begin
        for (i = 0; i <= 320000-1; ) begin
            @(posedge clk_32m);
                ad_data <= mem[i];
                if(i==320000-1) i<=0;else i<= i+1;
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