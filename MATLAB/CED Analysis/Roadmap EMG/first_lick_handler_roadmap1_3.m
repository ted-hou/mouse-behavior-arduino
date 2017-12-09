%% first_lick_handler_roadmap1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 
%% ------------------------------------------------------------------------------------------- (section validated 12/5/17)



if strcmp(exptype_,'hyb') && rxnwin_ == 500
	[f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,~,~,~,~, all_first_licks] = first_lick_grabber_hyb(lick_times_by_trial, num_trials);
elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
	[f_lick_rxn,f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,~, ~, ~, all_first_licks] = first_lick_grabber_hyb_0ms(lick_times_by_trial, num_trials);
elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
	h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 68 in roadmapv1 and debug');
elseif strcmp(exptype_,'op') && rxnwin_ == 500
	[f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, ~, ~, ~, all_first_licks] = first_lick_grabber_operant_fx(lick_times_by_trial, num_trials);
elseif strcmp(exptype_,'op') && rxnwin_ == 300
	[f_lick_rxn, f_lick_rxn_fail, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, ~, ~, ~, all_first_licks] = first_lick_grabber_operant_fx_300msv(lick_times_by_trial, num_trials);
elseif strcmp(exptype_,'op') && rxnwin_ == 0
	[f_lick_rxn, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, ~, ~, all_first_licks] = first_lick_grabber_operant_fx_0msv(lick_times_by_trial, num_trials);
elseif strcmp(exptype_,'op')
	h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 66 in roadmapv1 and debug');
else
	h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 68');
end
