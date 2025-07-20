module fm_demod (
    input clk_32m,
    input rst_n,           // 异步低电平复位
    input [9:0] ad_data,  // FM输入信号
    input mode,
    
    output [9:0] demod_out,  // 解调输出信号
    output reg [7:0] mf,  // 调频系数(调制指数)
    output reg [15:0] delta_f,     // 最大频偏(Hz)
    output reg [12:0] mod_freq  //调制频率
);

reg signed [10:0] ad_data_sign;
reg signed [10:0] ad_data_sign_t1;
reg signed [10:0] ad_data_sign_t2;
reg signed [10:0] ad_data_sign_t3;
reg signed [10:0] ad_data_sign_t4;
wire signed [21:0] ad_mult;
wire signed [39:0] ad_mult_filter;
wire signed [21:0] ad_mult_filter_f;
wire signed [21:0] ad_mult_filter_small;
wire signed [10:0]demod_out_1;
wire signed [10:0]demod_out_sign;
wire [39:0]ad_mult_filter_out; 

assign ad_mult_filter_small = ad_mult_filter_out[37:16];
assign demod_out_1 = -(ad_mult_filter_small[21:10]); 
assign demod_out_sign = demod_out_1*5;     //FSK的时候会超范围 需要修改
assign demod_out = demod_out_sign+512;     //FSK的时候会超范围 需要修改
 

always @(posedge clk_32m) begin
    if(~rst_n)ad_data_sign<=0;
    else
    ad_data_sign<={1'd0,ad_data}-512;
    ad_data_sign_t1<=ad_data_sign;
    ad_data_sign_t2<=ad_data_sign_t1;
    ad_data_sign_t3<=ad_data_sign_t2;
    ad_data_sign_t4<=ad_data_sign_t3;
  
end
assign ad_mult =ad_data_sign*ad_data_sign_t4;


assign ad_mult_filter_f=ad_mult_filter[37:16];



// mult_gen_1 mult_gen_11 (
//   .CLK(clk_32m),  // input wire CLK
//   .A(ad_data_sign),      // input wire [10 : 0] A
//   .B(ad_data_sign_t4),      // input wire [10 : 0] B
//   .P(ad_mult)      // output wire [21 : 0] P
// );

fir_compiler_0 u_fir_compiler_03 (
  .aclk(clk_32m),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(ad_mult),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(ad_mult_filter)    // output wire [39 : 0] m_axis_data_tdata
);

fir_compiler_0 u_fir_compiler_04 (
  .aclk(clk_32m),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(ad_mult_filter_f),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(ad_mult_filter_out)    // output wire [39 : 0] m_axis_data_tdata
);


     wire [15:0] F;       // 调制信号频率(Hz)

    // 线性拟合参数 (根据实际校准数据调整)
    parameter a2 = 32'd1000;   // 斜率系数(Hz/count)
    parameter b2 = 32'd0;      // 截距(Hz)

    // 信号峰峰值计算
    reg signed [10:0] max_val;
    reg signed [10:0]vpp_t;
    reg [9:0] vpp;            // 峰峰值(count)
    
    // 滑动窗口控制
    reg [15:0] sample_counter;
    parameter WINDOW_SIZE = 16'd1000; // 计算窗口大小
    
    always @(posedge clk_32m or posedge rst_n) begin
        if (rst_n) begin
            max_val <= 10'b0;
            vpp <= 10'b0;
            sample_counter <= 16'b0;
        end else begin
            // 更新最大值和最小值
            if (sample_counter == WINDOW_SIZE) begin
                // 定期重置max/min值
                max_val <= demod_out_sign;
                sample_counter <= 16'b0;
            end else begin
                if (demod_out_sign > max_val) max_val <= demod_out_sign;
                sample_counter <= sample_counter + 1;
            end
            
            // 计算峰峰值
            vpp_t <= 2*max_val;
            vpp <= vpp_t[9:0];
            
        end
    end

    // 最大频偏估计
    always @(posedge clk_32m or posedge rst_n) begin
        if (rst_n) begin
            delta_f <= 16'b0;
            mf <= 16'b0;
        end else begin
            // Δfmax = a2 * Vpp + b2
            // 使用32位计算防止溢出
            delta_f <= (a2 * vpp + b2);
            
            // mf = Δfmax / F
            if (F != 0) mf <= delta_f / F;
            else mf <= 16'b0;  // 避免除以零
        end
    end


endmodule