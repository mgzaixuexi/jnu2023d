% 参数设置
Fs = 8.192e6;       % 采样频率 8.192 MHz
N = 8192;           % 采样点数 8192
fc = 2e6;           % 载波频率 2 MHz
bit_rates = [6e3, 8e3, 10e3];  % 码率 [6kbps, 8kbps, 10kbps]
f_shift = 25e3;    % 2FSK频偏 100 kHz
t = (0:N-1)/Fs;     % 时间序列

% 创建图形
figure;
set(gcf, 'Position', [100, 100, 1200, 900]);

% 循环处理不同码率
for br_idx = 1:length(bit_rates)
    bit_rate = bit_rates(br_idx);
    
    % 计算比特数和每比特采样点数
    num_bits = floor(N * bit_rate / Fs);
    samples_per_bit = floor(Fs / bit_rate);
    
    % 生成随机二进制序列
    bits = randi([0, 1], 1, num_bits);
    
    % 1. 2ASK信号生成
    ask_signal = zeros(1, N);
    for i = 1:num_bits
        start_idx = (i-1)*samples_per_bit + 1;
        end_idx = min(i*samples_per_bit, N);
        
        if bits(i) == 1
            ask_signal(start_idx:end_idx) = cos(2*pi*fc*t(start_idx:end_idx));
        else
            ask_signal(start_idx:end_idx) = 0;
        end
    end
    
    % 2. 2FSK信号生成
    fsk_signal = zeros(1, N);
    for i = 1:num_bits
        start_idx = (i-1)*samples_per_bit + 1;
        end_idx = min(i*samples_per_bit, N);
        
        if bits(i) == 1
            fsk_signal(start_idx:end_idx) = cos(2*pi*(fc + f_shift)*t(start_idx:end_idx));
        else
            fsk_signal(start_idx:end_idx) = cos(2*pi*(fc - f_shift)*t(start_idx:end_idx));
        end
    end
    
    % 3. 2PSK信号生成
    psk_signal = zeros(1, N);
    for i = 1:num_bits
        start_idx = (i-1)*samples_per_bit + 1;
        end_idx = min(i*samples_per_bit, N);
        
        if bits(i) == 1
            psk_signal(start_idx:end_idx) = cos(2*pi*fc*t(start_idx:end_idx));
        else
            psk_signal(start_idx:end_idx) = -cos(2*pi*fc*t(start_idx:end_idx));
        end
    end
    
    % 计算FFT频谱
    frequencies = (0:N-1)*(Fs/N);  % 频率轴
    
    % 计算2ASK频谱
    ask_fft = fft(ask_signal);
    ask_spectrum = abs(ask_fft/N);
    ask_spectrum = ask_spectrum(1:N/2+1);
    ask_spectrum(2:end-1) = 2*ask_spectrum(2:end-1); % 单边谱
    
    % 计算2FSK频谱
    fsk_fft = fft(fsk_signal);
    fsk_spectrum = abs(fsk_fft/N);
    fsk_spectrum = fsk_spectrum(1:N/2+1);
    fsk_spectrum(2:end-1) = 2*fsk_spectrum(2:end-1); % 单边谱
    
    % 计算2PSK频谱
    psk_fft = fft(psk_signal);
    psk_spectrum = abs(psk_fft/N);
    psk_spectrum = psk_spectrum(1:N/2+1);
    psk_spectrum(2:end-1) = 2*psk_spectrum(2:end-1); % 单边谱
    
    % 绘制频谱图
    freq_range = frequencies(1:N/2+1)/1e6; % 转换为MHz
    
    % 2ASK频谱
    subplot(length(bit_rates), 3, (br_idx-1)*3+1);
    plot(freq_range, ask_spectrum);
    xlim([1.9 2.1]); 
    ylim([0 max(ask_spectrum)*1.1]);
    title(sprintf('2ASK频谱 (%d kbps)', bit_rate/1000));
    xlabel('频率 (MHz)');
    ylabel('幅度');
    grid on;
    
    % 添加带宽标注
    bw = 2*bit_rate; % ASK理论带宽
    line([fc/1e6-bw/2e6 fc/1e6-bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    line([fc/1e6+bw/2e6 fc/1e6+bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    text(1.95, max(ask_spectrum)*0.9, sprintf('BW=%.1fkHz', bw/1000), 'Color', 'r');
    
    % 2FSK频谱
    subplot(length(bit_rates), 3, (br_idx-1)*3+2);
    plot(freq_range, fsk_spectrum);
    xlim([1.8 2.2]); 
    ylim([0 max(fsk_spectrum)*1.1]);
    title(sprintf('2FSK频谱 (%d kbps)', bit_rate/1000));
    xlabel('频率 (MHz)');
    ylabel('幅度');
    grid on;
    
    % 添加载频标注
    line([(fc-f_shift)/1e6 (fc-f_shift)/1e6], ylim, 'Color', 'g', 'LineStyle', '--');
    line([(fc+f_shift)/1e6 (fc+f_shift)/1e6], ylim, 'Color', 'g', 'LineStyle', '--');
    text(1.85, max(fsk_spectrum)*0.9, sprintf('f1=%.4fMHz', (fc-f_shift)/1e6), 'Color', 'g');
    text(2.05, max(fsk_spectrum)*0.9, sprintf('f2=%.4fMHz', (fc+f_shift)/1e6), 'Color', 'g');
    
    % 2PSK频谱
    subplot(length(bit_rates), 3, (br_idx-1)*3+3);
    plot(freq_range, psk_spectrum);
    xlim([1.9 2.1]); 
    ylim([0 max(psk_spectrum)*1.1]);
    title(sprintf('2PSK频谱 (%d kbps)', bit_rate/1000));
    xlabel('频率 (MHz)');
    ylabel('幅度');
    grid on;
    
    % 添加带宽标注
    bw = 2*bit_rate; % PSK理论带宽
    line([fc/1e6-bw/2e6 fc/1e6-bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    line([fc/1e6+bw/2e6 fc/1e6+bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    text(1.95, max(psk_spectrum)*0.9, sprintf('BW=%.1fkHz', bw/1000), 'Color', 'r');
end

% 设置图形整体标题
%sgtitle(sprintf('不同码率下数字调制信号频谱 (载频%.1fMHz, 采样率%.1fMHz)', fc/1e6, Fs/1e6));

% 添加图例说明
annotation('textbox', [0.15, 0.005, 0.7, 0.05], 'String', ...
    sprintf('FFT点数: %d | 2FSK频偏: %.0f kHz | 总比特数: %d/%d/%d (对应6/8/10kbps)', ...
    N, f_shift/1000, ...
    floor(N*bit_rates(1)/Fs), ...
    floor(N*bit_rates(2)/Fs), ...
    floor(N*bit_rates(3)/Fs)), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center');