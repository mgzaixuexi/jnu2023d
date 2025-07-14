% CW/AM/FM信号分析（固定FFT为4096点，添加白噪声）

% 参数设置
fs = 2 * 4096000;          % 采样频率 (8.192MHz)
T = 1e-3;                % 信号持续时间 (1ms)
t = 0:1/fs:T-1/fs;       % 时间向量
N_fft = 2 * 4096;          % 固定FFT点数

fc = 2e6;                % 载波频率 (2MHz)
F = 5e3;                 % 调制信号频率 (5kHz)
Vpp = 100e-3;            % 峰峰值电压 (100mV)
Ac = Vpp/2;              % 载波幅度 (50mV)

% 噪声参数
SNR_dB = 20;             % 信噪比(dB)
noise_power = Ac^2 / (10^(SNR_dB/10)); % 噪声功率

%% 信号生成（添加高斯白噪声）
% 生成噪声
%noise = sqrt(noise_power) * randn(size(t));
noise = 0;
% CW信号
cw_signal = Ac * cos(2*pi*fc*t) + noise;

% AM信号（调制深度m=0.3）
m = 0.3;
am_signal = Ac*(1 + m*cos(2*pi*F*t)) .* cos(2*pi*fc*t) + noise;

% FM信号（调频指数β=5）
beta = 5;
fm_signal = Ac*cos(2*pi*fc*t + beta*sin(2*pi*F*t)) + noise;

%% 频谱分析函数（含加窗处理）
function [f, fft_result] = analyze_spectrum(signal, fs, N_fft)
    % 汉宁窗减少频谱泄漏
    window = hann(length(signal))';
    signal_windowed = signal .* window;
    
    % 补零至N_fft长度
    if length(signal) < N_fft
        signal_padded = [signal_windowed, zeros(1, N_fft-length(signal))];
    else
        signal_padded = signal_windowed(1:N_fft);
    end
    
    f = (-N_fft/2:N_fft/2-1)*fs/N_fft;
    fft_result = abs(fftshift(fft(signal_padded)/N_fft));
end

% 分析频谱
[f_cw, fft_cw] = analyze_spectrum(cw_signal, fs, N_fft);
[f_am, fft_am] = analyze_spectrum(am_signal, fs, N_fft);
[f_fm, fft_fm] = analyze_spectrum(fm_signal, fs, N_fft);

%% 绘图对比
figure;

% CW信号
subplot(3,2,1);
plot(t(1:200), cw_signal(1:200));
title(['CW时域波形 (SNR=',num2str(SNR_dB),'dB)']);
xlabel('时间 (s)'); ylabel('幅度 (V)');
grid on;

subplot(3,2,2);
plot(f_cw/1e6, 20*log10(fft_cw));
title('CW频谱 (加窗处理)');
xlabel('频率 (MHz)'); ylabel('幅度 (dB)');
xlim([-3, 3]); grid on;

% AM信号
subplot(3,2,3);
plot(t(1:200), am_signal(1:200));
title(['AM时域波形 (m=0.3, SNR=',num2str(SNR_dB),'dB)']);
xlabel('时间 (s)'); ylabel('幅度 (V)');
grid on;

subplot(3,2,4);
plot(f_am/1e6, 20*log10(fft_am));
title('AM频谱 (加窗处理)');
xlabel('频率 (MHz)'); ylabel('幅度 (dB)');
xlim([1.8, 2.2]); grid on;

% FM信号
subplot(3,2,5);
plot(t(1:200), fm_signal(1:200));
title(['FM时域波形 (β=5, SNR=',num2str(SNR_dB),'dB)']);
xlabel('时间 (s)'); ylabel('幅度 (V)');
grid on;

subplot(3,2,6);
plot(f_fm/1e6, 20*log10(fft_fm));
title('FM频谱 (加窗处理)');
xlabel('频率 (MHz)'); ylabel('幅度 (dB)');
xlim([1.5, 2.5]); grid on;

%% 参数估计（AM信号抗噪演示）
[~, center_idx] = max(fft_am);
fc_est = abs(f_am(center_idx));

% 改进的边带检测（增加噪声容限）
search_range = round(0.8*F*N_fft/fs):round(1.2*F*N_fft/fs);
left_side = center_idx - search_range;
right_side = center_idx + search_range;

left_side = left_side(left_side>1);
right_side = right_side(right_side<N_fft);

% 使用平均功率提高鲁棒性
window_size = 3; % 3点平滑窗口
left_power = movmean(fft_am(left_side), window_size);
right_power = movmean(fft_am(right_side), window_size);

[~, max_left] = max(left_power);
[~, max_right] = max(right_power);

F_est = mean([abs(f_am(left_side(max_left))-fc_est), abs(f_am(right_side(max_right))-fc_est)]);
m_est = 2 * mean([fft_am(left_side(max_left)), fft_am(right_side(max_right))]) / fft_am(center_idx);

fprintf('\n---带噪声估计结果(SNR=%ddB)---\n', SNR_dB);
fprintf('载波频率 fc_est = %.2f MHz (误差%.2f kHz)\n', fc_est/1e6, abs(fc_est-fc)/1e3);
fprintf('调制频率 F_est = %.2f kHz (误差%.2f Hz)\n', F_est/1e3, abs(F_est-F));
fprintf('调制深度 m_est = %.2f (误差%.2f)\n', m_est, abs(m_est-m));

%AM调制系数可以通过两倍边频分量幅度和➗载波幅度；在频谱分析中输出。
2*(10^(-54/20)/10^(-38/20))