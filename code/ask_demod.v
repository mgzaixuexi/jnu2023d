module ask_demod(
    input         clk,           // 系统时钟（8192kHz）
    input         clk_30M,       // 抽样时钟30MHz  
    input         rst_n,
    input         en,
    input  [9:0]  ad_data,
    
    output reg    bit_out,
    output reg    bit_valid,
    output [3:0]  bit_rate_kbps,
    output [7:0]  freq
);

// 保持您原有的参数和信号声明
parameter THRESHOLD = 16'd8000;
reg signed [15:0] centered;
reg [15:0] rectified;
wire [39:0] filtered_signal;
wire s_axis_data_tready;
wire m_axis_data_tvalid;
reg [15:0] filtered_reg;
reg [15:0] prev_filtered;

// 新增码率检测信号
reg [15:0] rise_pos = 0;      // 上升沿位置
reg [15:0] fall_pos = 0;      // 下降沿位置 
reg [15:0] half_period = 0;   // 半周期测量值
reg [3:0]  detected_rate = 6; // 检测到的码率
reg        rate_valid = 0;    // 码率有效标志

// 保持您原有的信号处理流水线
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        centered <= 0;
        rectified <= 0;
        filtered_reg <= 0;
        prev_filtered <= 0;
    end else begin
        centered <= {6'b0, ad_data} - 16'd512;
        rectified <= (centered < 0) ? -centered : centered;
        if (m_axis_data_tvalid) begin
            prev_filtered <= filtered_reg;
            filtered_reg <= filtered_signal[30:15];
        end
    end
end

// 保持您原有的FIR滤波器
fir_compiler_0 u_fir_filter (
  .aclk(clk),
  .s_axis_data_tvalid(1'b1),
  .s_axis_data_tready(s_axis_data_tready),
  .s_axis_data_tdata(rectified),
  .m_axis_data_tvalid(m_axis_data_tvalid),
  .m_axis_data_tdata(filtered_signal)
);

// 改进的码率检测逻辑（在30MHz时钟域）
reg [15:0] edge_counter = 0;      // 边沿间隔计数器
reg [15:0] high_duration = 0;     // 高电平持续时间测量值
reg [3:0]  detected_rate = 6;     // 检测到的码率 (默认6kbps)
reg        rate_valid = 0;        // 码率有效标志
reg        last_state = 0;        // 前一个状态记录

always @(posedge clk_30M or negedge rst_n) begin
    if (!rst_n) begin
        edge_counter <= 0;
        high_duration <= 0;
        detected_rate <= 6;
        rate_valid <= 0;
        last_state <= 0;
    end else if (en) begin
        // 更新前一个状态
        last_state <= (filtered_reg > THRESHOLD);
        
        // 状态变化检测
        if ((filtered_reg > THRESHOLD) && !last_state) begin
            // 上升沿检测
            edge_counter <= 0; // 开始新的计数
        end else if ((filtered_reg <= THRESHOLD) && last_state) begin
            // 下降沿检测
            high_duration <= edge_counter; // 记录高电平持续时间
            edge_counter <= 0;
            
            // 根据高电平持续时间判断码率
            if (high_duration >= 2800 && high_duration <= 3200) begin      // 10kbps ±6.7%
                detected_rate <= 10;
                rate_valid <= 1;
            end 
            else if (high_duration >= 3500 && high_duration <= 4000) begin // 8kbps ±6.7%
                detected_rate <= 8;
                rate_valid <= 1;
            end
            else if (high_duration >= 4700 && high_duration <= 5300) begin // 6kbps ±6%
                detected_rate <= 6;
                rate_valid <= 1;
            end
            else if (high_duration >= 5600 && high_duration <= 6400) begin      // 10kbps ±6.7%
                detected_rate <= 10;
                rate_valid <= 1;
            end 
            else if (high_duration >= 7000 && high_duration <= 8000) begin // 8kbps ±6.7%
                detected_rate <= 8;
                rate_valid <= 1;
            end
            else if (high_duration >= 9400 && high_duration <= 10600) begin // 6kbps ±6%
                detected_rate <= 6;
                rate_valid <= 1;
            end

        end else begin
            // 非边沿时刻，计数器递增
            edge_counter <= edge_counter + 1;
        end
    end
end
// 码率同步检测
reg [3:0] last_detected_rate = 6;
wire rate_changed = (detected_rate != last_detected_rate) && rate_valid;

// 解调判决逻辑（增加码率同步）
reg [12:0] samples_per_bit;  // 扩大位宽以容纳更大的计数值
always @(*) begin
    case(detected_rate)
        6:  samples_per_bit = 5000;  // 6kbps @30MHz: 30,000/6 = 5000
        8:  samples_per_bit = 3750;  // 8kbps @30MHz: 30,000/8 = 3750
        10: samples_per_bit = 3000;  // 10kbps @30MHz: 30,000/10 = 3000
        default: samples_per_bit = 5000;
    endcase
end

reg [12:0] bit_sample_cnt = 0;   // 比特内采样计数器
reg [12:0] high_sample_cnt = 0;  // 高电平采样计数
reg sync_pulse = 0;              // 同步脉冲信号

// 抽样判决（使用30MHz时钟）
always @(posedge clk_30M or negedge rst_n) begin
    if (!rst_n) begin
        bit_out <= 0;
        bit_valid <= 0;
        bit_sample_cnt <= 0;
        high_sample_cnt <= 0;
        last_detected_rate <= 6;
        sync_pulse <= 0;
    end else if (en) begin
        // 默认值
        bit_valid <= 0;
        sync_pulse <= 0;
        
        // 检测码率变化
        last_detected_rate <= detected_rate;
        
        // 码率变化时产生同步脉冲并重置计数器
        if (rate_changed) begin
            sync_pulse <= 1;
            bit_sample_cnt <= 0;
            high_sample_cnt <= 0;
        end 
        // 正常计数
        else begin
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
        end
    end else begin
        // en=0时的闲置状态
        bit_valid <= 0;
        bit_sample_cnt <= 0;
        high_sample_cnt <= 0;
        sync_pulse <= 0;
    end
end

//assign bit_rate_kbps = (rate_valid) ? detected_rate : 4'd6;
assign freq = 8'd2;

endmodule