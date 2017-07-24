function [f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,...
trials_with_rxn, trials_with_rxn_fail, trials_with_pav, trials_with_ITI, all_first_licks] = first_lick_grabber_hyb(lick_times_by_trial, num_trials)

% Type:
% [f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,~,~,~,~, all_first_licks] = first_lick_grabber_hyb(lick_times_by_trial, num_trials)
%[d5_f_ex1_lick_rxn, d5_f_ex1_lick_train_abort, d5_f_ex1_lick_operant_no_rew, d5_f_ex1_lick_operant_rew, d5_f_ex1_lick_pavlovian, d5_f_ex1_lick_ITI,~,~,~,~, d5_all_ex1_first_licks] = first_lick_grabber_hyb(d5_lick_ex1_times_by_trial, num_trials)

% 	FOR USE WITH HYBRID, 500 ms rxn**************** (7-21-17) - verified error-free on 7-21-17 vs H4 days 3 and 5
% 

% 7-24-17: FOUND ERRORS - fixed with 500ms operant version. need to redo H4's + B3's data. Now is compatible with any rxn time
% 			checked against Missy H5 - indeed corrected errors!
% 7-21-17: carefully reviewed for errors - checked against raster, all ok

% 6-30-17: New version for Hybrid only - use with early training days, will
%            score pav and op licks
% 5-24-17: detected error @ line 165 - should be NOT (~op_lick_in_trial_rew) in if statement



% CAUTION: as written, all_first_licks doesn't have f_lick_rxn_abort

% 	Created: 4/10/17   - ahamilos
% 	Modified: 7/24/17  - ahamilos

% Lick times all wrt the analog data array! (t=1500 or 1.5 = cue on)

%  IMPORTANT: Note how lick categories defined:
%		rxn lick: a lick within 500 ms of the cue
% 		rxn train abort lick: lick within first 200 ms of no-lick window if there was a rxn lick in same trial (<700 ms after cue) - while some may not be trains, this will exclude trains from our consideration
% 		op lick: if no rxn lick: a lick > 500 ms until target time. else: a lick > 700 ms until target time, whether rewarded or not
% 		pav lick: a lick between target and trial end (7000 ms)
% 		ITI lick: a lick after start ITI

%  NOTE: lick_times_by_trial_fx also finds the pre-cue licks, so you can use that later

%--------------------------------------------------------------
% times in seconds:

cue_on_time = 1.5;
% The rest all get added to the cue_on_time so defined wrt cue=0, in sec
rxn_window = 0.5; % need to score any rxn as rxn whether fail or not
rxn_ok_window = 0.5;
rxn_fail_window = 0.5; % end of what we will score as rxns, (e.g., 0.5s after cue, though within 0.3s is ok)
rxn_train_abort = 0.2; % add onto rxn_ok_window
op_win_open = 3.333;
ITI_begin = 7;
total_time = 17;
target_time = 5;


rxn_range = [cue_on_time, cue_on_time + rxn_window]; % we call any lick in this range a rxn, whether allowed or not
rxn_range_ok = [cue_on_time, cue_on_time + rxn_ok_window]; % this is the length of the allotted period for rxn
rxn_range_fail = [cue_on_time + rxn_ok_window, cue_on_time + rxn_fail_window]; % these trials were early lick aborts by trains, we will exclude if there was a rxn lick because could still be a rxn or train here, and this will eliminate trains
rxn_range_train_abort = [cue_on_time + rxn_ok_window, cue_on_time + rxn_ok_window + rxn_train_abort]; 
operant_no_rew_range = [cue_on_time + rxn_fail_window, cue_on_time + op_win_open]; % this is window of what we score as 1st lick in No-lick window till the target + 0.1 because is too fast for rxn
operant_rew_range = [cue_on_time + op_win_open, cue_on_time + target_time+.1]; %1.5 + 3.5]
pavlovian_range = [cue_on_time + target_time+.1, cue_on_time + ITI_begin];
post_ITI_range = [cue_on_time + ITI_begin, cue_on_time + total_time];
% note this means that aborted trials with rxn train to the cue will have a find(rxn_range(position)) = true, but no other 1st licks



f_lick_rxn = zeros(1, num_trials);
f_lick_rxn_ok = zeros(1, num_trials);
f_lick_rxn_fail = zeros(1,num_trials); % this is for licks within 500 ms rxn window that are failures in 300ms task, but not nec rxn trains
f_lick_rxn_abort = zeros(1, num_trials); % this is still a train abort
f_lick_operant_rew = zeros(1, num_trials);
f_lick_operant_no_rew = zeros(1, num_trials);
f_lick_pavlovian = zeros(1, num_trials);
f_lick_ITI = zeros(1, num_trials);



% Determine time of each first rxn lick in a trial, if any. if no first rxn lick, fill as NaN:

i_lick_in_trial = 1;

for i_trial = 1:num_trials
	% if no licks in the trial, skip the trial:
	if lick_times_by_trial(i_trial, 1) == 0
		%ignore this whole thing...
	else
		scored_rxn = false;
		scored_rxn_ok = false;
		scored_rxn_failure = false;
		scored_rxn_abort = false;
		scored_op_no_rew = false;
        scored_op_rew = false;
        scored_pav = false;
		scored_ITI = false;
		rxn_lick_in_trial = false;
        op_lick_in_trial_no_rew = false;
        op_lick_in_trial_rew = false;
        pav_lick_in_trial = false;
        rxn_ok_in_trial = false;
        rxn_fail_in_trial = false;
		i_lick_in_trial = 1;

		while i_lick_in_trial < size(lick_times_by_trial, 2)
			% check for first post-cue lick:
            if lick_times_by_trial(i_trial, i_lick_in_trial) == 0
                break
            end
 			% before anything, determine if there's a rxn lick (fail or not)
			if ~scored_rxn
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_range(2)
					f_lick_rxn(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					scored_rxn = true;
					rxn_lick_in_trial = true;
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				else
					scored_rxn = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
					% don't increment the lick yet bc need to check and see if disallowed
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end
			% check for an acceptable rxn if there's a rxn in trial
			elseif rxn_lick_in_trial && ~scored_rxn_ok
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range_ok(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_range_ok(2)
					f_lick_rxn_ok(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					rxn_ok_in_trial = true;
					scored_rxn_ok = true;
                elseif lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range_ok(2)
					scored_rxn_ok = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end

			% now check for rxn train abort:
			elseif rxn_ok_in_trial && ~scored_rxn_abort 
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range_train_abort(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_range_train_abort(2)
					f_lick_rxn_abort(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					rxn_fail_in_trial = true;
					scored_rxn_abort = true;
                elseif lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range_train_abort(2)
					scored_rxn_abort = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end



			% now check and see if there's a reaction failure
			elseif rxn_lick_in_trial && ~scored_rxn_failure 
				if lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range_fail(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= rxn_range_fail(2)
					f_lick_rxn_fail(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					rxn_fail_in_trial = true;
					scored_rxn_failure = true;
                elseif lick_times_by_trial(i_trial, i_lick_in_trial) > rxn_range_fail(2)
					scored_rxn_failure = true; % so you don't enter the if statement again when you've already checked and not found a rxn lick
					% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end



			% now check for first op lick - not rewarded:
			elseif ~scored_op_no_rew && ~scored_op_rew && ~scored_ITI && ~rxn_fail_in_trial
				if ~rxn_ok_in_trial % check range [500ms to 3333]
					if lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_no_rew_range(2)
						f_lick_operant_no_rew(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
						scored_op_no_rew = true;
						op_lick_in_trial_no_rew = true;
					elseif lick_times_by_trial(i_trial, i_lick_in_trial) > operant_no_rew_range(2)
						scored_op_no_rew = true; % so you don't enter if statement again...
						% then go back and check for this lick again, because otherwise will miss the first op/pav/ITI:
						i_lick_in_trial = i_lick_in_trial - 1;
                    end
                    
				elseif rxn_ok_in_trial % check range [700ms to 3333] -- the buffer is same time as we would have said an abort would be - makes sense. this may even be redundant
					if lick_times_by_trial(i_trial, i_lick_in_trial) > (operant_no_rew_range(1) + rxn_train_abort) && lick_times_by_trial(i_trial, i_lick_in_trial) <= operant_no_rew_range(2)
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
			elseif ~scored_op_rew && ~scored_ITI && ~rxn_fail_in_trial && ~op_lick_in_trial_no_rew
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
			elseif ~scored_pav && ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~rxn_fail_in_trial
				if lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(1) && lick_times_by_trial(i_trial, i_lick_in_trial) <= pavlovian_range(2)
					f_lick_pavlovian(i_trial) = lick_times_by_trial(i_trial, i_lick_in_trial);
					scored_pav = true;
					pav_lick_in_trial = true;
				elseif lick_times_by_trial(i_trial, i_lick_in_trial) > pavlovian_range(2)
					scored_pav = true; % so you don't enter if statement again...
					% then go back and check for this lick again, because otherwise will miss the first ITI:
					i_lick_in_trial = i_lick_in_trial - 1;
				end

			% check for ITI lick
			elseif ~scored_ITI && ~op_lick_in_trial_no_rew && ~op_lick_in_trial_rew && ~pav_lick_in_trial && ~rxn_fail_in_trial
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
trials_with_rxn_fail = find(f_lick_rxn_abort > 0);
trials_with_op_no_rew = find(f_lick_operant_no_rew > 0);
trials_with_op_rew = find(f_lick_operant_rew > 0);
trials_with_pav = find(f_lick_pavlovian > 0);
trials_with_ITI = find(f_lick_ITI > 0);

% All scored first licks (excluding the rxn/train):
all_first_licks = f_lick_operant_no_rew + f_lick_operant_rew + f_lick_pavlovian + f_lick_ITI;




end