module clk_div_2m(
    input       clk_32m,    // 32MHz输入时钟
    input       rst_n,      // 异步复位（低有效）
    output reg  clk_2m      // 2MHz输出时钟（50%占空比）
);

reg [3:0] counter = 0;  // 0-15计数（4位足够）

always @(posedge clk_32m or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        clk_2m  <= 0;
    end else begin
        if (counter == 7) begin  // 计数到15（共16个周期）
            counter <= 0;
            clk_2m  <= ~clk_2m;   // 翻转时钟
        end else begin
            counter <= counter + 1;
        end
    end
end
endmodule