% 参数设置
Fs = 8.192e6;       % 采样频率8.192MHz
Fc = 2e6;           % 载波频率2MHz
Fm = 1e3;           % 调制信号频率1kHz
Vpp = 0.1;          % 载波峰峰值100mV（幅值50mV）
N = 81920;           % 采样点数
bits = 10;          % 10位量化

% 生成时间序列
t = (0:N-1)/Fs;

% 生成调制信号（范围[-1, 1]，再缩放到调制深度）
m = 0.5;                            % 调制深度
mod_signal = m * sin(2*pi*Fm*t);    % 范围: [-0.5, 0.5]

% 生成载波信号（幅值50mV）
A_carrier = Vpp / 2;                % 载波幅值50mV
carrier = A_carrier * sin(2*pi*Fc*t); % 范围: [-0.05, 0.05]

% 生成AM信号（标准公式）
AM_signal = (1 + mod_signal) .* carrier; % 范围: [0.05*(1-0.5), 0.05*(1+0.5)] = [0.025, 0.075]

% 归一化到[0, 1]范围（适配10位量化）
AM_normalized = (AM_signal - min(AM_signal)) / (max(AM_signal) - min(AM_signal));

% 量化为10位无符号整数（0-1023）
AM_quantized = uint16(round(AM_normalized * (2^bits - 1)));

% 写入文件（二进制字符串，每行10位）
fid = fopen('AM_signal_2MHz_1kHz.txt', 'w');
for i = 1:N
    fprintf(fid, '%s\n', dec2bin(AM_quantized(i), bits));
end
fclose(fid);

% 绘制波形（前200点）
figure;
subplot(3,1,1);
plot(t(1:200), mod_signal(1:200));
title('调制信号 (m \cdot sin(2πFm t))');
xlabel('时间（秒）'); ylabel('幅值');

subplot(3,1,2);
plot(t(1:200), carrier(1:200));
title('载波信号 (A_c \cdot sin(2πFc t))');
xlabel('时间（秒）'); ylabel('幅值（V）');

subplot(3,1,3);
plot(t(1:200), AM_signal(1:200));
title('AM调制信号 (1 + m \cdot sin(2πFm t)) \cdot A_c sin(2πFc t)');
xlabel('时间（秒）'); ylabel('幅值（V）');
grid on;