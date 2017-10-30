function [filled_in_data, filled_in_ex_data, filled_in_data_trimmed, filled_in_ex_data_trimmed] = fill_in_nans_from_back_fx(dummy_data, dummy_ex_data, num_trials)

%% Fill in NaNs from the Back
% 
%  The equivalent of a back sided attack! Use on the full dataset (no exclusions and exclusions)
% 
%    [combined_DLS_values_by_trial_fi, combined_DLS_ex_values_by_trial_fi,combined_DLS_values_by_trial_fi_trim, combined_DLS_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(combined_DLS_values_by_trial, combined_DLS_ex_values_by_trial, num_trials);
% 	 [combined_SNc_values_by_trial_fi, combined_SNc_ex_values_by_trial_fi,combined_SNc_values_by_trial_fi_trim, combined_SNc_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(combined_SNc_values_by_trial, combined_SNc_ex_values_by_trial, num_trials);
% 

% dummy_data = d11_2_DLS_values_by_trial;
% dummy_ex_data = d11_2_DLS_ex1_values_by_trial;
cue = 1500;
backfilltime = 5000;

 %% DLS Plots---------------------------------------------------------------------------
        
        cue_position = cue;



        % expand the time stretch of the data array so we can backfill more times for early rxn licks:
        backfill = NaN(num_trials, backfilltime);
        cue_position = cue_position + backfilltime; % to account for the back-filled time, the cue_position also has to shift over
        dummy_data = horzcat(backfill, dummy_data);
        dummy_ex_data = horzcat(backfill, dummy_ex_data);



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
        filled_in_ex_data = dummy_ex_data;

        % exclude trial 1 because we cut off the data before it already
        % for each trial, pick off as many points as need to be filled in from the trial before
        for this_trial = 2:num_trials
            last_trial = this_trial - 1;
            endposition_thistrial = left_bounds(this_trial); % pluck off this number of points from prior trial and put in the array
            startposition_last_trial = right_bounds(last_trial) - endposition_thistrial + 1;
            endposition_lasttrial = right_bounds(last_trial);
            filled_in_data(this_trial, 1:endposition_thistrial) = dummy_data(last_trial, startposition_last_trial:endposition_lasttrial);
            if find(filled_in_ex_data(this_trial, :) > -1000000)
            	filled_in_ex_data(this_trial, 1:endposition_thistrial-1) = dummy_data(last_trial, startposition_last_trial+1:endposition_lasttrial);
        	end
        end


% trim off the excess:
filled_in_data_trimmed = filled_in_data(:, backfilltime+1:end);
filled_in_ex_data_trimmed = filled_in_ex_data(:, backfilltime+1:end);