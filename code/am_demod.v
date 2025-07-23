module am_demod(
    input         clk,       // 系统时钟（8192kHz）
    input         rst_n,     // 异步复位（低有效）
    input         en,        // 使能信号（高有效）
    input  [9:0]  ad_data,   // 10位ADC输入（AM信号）
    
    output [9:0]  demod_out, // 解调输出（基带信号）
    output [3:0]  ma,        // 调制度（0-10）
    output [7:0]  freq       // 调制频率（单位kHz，1~5）
);
//调制深度通常为已调波的最大振幅与最小振幅之差对载波最大振幅与最小振幅之和的比。就是生成AM波包络的最大值与最小值之差除以最大值与最小值之和。
//挪到中间，并进行全波整流,
// 中间信号
reg signed [15:0] am_centered; // 中心偏移后的信号（ad_data - 512）
reg [15:0] am_abs;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        am_centered <= 16'sd0;
        am_abs <= 16'sd0;
    end else begin
        // 1. 将10位无符号ADC数据转换为16位有符号数（减去512）
        am_centered <= {6'b0, ad_data} - 16'd512;
        
        // 2. 全波整流（取绝对值）
        if (am_centered < 0) begin
            am_abs <= -am_centered; // 负值取反
        end else begin
            am_abs <= am_centered;  // 正值保持不变
        end
    end
end

wire [39:0] demolate_signal;
wire s_axis_dalta_tready;
wire m_axis_data_tvalid;

fir_compiler_1 u_fir_compiler_0 (             //低通滤波
  .aclk(clk),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_dalta_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(am_abs),    // input wire [15 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(demolate_signal)    // output wire [39 : 0] m_axis_data_tdata
);
assign demod_out = demolate_signal[30:21]+10'd512;  //截位

// 计算调制系数ma。最大值检测相关信号，后面把ma_calc <= (min_am_abs * 10) / max_am_abs;的除法换成ip核
reg [15:0] am_abs_history [0:2]; // 存储连续三个时刻的am_abs值
reg [15:0] max_of_three;         // 三个时刻中的最大值
reg [9:0] min_am_abs = 1023;     // am_abs的最小值
reg [9:0] max_am_abs = 0;   // am_abs的最大值
reg [31:0] ma_calc = 0;        // 调制度计算中间值
reg [3:0] ma_reg = 0;          // 调制度寄存器
reg [19:0] sample_counter = 0; // 采样计数器

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        min_am_abs <= 1023;
        max_am_abs <= 0;
        ma_reg <= 0;
        sample_counter <= 0;
    end else begin
        // 3. 更新历史记录（移位寄存器）
        am_abs_history[2] <= am_abs_history[1];
        am_abs_history[1] <= am_abs_history[0];
        am_abs_history[0] <= am_abs;
        
        //4. 计算三个连续时刻中的最大值
        max_of_three = (am_abs_history[0] > am_abs_history[1]) ? 
                      ((am_abs_history[0] > am_abs_history[2]) ? am_abs_history[0] : am_abs_history[2]) :
                      ((am_abs_history[1] > am_abs_history[2]) ? am_abs_history[1] : am_abs_history[2]);
        //max_of_three = (am_abs_history[0] > am_abs_history[1]) ? am_abs_history[0] : am_abs_history[1];                
        // 5. 更新am_abs最小值
        if (max_of_three < min_am_abs) begin
            min_am_abs <= max_of_three;
        end
        
        // 4. 更新am_abs最大值
        if (max_of_three > max_am_abs) begin
            max_am_abs <= max_of_three;
        end
        
        // 5. 周期性计算调制度（每4096个采样点计算一次）尝试过16382但好像也没啥用
        sample_counter <= sample_counter + 1;
        if (sample_counter == 19'd4095) begin
            sample_counter <= 0;
            
            // 计算ma = 10 * min_am_abs / max_am_abs
            if (max_am_abs+min_am_abs != 0) begin
                ma_calc <= 10*(max_am_abs-min_am_abs)/(max_am_abs+min_am_abs);
                
                // 限制ma在0-10范围内
                if (ma_calc > 10) begin
                    ma_reg <= 10;
                end else begin
                    ma_reg <= ma_calc[3:0];
                end
            end
            
            // 重置
            min_am_abs <= 1023;
            max_am_abs <= 0;
        end
    end
end


endmodule
//这个是完成的AM解调模块，现在要实现调制系数的计算功能：
//一、修改min_am_abs和max_am_abs的更新规则
//二、变为设置三个变量记录am_abs连续三个时刻的值，选择其中最大时刻的变量跟min_am_abs和max_am_abs对比。