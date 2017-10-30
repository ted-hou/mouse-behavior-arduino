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
% Modified ahamilos 10-3-17
% 
% 
% SMOOTH = 50 ms gauss
% 
% (to get the same across files, add lines with
% *********************)
%  (replace all DMS with X, all EMG with EMG
% 
%  Update Log:
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
X = X_values_by_trial; % note: the exclusions are taken care of by f_ex_licks_etc *********************
Y = Y_values_by_trial; %*********************
Z = Z_values_by_trial; %*********************
EMG = EMG_values_by_trial; %*********************
num_trials = num_trials;
backfilltime = 5000*sample_scaling_factor; % in ms * scaling factor *********************
range_ = [-7000,4000]; % this is the range to be disp default for overlays *********************






%% Rxn Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_rxn;
    title_X = 'X rxn licks';
    title_Y = 'Y rxn licks'; %************************
    title_Z = 'Z rxn licks'; %************************
    title_EMG = 'EMG rxn licks';
    xlimits = range_;

    %% X Plots---------------------------------------------------------------------------
        dummy_data = X;
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
        X_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        X_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);


        % Save the X data:
        X_lick_triggered_trials = lick_triggered_trials;



    %% Y Plots--------------------------------------------------------------------------- %***********************
        dummy_data = Y;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Y_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Y_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Y data:  
        Y_lick_triggered_trials = lick_triggered_trials; %*********************** %***********************


    %% Z Plots--------------------------------------------------------------------------- %***********************
        dummy_data = Z;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Z_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Z_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Z data:  
        Z_lick_triggered_trials = lick_triggered_trials; %*********************** 


    %% EMG Plots--------------------------------------------------------------------------------
        dummy_data = EMG;
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
        EMG_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        EMG_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the EMG data:    
        EMG_lick_triggered_trials = lick_triggered_trials;

    %% Variables to save to header file:
    rxn_X_lick_triggered_trials = X_lick_triggered_trials;
    rxn_Y_lick_triggered_trials = Y_lick_triggered_trials;%***********************
    rxn_Z_lick_triggered_trials = Z_lick_triggered_trials; %***********************
    rxn_EMG_lick_triggered_trials = EMG_lick_triggered_trials;

    rxn_X_lick_triggered_ave_ignore_NaN = X_lick_triggered_ave_ignore_NaN;
    rxn_Y_lick_triggered_ave_ignore_NaN = Y_lick_triggered_ave_ignore_NaN;%***********************
    rxn_Z_lick_triggered_ave_ignore_NaN = Z_lick_triggered_ave_ignore_NaN;%***********************
    rxn_EMG_lick_triggered_ave_ignore_NaN = EMG_lick_triggered_ave_ignore_NaN;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_rxnX = subplot(1,4,1) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(rxn_X_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_X)

        ax_rxnY = subplot(1,4,2) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(rxn_Y_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)%***********************
        xlim(xlimits)
        title(title_Y)%***********************

        ax_rxnZ = subplot(1,4,3) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(rxn_Z_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)%***********************
        xlim(xlimits)
        title(title_Z)%***********************



        ax_rxnEMG = subplot(1,4,4) %***********************
        plot([0,0], [-1,1])
        hold on
        plot(time_array, gausssmooth(rxn_EMG_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_EMG)




%% Early Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_operant_no_rew;
    title_X = 'X op-early licks';
    title_Y = 'Y early licks'; %************************
    title_Z = 'Z early licks'; %************************
    title_EMG = 'EMG op-early licks';
    xlimits = range_;

    %% X Plots---------------------------------------------------------------------------
        dummy_data = X;
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
        X_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        X_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save X data:
        X_lick_triggered_trials = lick_triggered_trials;
    

    %% Y Plots--------------------------------------------------------------------------- %***********************
        dummy_data = Y;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Y_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Y_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Y data:  
        Y_lick_triggered_trials = lick_triggered_trials;  %***********************


    %% Z Plots--------------------------------------------------------------------------- %***********************
        dummy_data = Z;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Z_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Z_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Z data:  
        Z_lick_triggered_trials = lick_triggered_trials;   




    %% EMG Plots--------------------------------------------------------------------------------
        dummy_data = EMG;
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
        EMG_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        EMG_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save EMG data
        EMG_lick_triggered_trials = lick_triggered_trials;



    %% Variables to save to header file:
    early_X_lick_triggered_ave_ignore_NaN = X_lick_triggered_ave_ignore_NaN;
    early_Y_lick_triggered_ave_ignore_NaN = Y_lick_triggered_ave_ignore_NaN;%***********************
    early_Z_lick_triggered_ave_ignore_NaN = Z_lick_triggered_ave_ignore_NaN;%***********************
    early_EMG_lick_triggered_ave_ignore_NaN = EMG_lick_triggered_ave_ignore_NaN;
    
    early_X_lick_triggered_trials = X_lick_triggered_trials;
    early_Y_lick_triggered_trials = Y_lick_triggered_trials;%***********************
    early_Z_lick_triggered_trials = Z_lick_triggered_trials; %***********************
    early_EMG_lick_triggered_trials = EMG_lick_triggered_trials;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_earlyX = subplot(1,4,1)%***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(early_X_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_X)

        ax_earlyY = subplot(1,4,2) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(early_Y_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)%***********************
        xlim(xlimits)
        title(title_Y)%***********************

        ax_earlyZ = subplot(1,4,3) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(early_Z_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)%***********************
        xlim(xlimits)
        title(title_Z)%***********************



        ax_earlyEMG = subplot(1,4,4) %***********************
        plot([0,0], [-1,1])
        hold on
        plot(time_array, gausssmooth(early_EMG_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_EMG)





%% Operant Rewarded Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_operant_rew;
    title_X = 'X op-rewarded licks';
    title_Y = 'Y op-rewarded licks'; %************************
    title_Z = 'Z op-rewarded licks'; %************************
    title_EMG = 'EMG op-rewarded licks';
    xlimits = range_;

    %% X Plots---------------------------------------------------------------------------
        dummy_data = X;
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
        X_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        X_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the X data
        X_lick_triggered_trials = lick_triggered_trials;
    

    %% Y Plots--------------------------------------------------------------------------- *********************
        dummy_data = Y;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Y_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Y_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Y data:  
        Y_lick_triggered_trials = lick_triggered_trials;   %***********************


    %% Z Plots--------------------------------------------------------------------------- *********************
        dummy_data = Z;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Z_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Z_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Z data:  
        Z_lick_triggered_trials = lick_triggered_trials;   %*********************** 


    %% EMG Plots--------------------------------------------------------------------------------
        dummy_data = EMG;
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
        EMG_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        EMG_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save EMG data:
        EMG_lick_triggered_trials = lick_triggered_trials;



    %% Variables to save to header file:
    rew_X_lick_triggered_trials = X_lick_triggered_trials;
    rew_Y_lick_triggered_trials = Y_lick_triggered_trials;%***********************
    rew_Z_lick_triggered_trials = Z_lick_triggered_trials; %***********************
    rew_EMG_lick_triggered_trials = EMG_lick_triggered_trials;
    
    rew_X_lick_triggered_ave_ignore_NaN = X_lick_triggered_ave_ignore_NaN;
    rew_Y_lick_triggered_ave_ignore_NaN = Y_lick_triggered_ave_ignore_NaN;%***********************
    rew_Z_lick_triggered_ave_ignore_NaN = Z_lick_triggered_ave_ignore_NaN;%***********************
    rew_EMG_lick_triggered_ave_ignore_NaN = EMG_lick_triggered_ave_ignore_NaN;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_rewX = subplot(1,4,1) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(rew_X_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_X)

        ax_rewY = subplot(1,4,2) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(rew_Y_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3) %***********************
        xlim(xlimits)
        title(title_Y)%***********************

        ax_rewZ = subplot(1,4,3) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(rew_Z_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)%***********************
        xlim(xlimits)
        title(title_Z)%***********************

        ax_rewEMG = subplot(1,4,4) %***********************
        plot([0,0], [-1,1])
        hold on
        plot(time_array, gausssmooth(rew_EMG_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_EMG)



%% ITI Licks--------------------------------------------------------------------------------------------------
    dummy_licks = f_ex_lick_ITI;
    title_X = 'X ITI licks';
    title_Y = 'Y ITI licks'; %************************
    title_Z = 'Z ITI licks'; %************************
    title_EMG = 'EMG ITI licks';
    xlimits = range_;

    %% X Plots---------------------------------------------------------------------------
        dummy_data = X;
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
        X_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        X_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the X data
        X_lick_triggered_trials = lick_triggered_trials;
    
    %% Y Plots---------------------------------------------------------------------------
        dummy_data = Y;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Y_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Y_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Y data:  
        Y_lick_triggered_trials = lick_triggered_trials;   %*********************** %***********************


    %% Z Plots---------------------------------------------------------------------------
        dummy_data = Z;
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
            left_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'first');
            right_bounds(i_trial) = find(dummy_data(i_trial,:) > -1000000, 1, 'last');
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
            %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
            %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
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
        Z_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        Z_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the Z data:  
        Z_lick_triggered_trials = lick_triggered_trials;     %***********************



    %% EMG Plots--------------------------------------------------------------------------------
        dummy_data = EMG;
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
        EMG_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        EMG_lick_triggered_ave_ignore_NaN = nanmean(abs(lick_triggered_trials),1);

        % Save EMG data:
        EMG_lick_triggered_trials = lick_triggered_trials;



    %% Variables to save to header file:
    ITI_X_lick_triggered_trials = X_lick_triggered_trials;
    ITI_Y_lick_triggered_trials = Y_lick_triggered_trials;%***********************
    ITI_Z_lick_triggered_trials = Z_lick_triggered_trials; %***********************
    ITI_EMG_lick_triggered_trials = EMG_lick_triggered_trials;
    
    ITI_X_lick_triggered_ave_ignore_NaN = X_lick_triggered_ave_ignore_NaN;
    ITI_Y_lick_triggered_ave_ignore_NaN = Y_lick_triggered_ave_ignore_NaN;%***********************
    ITI_Z_lick_triggered_ave_ignore_NaN = Z_lick_triggered_ave_ignore_NaN;%***********************
    ITI_EMG_lick_triggered_ave_ignore_NaN = EMG_lick_triggered_ave_ignore_NaN;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_ITIX = subplot(1,4,1) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(ITI_X_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_X)

        ax_ITIY = subplot(1,4,2) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(ITI_Y_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3) %***********************
        xlim(xlimits)
        title(title_Y)%***********************

        ax_ITIZ = subplot(1,4,3) %***********************
        plot([0,0], [1,2])
        hold on
        plot(time_array, gausssmooth(ITI_Z_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)%***********************
        xlim(xlimits)
        title(title_Z)%***********************

        ax_ITIEMG = subplot(1,4,4) %***********************
        plot([0,0], [-1,1])
        hold on
        plot(time_array, gausssmooth(ITI_EMG_lick_triggered_ave_ignore_NaN, smoothwin, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        title(title_EMG)






%% Link plots:
    linkaxes([ax_rxnX, ax_earlyX, ax_rewX, ax_ITIX],'xy') %***********************
    linkaxes([ax_rxnY, ax_earlyY, ax_rewY, ax_ITIY],'xy') %***********************
    linkaxes([ax_rxnZ, ax_earlyZ, ax_rewZ, ax_ITIZ],'xy') %***********************
    linkaxes([ax_rxnEMG, ax_earlyEMG, ax_rewEMG, ax_ITIEMG],'xy') %***********************
    % turn off with linkaxes([ax_rxnX, ax_rxnEMG, ax_earlyX, ax_earlyEMG,ax_rewX,ax_rewEMG,ax_pavX,ax_pavEMG],'off')



%% Overlays (not normalized)
    pos1 = find(time_array==range_(1));
    pos2 = find(time_array==range_(2));
    zeropos = find(time_array==0);

    N_rxn_X = rxn_X_lick_triggered_ave_ignore_NaN;
    N_rxn_Y = rxn_Y_lick_triggered_ave_ignore_NaN; %***********************
    N_rxn_Z = rxn_Z_lick_triggered_ave_ignore_NaN; %***********************
    N_rxn_EMG = rxn_EMG_lick_triggered_ave_ignore_NaN;

    N_early_X = early_X_lick_triggered_ave_ignore_NaN;
    N_early_Y = early_Y_lick_triggered_ave_ignore_NaN; %***********************
    N_early_Z = early_Z_lick_triggered_ave_ignore_NaN; %***********************
    N_early_EMG = early_EMG_lick_triggered_ave_ignore_NaN;

    N_rew_X = rew_X_lick_triggered_ave_ignore_NaN;
    N_rew_Y = rew_Y_lick_triggered_ave_ignore_NaN; %***********************
    N_rew_Z = rew_Z_lick_triggered_ave_ignore_NaN; %***********************
    N_rew_EMG = rew_EMG_lick_triggered_ave_ignore_NaN;

    N_ITI_X = ITI_X_lick_triggered_ave_ignore_NaN;
    N_ITI_EMG = ITI_EMG_lick_triggered_ave_ignore_NaN;


%% Plot the overlays:

    figure
    ax1 = subplot(1,4,1); % X  %***********************
    plot([0,0], [1,2], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),N_rxn_X(pos1:pos2), 'linewidth', 3)
    plot(time_array(pos1:pos2),N_early_X(pos1:pos2), 'linewidth', 3)
    plot(time_array(pos1:pos2),N_rew_X(pos1:pos2), 'linewidth', 3)
    % plot(time_array(pos1:pos2),N_pav_X(pos1:pos2), 'linewidth', 3)
    % names = {'lick time','rxn', 'early', 'rew'};
    names = {'lick time', 'rxn', 'early', 'rew', 'pav'};
    legend(names)
    xlim(range_)
    title('X')

    ax2 = subplot(1,4,2); % Y  %***********************
    plot([0,0], [1,2], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),N_rxn_Y(pos1:pos2), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),N_early_Y(pos1:pos2), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),N_rew_Y(pos1:pos2), 'linewidth', 3) %***********************
    % plot(time_array(pos1:pos2),N_pav_Y(pos1:pos2), 'linewidth', 3) %***********************
    legend(names)
    xlim(range_)
    title('Y') %***********************

    ax3 = subplot(1,4,3); % Z  %***********************
    plot([0,0], [1,2], 'g-', 'linewidth', 2) 
    hold on
    plot(time_array(pos1:pos2),N_rxn_Z(pos1:pos2), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),N_early_Z(pos1:pos2), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),N_rew_Z(pos1:pos2), 'linewidth', 3) %***********************
    % plot(time_array(pos1:pos2),N_pav_Z(pos1:pos2), 'linewidth', 3) %***********************
    legend(names)
    xlim(range_)
    title('Z') %***********************

    ax4 = subplot(1,4,4); % EMG  %***********************
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),N_rxn_EMG(pos1:pos2), 'linewidth', 3)
    plot(time_array(pos1:pos2),N_early_EMG(pos1:pos2), 'linewidth', 3)
    plot(time_array(pos1:pos2),N_rew_EMG(pos1:pos2), 'linewidth', 3)
    % plot(time_array(pos1:pos2),N_pav_EMG(pos1:pos2), 'linewidth', 3)
    legend(names)
    xlim(range_)
    title('EMG')
    

    % Plot the overlays:

    figure
    ax5 = subplot(1,4,1); % X  %***********************
    plot([0,0], [1,2], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),gausssmooth(N_rxn_X(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_early_X(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_rew_X(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % plot(time_array(pos1:pos2),gausssmooth(N_pav_X(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % names = {'lick_time','rxn', 'early', 'rew'};
    names = {'lick_time', 'rxn', 'early', 'rew', 'pav'};
    legend(names)
    xlim(range_)
    title('X')



    ax6 = subplot(1,4,2); % Y  %***********************
    plot([0,0], [1,2], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),gausssmooth(N_rxn_Y(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),gausssmooth(N_early_Y(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),gausssmooth(N_rew_Y(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    % plot(time_array(pos1:pos2),gausssmooth(N_pav_Y(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    legend(names)
    xlim(range_)
    title('Y') %***********************

    ax7 = subplot(1,4,3); % Z  %***********************
    plot([0,0], [1,2], 'g-', 'linewidth', 2) 
    hold on
    plot(time_array(pos1:pos2),gausssmooth(N_rxn_Z(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),gausssmooth(N_early_Z(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    plot(time_array(pos1:pos2),gausssmooth(N_rew_Z(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    % plot(time_array(pos1:pos2),gausssmooth(N_pav_Z(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3) %***********************
    legend(names)
    xlim(range_)
    title('Z') %***********************

    ax8 = subplot(1,4,4); % EMG  %***********************
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),gausssmooth(N_rxn_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_early_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_rew_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    % plot(time_array(pos1:pos2),gausssmooth(N_pav_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    legend(names)
    xlim(range_)
    title('EMG')

    linkaxes([ax1, ax2, ax3, ax4],'off')
    linkaxes([ax5, ax6, ax7, ax8],'off')
    % turn off with linkaxes([ax1, ax2, ax3, ax4],'off')
    linkaxes([ax1, ax5],'xy')
    linkaxes([ax2, ax6],'xy')
    linkaxes([ax3, ax7],'xy')
    linkaxes([ax4, ax8],'xy')
    
    
    %% plot EMG alone:
    
    
    figure % EMG  %***********************
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)
    hold on
    plot(time_array(pos1:pos2),gausssmooth(N_rxn_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_early_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_rew_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),gausssmooth(N_pav_EMG(pos1:pos2),smoothwin,'gauss'), 'linewidth', 3)
    legend(names)
    xlim(range_)
    title('EMG')



