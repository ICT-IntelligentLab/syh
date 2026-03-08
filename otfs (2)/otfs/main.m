% Author: [YZ ]
% Date: [2024/9/8 ]
% Description: [Brief description of the code’s functionality]
% Version: [Version number, if applicable]
 
 
clc
clear all
close all
tic
%% OTFS parameters%%%%%%%%%%
% number of symbol
N = 16; %码元数为8
% number of subcarriers
M = 32;  %载波数为8
Nifft=N*M;
 
 
 
% size of constellation
M_mod = 4;  %进制数为4，那么一码元就包含2比特
M_bits = log2(M_mod);
% average energy per data symbol
eng_sqrt = (M_mod==2)+(M_mod~=2)*sqrt((M_mod-1)/6*(2^2));   %符号的平均能量energy square root
% number of symbols per frame
Protect_Front=8;
data_row_range=4:12;
data_col_range=9:24;
Pilot_row_index=8;
Pilot_col_index=1;
 
DATA_BLOCK_N=max(data_row_range)-min(data_row_range)+1;
DATA_BLOCK_M=max(data_col_range)-min(data_col_range)+1;
N_syms_perfram = DATA_BLOCK_N*DATA_BLOCK_M;   %一帧中包含的符号数=单个载波包含的码元数*载波个数\
% number of bits per frame
N_bits_perfram = N_syms_perfram*2;    %
 
%信噪比范围
SNR_dB =0:3:18;    %信噪比dB从0~15，间隔5dB取样，length为4
SNR = 10.^(SNR_dB/10);  %dB和10进制换算
noise_var_sqrt = sqrt(1./SNR);  %噪声
sigma_2 = abs(eng_sqrt*noise_var_sqrt).^2;
 
 
baud_rate=6400;
tau = [0 2e-3 3e-3 4e-3 5e-3]; % 五条多径的时延
pdb = [0 -4 -8 -12 -16]; % 五条多径的平均路径增益
fdmax=6.5;
channel = comm.RayleighChannel(...
'SampleRate',baud_rate, ...
'PathDelays',tau, ... % 五条多径的时延
'AveragePathGains',pdb, ... % 五条多径的平均路径增益
'MaximumDopplerShift',fdmax, ...
'NormalizePathGains',true,...
'PathGainsOutputPort',true,...
'RandomStream','mt19937ar with seed',...
'Seed',2);
 
%%
 
N_fram = 10;
PAPR_dB_SUM=0;
err_ber = zeros(length(SNR_dB),1); %生成0矩阵，length返回 X 中最大数组维度的长度，此时为4,即此命令生成4*1维的0矩阵
 
fprintf('Start to do OTFS simulation. Please wait...\n');
for iesn0 = 1:length(SNR_dB)    %1~4
    SNR_temp = SNR_dB(iesn0);   %SNR_temp取0,5,10,15
    SNR_temp 
    for ifram = 1:N_fram 
        rng(3);
        %% random input bits generation and 4QAM modulation%%%%%
        data_info_bit = randi([0,1],N_bits_perfram,1); %生成0或1的随机数，且维数是128*1，也就是生成了一个帧结构中包含的bit数
        data_bit      =  reshape(data_info_bit,N_syms_perfram,M_bits); 
        data_temp = bi2de(data_bit);%二进制数转换成10进制数，reshape为重组数组，语法为reshape(A,a,b)将矩阵A重构为a*b的矩阵
 
        x_temp = qammod(data_temp,M_mod, 'gray'); %输出使用正交幅度调制4-QAM消息信号X的复包络,gray格雷码编码
        x_temp = reshape(x_temp,DATA_BLOCK_N,DATA_BLOCK_M); %将64*1的x重组成8*8数组
        x=zeros(N,M);
        pilot=zeros(N,Protect_Front);
        pilot(Pilot_row_index,Pilot_col_index)=10;
        x(:,1:Protect_Front)=pilot;
 
        x(data_row_range,data_col_range)=x_temp;
   
        
        %% OTFS modulation%%%%
        s = OTFS_modulation(N,M,x);
        % 使用 imagesc 函数绘制二维图
        % figure(3)
        % magnitude=abs(x);
        % imagesc(magnitude);
        % % 添加颜色条，显示颜色映射
        % colorbar;
        % % 添加标题和轴标签
        % title('2D Plot of Array y');
        % xlabel('X Axis');
        % ylabel('Y Axis');
 
 
 
        [taps,delay_taps,Doppler_taps,chan_coef] = OTFS_channel_gen(N,M);
 
        %% OTFS channel output%%%%%
        r = OTFS_channel_output(N,M,taps,delay_taps,Doppler_taps,chan_coef,sigma_2(iesn0),s);
 
        %%           add noise    根据过信道信道能量 以及信噪比 计算所加噪声功率      %%
 
 
 
        %% 信道估计信道均衡%%%% y0_down_duopule
        y = OTFS_demodulation(N,M,r);
 
        % figure(2);
        % % 使用 imagesc 函数绘制二维图
        % magnitude=abs(y);
        % imagesc(magnitude);
        % % 添加颜色条，显示颜色映射
        % colorbar;
        % % 添加标题和轴标签
        % title('2D Plot of Array y');
        % xlabel('X Axis');
        % ylabel('Y Axis');
 
        threshold=0.01;
        k=1;
        for i=1:N
            for j=1:Protect_Front
                if(abs(y(i,j))>max(abs(y(:)))*0.1)
                    est_delay_tap(k)=j-1;
                    est_doppler_tap(k)=i-Pilot_row_index;
                    est_chan_coef(k) =y(i,j)*exp(-1i*est_doppler_tap(k));
                    est_chan_coef(k) =y(i,j);
                    k=k+1;
                end
            end
        end
        est_chan_coef=est_chan_coef./10;
        tic
        %% 估计信道mp检测
        x_est = OTFS_mp_detector(N,M,M_mod,length(est_delay_tap),est_delay_tap,est_doppler_tap,est_chan_coef,sigma_2(iesn0),y);
        %% 完美信道mp检测
        % x_est = OTFS_mp_detector(N,M,M_mod,taps,delay_taps,Doppler_taps,chan_coef,sigma_2(iesn0),y);
        toc;
        % figure(3);
        % % 使用 imagesc 函数绘制二维图
        % magnitude=abs(x_est);
        % imagesc(magnitude);
        % % 添加颜色条，显示颜色映射
        % colorbar;
        % % 添加标题和轴标签
        % title('2D Plot of Array y');
        % xlabel('X Axis');
        % ylabel('Y Axis');
        %% message passing detector%%%%  
        %% output bits and errors count%%%%%
        data_demapping_temp = qamdemod(x_est,M_mod,'gray');
        data_demapping=zeros(DATA_BLOCK_N,DATA_BLOCK_M);
        data_demapping=data_demapping_temp(data_row_range,data_col_range);
 
        data_info_est = reshape(de2bi(data_demapping,M_bits),N_bits_perfram,1);
        errors = sum(xor(data_info_est,data_info_bit));
        err_rate=errors/N_bits_perfram;
        err_ber(iesn0) = errors + err_ber(iesn0);    
 
    end
    PAPR=PAPR_dB_SUM/N_fram
    PAPR_dB_SUM=0;
    err_ber_fram_temp = err_ber(iesn0) / N_bits_perfram / N_fram;
    err_ber_fram_temp      %表达式加;可以隐藏输出
    err_ber_fram(iesn0) = err_ber_fram_temp;
end
 
figure(1)
 
err_ber_fram;
semilogy(SNR_dB, err_ber_fram,'-*');
title(sprintf('OTFS BER'))
ylabel('BER'); xlabel('SNR in dB');
grid on
toc