% function [lick_times_by_trial] = lick_times_by_trial_fx(lick_times, cue_on_times, trial_duration_cue_to_end_ITI, num_trials)

% The goal is to find all the lick times in a trial aligned to the analog
% array. Thus a lick at the time of the cue is at t = 1500


% lick_times_by_trial is RELATIVE TO ANALOG ARRAY - tcue = 1.5 sec - validated 2:48pm on 4/12/17

% NOTE: digital times in seconds!!!! 

% % defaults:
lick_times = lick_struct.times;
cue_on_times = cue_on_struct.times;
trial_duration_cue_to_end_ITI = 17;
num_trials = num_trials;

cue_pos = 1;
lick_pos = 1;

lick_times_by_trial = []; % note that non-filled in cells will be assigned 0
pre_cue_licks_by_trial = [];

for i_trial = 1:num_trials % don't include last trial start because is not a full trial
	lick_in_trial_pos = 1;
	lick_in_PRE_trial_pos = 1;
	for i_lick = 1:length(lick_times)
		if lick_times(lick_pos) > cue_on_times(i_trial) && lick_times(lick_pos) < cue_on_times(i_trial + 1) && lick_times(lick_pos) < (cue_on_times(i_trial) + trial_duration_cue_to_end_ITI)
			lick_times_by_trial(i_trial, lick_in_trial_pos) = lick_times(lick_pos) - cue_on_times(i_trial) + 1.5; % put in terms of the trial timeline. A lick at the cue is @ t=1500
			lick_in_trial_pos = lick_in_trial_pos + 1;
            lick_pos = lick_pos + 1;

		elseif lick_times(lick_pos) < cue_on_times(i_trial) && lick_times(lick_pos) > (cue_on_times(i_trial) - 1.5)
			pre_cue_licks_by_trial(i_trial, lick_in_PRE_trial_pos) = lick_times(lick_pos) - cue_on_times(i_trial) + 1.5;
			lick_in_PRE_trial_pos = lick_in_PRE_trial_pos + 1;
            lick_pos = lick_pos + 1;
            
		else
% 			lick_pos = lick_pos; % keep same position in lick array
% 			break
		end
	end
end

