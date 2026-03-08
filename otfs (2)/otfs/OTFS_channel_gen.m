function [taps,delay_taps,Doppler_taps,chan_coef] = OTFS_channel_gen(N,M)
%% Channel for testing%%%%%
%channel wih 4 taps of uniform power%%% 
taps = 4;   %抽头数设置为4
delay_taps = [0 1 2 3]; %时延抽头设置为4
Doppler_taps = [0 1 2 3 ];   %多普勒域抽头设置为4
pow_prof = (1/taps) * (ones(1,taps)); %每一个抽头都分到1/4的功率
chan_coef = sqrt(pow_prof).*(sqrt(1/2) * (randn(1,taps)+1i*randn(1,taps))); %每一个抽头生成一个信道系数，一共四个信道系数