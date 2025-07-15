% CW/AM/FM信号分析（固定FFT为4096点，添加白噪声）

% 参数设置
fs = 2 * 4096000;          % 采样频率 (8.192MHz)
T = 1e-3;                % 信号持续时间 (1ms)
t = 0:1/fs:T-1/fs;       % 时间向量
N_fft = 2 * 4096;          % 固定FFT点数

fc = 2e6;                % 载波频率 (2MHz)
F = 1e3;                 % 调制信号频率 (1kHz)
Vpp = 100e-3;            % 峰峰值电压 (100mV)
Ac = Vpp/2;              % 载波幅度 (50mV)

% 噪声参数
SNR_dB = 20;             % 信噪比(dB)
noise_power = Ac^2 / (10^(SNR_dB/10)); % 噪声功率

%% 信号生成（添加高斯白噪声）
% 生成噪声
%noise = sqrt(noise_power) * randn(size(t));
noise = 0;

% AM信号（调制深度m=0.3）
m = 0.3;
am_signal = abs(Ac*(1 + m*cos(2*pi*F*t)) .* cos(2*pi*fc*t) + noise);
%am_signal = Ac*(1 + m*cos(2*pi*F*t)) .* cos(2*pi*fc*t) + noise;


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
[f_am, fft_am] = analyze_spectrum(am_signal, fs, N_fft);

%% 绘图对比
figure;


% AM信号
subplot(2,2,1);
plot(t(1:200), am_signal(1:200));
title(['AM时域波形 (m=0.3, SNR=',num2str(SNR_dB),'dB)']);
xlabel('时间 (s)'); ylabel('幅度 (V)');
grid on;

subplot(2,2,2);
plot(f_am/1e6, 20*log10(fft_am));
title('AM频谱 (加窗处理)');
xlabel('频率 (MHz)'); ylabel('幅度 (dB)');
xlim([1.8, 2.2]); grid on;



%AM调制系数可以通过两倍边频分量幅度和➗载波幅度；在频谱分析中输出。
2*(10^(-54/20)/10^(-38/20))