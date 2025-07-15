module am_demod(
    input         clk,       // 系统时钟（8192kHz）
    input         rst_n,     // 异步复位（低有效）
    input         en,        // 使能信号（高有效）
    input  [9:0]  ad_data,   // 10位ADC输入（AM信号）
    
    output [9:0]  demod_out, // 解调输出（基带信号）
    output [7:0]  ma,        // 调制度（0-100，表示0% ~ 100%）
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

fir_compiler_0 u_fir_compiler_0 (             //低通滤波
  .aclk(clk),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_dalta_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(am_abs),    // input wire [15 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(demolate_signal)    // output wire [39 : 0] m_axis_data_tdata
);
assign demod_out = demolate_signal[24:15]+10'd512;  //截位


endmodule