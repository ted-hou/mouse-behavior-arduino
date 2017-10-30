% function [lick_triggered_trials,...
%          lick_triggered_ave_noNaN,...
%          lick_triggered_ave_ignore_NaN] = lick_triggered_ave_fx(dummy_data,...
%                                              dummy_licks,...
%                                              num_trials,...
%                                              cue_position)
% ---------------------------LICK TRIGGERED AVERAGE-----------------------------
% 
% test with:
%  lick_triggered_ave_fx(dummy_data, dummy_licks, num_trials, cue_position, num_trials)
%  lick_triggered_ave_fx(d5_SNc_values_by_trial, d5_all_first_licks, num_trials, 1501)
% 
% 
% Created  ahamilos 7-20-17
% Modified ahamilos 7-26-17
% 
% 
%  Update Log:
%       7-20-17: Seems like there may be an error with super6 data application - looking for errors
%       7-26-17: error validation complete, I believe it is reliable with dummy_data test set (below)
%
%
%
% Uses output of first_lick_grabber.m
% 
% 
%  Create LTA overlays with lta_normalized_overlay.m
% 
%% Input data to use in line below: ------------------------------------------------------

cue = 1501;
DLS = d5_DLS_values_by_trial;
SNc = d5_SNc_values_by_trial;
num_trials = 419;
backfilltime = 5000;
% 
% dummy_licks = d5_f_ex1_lick_rxn;
% title_DLS = 'DLS rxn licks';
% title_SNc = 'SNc rxn licks';
% xlimits = [-4000,1000];

% dummy_licks = d5_f_ex1_lick_operant_no_rew;
% title_DLS = 'DLS op-early licks';
% title_SNc = 'SNc op-early licks';
% xlimits = [-4000,1000];

% dummy_licks = d5_f_ex1_lick_operant_rew;
% title_DLS = 'DLS op-rewarded licks';
% title_SNc = 'SNc op-rewarded licks';
% xlimits = [-7500,1000];
% xlimits = [-4000,1000];

dummy_licks = d5_f_ex1_lick_pavlovian;
title_DLS = 'DLS pavlovian licks';
title_SNc = 'SNc pavlovian licks';
xlimits = [-4000,1000];


% print(1,'-depsc','-painters','lta_rxn_ex1_h3.eps')
% print(2,'-depsc','-painters','lta_opnorew_ex1_h3.eps')
% print(3,'-depsc','-painters','lta_oprew_ex1_h3.eps')
% print(4,'-depsc','-painters','lta_pav_ex1_h3.eps')





%% Debugging History---------------------------------------------------
    % % let's start from the beginning with dummy data:
    % dummy_data = [NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1.1 1 1 1 1 10 10 1 1 1.5;...
    %              NaN NaN NaN NaN NaN NaN NaN 2.1 2 2 2 2 2 2 2 2 2 10 10 2.5;...
    %              NaN 3.1 3 3 3 3 3 3 3 3 3 10 10 3 3 3 3 3 3.5 NaN;...
    %              NaN NaN NaN 4.1 4 4 4 4 4 4 4 4 10 10 4 4 4 4 4.5 NaN];

    % DLS = dummy_data;
    % SNc = dummy_data;

    % % dummy_licks = [.006, .008, .002, .003];
    % dummy_licks = [.006, .008, .002, .003] + 0.01; % including the cue position-1, 10
    % num_trials = 4;
    % % % this data is already aligned by cue on time at position 11 (analogous to the real lick data)
    % % % and input to the function should be the cue_on_position in the original dataset (1501 I think)
    % cue = 11;
    % cue_position = 11;
    % xlimits = [-20,20];
    % backfilltime = 5;

    % % validated with lta_normalized_overlay on 7-26-17
%-----------------------------------------------------------------------


%% DLS Plots---------------------------------------------------------------------------
    dummy_data = DLS;
    cue_position = cue;


    % first lick times are in seconds wrt the cue. We can convert these to the position
    lick_positions = round(1000*dummy_licks); % DON'T subtract off cue position bc we are going wrt the whole array!


    % expand the time stretch of the data array so we can backfill more times for early rxn licks:
    backfill = NaN(num_trials, backfilltime);
    cue_position = cue_position + backfilltime; % to account for the back-filled time, the cue_position also has to shift over
    lick_positions = lick_positions + backfilltime; % to account for back-filled time
    dummy_data = horzcat(backfill, dummy_data);



    % need to create an array where we fill in values from before the trial
    % let's try finding the first and last positions of numbers in the array
    left_bounds = NaN(num_trials,1);
    right_bounds = NaN(num_trials,1);
    for i_trial = 1:num_trials
        left_bounds(i_trial) = min(find(dummy_data(i_trial,:) > -1000000));
        right_bounds(i_trial) = max(find(dummy_data(i_trial,:) > -1000000));
    end

    % now let's make a container for the filled in data:
    filled_in_data = dummy_data;

    % exclude trial 1 because we cut off the data before it already
    % for each trial, pick off as many points as need to be filled in from the trial before
    for this_trial = 2:num_trials
        last_trial = this_trial - 1;
        endposition_thistrial = left_bounds(this_trial); % pluck off this number of points from prior trial and put in the array
        startposition_last_trial = right_bounds(last_trial) - endposition_thistrial + 1;
        endposition_lasttrial = right_bounds(last_trial);
        filled_in_data(this_trial, 1:endposition_thistrial) = dummy_data(last_trial, startposition_last_trial:endposition_lasttrial);
    end





    % find all positions including lick position and to the right
    right_of_and_lick = NaN(size(filled_in_data));


    for i_trial = 1:num_trials
        if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            % find the values to append:
            values_to_add = filled_in_data(i_trial, lick_positions(i_trial):size(filled_in_data,2));
            right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
        else
            values_to_add = [nan, nan, nan];
            right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
        end
    end

    % find all positions left of lick, not including the lick
    left_of_lick = NaN(size(filled_in_data));

    for i_trial = 1:num_trials
        % first, make sure the value of the lick time is not = -(cue_position-1) - that means time was recorded as zero for the lick and so it needs to be excluded
        if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            % find the values to append:
            lick_end = lick_positions(i_trial)-1;
            values_to_add = filled_in_data(i_trial, 1:lick_end);
            pos_start = size(left_of_lick,2)-length(values_to_add)+1;
            pos_end = size(left_of_lick,2);
            left_of_lick(i_trial,pos_start:pos_end) = values_to_add;
        end
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
    DLS_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
    % then let's try where we ignore nan with nanmean:
    DLS_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);


    % %% Plotting the lick-triggered ave versions:
    % figure
    % subplot(1,2,1)
    % plot(time_array, lick_triggered_ave_noNaN)

    % subplot(1,2,2)
    % plot(time_array, lick_triggered_ave_ignore_NaN)



    % %% Plotting the smoothed lick-triggered ave versions:
    % figure
    % subplot(1,2,1)
    % plot(time_array, smooth(lick_triggered_ave_noNaN, 50, 'gauss'), 'linewidth', 3)
    % hold on
    % plot([0,0], [min(smooth(lick_triggered_ave_noNaN, 50, 'gauss'))-0.005, max(smooth(lick_triggered_ave_noNaN, 50, 'gauss'))+0.005])

    % subplot(1,2,2)
    % plot(time_array, smooth(lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
    % hold on
    % plot([0,0], [min(smooth(lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.005, max(smooth(lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.005])








%% SNc Plots--------------------------------------------------------------------------------
    dummy_data = SNc;
    cue_position = cue;


    % first lick times are in seconds wrt the cue. We can convert these to the position
    lick_positions = round(1000*dummy_licks); % DON'T subtract off cue position bc we are going wrt the whole array!


    % expand the time stretch of the data array so we can backfill more times for early rxn licks:
    backfill = NaN(num_trials, backfilltime);
    cue_position = cue_position + backfilltime; % to account for the back-filled time, the cue_position also has to shift over
    lick_positions = lick_positions + backfilltime; % to account for back-filled time
    dummy_data = horzcat(backfill, dummy_data);



    % need to create an array where we fill in values from before the trial
    % let's try finding the first and last positions of numbers in the array
    left_bounds = NaN(num_trials,1);
    right_bounds = NaN(num_trials,1);
    for i_trial = 1:num_trials
        left_bounds(i_trial) = min(find(dummy_data(i_trial,:) > -1000000));
        right_bounds(i_trial) = max(find(dummy_data(i_trial,:) > -1000000));
    end

    % now let's make a container for the filled in data:
    filled_in_data = dummy_data;

    % exclude trial 1 because we cut off the data before it already
    % for each trial, pick off as many points as need to be filled in from the trial before
    for this_trial = 2:num_trials
        last_trial = this_trial - 1;
        endposition_thistrial = left_bounds(this_trial); % pluck off this number of points from prior trial and put in the array
        startposition_last_trial = right_bounds(last_trial) - endposition_thistrial + 1;
        endposition_lasttrial = right_bounds(last_trial);
        filled_in_data(this_trial, 1:endposition_thistrial) = dummy_data(last_trial, startposition_last_trial:endposition_lasttrial);
    end





    % find all positions including lick position and to the right
    right_of_and_lick = NaN(size(filled_in_data));


    for i_trial = 1:num_trials
        if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            % find the values to append:
            values_to_add = filled_in_data(i_trial, lick_positions(i_trial):size(filled_in_data,2));
            right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
        else
            values_to_add = [nan, nan, nan];
            right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
        end
    end

    % find all positions left of lick, not including the lick
    left_of_lick = NaN(size(filled_in_data));

    for i_trial = 1:num_trials
        % first, make sure the value of the lick time is not = -(cue_position-1) - that means time was recorded as zero for the lick and so it needs to be excluded
        if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            % find the values to append:
            lick_end = lick_positions(i_trial)-1;
            values_to_add = filled_in_data(i_trial, 1:lick_end);
            pos_start = size(left_of_lick,2)-length(values_to_add)+1;
            pos_end = size(left_of_lick,2);
            left_of_lick(i_trial,pos_start:pos_end) = values_to_add;
        end
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
    SNc_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
    % then let's try where we ignore nan with nanmean:
    SNc_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

    % %% Plotting the lick-triggered ave versions:
    % figure
    % subplot(1,2,1)
    % plot(time_array, lick_triggered_ave_noNaN)

    % subplot(1,2,2)
    % plot(time_array, lick_triggered_ave_ignore_NaN)



    % %% Plotting the smoothed lick-triggered ave versions:
    % figure
    % subplot(1,2,1)
    % plot(time_array, smooth(lick_triggered_ave_noNaN, 50, 'gauss'), 'linewidth', 3)
    % hold on
    % plot([0,0], [min(smooth(lick_triggered_ave_noNaN, 50, 'gauss'))-0.005, max(smooth(lick_triggered_ave_noNaN, 50, 'gauss'))+0.005])

    % subplot(1,2,2)
    % plot(time_array, smooth(lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
    % hold on
    % plot([0,0], [min(smooth(lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.005, max(smooth(lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.005])



%% The plots:
    figure
    subplot(1,2,1)
    plot(time_array, smooth(DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
    xlim(xlimits)
    hold on
    plot([0,0], [min(smooth(DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
    title(title_DLS)



    subplot(1,2,2)
    plot(time_array, smooth(SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
    xlim(xlimits)
    hold on
    plot([0,0], [min(smooth(SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
    title(title_SNc)


% %% (debug dataset) The plots:
%     figure
%     subplot(1,2,1)
%     plot(time_array, DLS_lick_triggered_ave_ignore_NaN, 'linewidth', 3)
%     xlim(xlimits)
%     hold on
%     plot([0,0], [min(DLS_lick_triggered_ave_ignore_NaN)-0.001, max(DLS_lick_triggered_ave_ignore_NaN)+0.001])
%     title(title_DLS)



%     subplot(1,2,2)
%     plot(time_array, SNc_lick_triggered_ave_ignore_NaN, 'linewidth', 3)
%     xlim(xlimits)
%     hold on
%     plot([0,0], [min(SNc_lick_triggered_ave_ignore_NaN)-0.001, max(SNc_lick_triggered_ave_ignore_NaN)+0.001])
%     title(title_DLS)

