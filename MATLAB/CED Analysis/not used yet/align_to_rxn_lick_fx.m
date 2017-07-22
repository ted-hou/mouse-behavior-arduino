% function []...
%     = align_to_rxn_lick_fx(analog_times_by_trial,...
%                                 analog_values_by_trial,...
%                                 f_lick_operant_no_rew,...
%                                 f_lick_operant_rew,...
%                                 f_lick_pavlovian,...
%                                 num_trials,...
%                                 signal)

%  Created 4/21/17 -- dependent on first_lick_grabber.m (f_lick_rxn)
                            

% % defaults:
analog_times_by_trial = SNc_times_by_trial;
analog_values_by_trial = SNc_values_by_trial;
signal = 'SNc'
f_lick_rxn = f_lick_rxn;
% note: all_first_licks = f_lick_operant_no_rew + f_lick_operant_rew + f_lick_pavlovian + f_lick_ITI;


% 1. Find the times of the analog values (positions):
analog_positions_by_trial = NaN(num_trials, size(analog_values_by_trial,2));

for i_trial = 1:num_trials
    positions_in_this_trial = find(analog_values_by_trial(i_trial,:) > 0);
    % make this the right length:
    number_NaNs_to_append = size(analog_values_by_trial, 2) - length(positions_in_this_trial);
    positions_in_this_trial(1, length(positions_in_this_trial)+1:length(positions_in_this_trial)+number_NaNs_to_append) = NaN;
    analog_positions_by_trial(i_trial, :) = positions_in_this_trial;
end


% Align the positions to the cue by subtracting 1500 from each position:
cue_aligned_positions = analog_positions_by_trial - 1500;
rxn_licks_wrt_cue = f_lick_rxn - 1.5;

% Now convert the cue aligned positions to seconds (right now is in ms, but
% licks are recorded as # of seconds after the cue
cue_aligned_times_sec = cue_aligned_positions./1000;

cue_aligned_values = NaN(num_trials, size(cue_aligned_times_sec,2));
% Now, remove all the NaN's from the beginning of the values to get aligned
% to the new times fx:
for i_trial = 1:num_trials
    this_trial = analog_values_by_trial(i_trial,:);
    values_this_trial = this_trial(~isnan(this_trial));
    num_NaNs_this_trial = length(find(isnan(this_trial)));
    values_this_trial(1, length(values_this_trial)+1:length(values_this_trial)+num_NaNs_this_trial) = NaN;
    cue_aligned_values(i_trial, :) = values_this_trial;
end

rxn_lick_aligned_times = NaN(num_trials, size(cue_aligned_times_sec,2));
rxn_lick_aligned_values = cue_aligned_values;
% Now, align the times to the first lick:
for i_trial = 1:num_trials
    if rxn_licks_wrt_cue(i_trial) ~= -1.5 % not zero because we aligned to the cue
        rxn_lick_aligned_times(i_trial, :) = cue_aligned_times_sec(i_trial, :) - (rxn_licks_wrt_cue(i_trial));
    else
%         disp(['No licks on trial', num2str(i_trial)])
        rxn_lick_aligned_times(i_trial, :) = NaN(1, size(analog_times_by_trial,2));
        rxn_lick_aligned_values(i_trial, :) = NaN(1, size(analog_values_by_trial,2));
    end
end


%% Now plot in two ways: 
%       1. Average of all lick-aligned trials
%       2. Overlay of smoothed lick-aligned trials



% To average the trials, need to get in the vector again aligned at the
% same position. Easiest way may be to split them into 2 vectors: those
% before and after the lick:
pre_lick_times_by_trial = NaN(num_trials, size(analog_times_by_trial,2));
post_lick_times_by_trial = NaN(num_trials, size(analog_times_by_trial,2));    %NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

pre_lick_values_by_trial = NaN(num_trials, size(analog_times_by_trial,2));
post_lick_values_by_trial = NaN(num_trials, size(analog_times_by_trial,2));


% Do the prelick: try doing the whole thing in reverse
num_of_cols = size(analog_times_by_trial,2);                % 18501
rev_trial_num = abs(-num_trials : -1);                      % [num_trials:1]
rev_col_nums = abs(-num_of_cols : -1);                      % [18501:1]


for i_trial = rev_trial_num         %[num_trials:1] - fill array from last trial to the first trial
  prelick_position = num_of_cols;
  for i_time = rev_col_nums       % fill the array from the right (time closest to lick)
        if find(0 > rxn_lick_aligned_times(i_trial, i_time)) % means we passed the lick time and now are on the pre lick side
            % start adding times to the end of the array:
            pre_lick_times_by_trial(i_trial, prelick_position) = rxn_lick_aligned_times(i_trial, i_time);
            pre_lick_values_by_trial(i_trial, prelick_position) = rxn_lick_aligned_values(i_trial, i_time);
            prelick_position = prelick_position - 1;
        end
  end
end




% Now the post lick:

for i_trial = 1:num_trials
    post_lick_pos = 1;
  for i_time = 1:num_of_cols         % fill the array from left to right
        if find(0 < rxn_lick_aligned_times(i_trial, i_time)) % means we passed the lick time and now are on the post lick side
            % start adding times to the array:
            post_lick_times_by_trial(i_trial, post_lick_pos) = rxn_lick_aligned_times(i_trial, i_time);
            post_lick_values_by_trial(i_trial, post_lick_pos) = rxn_lick_aligned_values(i_trial, i_time);
            post_lick_pos = post_lick_pos + 1;
        end
    end
end
    

% combine the arrays:
rxn_lick_aligned_times_for_ave = horzcat(pre_lick_times_by_trial, post_lick_times_by_trial);
rxn_lick_aligned_values_for_ave = horzcat(pre_lick_values_by_trial, post_lick_values_by_trial);

% take the average: 
ave_rxn_lick_times = nanmean(rxn_lick_aligned_times_for_ave, 1);
ave_rxn_lick_values = nanmean(rxn_lick_aligned_values_for_ave, 1);


%------- Plot the average ----------%
% figure, plot(ave_rxn_lick_times,ave_rxn_lick_values)
% hold on
% plot([0,0], [min(ave_rxn_lick_values), max(ave_rxn_lick_values)], 'r-', 'linewidth', 3)




%% 2. Plot the overlay of smoothed lick-aligned trials
smoothed_rxn_lick_aligned_values = NaN(size(rxn_lick_aligned_values));
for i_trial = 1:num_trials
    % smooth each trial
    smoothed_rxn_lick_aligned_values(i_trial, :) = smooth(rxn_lick_aligned_values(i_trial, :), 50, 'gauss');
end

normalized_smoothed_rxn_lick_aligned_values = NaN(size(rxn_lick_aligned_values));
% Normalize the values in each trial:
for i_trial = 1:num_trials
    % smooth each trial
    normalized_smoothed_rxn_lick_aligned_values(i_trial, :) = smoothed_rxn_lick_aligned_values(i_trial, :) .*1/max(smoothed_rxn_lick_aligned_values(i_trial, :));
end
% 
% figure,
% for i_trial = 1:num_trials
%     plot(rxn_lick_aligned_times(i_trial,:), normalized_smoothed_rxn_lick_aligned_values(i_trial, :))
%     hold on
% end
% hold on
% plot([0,0], [min(ave_rxn_lick_values), max(ave_rxn_lick_values)], 'r-', 'linewidth', 3)


