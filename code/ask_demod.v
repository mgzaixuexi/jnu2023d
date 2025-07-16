module ask_demod(
    input         clk,           // 系统时钟（8192kHz）
    input         clk_30M,       // 抽样时钟30MHz
    input         rst_n,         // 异步复位（低有效）
    input         en,            // 使能信号（高有效）
    input  [9:0]  ad_data,       // 10位ADC输入（ASK信号）
    
    output reg    bit_out,       // 解调输出的比特
    output reg    bit_valid,     // 比特有效信号
    output [3:0]  bit_rate_kbps, // 检测到的码率（kbps）
    output [7:0]  freq           // 载波频率（MHz）
);

// 参数定义
parameter THRESHOLD = 16'd8000;  // 固定判决门限
parameter BIT_RATE = 4'd6;      // 测试码率为6kbps

// 中间信号
reg signed [15:0] centered;      // 中心偏移后的信号
reg [15:0] rectified;            // 整流后信号

// FIR滤波器信号
wire [39:0] filtered_signal;
wire s_axis_data_tready;
wire m_axis_data_tvalid;

// 抽样判决相关信号
reg [15:0] filtered_reg;         // 滤波后信号寄存器
reg [9:0] sample_cnt = 0;       // 抽样计数器
reg [9:0] samples_per_bit;      // 每比特对应采样点数
reg [9:0] bit_sample_cnt = 0;   // 比特内采样计数器
reg [9:0] high_sample_cnt = 0;  // 高电平采样计数

// 中心偏移和整流
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        centered <= 0;
        rectified <= 0;
    end else begin
        // 中心偏移（ad_data - 512）
        centered <= {6'b0, ad_data} - 16'd512;
        
        // 全波整流
        rectified <= (centered < 0) ? -centered : centered;
    end
end

// FIR低通滤波器实例化
fir_compiler_0 u_fir_filter (
  .aclk(clk),                        // input wire aclk
  .s_axis_data_tvalid(1'b1),         // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(rectified),     // input wire [15 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(filtered_signal)    // output wire [39 : 0] m_axis_data_tdata
);

// 滤波后信号截位处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        filtered_reg <= 0;
    end else if (m_axis_data_tvalid) begin
        filtered_reg <= filtered_signal[30:15];
    end
end

// 设置每比特采样点数（根据固定码率）
always @(*) begin
    case(BIT_RATE)
        4'd6:  samples_per_bit = 10'd500;  // 30MHz/6kbps=5000
        4'd8:  samples_per_bit = 10'd375;  // 30MHz/8kbps=3750
        4'd10: samples_per_bit = 10'd300; // 30MHz/10kbps=3000
        default: samples_per_bit = 10'd300;
    endcase
end

// 抽样判决（使用30MHz时钟）
always @(posedge clk_30M or negedge rst_n) begin
    if (!rst_n) begin
        bit_out <= 0;
        bit_valid <= 0;
        bit_sample_cnt <= 0;
        high_sample_cnt <= 0;
        samples_per_bit <= 10'd300;
    end else if (en) begin
        bit_valid <= 0;
        
        // 更新比特内采样计数器
        bit_sample_cnt <= bit_sample_cnt + 1;
        
        // 统计高电平采样点数
        if (filtered_reg > THRESHOLD) begin
            high_sample_cnt <= high_sample_cnt + 1;
        end
        
        // 比特周期结束判断
        if (bit_sample_cnt == samples_per_bit - 1) begin
            // 判决输出：高电平采样超过50%则输出1，否则输出0
            bit_out <= (high_sample_cnt > (samples_per_bit >> 1));
            bit_valid <= 1;
            
            // 重置计数器
            bit_sample_cnt <= 0;
            high_sample_cnt <= 0;
        end
    end else begin
        // en=0时的闲置状态
        bit_valid <= 0;
        bit_sample_cnt <= 0;
        high_sample_cnt <= 0;
    end
end

// 输出赋值
assign bit_rate_kbps = BIT_RATE;
assign freq = 8'd2; // 固定2MHz载波

endmodule