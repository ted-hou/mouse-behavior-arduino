function [lick_triggered_trials,...
         lick_triggered_ave_noNaN,...
         lick_triggered_ave_ignore_NaN] = lick_triggered_ave_fx(dummy_data,...
                                             dummy_licks,...
                                             num_trials,...
                                             cue_position)

% test with:
%  lick_triggered_ave_fx(dummy_data, dummy_licks, num_trials, cue_position, num_trials)
%  lick_triggered_ave_fx(d22_SNc_values_by_trial, d22_all_first_licks, num_trials, 1501)

% function [ave_f_lick_times,...
%           ave_f_lick_values,...
%           scored_lick_aligned_times,...
%           smoothed_scored_lick_aligned_values,...
%           normalized_smoothed_scored_lick_aligned_values]...
%                     = align_to_lick_fx(analog_times_by_trial,...
%                                        analog_values_by_trial,...
%                                        all_first_licks,...
%                                        num_trials)
%
% Modified ahamilos 7-20-17
% 
% 
%  Update Log:
%       7-20-17: Seems like there may be an error with super6 data application - looking for errors
%
%
%
% Uses output of first_lick_grabber.m
% Analog data is by trial (rows = trial, column = timepoints)
% all_first_licks does not include early aborts where was train of rxn
%   licks, also doesn't include rxns
% f_lick_rxn includes all 1st rxns to cue

% Outline:
%   For each trial in analog data - make time zero the time of first lick
%       by subtracting the current timepoint from the first lick
%   Put the values in a new array that has one column for timepoints,
%       another column for the values
%   I suppose make a cell array of each trial so you can plot them all
%       together? -- no need! you'll have an array of corrected timepoints
% 

% defaults: 
% analog_times_by_trial = DLS_times_by_trial;
% analog_values_by_trial = DLS_values_by_trial;
% note: all_first_licks = f_lick_operant_no_rew + f_lick_operant_rew + f_lick_pavlovian + f_lick_ITI;




% % let's start from the beginning with dummy data:
% dummy_data = [NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1 1 1 1 1 10 10 1 1 1;...
%              NaN NaN NaN NaN NaN NaN NaN 1 1 1 1 1 1 1 1 1 1 10 10 1;...
%              NaN 1 1 1 1 1 1 1 1 1 1 10 10 1 1 1 1 1 1 NaN;...
%              NaN NaN NaN 1 1 1 1 1 1 1 1 1 10 10 1 1 1 1 1 NaN];

% dummy_licks = [.006, .008, .002, .003];
% num_trials = 4;
% % this data is already aligned by cue on time at position 11 (analogous to the real lick data)
% % and input to the function should be the cue_on_position in the original dataset (1501 I think)

% cue_position = 11;

% first lick times are in seconds wrt the cue. We can convert these to the position
lick_positions = 1000*dummy_licks + (cue_position-1);

% find all positions including lick position and to the right
right_of_and_lick = NaN(size(dummy_data));


for i_trial = 1:num_trials
    % find the values to append:
    values_to_add = dummy_data(i_trial, lick_positions(i_trial):size(dummy_data,2));
    right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
end

% find all positions left of lick, not including the lick
left_of_lick = NaN(size(dummy_data));

for i_trial = 1:num_trials
    % find the values to append:
    lick_end = lick_positions(i_trial)-1;
    values_to_add = dummy_data(i_trial, 1:lick_end);
    pos_start = size(left_of_lick,2)-length(values_to_add)+1;
    pos_end = size(left_of_lick,2);
    left_of_lick(i_trial,pos_start:pos_end) = values_to_add;
end


% combine the arrays. 
lick_triggered_trials = horzcat(left_of_lick, right_of_and_lick);

% Now position 21 is the position of the lick. Make a new time array:
time_array = NaN(1, size(lick_triggered_trials,2));
position_zero = size(left_of_lick,2) + 1;
position_max = length(time_array) - position_zero;
time_array(position_zero:end) = [0:position_max]; % this will be time in ms
position_zero_1 = position_zero - 1;
time_array(1:position_zero_1) = (-position_zero_1:-1); 


%% Calculating lick-triggered ave
% first, let's see how far we can see if we take the lick-triggered average, excluding any times where one of the trials has NaN
% regular mean function does not calc if one of the inputs is NaN
lick_triggered_ave_noNaN = mean(lick_triggered_trials,1);
% then let's try where we ignore nan with nanmean:
lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

%% Plotting the lick-triggered ave versions:
figure
subplot(1,2,1)
plot(time_array, lick_triggered_ave_noNaN)

subplot(1,2,2)
plot(time_array, lick_triggered_ave_ignore_NaN)







% % I don't see why I need to do this part, so commenting out
% % 1. Find the times of the analog values (positions):
% analog_positions_by_trial = NaN(num_trials, size(analog_values_by_trial,2));

% for i_trial = 1:num_trials
%     positions_in_this_trial = find(analog_values_by_trial(i_trial,:) > 0);
%     % make this the right length:
%     number_NaNs_to_append = size(analog_values_by_trial, 2) - length(positions_in_this_trial);
%     positions_in_this_trial(1, length(positions_in_this_trial)+1:length(positions_in_this_trial)+number_NaNs_to_append) = NaN;
%     analog_positions_by_trial(i_trial, :) = positions_in_this_trial;
% end


% % Align the positions to the cue by subtracting 1500 from each position:
% cue_aligned_positions = analog_positions_by_trial - 1500;
% all_first_licks_wrt_cue = all_first_licks - 1.5;

% % Now convert the cue aligned positions to seconds (right now is in ms, but
% % licks are recorded as # of seconds after the cue
% cue_aligned_times_sec = cue_aligned_positions./1000;

% cue_aligned_values = NaN(num_trials, size(cue_aligned_times_sec,2));
% % Now, remove all the NaN's from the beginning of the values to get aligned
% % to the new times fx:
% for i_trial = 1:num_trials
%     this_trial = analog_values_by_trial(i_trial,:);
%     values_this_trial = this_trial(~isnan(this_trial));
%     num_NaNs_this_trial = length(find(isnan(this_trial)));
%     values_this_trial(1, length(values_this_trial)+1:length(values_this_trial)+num_NaNs_this_trial) = NaN;
%     cue_aligned_values(i_trial, :) = values_this_trial;
% end

% scored_lick_aligned_times = NaN(num_trials, size(cue_aligned_times_sec,2));
% scored_lick_aligned_values = cue_aligned_values;
% % Now, align the times to the first lick:
% for i_trial = 1:num_trials
%     if all_first_licks_wrt_cue(i_trial) ~= -1.5 % not zero because we aligned to the cue
%         scored_lick_aligned_times(i_trial, :) = cue_aligned_times_sec(i_trial, :) - (all_first_licks_wrt_cue(i_trial));
%     else
% %         disp(['No licks on trial', num2str(i_trial)])
%         scored_lick_aligned_times(i_trial, :) = NaN(1, size(analog_times_by_trial,2));
%         scored_lick_aligned_values(i_trial, :) = NaN(1, size(analog_values_by_trial,2));
%     end
% end


% %% Now plot in two ways: 
% %       1. Average of all lick-aligned trials
% %       2. Overlay of smoothed lick-aligned trials



% % To average the trials, need to get in the vector again aligned at the
% % same position. Easiest way may be to split them into 2 vectors: those
% % before and after the lick:
% pre_lick_times_by_trial = NaN(num_trials, size(analog_times_by_trial,2));
% post_lick_times_by_trial = NaN(num_trials, size(analog_times_by_trial,2));		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

% pre_lick_values_by_trial = NaN(num_trials, size(analog_times_by_trial,2));
% post_lick_values_by_trial = NaN(num_trials, size(analog_times_by_trial,2));


% % Do the prelick: try doing the whole thing in reverse
% num_of_cols = size(analog_times_by_trial,2);                % 18501
% rev_trial_num = abs(-num_trials : -1);                      % [num_trials:1]
% rev_col_nums = abs(-num_of_cols : -1);                      % [18501:1]


% for i_trial = rev_trial_num         %[num_trials:1] - fill array from last trial to the first trial
% 	prelick_position = num_of_cols;
% 	for i_time = rev_col_nums       % fill the array from the right (time closest to lick)
%         if find(0 > scored_lick_aligned_times(i_trial, i_time)) % means we passed the lick time and now are on the pre lick side
%             % start adding times to the end of the array:
%             pre_lick_times_by_trial(i_trial, prelick_position) = scored_lick_aligned_times(i_trial, i_time);
%             pre_lick_values_by_trial(i_trial, prelick_position) = scored_lick_aligned_values(i_trial, i_time);
%             prelick_position = prelick_position - 1;
%         end
% 	end
% end




% % Now the post lick:

% for i_trial = 1:num_trials
%     post_lick_pos = 1;
% 	for i_time = 1:num_of_cols         % fill the array from left to right
%         if find(0 < scored_lick_aligned_times(i_trial, i_time)) % means we passed the lick time and now are on the post lick side
%             % start adding times to the array:
%             post_lick_times_by_trial(i_trial, post_lick_pos) = scored_lick_aligned_times(i_trial, i_time);
%             post_lick_values_by_trial(i_trial, post_lick_pos) = scored_lick_aligned_values(i_trial, i_time);
%             post_lick_pos = post_lick_pos + 1;
%         end
%     end
% end
    

% % combine the arrays:
% scored_lick_aligned_times_for_ave = horzcat(pre_lick_times_by_trial, post_lick_times_by_trial);
% scored_lick_aligned_values_for_ave = horzcat(pre_lick_values_by_trial, post_lick_values_by_trial);

% % take the average: 
% ave_f_lick_times = nanmean(scored_lick_aligned_times_for_ave, 1);
% ave_f_lick_values = nanmean(scored_lick_aligned_values_for_ave, 1);


% %------- Plot the average ----------%
% % figure, plot(ave_f_lick_times,ave_f_lick_values)
% % hold on
% % plot([0,0], [min(ave_f_lick_values), max(ave_f_lick_values)], 'r-', 'linewidth', 3)




% %% 2. Plot the overlay of smoothed lick-aligned trials
% smoothed_scored_lick_aligned_values = NaN(size(scored_lick_aligned_values));
% for i_trial = 1:num_trials
%     % smooth each trial
%     smoothed_scored_lick_aligned_values(i_trial, :) = smooth(scored_lick_aligned_values(i_trial, :), 50, 'gauss');
% end

% normalized_smoothed_scored_lick_aligned_values = NaN(size(scored_lick_aligned_values));
% % Normalize the values in each trial:
% for i_trial = 1:num_trials
%     % smooth each trial
%     normalized_smoothed_scored_lick_aligned_values(i_trial, :) = smoothed_scored_lick_aligned_values(i_trial, :) .*1/max(smoothed_scored_lick_aligned_values(i_trial, :));
% end
% % 
% % figure,
% % for i_trial = 1:num_trials
% %     plot(scored_lick_aligned_times(i_trial,:), normalized_smoothed_scored_lick_aligned_values(i_trial, :))
% %     hold on
% % end
% % hold on
% % plot([0,0], [min(ave_f_lick_values), max(ave_f_lick_values)], 'r-', 'linewidth', 3)




