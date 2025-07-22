module am_ask_demod(
    input         clk,           // 系统时钟（8192kHz）
    input         clk_30M,       // 抽样时钟30MHz  
    input         rst_n,
    input  [9:0]  ad_data,       // 10位ADC输入
    
    output        bit_out,       // ASK解调输出
    output        bit_valid,     // ASK解调有效信号
    output [3:0]  bit_rate_kbps, // ASK码率
    output [9:0]  demod_out,     // AM解调输出
    output [3:0]  ma,            // AM调制度
    output [7:0]  freq,          // 载波频率
    output        is_ask         // 信号类型指示(1:ASK, 0:AM)
);
// 信号检测参数
parameter SAMPLE_COUNT = 10000;  // 采样点数
parameter ASK_THRESHOLD = 2000;  // 判断为ASK信号的零值点阈值
parameter LOW_LEVEL_THRESHOLD = 10; // 判断为低电平的阈值

// 信号检测相关寄存器
reg [15:0] sample_counter = 0;
reg [15:0] zero_count = 0;
reg signal_type = 0;  // 0:AM, 1:ASK
reg type_valid = 0;

// 模块使能信号
wire ask_en = (signal_type && type_valid);
wire am_en = (!signal_type && type_valid);

// 信号类型检测
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sample_counter <= 0;
        zero_count <= 0;
        signal_type <= 0;
        type_valid <= 0;
    end else begin
        // 检测输入信号是否为低电平（接近0）
        if (ad_data < LOW_LEVEL_THRESHOLD) begin
            zero_count <= zero_count + 1;
        end
        
        // 计数器递增
        if (sample_counter < SAMPLE_COUNT - 1) begin
            sample_counter <= sample_counter + 1;
        end else begin
            // 采样完成，进行判决
            sample_counter <= 0;
            
            // 如果零值点超过阈值，判定为ASK信号
            if (zero_count > ASK_THRESHOLD) begin
                signal_type <= 1;  // ASK信号
            end else begin
                signal_type <= 0;  // AM信号
            end
            
            type_valid <= 1;
            zero_count <= 0;
        end
    end
end

// 实例化ASK解调模块
ask_demod u_ask_demod(
    .clk(clk),
    .clk_30M(clk_30M),
    .rst_n(rst_n),
    .en(ask_en),
    .ad_data(ad_data),
    .bit_out(bit_out),
    .bit_valid(bit_valid),
    .bit_rate_kbps(bit_rate_kbps),
    .freq(freq)
);

// 实例化AM解调模块
am_demod u_am_demod(
    .clk(clk),
    .rst_n(rst_n),
    .en(am_en),
    .ad_data(ad_data),
    .demod_out(demod_out),
    .ma(ma),
    .freq(freq)
);

// 输出信号类型指示
assign is_ask = signal_type;

endmodule