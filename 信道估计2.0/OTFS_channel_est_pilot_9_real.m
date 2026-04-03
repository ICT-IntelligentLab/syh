function [est_delay_tap, est_doppler_tap, est_chan_coef, score_map, k_list, l_list] = ...
    OTFS_channel_est_pilot_9_real(Y_DD, pilot_rows, pilot_cols, pilot_seq, ...
                                  max_delay_tap, max_doppler_tap, numPaths, ...
                                  threshold_score, ...
                                  local_win_k, local_win_l, ...
                                  min_sep_k, min_sep_l)


    [N, M] = size(Y_DD);

    pilot_rows = pilot_rows(:);
    pilot_cols = pilot_cols(:);
    pilot_seq  = pilot_seq(:);

    numPilots = length(pilot_rows);

    if length(pilot_cols) ~= numPilots || length(pilot_seq) ~= numPilots
        error('pilot_rows, pilot_cols, pilot_seq 长度必须一致。');
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

            % 归一化相关分数：一个候选偏移对应一个标量
            corr_val = pilot_seq' * rx;
            rx_energy = sum(abs(rx).^2);

            score_map(ik, il) = abs(corr_val)^2 / (p_energy * rx_energy + eps);
        end
    end

    %% 2) 局部峰检测
    cand_ik = [];
    cand_il = [];
    cand_score = [];
% threshold_score_use = max(0.15, 0.45 * max(score_map(:)));
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

    % %% 4) 0 tap特判
    % keep_after_zero_rule = true(length(cand_score),1);
    % 
    % for n = 1:length(cand_score)
    %     k_hat = k_list(cand_ik(n));
    %     l_hat = l_list(cand_il(n));
    % 
    %     if (k_hat == 0) || (l_hat == 0)
    %         if n < length(cand_score)
    %             diff_score = cand_score(n) - cand_score(n+1);
    %             if diff_score > zeroTapDiffTh
    %                 keep_after_zero_rule(n) = false;
    %             end
    %         end
    %     end
    % end
    % 
    % cand_ik = cand_ik(keep_after_zero_rule);
    % cand_il = cand_il(keep_after_zero_rule);
    % cand_score = cand_score(keep_after_zero_rule);
    % 
    % if isempty(cand_score)
    %     est_delay_tap = [];
    %     est_doppler_tap = [];
    %     est_chan_coef = [];
    %     return;
    % end

    %% 5) 峰值去重
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

            if length(sel_ik) >= numPaths
                break;
            end
        end
    end

    %% 6) 联合LS估计路径增益
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

        % LS: rx ≈ h * pilot_seq
        est_chan_coef(p) = (pilot_seq' * rx) / denom;
    end
end