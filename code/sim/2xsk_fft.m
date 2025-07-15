% ��������
Fs = 8.192e6;       % ����Ƶ�� 8.192 MHz
N = 8192;           % �������� 8192
fc = 2e6;           % �ز�Ƶ�� 2 MHz
bit_rates = [6e3, 8e3, 10e3];  % ���� [6kbps, 8kbps, 10kbps]
f_shift = 25e3;    % 2FSKƵƫ 100 kHz
t = (0:N-1)/Fs;     % ʱ������

% ����ͼ��
figure;
set(gcf, 'Position', [100, 100, 1200, 900]);

% ѭ������ͬ����
for br_idx = 1:length(bit_rates)
    bit_rate = bit_rates(br_idx);
    
    % �����������ÿ���ز�������
    num_bits = floor(N * bit_rate / Fs);
    samples_per_bit = floor(Fs / bit_rate);
    
    % �����������������
    bits = randi([0, 1], 1, num_bits);
    
    % 1. 2ASK�ź�����
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
    
    % 2. 2FSK�ź�����
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
    
    % 3. 2PSK�ź�����
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
    
    % ����FFTƵ��
    frequencies = (0:N-1)*(Fs/N);  % Ƶ����
    
    % ����2ASKƵ��
    ask_fft = fft(ask_signal);
    ask_spectrum = abs(ask_fft/N);
    ask_spectrum = ask_spectrum(1:N/2+1);
    ask_spectrum(2:end-1) = 2*ask_spectrum(2:end-1); % ������
    
    % ����2FSKƵ��
    fsk_fft = fft(fsk_signal);
    fsk_spectrum = abs(fsk_fft/N);
    fsk_spectrum = fsk_spectrum(1:N/2+1);
    fsk_spectrum(2:end-1) = 2*fsk_spectrum(2:end-1); % ������
    
    % ����2PSKƵ��
    psk_fft = fft(psk_signal);
    psk_spectrum = abs(psk_fft/N);
    psk_spectrum = psk_spectrum(1:N/2+1);
    psk_spectrum(2:end-1) = 2*psk_spectrum(2:end-1); % ������
    
    % ����Ƶ��ͼ
    freq_range = frequencies(1:N/2+1)/1e6; % ת��ΪMHz
    
    % 2ASKƵ��
    subplot(length(bit_rates), 3, (br_idx-1)*3+1);
    plot(freq_range, ask_spectrum);
    xlim([1.9 2.1]); 
    ylim([0 max(ask_spectrum)*1.1]);
    title(sprintf('2ASKƵ�� (%d kbps)', bit_rate/1000));
    xlabel('Ƶ�� (MHz)');
    ylabel('����');
    grid on;
    
    % ��Ӵ����ע
    bw = 2*bit_rate; % ASK���۴���
    line([fc/1e6-bw/2e6 fc/1e6-bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    line([fc/1e6+bw/2e6 fc/1e6+bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    text(1.95, max(ask_spectrum)*0.9, sprintf('BW=%.1fkHz', bw/1000), 'Color', 'r');
    
    % 2FSKƵ��
    subplot(length(bit_rates), 3, (br_idx-1)*3+2);
    plot(freq_range, fsk_spectrum);
    xlim([1.8 2.2]); 
    ylim([0 max(fsk_spectrum)*1.1]);
    title(sprintf('2FSKƵ�� (%d kbps)', bit_rate/1000));
    xlabel('Ƶ�� (MHz)');
    ylabel('����');
    grid on;
    
    % �����Ƶ��ע
    line([(fc-f_shift)/1e6 (fc-f_shift)/1e6], ylim, 'Color', 'g', 'LineStyle', '--');
    line([(fc+f_shift)/1e6 (fc+f_shift)/1e6], ylim, 'Color', 'g', 'LineStyle', '--');
    text(1.85, max(fsk_spectrum)*0.9, sprintf('f1=%.4fMHz', (fc-f_shift)/1e6), 'Color', 'g');
    text(2.05, max(fsk_spectrum)*0.9, sprintf('f2=%.4fMHz', (fc+f_shift)/1e6), 'Color', 'g');
    
    % 2PSKƵ��
    subplot(length(bit_rates), 3, (br_idx-1)*3+3);
    plot(freq_range, psk_spectrum);
    xlim([1.9 2.1]); 
    ylim([0 max(psk_spectrum)*1.1]);
    title(sprintf('2PSKƵ�� (%d kbps)', bit_rate/1000));
    xlabel('Ƶ�� (MHz)');
    ylabel('����');
    grid on;
    
    % ��Ӵ����ע
    bw = 2*bit_rate; % PSK���۴���
    line([fc/1e6-bw/2e6 fc/1e6-bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    line([fc/1e6+bw/2e6 fc/1e6+bw/2e6], ylim, 'Color', 'r', 'LineStyle', '--');
    text(1.95, max(psk_spectrum)*0.9, sprintf('BW=%.1fkHz', bw/1000), 'Color', 'r');
end

% ����ͼ���������
%sgtitle(sprintf('��ͬ���������ֵ����ź�Ƶ�� (��Ƶ%.1fMHz, ������%.1fMHz)', fc/1e6, Fs/1e6));

% ���ͼ��˵��
annotation('textbox', [0.15, 0.005, 0.7, 0.05], 'String', ...
    sprintf('FFT����: %d | 2FSKƵƫ: %.0f kHz | �ܱ�����: %d/%d/%d (��Ӧ6/8/10kbps)', ...
    N, f_shift/1000, ...
    floor(N*bit_rates(1)/Fs), ...
    floor(N*bit_rates(2)/Fs), ...
    floor(N*bit_rates(3)/Fs)), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center');