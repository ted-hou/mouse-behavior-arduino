function [times_by_trial, values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx_v1_3(analog_times,...
																					 analog_values,...
																					 trial_start_times,...
																					 cue_on_times,...
                                                                                     trial_duration_)
% 
% Created 			4-24-17 - ahamilos (from put_data_into_trials_aligned_to_cue_on_fx.m)
% Last Modified 	11-2-17 - ahamilos
% 
% Takes raw CED Data and breaks it into trials aligned to cue on at position 1501
% 
% Returns the CED timestamp at each point in the trial and the CED values at each point
% 
% Update 11-2-17: now can handle any input trial duration and pads the back
% end - trial duration should be from cue-on to end of ITI (17000 for
% normal training)
% 
% 

% Length of post-cue array (17001 for photom in normal training):
post_cue_time = trial_duration_ + 1; % must have +1 to deal with differences in sampling between analog and digital lines

% %% Debug defaults:
% analog_times = DLS_times;
% analog_values = DLS_values;
% trial_start_times = trial_start_times;



% % DEBUG:
% analog_times = DLS_times;
% analog_values = gfit_DLS;
% trial_start_times = trial_start_times;
% cue_on_times = cue_on_times;



% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)

analog_trial_start_positions = []; % to track which positions should be the split points
trial_num = 1;

% find the position in the 1xn array where trial is starting (houselamp off)
for i_starttime = 1:length(trial_start_times)
	positions = find(analog_times<trial_start_times(trial_num)+0.001 & analog_times>trial_start_times(trial_num)-0.001);
    analog_trial_start_positions(trial_num) = positions(1);
	trial_num = trial_num + 1;
end

% Find the analog times when start cue on:
analog_cue_on_positions = []; % to track which positions should be the split points
trial_num = 1;

for i_starttime = 1:length(cue_on_times)
	positions = find(analog_times<cue_on_times(trial_num)+0.001 & analog_times>cue_on_times(trial_num)-0.001);
    analog_cue_on_positions(trial_num) = positions(1);
	trial_num = trial_num + 1;
end


% Trim analog to remove non-trial data: delete all times before first trial start and after last trial start
% don't include the last incomplete trial!

analog_times_trimmed = analog_times(analog_trial_start_positions(1):analog_trial_start_positions(end)); %doesn't include the last incomplete trial
analog_values_trimmed = analog_values(analog_trial_start_positions(1):analog_trial_start_positions(end));


% Divide analog into trials 
%	Make pre-cue and post-cue arrays so that it's aligned to the start cue
% For 5 sec interval -> total post-cue length = 1000samples/s * (7 + 10) s = 17000 samples/trial
% Precue delay: 400-1500 ms = 1.5 sec * 1000samples/s = 1500 samples/precue

analog_pre_cue_times_by_trial = NaN(num_trials_plus_1-1, 1500);
analog_post_cue_times_by_trial = NaN(num_trials_plus_1-1, post_cue_time);		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

analog_pre_cue_values_by_trial = NaN(num_trials_plus_1-1, 1500);
analog_post_cue_values_by_trial = NaN(num_trials_plus_1-1, post_cue_time);


trimmed_analog_trial_start_positions = analog_trial_start_positions - analog_trial_start_positions(1) + 1;
trimmed_analog_cue_on_positions = analog_cue_on_positions - analog_trial_start_positions(1) + 1;


% Do the precue files first: try doing the whole thing in reverse
analog_position = length(analog_times_trimmed);
rev_order_trials = abs(-(length(trial_start_times)-1) : 0);
rev_order_times = abs(-18500: -1);
rev_order_time_markers = abs(-1500:-1);
rev_order_analog_times = analog_times_trimmed';
rev_order_analog_values = analog_values_trimmed';
lasttrialdone = false;
dontupdate = false;

for i_trial = rev_order_trials
	pastcue = true;
	newtrial = false;
	precue_position = 1;
	for i_time = rev_order_times % fill the array from the bottom and end (1499:1)
		if find(trimmed_analog_trial_start_positions == analog_position)
			% Need to ignore the last trial start time because is not a full trial:
			if lasttrialdone == false
				lasttrialdone = true;
                analog_position = analog_position - 1;
			else
				newtrial = true;
				analog_pre_cue_times_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_analog_times(analog_position);
				analog_pre_cue_values_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_analog_values(analog_position);
				analog_position = analog_position - 1;
				break
			end
		elseif find(trimmed_analog_cue_on_positions == analog_position)
			pastcue = false;
			dontupdate = true;
            analog_position = analog_position - 1;
		end

		if dontupdate
            dontupdate = false;
        elseif ~pastcue && ~newtrial
			analog_pre_cue_times_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_analog_times(analog_position);
			analog_pre_cue_values_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_analog_values(analog_position);
			analog_position = analog_position - 1;
			precue_position = precue_position+1;
        else
			analog_position = analog_position - 1;
		end
		if analog_position > length(rev_order_analog_times)
			break
		end
	end
	if analog_position > length(rev_order_analog_times)
		break
	end
end




%% Now the postcue:
analog_position = 1;
positions_array = [1:post_cue_time];
dontupdate = false;

for i_trial = 0:(length(trial_start_times)-1)
	pastcue = false;
	newtrial = false;
	for i_time = 1:18500 % fill the array from the front
		if find(trimmed_analog_trial_start_positions == analog_position)
			newtrial = true;
			analog_position = analog_position + 1;
			postcue_position = 1;
			break
        elseif find(trimmed_analog_cue_on_positions == analog_position)
            analog_post_cue_times_by_trial(i_trial, postcue_position) = analog_times_trimmed(analog_position);
			analog_post_cue_values_by_trial(i_trial, postcue_position) = analog_values_trimmed(analog_position);
			pastcue = true;
			dontupdate = true;
            analog_position = analog_position + 1;
            postcue_position = postcue_position + 1;
        end
        
%         if postcue_position == 17002
%             disp(postcue_position)
%             break
%         end
        
        if pastcue && ~dontupdate
			analog_post_cue_times_by_trial(i_trial, positions_array(postcue_position)) = analog_times_trimmed(analog_position);
			analog_post_cue_values_by_trial(i_trial, positions_array(postcue_position)) = analog_values_trimmed(analog_position);
			analog_position = analog_position + 1;
			postcue_position = postcue_position+1;
        elseif dontupdate
        % do nothing
            dontupdate = false;
        else
			analog_position = analog_position + 1;
		end
		if analog_position > length(analog_times_trimmed)
			break
		end
	end
	if analog_position > length(analog_times_trimmed)
		break
	end
end


%% Combine into one vector:
times_by_trial = horzcat(analog_pre_cue_times_by_trial, analog_post_cue_times_by_trial);
values_by_trial = horzcat(analog_pre_cue_values_by_trial, analog_post_cue_values_by_trial);
% CUE ON marker @ column position 1501!!!