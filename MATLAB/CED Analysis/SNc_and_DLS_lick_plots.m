%% Pull the lick data from the file:

lick_times = lick_struct.times;
cue_on_times = cue_on_struct.times;
trial_duration_cue_to_end_ITI = 17;
num_trials = num_trials;

[lick_times_by_trial] = lick_times_by_trial_fx(lick_times, cue_on_times, trial_duration_cue_to_end_ITI, num_trials);

[f_lick_rxn,... 
 f_lick_train_abort,...
 f_lick_operant_no_rew,...
 f_lick_operant_rew,...
 f_lick_pavlovian,...
 f_lick_ITI,...
 trials_with_rxn,...
 trials_with_train,...
 trials_with_pav,...
 trials_with_ITI] = first_lick_grabber(lick_times_by_trial, num_trials);



%% First do for SNc

align_to_rewarded_lick_fx(SNc_times_by_trial,...
                                SNc_values_by_trial,...
                                f_lick_operant_no_rew,...
                                f_lick_operant_rew,...
                                f_lick_pavlovian,...
                                num_trials,...
                                'SNc');
                            
                            
%% Now for DLS

align_to_rewarded_lick_fx(DLS_times_by_trial,...
                                DLS_values_by_trial,...
                                f_lick_operant_no_rew,...
                                f_lick_operant_rew,...
                                f_lick_pavlovian,...
                                num_trials,...
                                'Striatum');