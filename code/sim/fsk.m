clear all;
close all;
clc;

% 参数设置
fc = 2e6;          % 载波频率 2MHz
Rb = 10e3;         % 码速率 10kbps
h = 5;             % 移频键控系数
fs = 32e6;         % 采样频率 32MHz
Tb = 1/Rb;         % 比特周期
Ns = round(Tb * fs); % 每个比特的采样点数
N = 100;           % 生成的比特数

% 生成随机二进制数据
data = randi([0 1], 1, N);

% 计算频偏
delta_f = h / (2*Tb);  % 频偏 = h/(2Tb)

% 初始化时间轴和信号
t = 0:1/fs:(N*Tb - 1/fs);
fsk_signal = zeros(1, length(t));

% 生成2FSK信号
for i = 1:N
    if data(i) == 1
        freq = fc + delta_f;  % 比特1对应高频
    else
        freq = fc - delta_f;  % 比特0对应低频
    end
    
    % 当前比特对应的时间段
    time_segment = ((i-1)*Ns+1):min(i*Ns, length(t));
    
    % 生成对应频率的正弦波
    fsk_signal(time_segment) = cos(2*pi*freq*t(time_segment));
end

% 将信号量化为10位无符号二进制
% 先归一化到0-1范围
normalized_signal = (fsk_signal + 1) / 2;  % 从[-1,1]映射到[0,1]
% 量化为10位(0-1023)
quantized_signal = round(normalized_signal * (2^10 - 1));

% 将量化后的数据转为二进制字符串
binary_str = dec2bin(quantized_signal, 10);

% 保存到txt文件(每行一个采样点的10位二进制值)
fileID = fopen('fsk_10bit_binary.txt', 'w');
for i = 1:size(binary_str, 1)
    fprintf(fileID, '%s\n', binary_str(i,:));
end
fclose(fileID);
disp('10位无符号二进制数据已保存到fsk_10bit_binary.txt');

% 绘制时域波形(部分)
figure;
subplot(2,1,1);
plot(t(1:10*Ns), fsk_signal(1:10*Ns));
title('2FSK信号时域波形(前10比特)');
xlabel('时间(s)');
ylabel('幅度');
grid on;

subplot(2,1,2);
plot(t(1:10*Ns), quantized_signal(1:10*Ns));
title('量化后的信号(前10比特)');
xlabel('时间(s)');
ylabel('10位量化值');
grid on;

% 绘制频谱
figure;
nfft = 2^nextpow2(length(fsk_signal));
f = (-nfft/2:nfft/2-1)*fs/nfft;
spectrum = abs(fftshift(fft(fsk_signal, nfft)));
plot(f, 20*log10(spectrum/max(spectrum)));
title('2FSK信号频谱');
xlabel('频率(Hz)');
ylabel('幅度(dB)');
xlim([fc-3*delta_f fc+3*delta_f]);
grid on;

% 显示参数
disp(['载波频率: ', num2str(fc/1e6), ' MHz']);
disp(['码速率: ', num2str(Rb/1e3), ' kbps']);
disp(['采样频率: ', num2str(fs/1e6), ' MHz']);
disp(['移频键控系数: ', num2str(h)]);
disp(['频偏: ±', num2str(delta_f/1e3), ' kHz']);
disp(['每个比特采样点数: ', num2str(Ns)]);