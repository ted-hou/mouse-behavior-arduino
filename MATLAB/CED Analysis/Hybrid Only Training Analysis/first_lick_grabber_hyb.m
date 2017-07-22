function [f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,...
trials_with_rxn, trials_with_train, trials_with_pav, trials_with_ITI, all_first_licks] = first_lick_grabber_hyb(lick_times_by_trial, num_trials)

% Type:
% [f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,~,~,~,~, all_first_licks] = first_lick_grabber_hyb(lick_times_by_trial, num_trials)
%[d3_f_ex1_lick_rxn, d3_f_ex1_lick_train_abort, d3_f_ex1_lick_operant_no_rew, d3_f_ex1_lick_operant_rew, d3_f_ex1_lick_pavlovian, d3_f_ex1_lick_ITI,~,~,~,~, d3_all_ex1_first_licks] = first_lick_grabber_hyb(d3_lick_ex1_times_by_trial, num_trials)

% 	FOR USE WITH HYBRID, 500 ms rxn**************** (7-21-17) - verified error-free on 7-21-17 vs H4 days 3 and 5
% 
% 7-21-17: carefully reviewed for errors - checked against raster, all ok

% 6-30-17: New version for Hybrid only - use with early training days, will
%            score pav and op licks
% 5-24-17: detected error @ line 165 - should be NOT (~op_lick_in_trial_rew) in if statement

% CAUTION: as written, all_first_licks doesn't have f_lick_train_abort

% 	Created: 4/10/17   - ahamilos
% 	Modified: 7/21/17  - ahamilos

% Lick times all wrt the analog data array! (t=1500 or 1.5 = cue on)

%  IMPORTANT: Note how lick categories defined:
%		rxn lick: a lick within 500 ms of the cue
% 		rxn train abort lick: lick within first 200 ms of no-lick window if there was a rxn lick in same trial (<700 ms after cue) - while some may not be trains, this will exclude trains from our consideration
% 		op lick: if no rxn lick: a lick > 500 ms until target time. else: a lick > 700 ms until target time, whether rewarded or not
% 		pav lick: a lick between target and trial end (7000 ms)
% 		ITI lick: a lick after start ITI

%  NOTE: lick_times_by_trial_fx also finds the pre-cue licks, so you can use that later

%--------------------------------------------------------------

cue_on_time = 1.5;
% The rest all get added to the cue_on_time so defined wrt cue=0, in sec
buffer_time = 0; % how much to exclude from abort window open for op_no_rew_licks
rxn_time = 0.5;
op_win_open = 3.333;
target_time = 5;
trial_duration = 7;
total_trial_length = 17;




rxn_range = [cue_on_time, cue_on_time + rxn_time]; % this is the length of the allotted period 
rxn_train_abort_range = [cue_on_time + rxn_time, cue_on_time + rxn_time + 0.2]; % these trials were early lick aborts by trains, we will exclude if there was a rxn lick because could still be a rxn or train here, and this will eliminate trains
operant_no_rew_range = [cue_on_time + rxn_time + buffer_time, cue_on_time + op_win_open]; % this is window of what we score as 1st lick in No-lick window till the target + 0.1 because is too fast for rxn
operant_rew_range = [cue_on_time + op_win_open, cue_on_time + target_time+.1]; %1.5 + 3.5]
pavlovian_range = [cue_on_time + target_time+.1, cue_on_time + trial_duration];
post_ITI_range = [cue_on_time + trial_duration, cue_on_time + total_trial_length];
% note this means that aborted trials with rxn train to the cue will have a find(rxn_range(position)) = true, but no other 1st licks

f_lick_rxn = zeros(1, num_trials);
f_lick_train_abort = zeros(1, num_trials);
f_lick_operant_rew = zeros(1, num_trials);
f_lick_operant_no_rew = zeros(1, num_trials);
f_lick_pavlovian = zeros(1, num_trials);
f_lick_ITI = zeros(1, num_trials);

% Determine time of each first rxn lick in a trial, if any. if no first rxn lick, fill as NaN:
scored_rxn = false;
scored_op_no_rew = false;
scored_pav = false;
scored_ITI = false;

op_lick_in_trial_no_rew = false;
pav_lick_in_trial = false;
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
		scored_pav = false;
		scored_ITI = false;
		rxn_lick_in_trial = false;
        op_lick_in_trial_no_rew = false;
        op_lick_in_trial_rew = false;
        pav_lick_in_trial = false;
        rxn_train_in_trial = false;
		i_lick_in_trial = 1;
		while i_lick_in_trial < size(lick_times_by_trial, 2)
			% check for first post-cue lick:
            if lick_times_by_trial(i_trial, i_lick_in_trial) == 0
                break
            end
			if ~scored_rxn && ~scored_op_no_rew && ~scored_op_rew && ~scored_pav && ~scored_ITI
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
			elseif ~scored_op_no_rew && ~scored_op_rew && ~scored_pav && ~scored_ITI && ~rxn_train_in_trial
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
			elseif ~scored_op_rew && ~scored_pav && ~scored_ITI && ~rxn_train_in_trial && ~op_lick_in_trial_no_rew
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
                
                
            % check for pavlovian reward
			elseif ~scored_pav && ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~rxn_train_in_trial
				if lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= pavlovian_range(2)
					f_lick_pavlovian(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					
					scored_pav = true;
					pav_lick_in_trial = true;
				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(2)
					scored_pav = true; % so you don't enter if statement again...
					% then go back and check for this lick again, because otherwise will miss the first ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end

			elseif ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~pav_lick_in_trial && ~rxn_train_in_trial
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
trials_with_pav = find(f_lick_pavlovian > 0);
trials_with_ITI = find(f_lick_ITI > 0);

% All scored first licks (excluding the rxn/train):
all_first_licks = f_lick_operant_no_rew + f_lick_operant_rew + f_lick_pavlovian + f_lick_ITI;




end