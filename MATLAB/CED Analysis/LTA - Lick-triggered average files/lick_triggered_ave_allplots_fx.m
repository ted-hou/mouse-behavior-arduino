% LTA - Make all plots
%   A composite version of lick_triggered_ave_fx and lta_normalized_overlay that can be run for full dataset in one click
% 
%   NOTE: Overlay should NOT BE NORMALIZED from now on

% ---------------------------LICK TRIGGERED AVERAGE-----------------------------
% 
% test with:
%  lick_triggered_ave_fx(dummy_data, dummy_licks, num_trials, cue_position, num_trials)
%  lick_triggered_ave_fx(d22_SNc_values_by_trial, d22_all_first_licks, num_trials, 1501)
% 
% 
% Created  ahamilos 7-20-17
% Modified ahamilos 7-27-17
% 
% 
%  Update Log:
%       7-20-17: Seems like there may be an error with super6 data application - looking for errors
%       7-26-17: error validation complete, I believe it is reliable with dummy_data test set (below)
%       7-27-17: Made composite version for one click running
%               Corrected error with right and left parts >0 (is now >backfilltime, as is correct)
%
%
%
% Uses output of first_lick_grabber.m
%% Debugging History---------------------------------------------------
    % let's start from the beginning with dummy data:
    % dummy_data = [NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN 1.1 1 1 1 1 10 10 1 1 1.5;...
    %              NaN NaN NaN NaN NaN NaN NaN 2.1 2 2 2 2 2 2 2 2 2 10 10 2.5;...
    %              NaN 3.1 3 3 3 3 3 3 3 3 3 10 10 3 3 3 3 3 3.5 NaN;...
    %              NaN NaN NaN 4.1 4 4 4 4 4 4 4 4 10 10 4 4 4 4 4.5 NaN];

    % DLS = dummy_data;
    % SNc = dummy_data;

    
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
cue = 1501;
DLS = d22_DLS_values_by_trial;
SNc = d22_SNc_values_by_trial;
num_trials = 615;
backfilltime = 5000;
range_ = [-4000,1000]; % this is the range to be disp default for overlays

% Copy and paste to save figures:
% print(1,'-depsc','-painters','lta_rxn_ex1_h3.eps')
% saveas(1,'lta_rxn_ex1_h3.fig','fig')
% print(2,'-depsc','-painters','lta_opnorew_ex1_h3.eps')
% saveas(2,'lta_opnorew_ex1_h3.fig','fig')
% print(3,'-depsc','-painters','lta_oprew_ex1_h3.eps')
% saveas(3,'lta_oprew_ex1_h3.fig','fig')

% print(4,'-depsc','-painters','lta_overlay_nonorm_wnoise_ex1_h3.eps')
% saveas(4,'lta_overlay_nonorm_wnoise_ex1_h3.fig','fig')
% print(5,'-depsc','-painters','lta_overlay_nonorm_smooth_ex1_h3.eps')
% saveas(5,'lta_overlay_nonorm_smooth_ex1_h3.fig','fig')

% print(4,'-depsc','-painters','lta_pav_ex1_h3.eps')
% saveas(4,'test.fig','fig')





%% Pavlovian Licks (comment out for op only)--------------------------------------------------------------------------------------------------
    % dummy_licks = d22_f_ex1_lick_pavlovian;
    % title_DLS = 'DLS pavlovian licks';
    % title_SNc = 'SNc pavlovian licks';
    % xlimits = [-4000,1000];

    % %% DLS Plots---------------------------------------------------------------------------
    %     dummy_data = DLS;
    %     cue_position = cue;


    %     % first lick times are in seconds wrt the cue. We can convert these to the position
    %     lick_positions = round(1000*dummy_licks); % DON'T subtract off cue position bc we are going wrt the whole array!


    %     % expand the time stretch of the data array so we can backfill more times for early rxn licks:
    %     backfill = NaN(num_trials, backfilltime);
    %     cue_position = cue_position + backfilltime; % to account for the back-filled time, the cue_position also has to shift over
    %     lick_positions = lick_positions + backfilltime; % to account for back-filled time
    %     dummy_data = horzcat(backfill, dummy_data);



    %     % need to create an array where we fill in values from before the trial
    %     % let's try finding the first and last positions of numbers in the array
    %     left_bounds = NaN(num_trials,1);
    %     right_bounds = NaN(num_trials,1);
    %     for i_trial = 1:num_trials
    %         left_bounds(i_trial) = min(find(dummy_data(i_trial,:) > -1000000));
    %         right_bounds(i_trial) = max(find(dummy_data(i_trial,:) > -1000000));
    %     end

    %     % now let's make a container for the filled in data:
    %     filled_in_data = dummy_data;

    %     % exclude trial 1 because we cut off the data before it already
    %     % for each trial, pick off as many points as need to be filled in from the trial before
    %     for this_trial = 2:num_trials
    %         last_trial = this_trial - 1;
    %         endposition_thistrial = left_bounds(this_trial); % pluck off this number of points from prior trial and put in the array
    %         startposition_last_trial = right_bounds(last_trial) - endposition_thistrial + 1;
    %         endposition_lasttrial = right_bounds(last_trial);
    %         filled_in_data(this_trial, 1:endposition_thistrial) = dummy_data(last_trial, startposition_last_trial:endposition_lasttrial);
    %     end





    %     % find all positions including lick position and to the right
    %     right_of_and_lick = NaN(size(filled_in_data));


    %     for i_trial = 1:num_trials
    %         %%% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
              % if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
    %             % find the values to append:
    %             values_to_add = filled_in_data(i_trial, lick_positions(i_trial):size(filled_in_data,2));
    %             right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
    %         else
    %             values_to_add = [nan, nan, nan];
    %             right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
    %         end
    %     end

    %     % find all positions left of lick, not including the lick
    %     left_of_lick = NaN(size(filled_in_data));

    %     for i_trial = 1:num_trials
    %         % first, make sure the value of the lick time is not = -(cue_position-1) - that means time was recorded as zero for the lick and so it needs to be excluded
    %         %% if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
    %         if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
    %             % find the values to append:
    %             lick_end = lick_positions(i_trial)-1;
    %             values_to_add = filled_in_data(i_trial, 1:lick_end);
    %             pos_start = size(left_of_lick,2)-length(values_to_add)+1;
    %             pos_end = size(left_of_lick,2);
    %             left_of_lick(i_trial,pos_start:pos_end) = values_to_add;
    %         end
    %     end


    %     % combine the arrays. 
    %     lick_triggered_trials = horzcat(left_of_lick, right_of_and_lick);

    %     % Now position 21 is the position of the lick. Make a new time array:
    %     time_array = NaN(1, size(lick_triggered_trials,2));
    %     position_zero = size(left_of_lick,2) + 1;
    %     position_max = length(time_array) - position_zero;
    %     time_array(position_zero:end) = [0:position_max]; % this will be time in ms
    %     position_zero_1 = position_zero - 1;
    %     time_array(1:position_zero_1) = (-position_zero_1:-1); 


    %     %% Calculating lick-triggered ave
    %     % first, let's see how far we can see if we take the lick-triggered average, excluding any times where one of the trials has NaN
    %     % regular mean function does not calc if one of the inputs is NaN
    %     DLS_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
    %     % then let's try where we ignore nan with nanmean:
        % DLS_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % % Save the DLS data:  
        % DLS_lick_triggered_trials = lick_triggered_trials;
    









    % %% SNc Plots--------------------------------------------------------------------------------
    %     dummy_data = SNc;
    %     cue_position = cue;


    %     % first lick times are in seconds wrt the cue. We can convert these to the position
    %     lick_positions = round(1000*dummy_licks); % DON'T subtract off cue position bc we are going wrt the whole array!


    %     % expand the time stretch of the data array so we can backfill more times for early rxn licks:
    %     backfill = NaN(num_trials, backfilltime);
    %     cue_position = cue_position + backfilltime; % to account for the back-filled time, the cue_position also has to shift over
    %     lick_positions = lick_positions + backfilltime; % to account for back-filled time
    %     dummy_data = horzcat(backfill, dummy_data);



    %     % need to create an array where we fill in values from before the trial
    %     % let's try finding the first and last positions of numbers in the array
    %     left_bounds = NaN(num_trials,1);
    %     right_bounds = NaN(num_trials,1);
    %     for i_trial = 1:num_trials
    %         left_bounds(i_trial) = min(find(dummy_data(i_trial,:) > -1000000));
    %         right_bounds(i_trial) = max(find(dummy_data(i_trial,:) > -1000000));
    %     end

    %     % now let's make a container for the filled in data:
    %     filled_in_data = dummy_data;

    %     % exclude trial 1 because we cut off the data before it already
    %     % for each trial, pick off as many points as need to be filled in from the trial before
    %     for this_trial = 2:num_trials
    %         last_trial = this_trial - 1;
    %         endposition_thistrial = left_bounds(this_trial); % pluck off this number of points from prior trial and put in the array
    %         startposition_last_trial = right_bounds(last_trial) - endposition_thistrial + 1;
    %         endposition_lasttrial = right_bounds(last_trial);
    %         filled_in_data(this_trial, 1:endposition_thistrial) = dummy_data(last_trial, startposition_last_trial:endposition_lasttrial);
    %     end





    %     % find all positions including lick position and to the right
    %     right_of_and_lick = NaN(size(filled_in_data));


    %     for i_trial = 1:num_trials
    %         %if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
    %         if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
    %             % find the values to append:
    %             values_to_add = filled_in_data(i_trial, lick_positions(i_trial):size(filled_in_data,2));
    %             right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
    %         else
    %             values_to_add = [nan, nan, nan];
    %             right_of_and_lick(i_trial,1:length(values_to_add)) = values_to_add;
    %         end
    %     end

    %     % find all positions left of lick, not including the lick
    %     left_of_lick = NaN(size(filled_in_data));

    %     for i_trial = 1:num_trials
    %         % first, make sure the value of the lick time is not = -(cue_position-1) - that means time was recorded as zero for the lick and so it needs to be excluded
    %         %if lick_positions(i_trial) > 0 % only positive lick positions should be considered, all negative are artifacts of there not being a recorded first lick on that trial
    %         if lick_positions(i_trial) > backfilltime % should actually be > 0 + backfilltime - corrected 7-26-17
    %             % find the values to append:
    %             lick_end = lick_positions(i_trial)-1;
    %             values_to_add = filled_in_data(i_trial, 1:lick_end);
    %             pos_start = size(left_of_lick,2)-length(values_to_add)+1;
    %             pos_end = size(left_of_lick,2);
    %             left_of_lick(i_trial,pos_start:pos_end) = values_to_add;
    %         end
    %     end


    %     % combine the arrays. 
    %     lick_triggered_trials = horzcat(left_of_lick, right_of_and_lick);

    %     % Now position 21 is the position of the lick. Make a new time array:
    %     time_array = NaN(1, size(lick_triggered_trials,2));
    %     position_zero = size(left_of_lick,2) + 1;
    %     position_max = length(time_array) - position_zero;
    %     time_array(position_zero:end) = [0:position_max]; % this will be time in ms
    %     position_zero_1 = position_zero - 1;
    %     time_array(1:position_zero_1) = (-position_zero_1:-1); 


    %     %% Calculating lick-triggered ave
    %     % first, let's see how far we can see if we take the lick-triggered average, excluding any times where one of the trials has NaN
    %     % regular mean function does not calc if one of the inputs is NaN
    %     SNc_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
    %     % then let's try where we ignore nan with nanmean:
    %     SNc_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        %    % Save the SNc data:
        % SNc_lick_triggered_trials = lick_triggered_trials;


 %   %% Variables to save:
    % pav_DLS_lick_triggered_trials = DLS_lick_triggered_trials;
    % pav_SNc_lick_triggered_trials = SNc_lick_triggered_trials;
    % pav_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
    % pav_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;
    % %% The plots:---------------------------------------------------------------------------
    %     figure
    %     ax_pavDLS = subplot(1,2,1)
    %     plot(time_array, smooth(pav_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
    %     xlim(xlimits)
    %     hold on
    %     plot([0,0], [min(smooth(pav_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(pav_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
    %     title(title_DLS)



    %     ax_pavSNc = subplot(1,2,2)
    %     plot(time_array, smooth(pav_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
    %     xlim(xlimits)
    %     hold on
    %     plot([0,0], [min(smooth(pav_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(pav_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
    %     title(title_SNc)




%% Rxn Licks--------------------------------------------------------------------------------------------------
    dummy_licks = d22_f_ex1_lick_rxn;
    title_DLS = 'DLS rxn licks';
    title_SNc = 'SNc rxn licks';
    xlimits = [-4000,1000];

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
        DLS_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        DLS_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);


        % Save the DLS data:
        DLS_lick_triggered_trials = lick_triggered_trials;






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
        SNc_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        SNc_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the SNc data:    
        SNc_lick_triggered_trials = lick_triggered_trials;

    %% Variables to save to header file:
    rxn_DLS_lick_triggered_trials = DLS_lick_triggered_trials;
    rxn_SNc_lick_triggered_trials = SNc_lick_triggered_trials;
    rxn_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
    rxn_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_rxnDLS = subplot(1,2,1)
        plot(time_array, smooth(rxn_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        hold on
        plot([0,0], [min(smooth(rxn_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(rxn_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
        title(title_DLS)



        ax_rxnSNc = subplot(1,2,2)
        plot(time_array, smooth(rxn_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        hold on
        plot([0,0], [min(smooth(rxn_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(rxn_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
        title(title_SNc)




%% Early Licks--------------------------------------------------------------------------------------------------
    dummy_licks = d22_f_ex1_lick_operant_no_rew;
    title_DLS = 'DLS op-early licks';
    title_SNc = 'SNc op-early licks';
    xlimits = [-4000,1000];

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
        DLS_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        DLS_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save DLS data:
        DLS_lick_triggered_trials = lick_triggered_trials;
    






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
        SNc_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        SNc_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save SNc data
        SNc_lick_triggered_trials = lick_triggered_trials;



    %% Variables to save to header file:
    early_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
    early_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;
    early_DLS_lick_triggered_trials = DLS_lick_triggered_trials;
    early_SNc_lick_triggered_trials = SNc_lick_triggered_trials;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_earlyDLS = subplot(1,2,1)
        plot(time_array, smooth(early_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        hold on
        plot([0,0], [min(smooth(early_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(early_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
        title(title_DLS)



        ax_earlySNc = subplot(1,2,2)
        plot(time_array, smooth(early_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        hold on
        plot([0,0], [min(smooth(early_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(early_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
        title(title_SNc)





%% Operant Rewarded Licks--------------------------------------------------------------------------------------------------
    dummy_licks = d22_f_ex1_lick_operant_rew;
    title_DLS = 'DLS op-rewarded licks';
    title_SNc = 'SNc op-rewarded licks';
    xlimits = [-4000,1000];

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
        DLS_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        DLS_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save the DLS data
        DLS_lick_triggered_trials = lick_triggered_trials;
    




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
        SNc_lick_triggered_ave_noNaN = mean(lick_triggered_trials(2:end,:),1);
        % then let's try where we ignore nan with nanmean:
        SNc_lick_triggered_ave_ignore_NaN = nanmean(lick_triggered_trials,1);

        % Save SNc data:
        SNc_lick_triggered_trials = lick_triggered_trials;



    %% Variables to save to header file:
    rew_DLS_lick_triggered_trials = DLS_lick_triggered_trials;
    rew_SNc_lick_triggered_trials = SNc_lick_triggered_trials;
    rew_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
    rew_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;
    %% The plots:---------------------------------------------------------------------------
        figure
        ax_rewDLS = subplot(1,2,1)
        plot(time_array, smooth(rew_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        hold on
        plot([0,0], [min(smooth(rew_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(rew_DLS_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
        title(title_DLS)



        ax_rewSNc = subplot(1,2,2)
        plot(time_array, smooth(rew_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'), 'linewidth', 3)
        xlim(xlimits)
        hold on
        plot([0,0], [min(smooth(rew_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))-0.001, max(smooth(rew_SNc_lick_triggered_ave_ignore_NaN, 50, 'gauss'))+0.001])
        title(title_SNc)






%% Link plots:
    linkaxes([ax_rewSNc, ax_rewDLS, ax_rxnDLS, ax_rxnSNc, ax_earlyDLS, ax_earlySNc],'xy')
    % linkaxes([ax_rxnDLS, ax_rxnSNc, ax_earlyDLS, ax_earlySNc,ax_rewDLS,ax_rewSNc,ax_pavDLS,ax_pavSNc],'xy')
    % turn off with linkaxes([ax_rxnDLS, ax_rxnSNc, ax_earlyDLS, ax_earlySNc,ax_rewDLS,ax_rewSNc,ax_pavDLS,ax_pavSNc],'off')




%% Overlays (not normalized)
    pos1 = find(time_array==range_(1));
    pos2 = find(time_array==range_(2));
    zeropos = find(time_array==0);

    N_rxn_DLS = rxn_DLS_lick_triggered_ave_ignore_NaN;%(pos1:pos2)%/max(rxn_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
    N_rxn_SNc = rxn_SNc_lick_triggered_ave_ignore_NaN;%(pos1:pos2)%/max(rxn_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));

    N_early_DLS = early_DLS_lick_triggered_ave_ignore_NaN;%(pos1:pos2)%/max(early_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
    N_early_SNc = early_SNc_lick_triggered_ave_ignore_NaN;%(pos1:pos2)%/max(early_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));

    N_rew_DLS = rew_DLS_lick_triggered_ave_ignore_NaN;%(pos1:pos2)%/max(rew_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
    N_rew_SNc = rew_SNc_lick_triggered_ave_ignore_NaN;%(pos1:pos2)%/max(rew_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));

    % N_pav_DLS = pav_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2)/max(pav_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
    % N_pav_SNc = pav_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2)/max(pav_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));


    % Plot the overlays:

    figure
    ax1 = subplot(1,2,1) % DLS
    plot(time_array(pos1:pos2),N_rxn_DLS(pos1:pos2), 'linewidth', 3)
    hold on
    plot(time_array(pos1:pos2),N_early_DLS(pos1:pos2), 'linewidth', 3)
    plot(time_array(pos1:pos2),N_rew_DLS(pos1:pos2), 'linewidth', 3)
    % plot(time_array(pos1:pos2),N_pav_DLS, 'linewidth', 3)
    names = {'rxn', 'early', 'rew'};
    % names = {'rxn', 'early', 'rew', 'pav'};
    legend(names)
    xlim(range_)
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)

    ax2 = subplot(1,2,2) % SNc
    plot(time_array(pos1:pos2),N_rxn_SNc(pos1:pos2), 'linewidth', 3)
    hold on
    plot(time_array(pos1:pos2),N_early_SNc(pos1:pos2), 'linewidth', 3)
    plot(time_array(pos1:pos2),N_rew_SNc(pos1:pos2), 'linewidth', 3)
    % plot(time_array(pos1:pos2),N_pav_SNc, 'linewidth', 3)
    legend(names)
    xlim(range_)
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)

    % Plot the overlays:

    figure
    ax3 = subplot(1,2,1) % DLS
    plot(time_array(pos1:pos2),smooth(N_rxn_DLS(pos1:pos2),50,'gauss'), 'linewidth', 3)
    hold on
    plot(time_array(pos1:pos2),smooth(N_early_DLS(pos1:pos2),50,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),smooth(N_rew_DLS(pos1:pos2),50,'gauss'), 'linewidth', 3)
    % plot(time_array(pos1:pos2),smooth(N_pav_DLS,50,'gauss'), 'linewidth', 3)
    names = {'rxn', 'early', 'rew'};
    % names = {'rxn', 'early', 'rew', 'pav'};
    legend(names)
    xlim(range_)
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)

    ax4 = subplot(1,2,2) % SNc
    plot(time_array(pos1:pos2),smooth(N_rxn_SNc(pos1:pos2),50,'gauss'), 'linewidth', 3)
    hold on
    plot(time_array(pos1:pos2),smooth(N_early_SNc(pos1:pos2),50,'gauss'), 'linewidth', 3)
    plot(time_array(pos1:pos2),smooth(N_rew_SNc(pos1:pos2),50,'gauss'), 'linewidth', 3)
    % plot(time_array(pos1:pos2),smooth(N_pav_SNc,50,'gauss'), 'linewidth', 3)
    legend(names)
    xlim(range_)
    plot([0,0], [-1,1], 'g-', 'linewidth', 2)

    linkaxes([ax1, ax2, ax3, ax4],'xy')
    % turn off with linkaxes([ax1, ax2, ax3, ax4],'off')



%% (debug dataset) The plots:
    % figure
    % subplot(1,2,1)
    % plot(time_array, DLS_lick_triggered_ave_ignore_NaN, 'linewidth', 3)
    % xlim(xlimits)
    % hold on
    % plot([0,0], [min(DLS_lick_triggered_ave_ignore_NaN)-0.001, max(DLS_lick_triggered_ave_ignore_NaN)+0.001])
    % title(title_DLS)



    % subplot(1,2,2)
    % plot(time_array, SNc_lick_triggered_ave_ignore_NaN, 'linewidth', 3)
    % xlim(xlimits)
    % hold on
    % plot([0,0], [min(SNc_lick_triggered_ave_ignore_NaN)-0.001, max(SNc_lick_triggered_ave_ignore_NaN)+0.001])
    % title(title_DLS)

