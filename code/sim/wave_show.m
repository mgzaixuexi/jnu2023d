% 文件路径
file_path = 'D:\vivado\project\ti\jnu2023d_test\code\sim\AM_signal_2MHz_1kHz.txt';

% 打开文件
fid = fopen(file_path, 'r');
if fid == -1
    error('无法打开文件，请检查路径是否正确');
end

% 读取二进制数据（10位无符号，假设是二进制字符串形式）
% 方法1：如果文件是每行一个10位二进制数（如 '0000000001'）
data_str = textscan(fid, '%s');  % 读取所有行为字符串单元数组
fclose(fid);

% 转换为数值
binary_str = data_str{1};  % 提取字符串单元数组
num_samples = length(binary_str);
data = zeros(num_samples, 1, 'uint16');  % 10位无符号数范围0-1023

for i = 1:num_samples
    data(i) = bin2dec(binary_str{i});  % 二进制字符串转十进制
end

% 方法2：如果文件是连续的二进制位流（需知道总位数）
% 此情况需要更复杂的解析，假设方法1适用

% 绘制波形
figure;
plot(data, 'b-', 'LineWidth', 0.5);
xlabel('样本点');
ylabel('幅值 (10位无符号)');
title('AM信号波形 (2MHz载波, 1kHz调制)');
grid on;

% 可选：限制显示范围（例如前1000个点）
% xlim([0, 1000]);