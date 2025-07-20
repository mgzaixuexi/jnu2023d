//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/13 14:00:00
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
    input          sys_clk,        // 系统时钟
    input          sys_rst_n,      // 系统复位
    input  [2:0]   key,           // 按键输入 [0:启动, 1:模式选择, 2:保留]
    
    // ADC接口
    input  [9:0]   ad_data,       // ADC数据输入(10位)
    input          ad_otr,        // ADC输入电压超过量程标志
	input		   ad_clk,
    
    // DA接口
    output         da_clk,        // DAC驱动时钟
    output [9:0]   da_data,       // DAC数据输出(10位)
    
    // 数码管接口
    output [4:0]   seg_sel,       // 数码管位选
    output [7:0]   seg_led        // 数码管段选
);

// 内部信号定义
wire             clk_100m;        // 100MHz时钟
wire             clk_50m;         // 50MHz时钟
wire             clk_32m;         // 32MHz时钟
wire             clk_32m_120;         // 32MHz时钟
wire             clk_2m;          // 2MHz时钟(载波频率)
wire             locked;          // PLL锁定信号
wire             rst_n;           // 全局复位信号
wire [2:0]       key_value;       // 按键值（防抖后）
wire [15:0]      data_modulus;    // FFT取模结果
wire             data_valid;      // 数据有效信号
wire             fft_shutdown;    // FFT关闭信号
wire [7:0]      wr_addr;         // RAM写地址
wire [15:0]      wr_data;         // RAM写数据
wire             wr_en;           // RAM写使能
wire             wr_done;         // RAM写完成
wire [7:0]      rd_addr;         // RAM读地址
wire [15:0]      rd_data;         // RAM读数据
wire             wave_vaild;      // 波形有效信号
wire			mode;				// 1：数字调制 0：模拟调制

// 解调相关信号
wire [2:0]       mod_type;        // 调制类型: 001-CW, 010-AM, 100-FM
wire [7:0]       mod_param1;      // 调制参数1 (AM:ma, FM:mf)
wire [7:0]       mod_param2;      // 调制参数2 (FM:Δfmax)
wire [7:0]       mod_freq;        // 调制频率F (1-5kHz)
wire [9:0]       demod_out_cw;       // 解调输出信号
wire [9:0]       demod_out_am;       // 解调输出信号
wire [9:0]       demod_out_fm;       // 解调输出信号

// 复位信号
assign rst_n = sys_rst_n && locked;

//ADC时钟
assign ad_clk = (wave_vaild) ? clk_32m : clk_8192k;

// PLL IP核
clk_wiz_0 u_clk_wiz_0(
    .clk_out1 (clk_100m),        // 
    .clk_out2 (clk_50m),         // 50MHz时钟
    .clk_out3 (clk_50m_180),     // 50MHz时钟相移180
    .clk_out4 (clk_32m),         // 32MHz时钟

    .locked   (locked),          // PLL锁定信号
    .clk_in1  (sys_clk)          // 系统输入时钟
);
// PLL IP核
clk_wiz_1 u_clk_wiz_1(
    .clk_out1 (clk_8192k),        // 8192kHz采样时钟

    .clk_in1  (clk_32m)          // 系统输入时钟
);
// PLL IP核
/* clk_wiz_2 u_clk_wiz_2(
    .clk_out1 (clk_30m),        // 30MHz采样时钟

    .clk_in1  (sys_clk)          // 系统输入时钟
); */
//2MHz时钟(载波频率)、、注意因为PLL塞不下那么多时钟所以专门写个2m的时钟模块。
/* clk_div_2m u_clk_div_2m (
    .clk_32m (clk_32m),  // 输入50MHz时钟
    .rst_n   (rst_n),    // 全局复位
    .clk_2m  (clk_2m)    // 输出2MHz时钟
); */

// 按键防抖模块
key_debounce u_key_debounce(
    .clk(clk_50m),
    .rst_n(rst_n),
    .key(key),
    .key_value(key_value)
);

// FFT控制模块
fft_ctrl u_fft_ctrl(
    .clk(clk_50m),
    .rst_n(rst_n),
    .key(key_value[1:0]),          // 启动按键
    .fft_shutdown(fft_shutdown),
    .fft_valid(fft_valid)
);

// FFT IP核
xfft_0 u_fft(
    .aclk(clk_8192k),
    .aresetn(fft_valid & rst_n), // FFT重置信号
    .s_axis_config_tdata(8'd1),
    .s_axis_config_tvalid(1'b1),
    .s_axis_config_tready(),     // 悬空
    
    .s_axis_data_tdata({6'b0, ad_data}), // 输入数据(10位ADC数据)
    .s_axis_data_tvalid(1'b1),
    .s_axis_data_tready(),
    .s_axis_data_tlast(),
    
    .m_axis_data_tdata(),
    .m_axis_data_tuser(),
    .m_axis_data_tvalid(fft_m_data_tvalid),
    .m_axis_data_tready(1'b1),
    .m_axis_data_tlast(),
    
    .m_axis_status_tdata(),
    .m_axis_status_tvalid(),
    .m_axis_status_tready(1'b0),
    
    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);
wire [32:0] fft_m_data_tdata;
// 数据取模模块
data_modulus u_data_modulus(
    .clk(clk_50m),
    .rst_n(rst_n),
    .source_real(fft_m_data_tdata[15:0]),   // 实部
    .source_imag(fft_m_data_tdata[31:16]),  // 虚部
    .source_valid(fft_m_data_tvalid),
    .data_modulus(data_modulus),
    .data_valid(data_valid)
);

// RAM写控制模块
ram_wr_ctrl u_ram_wr_ctrl(
    .clk(clk_8192k),
    .rst_n(rst_n & key_value[0] & key_value[1]), // 复位，接(rst_n & key[0])
    .data_modulus(data_modulus),
    .data_valid(data_valid),
    .wr_data(wr_data),
    .wr_addr(wr_addr),
    .wr_en(wr_en),
    .wr_done(wr_done),
    .fft_shutdown(fft_shutdown)
);

// RAM IP核 (256x16)
ram_256x16 u_ram_256x16 (
    .clka(clk_50m),              // FFT时钟
    .wea(wr_en),                 // 写使能
    .addra(wr_addr),             // 写地址
    .dina(wr_data),              // 写数据
    .clkb(clk_50m),              // 读时钟
    .addrb(rd_addr),             // 读地址
    .doutb(rd_data)              // 读数据
);

// 调制类型识别模块
modulation_detect u_modulation_detect(
    .clk(clk_50m_180),
    .rst_n(rst_n),
    .en(wr_done),                // 使能信号
    .key(key_value[1:0]),          // 模式选择按键
    .rd_data(rd_data),           // FFT取模数据
    .rd_addr(rd_addr),           // RAM地址
    .mode_type(mod_type),         // 调制类型
    .valid(wave_vaild),      // 数据有效信号
	.mode(mode)					// 1：数字调制 0：模拟调制
);

// AM解调模块
am_demod u_am_demod(
    .clk(clk_50m),
    .rst_n(rst_n),
    .en(mod_type[0]),      // AM模式使能
	.mode(mode),			//1：数字调制 0：模拟调制
    .ad_data(ad_data),           // ADC输入数据
    .demod_out(demod_out_am),       // 解调输出
    .ma(mod_param1),             // 调幅系数
    .freq(mod_freq)              // 调制频率
);

// FM解调模块
fm_demod u_fm_demod(
    .clk(clk_50m),
    .rst_n(rst_n),
    .en(mod_type[1]),      // FM模式使能
	.mode(mode),		//1：数字调制 0：模拟调制
	.ad_data(ad_data),           // ADC输入数据
    .demod_out(demod_out_fm),       // 解调输出
    .mf(mod_param1),             // 调频系数
    .delta_f(mod_param2),        // 最大频偏
    .freq(mod_freq)              // 调制频率
 );
// 2PSK解调模块
bpsk_demod1 u_bpsk_demod(
	.clk_32m(clk_32m),
	.rst_n(rst_n),
	.en(mod_type[2]),// 2PSK模式使能
	.mode(mode),		//1：数字调制 0：模拟调制
	.ad_data(ad_data),   		// ADC输入数据
	.demod_out(demod_out_cw),      // 解调输出
	.freq(mod_freq)       	// 调制频率
);

// DA输出控制
assign da_clk = clk_32m;          // DAC时钟使用采样频率
assign da_data = (mod_type[2]) ? demod_out_cw : // CW模式输出中间值
                 (mod_type[1]) ? demod_out_fm : 
				 (mod_type[0]) ? demod_out_am : 0;
// 数码管显示模块
seg_led u_seg_led(
    .sys_clk(clk_50m),
    .sys_rst_n(rst_n),
	.num1(mod_freq),
	.num2(mod_param1),
	.num3(mod_param2),
    .seg_sel(seg_sel),
    .seg_led(seg_led)
);

endmodule