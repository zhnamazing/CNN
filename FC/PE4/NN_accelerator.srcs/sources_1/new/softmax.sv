`timescale 1ns / 1ps
module softmax (
    input  signed [7:0] in[0:9],  // 10 位输入向量（8 位有符号整数）
    output reg [7:0] out[0:9]     // 10 位输出向量（8 位无符号整数）
);

    // 查找表（LUT）用于近似指数函数
    reg [7:0] exp_lut[127:0];  // 8 位指数查找表
    integer i;

    // 初始化查找表
    initial begin
        for (i = 0; i < 128; i = i + 1) 
          begin
            exp_lut[i] = $rtoi($exp(i / 16.0)) * 16;  // 近似指数函数
          end
    end

    // 计算指数值
    reg [7:0] exp_values[0:9];  // 存储每个输入的指数值
    reg [15:0] sum_exp = 0;     // 存储所有指数值的和

    always @(*) begin
        sum_exp = 0;
        for (i = 0; i < 10; i = i + 1) begin
            // 将输入值映射到查找表索引
            if (in[i] < 0) begin
                exp_values[i] = 0;  // 负数的指数近似为 0
            end else if (in[i] > 127) begin
                exp_values[i] = exp_lut[127];  // 超过范围的值取最大值
            end else begin
                exp_values[i] = exp_lut[in[i]];  // 查找指数值
            end
            sum_exp = sum_exp + exp_values[i];  // 累加指数值
        end
    end

    // 计算 Softmax 输出
    always @(*) begin
        for (i = 0; i < 10; i = i + 1) begin
            if (sum_exp == 0) begin
                out[i] = 0;  // 避免除以零
            end else begin
                out[i] = (exp_values[i] * 255) / sum_exp;  // 归一化并映射到 0-255
            end
        end
    end

endmodule