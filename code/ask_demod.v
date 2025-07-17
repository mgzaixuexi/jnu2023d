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
reg [1:0] edge_state = 0;
reg [15:0] sample_cnt = 0;

always @(posedge clk_30M or negedge rst_n) begin
    if (!rst_n) begin
        edge_state <= 0;
        sample_cnt <= 0;
        rise_pos <= 0;
        fall_pos <= 0;
        rate_valid <= 0;
    end else if (en) begin
        sample_cnt <= sample_cnt + 1;
        
        // 上升沿检测
        if (filtered_reg > THRESHOLD && prev_filtered <= THRESHOLD) begin
            rise_pos <= sample_cnt;
            if (edge_state == 1) begin // 已完成高电平测量
                edge_state <= 2;
                half_period <= rise_pos - fall_pos;
            end
        end
        
        // 下降沿检测  
        if (filtered_reg <= THRESHOLD && prev_filtered > THRESHOLD) begin
            fall_pos <= sample_cnt;
            if (edge_state == 0) begin // 开始新测量
                edge_state <= 1;
            end
        end
        
        // 码率判定
        if (half_period > 0) begin
            if (half_period >= 240 && half_period <= 260) begin      // 500/2 ±4%
                detected_rate <= 6;
                rate_valid <= 1;
            end 
            else if (half_period >= 180 && half_period <= 195) begin // 375/2 ±4%
                detected_rate <= 8;
                rate_valid <= 1;
            end
            else if (half_period >= 140 && half_period <= 160) begin // 300/2 ±4%
                detected_rate <= 10;
                rate_valid <= 1;
            end
            half_period <= 0; // 清除测量值
        end
    end
end

// 保持您原有的解调逻辑（增加码率动态选择）
reg [9:0] samples_per_bit;
always @(*) begin
    case(detected_rate)
        6:  samples_per_bit = 500;
        8:  samples_per_bit = 375; 
        10: samples_per_bit = 300;
        default: samples_per_bit = 500;
    endcase
end

reg [9:0] bit_sample_cnt = 0;   // 比特内采样计数器
reg [9:0] high_sample_cnt = 0;  // 高电平采样计数
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

assign bit_rate_kbps = (rate_valid) ? detected_rate : 4'd6;
assign freq = 8'd2;

endmodule