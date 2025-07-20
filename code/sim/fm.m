% FM调制波生成并保存二进制数据到txt文件
% 参数设置
fs = 32e6;       % 采样频率 8MHz
fc = 2e6;       % 载波频率 2MHz
fm = 3e3;       % 调制频率 5kHz
duration = 0.01; % 信号持续时间 10ms
bits = 10;      % 输出位数

% 时间向量
t = 0:1/fs:duration-1/fs;

% 调制信号
mod_signal = sin(2*pi*fm*t);

% 调制指数/频偏
beta = 5;
f_dev = beta * fm;

% FM调制
fm_signal = cos(2*pi*fc*t + 2*pi*f_dev*cumsum(mod_signal)/fs);

% 量化为10位无符号二进制 (0-1023)
quantized = round((fm_signal + 1) * (2^bits-1)/2);

% 转换为二进制字符串
binary_out = dec2bin(quantized, bits);

% 保存到txt文件
filename = 'fm_modulation_binary_data.txt';
fid = fopen(filename, 'w');


% 写入二进制数据
for i = 1:length(binary_out)
    fprintf(fid, '%s\n', binary_out(i,:));
end

fclose(fid);
disp(['二进制数据已保存到文件: ' filename]);

% 显示部分结果
disp('前10个样本的10位二进制值:');
disp(binary_out(1:10,:));