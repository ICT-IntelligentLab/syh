function [taps,delay_taps,Doppler_taps,chan_coef] = OTFS_channel_gen(max_delay_tap,max_doppler_tap,max_taps,taps_random)
%% Channel for testing%%%%%
%channel wih 4 taps of uniform power%%% 
 if strcmpi(taps_random, 'True')
     taps =randi([1 max_taps]);   %抽头数
  else
      taps =max_taps;   %抽头数
  end

low_doppler=-max_doppler_tap;up_doppler=max_doppler_tap;
low_delay=0;       up_delay=max_delay_tap;
flag=1;
while flag==1
    Doppler_taps = randi([low_doppler,up_doppler],1,taps); %时延抽头
    delay_taps =  randi([low_delay,up_delay],1,taps);   %多普勒域抽头
    
    pairs = [Doppler_taps(:), delay_taps(:)];   % 转成 Nx2 矩阵，每行是一对
    [~, ia, ~] = unique(pairs, 'rows');
    
    if length(ia) == taps
         flag=0;
    end
end
pow_prof = (1/taps) * (ones(1,taps)); %每一个抽头都分到的功率
chan_coef = sqrt(pow_prof).*(sqrt(1/2) * (randn(1,taps)+1i*randn(1,taps))); %每一个抽头生成一个信道系数，一共四个信道系数

end