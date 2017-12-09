function [rxn_signal_lick_triggered_trials,...
    early_signal_lick_triggered_trials,...
    rew_signal_lick_triggered_trials,...
    ITI_signal_lick_triggered_trials,...
    N_rxn_signal,...
    N_early_signal,...
    N_rew_signal,...
    N_ITI_signal,...
    time_array] = NOFIGS_LTA_EMGAC_extractor_overlay_op_roadmapv1_3_fx(signal_vbt,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname)

% LTA - Make all plots 
%   A composite version of lick_triggered_ave_fx and lta_normalized_overlay that can be run for full dataset in one click
% ---------------------------LICK TRIGGERED AVERAGE-----------------------------
% 
% test with:
%  lick_triggered_ave_fx(dummy_data, dummy_licks, num_trials, cue_position, num_trials)
%  lick_triggered_ave_fx(d22_EMG_values_by_trial, d22_all_first_licks, num_trials, 1501)
% 
% 
% Created  ahamilos 7-20-17
% Modified ahamilos 12-5-17 (from figure+ version)
% 
% 
% SMOOTH = 50 ms gauss
% 
% (to get the same across files, add lines with
% *********************)
%  (replace all DMS with X, all EMG with EMG
% 
%  Update Log:
%      10-27-17: Modified to be generic for any movement input
%       10-3-17: Modified for EMG/acc data (sampling rate now variable)
%       9-04-17: Disambiguated smooth method to gausssmooth.m
%       8-10-17: Updated Legend to Match Times In Bin
%       8-01-17: Modified for Roadmap v1 autorun
%       7-20-17: Seems like there may be an error with super6 data application - looking for errors
%       7-26-17: error validation complete, I believe it is reliable with dummy_data test set (below)
%       7-27-17: Made composite version for one click running
%               Corrected error with right and left parts >0 (is now >backfilltime, as is correct)
%
    smoothwin = 50; %**************************************************************************************
    Hz = 2000; % sampling rate ****************************************************************************
    sample_scaling_factor = Hz/1000; % this is what will be used to transform time in ms to samples at the sampling rate *********************
%
%
% Uses output of first_lick_grabber.m
%% Debugging History---------------------------------------------------
    % let's start from the beginning with dummy data:
    % dummy_data = [NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1.1 1 1 1 1 10 10 1 1 1.5;...
    %              NaN NaN NaN NaN NaN NaN NaN 2.1 2 2 2 2 2 2 2 2 2 10 10 2.5;...
    %              NaN 3.1 3 3 3 3 3 3 3 3 3 10 10 3 3 3 3 3 3.5 NaN;...
    %              NaN NaN NaN 4.1 4 4 4 4 4 4 4 4 10 10 4 4 4 4 4.5 NaN];

    % X = dummy_data;
    % EMG = dummy_data;

    
    % dummy_licks = [.006, .008, -.01, .003] + 0.01; % including the cue position-1, 10, and -0.01 is so no-lick case appears as zero (0)
    % d22_f_ex1_lick_rxn = dummy_licks;
    % d22_f_ex1_lick_operant_no_rew = dummy_licks;
    % d22_f_ex1_lick_operant_rew = dummy_licks;


    % num_trials = 4;
    % % % this data is already aligned by cue on time at position 11 (analogous to the real lick data)
    % % % and input to the function should be the cue_on_position in the original dataset (1501 I think)
    % cue = 11;
    % cue_position = 11;
    % range_  = [-20,20];
    % backfilltime = 5;

    % validated again on 7-27-17 with no-lick trial test case
%-----------------------------------------------------------------------
% 
%% Input data to use in line below: ------------------------------------------------------
% Input day # by ctrl-H, then apply d## to all
    cue = 1501*sample_scaling_factor; % cue_on_time_rel = cue_on_time_in_ms*sample_scaling_factor; *********************
    % X = signal_values_by_trial; % note: the exclusions are taken care of by f_ex_licks_etc *********************
    % Y = Y_values_by_trial; %*********************
    % Z = Z_values_by_trial; %*********************
    % EMG = EMG_values_by_trial; %*********************
    % num_trials = num_trials;
    backfilltime = 5000*sample_scaling_factor; % in ms * scaling factor *********************
    range_ = [-7000,4000]; % this is the range to be disp default for overlays *********************


    axisarray = [];



%% Rxn Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_rxn;
    title_signal = [signalname, 'licks'];
    xlimits = range_;

    %% Signal Plots---------------------------------------------------------------------------
        dummy_data = signal_vbt;
        cue_position = cue;


        % first lick times are in seconds wrt the cue. We can convert these to the position
        lick_positions = round(1000*dummy_licks*sample_scaling_factor); % DON'T subtract off cue position bc we are going wrt the whole array! *********************


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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-27-17
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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-27-17
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
        signal_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        signal_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);


        % Save the signal data:
        signal_lick_triggered_trials = lick_triggered_trials;



    %% Variables to save to header file:
    rxn_signal_lick_triggered_trials = signal_lick_triggered_trials;
   
    rxn_signal_lick_triggered_ave_ignore_NaN = signal_lick_triggered_ave_ignore_NaN;
   
    %% The plots:---------------------------------------------------------------------------
% SUPPRESSED 11/15/17
    %         figure
%         ax_rxn = subplot(1,1,1); %***********************
%         axisarray(1) = ax_rxn;
%         plot([0,0], [1,2])
%         hold on
%         plot(time_array, gausssmooth(rxn_signal_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
%         xlim(xlimits)
%         title(title_signal)




%% Early Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_operant_no_rew;
    xlimits = range_;

    %% Signal Plots---------------------------------------------------------------------------
        dummy_data = signal_vbt;
        cue_position = cue;


        % first lick times are in seconds wrt the cue. We can convert these to the position
        lick_positions = round(1000*dummy_licks*sample_scaling_factor); % DON'T subtract off cue position bc we are going wrt the whole array! *********************


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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
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
        signal_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        signal_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save signal data:
        signal_lick_triggered_trials = lick_triggered_trials;
    



    %% Variables to save to header file:
    early_signal_lick_triggered_ave_ignore_NaN = signal_lick_triggered_ave_ignore_NaN;
   
    early_signal_lick_triggered_trials = signal_lick_triggered_trials;
    
%% The plots:---------------------------------------------------------------------------
% SUPPRESSED 11/15/17

%         figure
%         ax_early = subplot(1,1,1);%***********************
%         axisarray(end+1) = ax_early;
%         plot([0,0], [1,2])
%         hold on
%         plot(time_array, gausssmooth(early_signal_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
%         xlim(xlimits)
%         title(title_signal)



%% Operant Rewarded Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_operant_rew;

    xlimits = range_;

    %% signal Plots---------------------------------------------------------------------------
        dummy_data = signal_vbt;
        cue_position = cue;


        % first lick times are in seconds wrt the cue. We can convert these to the position
        lick_positions = round(1000*dummy_licks*sample_scaling_factor); % DON'T subtract off cue position bc we are going wrt the whole array! *********************


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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
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
        signal_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        signal_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the signal data
        signal_lick_triggered_trials = lick_triggered_trials;
    

   
    %% Variables to save to header file:
    rew_signal_lick_triggered_trials = signal_lick_triggered_trials;
    
    rew_signal_lick_triggered_ave_ignore_NaN = signal_lick_triggered_ave_ignore_NaN;
 
    %% The plots:---------------------------------------------------------------------------
% SUPPRESSED 11/15/17
%         figure
%         ax_rew = subplot(1,1,1); %***********************
%         axisarray(end+1) = ax_rew;
%         plot([0,0], [1,2])
%         hold on
%         plot(time_array, gausssmooth(rew_signal_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
%         xlim(xlimits)
%         title(title_signal)



%% ITI Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_ITI;
    xlimits = range_;

    %% signal Plots---------------------------------------------------------------------------
        dummy_data = signal_vbt;
        cue_position = cue;


        % first lick times are in seconds wrt the cue. We can convert these to the position
        lick_positions = round(1000*dummy_licks*sample_scaling_factor); % DON'T subtract off cue position bc we are going wrt the whole array! *********************


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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
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
            % if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
            if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
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
        signal_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        signal_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the signal data
        signal_lick_triggered_trials = lick_triggered_trials;
    


    %% Variables to save to header file:
    ITI_signal_lick_triggered_trials = signal_lick_triggered_trials;
  
    ITI_signal_lick_triggered_ave_ignore_NaN = signal_lick_triggered_ave_ignore_NaN;

    %% The plots:---------------------------------------------------------------------------
% SUPPRESSED 11/15/17
%         figure
%         ax_ITI = subplot(1,1,1); %***********************
%         axisarray(end+1) = ax_ITI;
%         plot([0,0], [1,2])
%         hold on
%         plot(time_array, gausssmooth(ITI_signal_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
%         xlim(xlimits)
%         title(title_signal)




%% Link plots:
%     linkaxes(axisarray,'xy') %***********************



%% Overlays (not normalized)
    pos1 = find(time_array==range_(1));
    pos2 = find(time_array==range_(2));
    zeropos = find(time_array==0);

    N_rxn_signal = rxn_signal_lick_triggered_ave_ignore_NaN;
    N_early_signal = early_signal_lick_triggered_ave_ignore_NaN;
    N_rew_signal = rew_signal_lick_triggered_ave_ignore_NaN;
    N_ITI_signal = ITI_signal_lick_triggered_ave_ignore_NaN;


%% Plot the overlays:
% SUPPRESSED 11/15/17
    axisarray2 = [];
%     figure
%     ax1 = subplot(1,1,1); % signal  %***********************
%     axisarray2(1) = ax1;
%     plot([0,0], [1,2], 'g-', 'linewidth', 2)
%     hold on
%     plot(time_array(pos1:pos2),N_rxn_signal(pos1:pos2), 'linewidth', 3)
%     plot(time_array(pos1:pos2),N_early_signal(pos1:pos2), 'linewidth', 3)
%     plot(time_array(pos1:pos2),N_rew_signal(pos1:pos2), 'linewidth', 3)
%     names = {'lick time','rxn', 'early', 'rew'};
%     % names = {'lick time', 'rxn', 'early', 'rew', 'pav'};
%     legend(names)
%     xlim(range_)
%     title(title_signal)

 

    % Plot the overlays smoothed:

    % figure
    % ax5 = subplot(1,1,1); % signal  %***********************
    % axisarray2(end+1) = ax5;
    % plot([0,0], [1,2], 'g-', 'linewidth', 2)
    % hold on
    % plot(time_array(pos1:pos2),gausssmooth(N_rxn_signal(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % plot(time_array(pos1:pos2),gausssmooth(N_early_signal(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % plot(time_array(pos1:pos2),gausssmooth(N_rew_signal(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % % plot(time_array(pos1:pos2),gausssmooth(N_pav_signal(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % names = {'lick_time','rxn', 'early', 'rew'};
    % % names = {'lick_time', 'rxn', 'early', 'rew', 'pav'};
    % legend(names)
    % xlim(range_)
    % title(title_signal)


    % linkaxes(axisarray2,'xy')



end
