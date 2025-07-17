module fm_demod (
    input clk_50m,         // 50MHz系统时钟
    input clk_100m,
    input rst_n,           // 异步低电平复位
    input [9:0] ad_data,  // FM输入信号
    input [9:0]rd_data1,
    input [9:0]rd_data2,
    output reg [5:0]rd_addr1,
    output reg [5:0]rd_addr2,

    output [9:0] demod_out,  // 解调输出信号
    output reg [7:0] mf,  // 调频系数(调制指数)
    output reg [15:0] delta_f,     // 最大频偏(Hz)
    output reg [12:0] mod_freq  //调制频率
);


    // =============================================
    // 参数定义
    // =============================================
    // 载波周期对应的采样点数(100MHz/2MHz=50)
    
    // =============================================
    // 1. 正交信号生成（I/Q路）
    // =============================================

    // ROM地址计数器
    always @(posedge clk_100m or negedge rst_n) begin
        if(~rst_n) rd_addr1<=6'd0;
        else
            rd_addr1<=(rd_addr1 == 50-1) ? 0 : rd_addr1 + 1;
    end

    // ROM地址计数器
    always @(posedge clk_100m or negedge rst_n) begin
         if(~rst_n) rd_addr2<=6'd0;
        else
        rd_addr2<=(rd_addr2 == 50-1) ? 0 : rd_addr2 + 1;
    end

    // 当前正交参考信号
    reg signed [10:0] i_ref;  // I路（余弦）
    reg signed [10:0] q_ref; // Q路（正弦）
    reg signed [10:0] ad_data_sign;
    // =============================================
    // 2. 正交下变频（混频）
    // =============================================
    reg  [20:0] i_mixed, q_mixed;
    always @(posedge clk_100m) begin
        i_ref <= {1'b0,rd_data2}-512;
        q_ref <= {1'b0,rd_data1}-512;
        ad_data_sign <= {1'b0,ad_data}-512;
        i_mixed <= ad_data_sign * i_ref;  // I路混频
        q_mixed <= ad_data_sign * q_ref;  // Q路混频
    end
    
    // =============================================
    // 3. 低通滤波（抽取基带信号）
    // =============================================
    // FIR低通滤波器（截止频率设为10kHz）

    wire  [47:0] i_filtered;
    wire [47:0] q_filtered;
fir_compiler_0 u_fir_compiler_01 (
  .aclk(clk_100m),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(i_mixed),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(i_filtered)    // output wire [47 : 0] m_axis_data_tdata
);

fir_compiler_0 u_fir_compiler_02 (
  .aclk(clk_100m),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(q_mixed),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(q_filtered)    // output wire [47 : 0] m_axis_data_tdata
);

    // 滤波后基带信号（20位）
    wire  signed [20:0] i_baseband = i_filtered[36:16];
    wire  signed [20:0] q_baseband = q_filtered[36:16];
    
    // =============================================
    // 4. 正交解调核心算法
    // =============================================
    /*
    正交解调公式：
    demod_out = (I * dQ/dt - Q * dI/dt) / (I² + Q²)
    实际实现简化为：
    demod_out = (I[n]*(Q[n]-Q[n-1]) - Q[n]*(I[n]-I[n-1]))
    demod_out = I(n-1)Q(n)-I(n)Q(n-1) / I2 + Q2
    */
    reg signed [20:0] i_prev;
    reg signed [20:0] q_prev;
    always @(posedge clk_100m) begin
        i_prev <= i_baseband;
        q_prev <= q_baseband;
    end

    // // 微分计算（有符号减法）
    // wire signed [20:0] di = i_signed - i_prev_signed;  // I路微分
    // wire signed [20:0] dq = q_signed - q_prev_signed;  // Q路微分
    
    // wire signed [41:0] numerator = i_signed * dq - q_signed * di;
    
    reg signed [41:0] denominator;
    reg signed [41:0] safe_denominator;
    reg signed [41:0] numerator;
    wire signed [63:0] numerator_filter;
    reg signed [41:0] numerator_t; 
    wire signed [63:0]denominator_filter;
    // 解调输出（有符号结果）
    reg signed [41:0] demod_raw;
    wire  [63:0] demod_raw_filter;

wire signed [41:0]i_q_mult1;
wire signed [41:0]i_q_mult2;
wire signed [41:0]i_i_mult;
wire signed [41:0]q_q_mult;
    mult_gen_0 mult_gen_01 (
  .CLK(clk_100m),  // input wire CLK
  .A(i_baseband),      // input wire [20 : 0] A
  .B(q_prev),      // input wire [20 : 0] B
  .P(i_q_mult1)      // output wire [41 : 0] P
);
mult_gen_0 mult_gen_02 (
  .CLK(clk_100m),  // input wire CLK
  .A(q_baseband),      // input wire [20 : 0] A
  .B(i_prev),      // input wire [20 : 0] B
  .P(i_q_mult2)      // output wire [41 : 0] P
);
mult_gen_0 mult_gen_03 (
  .CLK(clk_100m),  // input wire CLK
  .A(i_prev),      // input wire [20 : 0] A
  .B(i_prev),      // input wire [20 : 0] B
  .P(i_i_mult)      // output wire [41 : 0] P
);
mult_gen_0 mult_gen_04 (
  .CLK(clk_100m),  // input wire CLK
  .A(q_prev),      // input wire [20 : 0] A
  .B(q_prev),      // input wire [20 : 0] B
  .P(q_q_mult)      // output wire [41 : 0] P
);

    always @(posedge clk_100m) begin
        // 分子计算 (I*dQ - Q*dI)
        numerator_t<= i_q_mult1 - i_q_mult2;
        numerator<=(numerator_t == 0)?numerator:numerator_t;
        // 分母计算 (I² + Q²)
        denominator <= i_i_mult + q_q_mult;
    end

wire signed [95:0] demod_raw_t;


// fir_compiler_1 fir_compiler_12 (
//   .aclk(clk_100m),                              // input wire aclk
//   .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
//   .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
//   .s_axis_data_tdata(denominator),    // input wire [47 : 0] s_axis_data_tdata
//   .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
//   .m_axis_data_tdata(denominator_filter)    // output wire [63 : 0] m_axis_data_tdata
// );

// fir_compiler_1 fir_compiler_11 (
//   .aclk(clk_100m),                              // input wire aclk
//   .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
//   .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
//   .s_axis_data_tdata(numerator),    // input wire [47 : 0] s_axis_data_tdata
//   .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
//   .m_axis_data_tdata(numerator_filter)    // output wire [63 : 0] m_axis_data_tdata
// );

    div_gen_0 div_gen_01 (
  .aclk(clk_100m),                                      // input wire aclk
  .s_axis_divisor_tvalid(1),    // input wire s_axis_divisor_tvalid
  .s_axis_divisor_tdata(denominator>>28),      // input wire [47 : 0] s_axis_divisor_tdata
  .s_axis_dividend_tvalid(1),  // input wire s_axis_dividend_tvalid
  .s_axis_dividend_tdata(numerator),    // input wire [47 : 0] s_axis_dividend_tdata
  .m_axis_dout_tvalid(m_axis_dout_tvalid),          // output wire m_axis_dout_tvalid
  .m_axis_dout_tdata(demod_raw_t)            // output wire [95 : 0] m_axis_dout_tdata
);

    always @(posedge clk_100m) begin

        // demod_raw <= (numerator / (denominator>>20));
        demod_raw <= (demod_raw_t[89:48]>>>28);
    end

fir_compiler_1 fir_compiler_13 (
  .aclk(clk_100m),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(demod_raw),    // input wire [47 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(demod_raw_filter)    // output wire [63 : 0] m_axis_data_tdata
);




wire [63:0] demod_raw_tt;
assign demod_raw_tt =demod_raw_filter+(1<<63);
assign demod_out =demod_raw_tt[37:28];



// wire unsigned [9:0] demod_out1;
// assign demod_out1 = demod_raw[94:]


    // // 延迟寄存器用于微分计算
    // reg signed [19:0] i_prev = 0, q_prev = 0;
    // always @(posedge clk_100m) begin
    //     i_prev <= i_baseband;
    //     q_prev <= q_baseband;
    // end
    
    // // 微分计算
    // wire [19:0] di = i_baseband - i_prev;  // I路微分
    // wire [19:0] dq = q_baseband - q_prev;  // Q路微分
    
    // // 分子计算 (I*dQ - Q*dI)
    // wire [20:0] numerator = i_baseband * dq - q_baseband * di;
    
    // // 分母计算 (I² + Q²)，避免除零
    // wire [20:0] denominator = (i_baseband * i_baseband) + (q_baseband * q_baseband);
    // wire [20:0] safe_denominator = (denominator == 0) ? 21'd1 : denominator;
    
    // // 解调输出（简化除法为右移）
    // reg signed [9:0] demod_raw;
    // always @(posedge clk_100m) begin
    //     demod_raw <= numerator / (safe_denominator >>> 12);  // 近似计算
    // end
    
    // =============================================
    // 6. 调频系数和最大频偏测量
    // =============================================
    /*
    调频系数β = Δf/fm
    最大频偏Δf = max(demod_out) * k
    这里k为系统增益系数
    */
    
    // 峰值检测器（测量最大频偏）
    // 假设解调输出是10位无符号(0-1023)，中值512对应零电平
    reg [9:0] peak_positive = 380;  // 正向峰值（大于512）
    reg [9:0] peak_negative = 380;  // 负向峰值（小于512）
    reg [31:0] measure_counter = 0;

    // 中值定义（根据实际系统调整）
    parameter MID_VALUE = 380;

    // 过零检测（针对无符号数据）
    reg [9:0] prev_sample = MID_VALUE;
    reg [15:0] zero_cross_count = 0;
    reg [31:0] sample_count = 0;

    always @(posedge clk_100m) begin
        prev_sample <= demod_out;
        
        // 检测从低于中值到高于中值，或相反
        if ((prev_sample < MID_VALUE && demod_out >= MID_VALUE) || 
            (prev_sample >= MID_VALUE && demod_out < MID_VALUE)) begin
            zero_cross_count <= zero_cross_count + 1;
        end
        
        // 频率测量周期（例如每1ms）
        sample_count <= sample_count + 1;
        if (sample_count == 100_000) begin
            // 调制频率 = 过零次数 / (2 * 时间)
            // 100ms内过零次数 × 5 = 频率（Hz）
            mod_freq <= zero_cross_count * 5 * 100;
            zero_cross_count <= 0;
            sample_count <= 0;
        end
    end

    always @(posedge clk_100m or negedge rst_n) begin
        if (!rst_n) begin
            peak_positive <= MID_VALUE;
            peak_negative <= MID_VALUE;
            measure_counter <= 0;
        end else begin
            // 正向峰值检测（信号高于中值）
            if (demod_out > MID_VALUE && demod_out > peak_positive)
                peak_positive <= demod_out;
            
            // 负向峰值检测（信号低于中值）
            if (demod_out < MID_VALUE && demod_out < peak_negative)
                peak_negative <= demod_out;
            
            // 每1ms更新一次参数
            measure_counter <= measure_counter + 1;
            if (measure_counter == 100_000) begin
                measure_counter <= 0;
                
                // 计算最大频偏（单位Hz，假设比例系数k=100Hz/LSB）
                // 正向偏移量 = peak_positive - MID_VALUE
                // 负向偏移量 = MID_VALUE - peak_negative
                delta_f <= (peak_positive - MID_VALUE > MID_VALUE - peak_negative) ? 
                            (peak_positive - MID_VALUE) * 1 : 
                            (MID_VALUE - peak_negative) * 1;
                
                // 计算调频系数β = Δf/fm
                if (mod_freq > 0) // mod_freq需通过过零检测获得
                    mf <= delta_f / mod_freq;
                
                // 重置峰值检测器
                peak_positive <= MID_VALUE;
                peak_negative <= MID_VALUE;
            end
        end
    end



endmodule