//****************************************Copyright (c)***********************************//
// 修改说明：适配16位有符号数输入
// 主要修改点：
// 1. 输入位宽扩展为16位
// 2. 原码转换逻辑适配15位数据
// 3. 平方和计算扩展到31位
// 4. Cordic输入接口适配
//****************************************************************************************/

module data_modulus(
    input             clk,
    input             rst_n,
    // FFT ST接口（修改为16位输入）
    input   [15:0]    source_real,   // 实部 有符号数（补码）
    input   [15:0]    source_imag,   // 虚部 有符号数（补码）
    input             source_eop,    // 帧结束信号
    input             source_valid,  // 数据有效信号
    
    // 取模运算接口
    output  [15:0]    data_modulus,  // 取模结果
    output            data_eop,      // 结果帧结束
    output            data_valid     // 结果有效信号

/* 	//jhb部分
	input key,                       //键控重置，就是题目里的启动键，不是复位

	output  reg       fft_en,		 //fft的使能，接到数据有效或者时钟有效都行
    //取模运算后的数据接口 
    output  [15:0]    data_modulus,  //取模后的数据 
	output  reg  [7:0]	  wr_addr,	 //写ram地址
	output         	  wr_en,		 //写使能	
	output  reg       wr_done		 //分离模块使能 */

);

// 参数定义
localparam DATA_WIDTH = 15;  // 有效数据位宽（符号扩展后）

// 寄存器定义
reg  [DATA_WIDTH-1:0] data_real;     // 实部原码（无符号）
reg  [DATA_WIDTH-1:0] data_imag;     // 虚部原码（无符号）
reg  [2*DATA_WIDTH:0] source_data;   // 平方和（位宽2N+1）
reg  [7:0]            source_valid_d; // 有效信号延迟链
reg  [7:0]            source_eop_d;    // EOP信号延迟链

//*****************************************************
//**                    主要逻辑
//*****************************************************

// 补码转原码处理（适配16位输入）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_real <= 0;
        data_imag <= 0;
    end
/* 	else if(!key) begin 
        //source_data <= 0; 
        data_real   <= 16'd0; 
        data_imag   <= 16'd0; 
    end */
    else begin
        // 处理实部（符号位为最高位）
        data_real <= source_real[15] ? 
                   (~source_real[DATA_WIDTH-1:0] + 1'b1) :  // 负数取补
                   source_real[DATA_WIDTH-1:0];              // 正数直接取
        
        // 处理虚部
        data_imag <= source_imag[15] ? 
                   (~source_imag[DATA_WIDTH-1:0] + 1'b1) : 
                   source_imag[DATA_WIDTH-1:0];
    end
end

// 平方和计算（31位存储）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        source_data <= 0;
    else
        source_data <= (data_real * data_real) + (data_imag * data_imag);
end

// 信号延迟链（保持时序对齐）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        source_valid_d <= 0;
        source_eop_d <= 0;
    end
    else begin
        source_valid_d <= {source_valid_d[6:0], source_valid};
        source_eop_d   <= {source_eop_d[6:0], source_eop};
    end
end

// Cordic IP核接口（需重新配置为31位输入）
cordic_0 u_cordic_0 (
    .aclk(clk),    // 时钟
    // 输入接口（需确保IP核配置支持31位输入）
    .s_axis_cartesian_tvalid(source_valid_d[3]),  // 时序对齐
    .s_axis_cartesian_tdata(source_data),         // 31位平方和
    // 输出接口
    .m_axis_dout_tvalid(data_valid),
    .m_axis_dout_tdata(data_modulus)              // 16位输出
);

// EOP信号时序对齐
assign data_eop = source_eop_d[7];

/* //jhb部分
assign wr_en = (wr_addr <= 128) ? data_valid : 0 ;
 
//写ram控制
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        wr_addr  <= 8'd0;
    else if(!key)
        wr_addr  <= 8'd0;        
    else if(wr_en)
        wr_addr  <= wr_addr + 8'd1;
    else
        wr_addr  <= wr_addr;          
end

always @ (posedge clk or negedge rst_n)
    if(!rst_n) begin 
	wr_done <= 0;
	fft_en <= 1;
	end
	else if(!key) begin 
	wr_done <= 0;
	fft_en <= 1;
	end
	else if(wr_addr > 128)begin
	wr_done <= 1;
	fft_en <= 0;
	end
	else begin
	wr_done <= wr_done;
	fft_en <= fft_en;
	end
//取到一半多一点就关闭fft，同时不再写入ram */
endmodule