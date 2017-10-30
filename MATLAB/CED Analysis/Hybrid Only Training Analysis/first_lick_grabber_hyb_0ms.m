function [f_lick_rxn,f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,...
trials_with_rxn, trials_with_pav, trials_with_ITI, all_first_licks] = first_lick_grabber_hyb_0ms(lick_times_by_trial, num_trials)
%-------------HYBRID, 0 ms rxn**************** (8-4-17)
% 
% 
% 
% Type:
% [f_lick_rxn,f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,~, ~, ~, all_first_licks] = first_lick_grabber_hyb_0ms(lick_times_by_trial, num_trials)
% [f_ex_lick_rxn,f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_pavlovian, f_ex_lick_ITI,~, ~, ~, all_ex_first_licks] = first_lick_grabber_hyb_0ms(lick_ex_times_by_trial, num_trials);
% 
% 
% UPDATE LOG:
% 8-14-17: ERROR DETECTED - not computing all_first_licks correctly -- was
%           because counting ITI licks when trials were pavlovian. Fixed today!
% 8-04-17: Created 0ms version from hyb (500ms version) last updated 7-24-17
% 7-24-17: FOUND ERRORS - fixed with 500ms operant version. need to redo H4's + B3's data. Now is compatible with any rxn time
% 			checked against Missy H5 - indeed corrected errors!
% 7-21-17: carefully reviewed for errors - checked against raster, all ok
% 6-30-17: New version for Hybrid only - use with early training days, will
%            score pav and op licks
% 5-24-17: detected error @ line 165 - should be NOT (~op_lick_in_trial_rew) in if statement
% 
% 	Created:  8/04/17  - ahamilos
% 	Modified: 8/14/17  - ahamilos
% 
% Lick times all wrt the analog data array! (t=1500 or 1.5 = cue on)
% 
% 
%--------------------------------------------------------------
% NOTE: to deal with 0ms rxn time, we will change the search structure instead of the times up top
% times in seconds:
cue_on_time = 1.5;
rxn_window = 0.5; % there's no rxns allowed, but we still don't want to be looking at these licks because they are rxns to the cue
op_win_open = 3.333;
ITI_begin = 7;
total_time = 17;
target_time = 5;


rxn_range = [cue_on_time, cue_on_time + rxn_window]; % this is the length of the allotted period 
operant_no_rew_range = [cue_on_time + rxn_window, cue_on_time + op_win_open]; % this is window of what we score as 1st lick in No-lick window till the target + 0.1 because is too fast for rxn
operant_rew_range = [cue_on_time + op_win_open, cue_on_time + target_time+.1]; %1.5 + 3.5]
pavlovian_range = [cue_on_time + target_time+.1, cue_on_time + ITI_begin];
post_ITI_range = [cue_on_time + ITI_begin, cue_on_time + total_time];

% note this means that aborted trials with rxn train to the cue will have a find(rxn_range(position)) = true, but no other 1st licks



f_lick_rxn = zeros(1, num_trials);
f_lick_operant_rew = zeros(1, num_trials);
f_lick_operant_no_rew = zeros(1, num_trials);
f_lick_pavlovian = zeros(1, num_trials);
f_lick_ITI = zeros(1, num_trials);



% Determine time of each first rxn lick in a trial, if any. if no first rxn lick, fill as NaN:


% Determine time of each first rxn lick in a trial, if any. if no first rxn lick, fill as NaN:
i_lick_in_trial = 1;

for i_trial = 1:num_trials
	% if no licks in the trial, skip the trial:
	if lick_times_by_trial(i_trial, 1) == 0
		%ignore this whole thing...
	else
		scored_rxn = false;
		scored_op_no_rew = false;
        scored_op_rew = false;
        scored_pav = false;
		scored_ITI = false;
		rxn_lick_in_trial = false;
        op_lick_in_trial_no_rew = false;
        op_lick_in_trial_rew = false;
        pav_lick_in_trial = false;
		i_lick_in_trial = 1;

		while i_lick_in_trial < size(lick_times_by_trial, 2)
			% check for first post-cue lick:
            if lick_times_by_trial(i_trial, i_lick_in_trial) == 0
                break
            end
            % check for rxn to cue lick
			if ~scored_rxn && ~scored_op_no_rew && ~scored_op_rew && ~scored_ITI 
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_range(2)
					f_lick_rxn(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					rxn_lick_in_trial = true;
					scored_rxn = true;
				else
					scored_rxn = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
                    i_lick_in_trial = i_lick_in_trial - 1;
				end
			% now check for first op lick - not rewarded:
			elseif ~scored_op_no_rew && ~scored_op_rew && ~scored_ITI && ~rxn_lick_in_trial
					% check range [500ms to 3333]
				if lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_no_rew_range(2)
					f_lick_operant_no_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					scored_op_no_rew = true;
					op_lick_in_trial_no_rew = true;
				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(2)
					scored_op_no_rew = true; % so you don't enter if statement again...
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
                end
                
            % now check for first op lick - rewarded:
			elseif ~scored_op_rew && ~scored_ITI && ~op_lick_in_trial_no_rew && ~rxn_lick_in_trial %&& ~scored_pav && ~rxn_train_in_trial 
					% check range [3333ms to target]
				if lick_times_by_trial(i_trial, i_lick_in_trial) > operant_rew_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_rew_range(2)
					f_lick_operant_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					scored_op_rew = true;
					op_lick_in_trial_rew = true;
				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_rew_range(2)
					scored_op_rew = true; % so you don't enter if statement again...
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
                end

			% check for pavlovian reward
			elseif ~scored_pav && ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~rxn_lick_in_trial
				if lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= pavlovian_range(2)
					f_lick_pavlovian(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					scored_pav = true;
					pav_lick_in_trial = true;
				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(2)
					scored_pav = true; % so you don't enter if statement again...
					% then go back and check for this lick again, because otherwise will miss the first ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end

            % check for first lick in ITI
			elseif ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~rxn_lick_in_trial && ~pav_lick_in_trial  
				if lick_times_by_trial(i_trial, i_lick_in_trial) > post_ITI_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= post_ITI_range(2)
					f_lick_ITI(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					
					scored_ITI = true;
				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > post_ITI_range(2)
					scored_ITI = true; % so you don't enter if statement again...
                end
            end
			i_lick_in_trial = i_lick_in_trial + 1; % move on to the next lick if haven't done anything yet without doing anything
		end
    end
    
    

% Checking your work: Identify rxn lick trials, train trials, op trials, and pav trials:
trials_with_rxn = find(f_lick_rxn > 0);
trials_with_op_no_rew = find(f_lick_operant_no_rew > 0);
trials_with_op_rew = find(f_lick_operant_rew > 0);
trials_with_pav = find(f_lick_pavlovian > 0);
trials_with_ITI = find(f_lick_ITI > 0);

% All scored first licks (excluding the rxn/train):
all_first_licks = f_lick_operant_no_rew + f_lick_operant_rew + f_lick_pavlovian + f_lick_ITI;         


end