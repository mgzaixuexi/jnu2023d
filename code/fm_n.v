module fm_demod_n (
    input clk_8192k,         // 50MHz系统时钟
    input clk_81920k,
    input clk_50k,
    input clk_8m,
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

reg signed [10:0] ad_data_sign;
reg signed [10:0] ad_data_sign_t;
wire signed [21:0] ad_mult;
wire signed [39:0] ad_mult_filter;
always @(posedge clk_8m) begin
    if(~rst_n)ad_data_sign<=0;
    else
    ad_data_sign<={1'd0,ad_data}-512;
    ad_data_sign_t<=ad_data_sign;
    
end
assign ad_mult =ad_data_sign*ad_data_sign_t;

wire [20:0]ad_mult_filter_out; 
assign ad_mult_filter_out=ad_mult_filter[36:16];
// mult_gen_1 mult_gen_11 (
//   .CLK(clk_8m),  // input wire CLK
//   .A(ad_data_sign),      // input wire [10 : 0] A
//   .B(ad_data_sign_t),      // input wire [10 : 0] B
//   .P(ad_mult)      // output wire [21 : 0] P
// );

fir_compiler_2 u_fir_compiler_03 (
  .aclk(clk_50k),                              // input wire aclk
  .s_axis_data_tvalid(1),  // input wire s_axis_data_tvalid
  .s_axis_data_tready(s_axis_data_tready),  // output wire s_axis_data_tready
  .s_axis_data_tdata(ad_mult),    // input wire [23 : 0] s_axis_data_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata(ad_mult_filter)    // output wire [39 : 0] m_axis_data_tdata
);


endmodule