function [est_delay_tap, est_doppler_tap, est_chan_coef, score_map, k_list, l_list] = ...
    OTFS_channel_est_pilot_general(Y_DD, pilot_rows, pilot_cols, pilot_seq, ...
                                   max_delay_tap, max_doppler_tap, max_search_paths, ...
                                   threshold_score, ...
                                   local_win_k, local_win_l, ...
                                   min_sep_k, min_sep_l, ...
                                   rel_amp_th, abs_amp_th)
% ============================================================
% 真实OTFS链路下的通用导频信道估计（自适应路径数版本）
%
% 功能：
% 1) 支持任意个导频
% 2) 支持负Doppler搜索
% 3) score_map联合检测
% 4) 局部峰检测
% 5) 峰值去重
% 6) 联合LS估计路径增益
% 7) 根据估计增益自动删弱路径
%
% 输入:
%   Y_DD              : 接收DD域矩阵 (N x M)
%   pilot_rows        : 导频行坐标列向量
%   pilot_cols        : 导频列坐标列向量
%   pilot_seq         : 导频复数序列列向量
%   max_delay_tap     : delay搜索范围 [0, max_delay_tap]
%   max_doppler_tap   : doppler搜索范围 [-max_doppler_tap, max_doppler_tap]
%   max_search_paths  : 候选输出上限（仅控制复杂度，不代表真实路径数）
%   threshold_score   : score_map门限
%   local_win_k       : Doppler方向局部峰窗口半径
%   local_win_l       : Delay方向局部峰窗口半径
%   min_sep_k         : Doppler方向最小分离
%   min_sep_l         : Delay方向最小分离
%   rel_amp_th        : 相对幅度门限（相对最强路径），如 0.08
%   abs_amp_th        : 绝对幅度门限，如 0.02
%
% 输出:
%   est_delay_tap
%   est_doppler_tap
%   est_chan_coef
%   score_map
%   k_list
%   l_list
% ============================================================

    [N, M] = size(Y_DD);

    pilot_rows = pilot_rows(:);
    pilot_cols = pilot_cols(:);
    pilot_seq  = pilot_seq(:);

    numPilots = length(pilot_rows);

    if length(pilot_cols) ~= numPilots || length(pilot_seq) ~= numPilots
        error('pilot_rows, pilot_cols, pilot_seq 长度必须一致。');
    end

    if nargin < 13 || isempty(rel_amp_th)
        rel_amp_th = 0.08;
    end
    if nargin < 14 || isempty(abs_amp_th)
        abs_amp_th = 0.02;
    end

    k_list = (-max_doppler_tap : max_doppler_tap).';
    l_list = (0 : max_delay_tap).';

    numK = length(k_list);
    numL = length(l_list);

    %% 1) 计算 score_map
    score_map = zeros(numK, numL);
    p_energy = sum(abs(pilot_seq).^2);

    for ik = 1:numK
        k = k_list(ik);

        for il = 1:numL
            l = l_list(il);

            rx = zeros(numPilots,1);
            valid = true;

            for i = 1:numPilots
                rr = pilot_rows(i) + k;
                cc = pilot_cols(i) + l;

                if rr < 1 || rr > N || cc < 1 || cc > M
                    valid = false;
                    break;
                end

                rx(i) = Y_DD(rr, cc);
            end

            if ~valid
                score_map(ik, il) = 0;
                continue;
            end

            corr_val = pilot_seq' * rx;
            rx_energy = sum(abs(rx).^2);

            score_map(ik, il) = abs(corr_val)^2 / (p_energy * rx_energy + eps);
        end
    end

    %% 2) 局部峰检测 + 阈值筛选
    cand_ik = [];
    cand_il = [];
    cand_score = [];

    for ik = 1:numK
        for il = 1:numL
            cur_val = score_map(ik, il);

            if cur_val <= threshold_score
                continue;
            end

            ik_min = max(1, ik - local_win_k);
            ik_max = min(numK, ik + local_win_k);
            il_min = max(1, il - local_win_l);
            il_max = min(numL, il + local_win_l);

            local_block = score_map(ik_min:ik_max, il_min:il_max);

            if cur_val >= max(local_block(:))
                cand_ik(end+1,1) = ik;
                cand_il(end+1,1) = il;
                cand_score(end+1,1) = cur_val;
            end
        end
    end

    if isempty(cand_score)
        est_delay_tap = [];
        est_doppler_tap = [];
        est_chan_coef = [];
        return;
    end

    %% 3) 候选峰按强度排序
    [cand_score, sort_idx] = sort(cand_score, 'descend');
    cand_ik = cand_ik(sort_idx);
    cand_il = cand_il(sort_idx);

    %% 4) 峰值去重 + 候选上限截断
    sel_ik = [];
    sel_il = [];

    for n = 1:length(cand_score)
        ik_now = cand_ik(n);
        il_now = cand_il(n);

        keep_flag = true;

        for m = 1:length(sel_ik)
            if abs(ik_now - sel_ik(m)) <= min_sep_k && ...
               abs(il_now - sel_il(m)) <= min_sep_l
                keep_flag = false;
                break;
            end
        end

        if keep_flag
            sel_ik(end+1,1) = ik_now;
            sel_il(end+1,1) = il_now;

            if length(sel_ik) >= max_search_paths
                break;
            end
        end
    end

    %% 5) LS估计路径增益
    numSel = length(sel_ik);

    est_delay_tap = zeros(numSel,1);
    est_doppler_tap = zeros(numSel,1);
    est_chan_coef = zeros(numSel,1);

    denom = sum(abs(pilot_seq).^2);

    for p = 1:numSel
        k_hat = k_list(sel_ik(p));
        l_hat = l_list(sel_il(p));

        est_doppler_tap(p) = k_hat;
        est_delay_tap(p)   = l_hat;

        rx = zeros(numPilots,1);

        for i = 1:numPilots
            rr = pilot_rows(i) + k_hat;
            cc = pilot_cols(i) + l_hat;
            rx(i) = Y_DD(rr, cc);
        end

        est_chan_coef(p) = (pilot_seq' * rx) / denom;
    end

    %% 6) 自动删弱路径
    amp_all = abs(est_chan_coef);

    if isempty(amp_all)
        return;
    end

    amp_max = max(amp_all);
    keep_idx = (amp_all > abs_amp_th) & (amp_all > rel_amp_th * amp_max);

    est_delay_all   = est_delay_tap;
    est_doppler_all = est_doppler_tap;
    est_chan_all    = est_chan_coef;

    est_delay_tap   = est_delay_tap(keep_idx);
    est_doppler_tap = est_doppler_tap(keep_idx);
    est_chan_coef   = est_chan_coef(keep_idx);

    %% 7) 保底：全删空则保留最强一路
    if isempty(est_chan_coef)
        [~, idx_max] = max(amp_all);
        est_delay_tap   = est_delay_all(idx_max);
        est_doppler_tap = est_doppler_all(idx_max);
        est_chan_coef   = est_chan_all(idx_max);
    end
end