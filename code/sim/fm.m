% 参数设置
Fs = 8.192e6;       % 采样频率8.192MHz
Fc = 2e6;           % 载波频率2MHz
Fm = 5e3;           % 调制信号频率5kHz
Vpp = 0.1;          % 载波峰峰值100mV（幅值50mV）
N = 81920;          % 采样点数
bits = 10;          % 10位量化
beta = 5;           % 调制指数（频偏比）

% 生成时间序列
t = (0:N-1)/Fs;

% 生成调制信号（频率调制）
mod_signal = sin(2*pi*Fm*t);       % 调制信号（范围[-1,1]）

% 生成FM信号（频率调制公式）
% 积分调制信号得到相位偏移：∫mod_signal dt = -cos(2πFm t)/(2πFm)
phase_integral = -cos(2*pi*Fm*t) / (2*pi*Fm);
FM_signal = Vpp/2 * sin(2*pi*Fc*t + beta * phase_integral); % 频偏=β*Fm

% 归一化到[0,1]范围（适配10位量化）
FM_normalized = (FM_signal - min(FM_signal)) / (max(FM_signal) - min(FM_signal));

% 量化为10位无符号整数（0-1023）
FM_quantized = uint16(round(FM_normalized * (2^bits - 1)));

% 写入文件（二进制字符串，每行10位）
fid = fopen('FM_signal_2MHz_5kHz.txt', 'w');
for i = 1:N
    fprintf(fid, '%s\n', dec2bin(FM_quantized(i), bits));
end
fclose(fid);

% 绘制波形（前2000点）
figure;
subplot(3,1,1);
plot(t(1:2000), mod_signal(1:2000));
title('调制信号 (sin(2πFm t))');
xlabel('时间（秒）'); ylabel('幅值');

subplot(3,1,2);
plot(t(1:2000), phase_integral(1:2000));
title('积分相位偏移 (∫mod\_signal dt)');
xlabel('时间（秒）'); ylabel('相位（rad）');

subplot(3,1,3);
plot(t(1:2000), FM_signal(1:2000));
title('FM调制信号 (A_c \cdot sin(2πFc t + β∫mod\_signal dt))');
xlabel('时间（秒）'); ylabel('幅值（V）');
grid on;