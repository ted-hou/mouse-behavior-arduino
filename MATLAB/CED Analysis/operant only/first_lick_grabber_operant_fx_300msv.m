function [f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI,...
trials_with_rxn, trials_with_train, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx_300msv(lick_times_by_trial, num_trials)
% 
%   Update: 7-14-17: for 300 ms rxn window
% 	Update: 7-21-17: verified with H4 day 11 - appears to work without errors
% 
% Copy and paste after running lick_times_by_trial_fx:
%       [f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, ~, ~, ~, all_first_licks] = first_lick_grabber_operant_fx_300msv(lick_times_by_trial, num_trials);
% 
%   [d15_f_ex1_lick_rxn, d15_f_ex1_lick_train_abort, d15_f_ex1_lick_operant_no_rew, d15_f_ex1_lick_operant_rew, d15_f_ex1_lick_ITI, ~, ~, ~, d15_all_ex1_first_licks] = first_lick_grabber_operant_fx_300msv(d15_lick_ex1_times_by_trial, num_trials);
% 
%   Created: 4/10/17   - ahamilos
% 	Modified: 7/14/17  - ahamilos
% 
% Lick times all wrt the analog data array! (t=1500 or 1.5 = cue on -- in SECONDS and +1.5 wrt cue on)
% 
%  IMPORTANT: Note how lick categories defined:
%		rxn lick: a lick within 300 ms of the cue
% 		rxn train abort lick: lick within first 200 ms of no-lick window if there was a rxn lick in same trial (<500 ms after cue) - while some may not be trains, this will exclude trains from our consideration
% 		op lick: if no rxn lick: a lick > 300 ms until target time. else: a lick > 500 ms until target time, whether rewarded or not
% 		ITI lick: a lick after start ITI
% 
%  NOTE: lick_times_by_trial_fx also finds the pre-cue licks, so you can use that later
% 
%--------------------------------------------------------------
% times in seconds:
buffer_time = 0.2; % gives 200ms after rxn window for rxn train abort
cue_on_time = 1.5;
rxn_window = 0.3;
op_win_open = 3.333;
ITI_begin = 7;
total_time = 17;
target_time = 5;


rxn_range = [cue_on_time, cue_on_time + rxn_window]; % this is the length of the allotted period 
rxn_train_abort_range = [cue_on_time + rxn_window, cue_on_time + rxn_window + buffer_time]; % these trials were early lick aborts by trains, we will exclude if there was a rxn lick because could still be a rxn or train here, and this will eliminate trains
operant_no_rew_range = [cue_on_time + rxn_window + buffer_time, cue_on_time + op_win_open]; % this is window of what we score as 1st lick in No-lick window till the target + 0.1 because is too fast for rxn
operant_rew_range = [cue_on_time + op_win_open, cue_on_time + ITI_begin]; %1.5 + 3.5]
% pavlovian_range = [1.5 + 7, 1.5 + 7]; % NOTE: this essentially makes pavlovian not exist
post_ITI_range = [cue_on_time + ITI_begin, cue_on_time + total_time];
% note this means that aborted trials with rxn train to the cue will have a find(rxn_range(position)) = true, but no other 1st licks

f_lick_rxn = zeros(1, num_trials);
f_lick_train_abort = zeros(1, num_trials);
f_lick_operant_rew = zeros(1, num_trials);
f_lick_operant_no_rew = zeros(1, num_trials);
% f_lick_pavlovian = zeros(1, num_trials);
f_lick_ITI = zeros(1, num_trials);

% Determine time of each first rxn lick in a trial, if any. if no first rxn lick, fill as NaN:
scored_rxn = false;
scored_op_no_rew = false;
% scored_pav = false;
scored_ITI = false;

op_lick_in_trial_no_rew = false;
% pav_lick_in_trial = false;
i_lick_in_trial = 1;

for i_trial = 1:num_trials
	% if no licks in the trial, skip the trial:
	if lick_times_by_trial(i_trial, 1) == 0
		%ignore this whole thing...
	else
		scored_rxn = false;
		scored_rxn_train = false;
		scored_op_no_rew = false;
        scored_op_rew = false;
% 		scored_pav = false;
		scored_ITI = false;
		rxn_lick_in_trial = false;
        op_lick_in_trial_no_rew = false;
        op_lick_in_trial_rew = false;
%         pav_lick_in_trial = false;
        rxn_train_in_trial = false;
		i_lick_in_trial = 1;
		while i_lick_in_trial < size(lick_times_by_trial, 2)
			% check for first post-cue lick:
            if lick_times_by_trial(i_trial, i_lick_in_trial) == 0
                break
            end
			if ~scored_rxn && ~scored_op_no_rew && ~scored_op_rew && ~scored_ITI %&& ~scored_pav 
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_range(2)
					f_lick_rxn(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					rxn_lick_in_trial = true;
					scored_rxn = true;
				else
					scored_rxn = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
                    i_lick_in_trial = i_lick_in_trial - 1;
				end
			elseif rxn_lick_in_trial && ~scored_rxn_train
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_train_abort_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_train_abort_range(2)
					f_lick_train_abort(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					rxn_train_in_trial = true;
					scored_rxn_train = true;
                elseif lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_train_abort_range(2)
					scored_rxn_train = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end

			% now check for first op lick - not rewarded:
			elseif ~scored_op_no_rew && ~scored_op_rew && ~scored_ITI && ~rxn_train_in_trial %&& ~scored_pav 
				if ~rxn_lick_in_trial % check range [500ms to 3333]
					if lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_no_rew_range(2)
						f_lick_operant_no_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
						scored_op_no_rew = true;
						op_lick_in_trial_no_rew = true;
					elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(2)
						scored_op_no_rew = true; % so you don't enter if statement again...
						% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
						i_lick_in_trial = i_lick_in_trial - 1;
                    end
                    
				elseif rxn_lick_in_trial % check range [700ms to 3333]
					if lick_times_by_trial(i_trial, i_lick_in_trial) > (operant_no_rew_range(1) + 0.2) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_no_rew_range(2)
						f_lick_operant_no_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
						scored_op_no_rew = true;
						op_lick_in_trial_no_rew = true;
					elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(2)
						scored_op_no_rew = true; % so you don't enter if statement again...
						% then go back and check for this lick again, because otherwise will miss the first pav/ITI:
						i_lick_in_trial = i_lick_in_trial - 1;
					end
                end

            % now check for first op lick - rewarded:
			elseif ~scored_op_rew && ~scored_ITI && ~rxn_train_in_trial && ~op_lick_in_trial_no_rew %&& ~scored_pav
				if ~rxn_lick_in_trial % check range [3333ms to target]
					if lick_times_by_trial(i_trial, i_lick_in_trial) > operant_rew_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_rew_range(2)
						f_lick_operant_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
						scored_op_rew = true;
						op_lick_in_trial_rew = true;
					elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_rew_range(2)
						scored_op_rew = true; % so you don't enter if statement again...
						% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
						i_lick_in_trial = i_lick_in_trial - 1;
                    end
                    
				elseif rxn_lick_in_trial % check range [3333ms to target]
					if lick_times_by_trial(i_trial, i_lick_in_trial) > (operant_rew_range(1) + 0.2) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_rew_range(2)
						f_lick_operant_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
						scored_op_rew = true;
						op_lick_in_trial_rew = true;
					elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_rew_range(2)
						scored_op_rew = true; % so you don't enter if statement again...
						% then go back and check for this lick again, because otherwise will miss the first pav/ITI:
						i_lick_in_trial = i_lick_in_trial - 1;
					end
                end
                
                
%             % check for pavlovian reward
% 			elseif ~scored_pav && ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~rxn_train_in_trial
% 				if lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= pavlovian_range(2)
% 					f_lick_pavlovian(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
% 					
% 					scored_pav = true;
% 					pav_lick_in_trial = true;
% 				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(2)
% 					scored_pav = true; % so you don't enter if statement again...
% 					% then go back and check for this lick again, because otherwise will miss the first ITI:
% 					i_lick_in_trial = i_lick_in_trial - 1;
% 				end

			elseif ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~rxn_train_in_trial %&& ~pav_lick_in_trial 
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
trials_with_train = find(f_lick_train_abort > 0);
trials_with_op_no_rew = find(f_lick_operant_no_rew > 0);
trials_with_op_rew = find(f_lick_operant_rew > 0);
% trials_with_pav = find(f_lick_pavlovian > 0);
trials_with_ITI = find(f_lick_ITI > 0);

% All scored first licks (excluding the rxn/train):
all_first_licks = f_lick_operant_no_rew + f_lick_operant_rew + f_lick_ITI;




end