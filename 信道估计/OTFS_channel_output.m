 
function r = OTFS_channel_output(N,M,taps,delay_taps,Doppler_taps,chan_coef,noiseVar,s)
%% wireless channel and noise 
L = max(delay_taps);%最大的时延
s = [s(N*M-L+1:N*M);s]; %加入循环前缀编码
s_chan = 0; %信道输入信号初始化
for itao = 1:taps
    s_chan = s_chan+chan_coef(itao)*circshift([s.*exp(1j*2*pi/M *(-L:-L+length(s)-1)*Doppler_taps(itao)/N).';zeros(L,1)],delay_taps(itao));
    %%s_chan是71*1维数组
end

noise = sqrt(noiseVar/2)*(randn(size(s_chan)) + 1i*randn(size(s_chan)));%信道噪声
r = s_chan+noise;
r = r(L+1:L+(N*M));%discard cp(去掉循环前缀，也就是输出68*1维数组的后64位）
end