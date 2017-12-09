% generate_variable_names_roadmap1_3.m 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% 	Created  12-5-17 	ahamilos	(from roadmap_EMG_phot_v1_3.m)
% 	Modified 12-5-17	ahamilos    
% 
%  USE: Used to make roadmap runner more compact - not a function, but just called as a script from roadmap_EMG_phot_v1_3.m
% 
% --------------------------------------------------------------------------------


	datastruct_name = genvarname(['d', daynum_, '_data_struct']);
	Z_scored_name = genvarname(['d', daynum_, '_Zscored_struct']);
	eval([datastruct_name '= {};']);

% 1. extracted data
	eval([datastruct_name '.gfit_SNc = gfit_SNc;']);
	eval([datastruct_name '.gfit_DLS = gfit_DLS;']);
	eval([datastruct_name '.gfit_VTA = gfit_VTA;']);
	eval([datastruct_name '.gfit_SNcred = gfit_SNcred;']);
	eval([datastruct_name '.gfit_DLSred = gfit_DLSred;']);
	eval([datastruct_name '.gfit_VTAred = gfit_VTAred;']);
	eval([datastruct_name '.X_values = X_values;']);
	eval([datastruct_name '.Y_values = Y_values;']);
	eval([datastruct_name '.Z_values = Z_values;']);
	eval([datastruct_name '.EMG_values = EMG_values;']);

% 2. By Trial:
	% only saving backfilled version of this.....
	% eval([datastruct_name '.SNc_ex_values_by_trial = SNc_ex_values_by_trial;']);
	% eval([datastruct_name '.DLS_ex_values_by_trial = DLS_ex_values_by_trial;']);
	% eval([datastruct_name '.VTA_ex_values_by_trial = VTA_ex_values_by_trial;']);
	% eval([datastruct_name '.VTAred_ex_values_by_trial = VTAred_ex_values_by_trial;']);
	% eval([datastruct_name '.SNcred_ex_values_by_trial = SNcred_ex_values_by_trial;']);
	% eval([datastruct_name '.DLSred_ex_values_by_trial = DLSred_ex_values_by_trial;']);
	% eval([datastruct_name '.X_ex_values_by_trial = X_ex_values_by_trial;']);
	% eval([datastruct_name '.Y_ex_values_by_trial = Y_ex_values_by_trial;']);
	% eval([datastruct_name '.Z_ex_values_by_trial = Z_ex_values_by_trial;']);
	% eval([datastruct_name '.EMG_ex_values_by_trial = EMG_ex_values_by_trial;']);

	eval([datastruct_name '.SNc_values_by_trial = SNc_values_by_trial;']);
	eval([datastruct_name '.DLS_values_by_trial = DLS_values_by_trial;']);
	eval([datastruct_name '.VTA_values_by_trial = VTA_values_by_trial;']);
	eval([datastruct_name '.VTAred_values_by_trial = VTAred_values_by_trial;']);
	eval([datastruct_name '.SNcred_values_by_trial = SNcred_values_by_trial;']);
	eval([datastruct_name '.DLSred_values_by_trial = DLSred_values_by_trial;']);
	eval([datastruct_name '.X_values_by_trial = X_values_by_trial;']);
	eval([datastruct_name '.Y_values_by_trial = Y_values_by_trial;']);
	eval([datastruct_name '.Z_values_by_trial = Z_values_by_trial;']);
	eval([datastruct_name '.EMG_values_by_trial = EMG_values_by_trial;']);

	eval([datastruct_name '.SNc_times_by_trial = SNc_times_by_trial;']);
	eval([datastruct_name '.VTA_times_by_trial = VTA_times_by_trial;']);
	eval([datastruct_name '.X_times_by_trial = X_times_by_trial;']);
	% note, not saving all the photom times by trial to save space

%3. Lick times by trial data
	eval([datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
	eval([datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);



%4. Exclusions and Number of Trials
	eval([datastruct_name '.Excluded_Trials = Excluded_Trials;']);
	eval([datastruct_name '.num_trials = num_trials;']);



%5. First lick grabber - no exclusions		
	eval([datastruct_name '.f_lick_rxn = f_lick_rxn;']);
	eval([datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
	eval([datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
	eval([datastruct_name '.f_lick_ITI = f_lick_ITI;']);
	eval([datastruct_name '.all_first_licks = all_first_licks;']);

%6. First lick grabber - exclusions	
	eval([datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
	eval([datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
	eval([datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
	eval([datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
	eval([datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);

%7 Backfilled:
	% only saving backfilled with exclusions -- and saving those as the base file for ex
	% % eval([datastruct_name '.SNc_values_by_trial_fi = SNc_values_by_trial_fi;']);
	% eval([datastruct_name '.SNc_ex_values_by_trial = SNc_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.DLS_values_by_trial_fi = DLS_values_by_trial_fi;']);
	% eval([datastruct_name '.DLS_ex_values_by_trial = DLS_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.VTA_values_by_trial_fi = VTA_values_by_trial_fi;']);
	% eval([datastruct_name '.VTA_ex_values_by_trial = VTA_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.SNcred_values_by_trial_fi = SNcred_values_by_trial_fi;']);
	% eval([datastruct_name '.SNcred_ex_values_by_trial = SNcred_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.DLSred_values_by_trial_fi = DLSred_values_by_trial_fi;']);
	% eval([datastruct_name '.DLSred_ex_values_by_trial = DLSred_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.VTAred_values_by_trial_fi = VTAred_values_by_trial_fi;']);
	% eval([datastruct_name '.VTAred_ex_values_by_trial = VTAred_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.X_values_by_trial_fi = X_values_by_trial_fi;']);
	% eval([datastruct_name '.X_ex_values_by_trial = X_values_by_trial_fi_trim;']);	
	% % eval([datastruct_name '.Y_values_by_trial_fi = Y_values_by_trial_fi;']);
	% eval([datastruct_name '.Y_ex_values_by_trial = Y_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.Z_values_by_trial_fi = Z_values_by_trial_fi;']);
	% eval([datastruct_name '.Z_ex_values_by_trial = Z_values_by_trial_fi_trim;']);
	% % eval([datastruct_name '.EMG_values_by_trial_fi = EMG_values_by_trial_fi;']);
	% eval([datastruct_name '.EMG_ex_values_by_trial = EMG_values_by_trial_fi_trim;']);

	% eval([datastruct_name '.SNc_ex_values_by_trial_fi = SNc_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.DLS_ex_values_by_trial_fi = DLS_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.VTA_ex_values_by_trial_fi = VTA_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.SNcred_ex_values_by_trial_fi = SNcred_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.DLSred_ex_values_by_trial_fi = DLSred_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.VTAred_ex_values_by_trial_fi = VTAred_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.X_ex_values_by_trial_fi = X_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.Y_ex_values_by_trial_fi = Y_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.Z_ex_values_by_trial_fi = Z_ex_values_by_trial_fi;']);
	% eval([datastruct_name '.EMG_ex_values_by_trial_fi = EMG_ex_values_by_trial_fi;']);

	eval([datastruct_name '.SNc_ex_values_by_trial = SNc_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.DLS_ex_values_by_trial = DLS_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.VTA_ex_values_by_trial = VTA_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.SNcred_ex_values_by_trial = SNcred_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.DLSred_ex_values_by_trial = DLSred_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.VTAred_ex_values_by_trial = VTAred_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.X_ex_values_by_trial = X_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.Y_ex_values_by_trial = Y_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.Z_ex_values_by_trial = Z_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.EMG_ex_values_by_trial = EMG_ex_values_by_trial_fi_trim;']);



%8. Values by trial up to lick:
	eval([datastruct_name '.DLS_ex_values_up_to_lick = DLS_ex_values_up_to_lick;']);
	eval([datastruct_name '.SNc_ex_values_up_to_lick = SNc_ex_values_up_to_lick;']);
	eval([datastruct_name '.VTA_ex_values_up_to_lick = VTA_ex_values_up_to_lick;']);
	eval([datastruct_name '.VTAred_ex_values_up_to_lick = VTAred_ex_values_up_to_lick;']);
	eval([datastruct_name '.DLSred_ex_values_up_to_lick = DLSred_ex_values_up_to_lick;']);
	eval([datastruct_name '.SNcred_ex_values_up_to_lick = SNcred_ex_values_up_to_lick;']);
	eval([datastruct_name '.X_ex_values_up_to_lick = X_ex_values_up_to_lick;']);
	eval([datastruct_name '.Y_ex_values_up_to_lick = Y_ex_values_up_to_lick;']);
	eval([datastruct_name '.Z_ex_values_up_to_lick = Z_ex_values_up_to_lick;']);
	eval([datastruct_name '.EMG_ex_values_up_to_lick = EMG_ex_values_up_to_lick;']);

%9. LTA
	eval([datastruct_name '.lick_triggered_trials_struct = lick_triggered_trials_struct;']);
		
	eval([datastruct_name '.time_array_1000hz = time_array_1000hz;']);
	eval([datastruct_name '.time_array_2000hz = time_array_2000hz;']);
	


	%6. Pavlovian
	if strcmp(exptype_, 'hyb')
		eval([datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
		eval([datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);


	end
	
	if rxnwin_ == 300
			eval([datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
			eval([datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
		
	elseif rxnwin_ == 500 & strcmp(exptype_,'op')
			eval([datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
			eval([datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
	end


%%  Z scored data structure: --------------------------------------------------------------------------------

	% Obligatory Lick Parcing:
	eval([Z_scored_name  '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
	eval([Z_scored_name  '.num_trials = num_trials;']);

	eval([Z_scored_name  '.f_ex_lick_rxn = f_ex_lick_rxn;']);
	eval([Z_scored_name  '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
	eval([Z_scored_name  '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
	eval([Z_scored_name  '.f_ex_lick_ITI = f_ex_lick_ITI;']);
	eval([Z_scored_name  '.all_ex_first_licks = all_ex_first_licks;']);

	% Z scored data with exclusions - backfilled
	eval([Z_scored_name  '.SNc_exZ = SNc_exZ;']);
	eval([Z_scored_name  '.DLS_exZ = DLS_exZ;']);
	eval([Z_scored_name  '.VTA_exZ = VTA_exZ;']);
	eval([Z_scored_name  '.SNcred_exZ = SNcred_exZ;']);
	eval([Z_scored_name  '.DLSred_exZ = DLSred_exZ;']);
	eval([Z_scored_name  '.VTAred_exZ = VTAred_exZ;']);
	eval([Z_scored_name  '.X_exZ = X_exZ;']);
	eval([Z_scored_name  '.Y_exZ = Y_exZ;']);
	eval([Z_scored_name  '.Z_exZ = Z_exZ;']);
	eval([Z_scored_name  '.EMG_exZ = EMG_exZ;']);

	% Z scored data with exclusions - backfilled up to the first lick
	eval([Z_scored_name '.SNc_exZ_tolick = SNc_exZ_tolick;']);
	eval([Z_scored_name '.DLS_exZ_tolick = DLS_exZ_tolick;']);
	eval([Z_scored_name '.VTA_exZ_tolick = VTA_exZ_tolick;']);
	eval([Z_scored_name '.SNcred_exZ_tolick = SNcred_exZ_tolick;']);
	eval([Z_scored_name '.DLSred_exZ_tolick = DLSred_exZ_tolick;']);
	eval([Z_scored_name '.VTAred_exZ_tolick = VTAred_exZ_tolick;']);
	eval([Z_scored_name '.X_exZ_tolick = X_exZ_tolick;']);
	eval([Z_scored_name '.Y_exZ_tolick = Y_exZ_tolick;']);
	eval([Z_scored_name '.Z_exZ_tolick = Z_exZ_tolick;']);
	eval([Z_scored_name '.EMG_exZ_tolick = EMG_exZ_tolick;']);

	% Z scored data with exclusions - lick-aligned
	eval([Z_scored_name  '.Z_scored_lick_triggered_structure = Z_scored_lick_triggered_structure;']);