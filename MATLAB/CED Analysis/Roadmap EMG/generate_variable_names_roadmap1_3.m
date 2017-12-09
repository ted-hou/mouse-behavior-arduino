% generate_variable_names_roadmap1_3.m 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% 	Created  12-5-17 	ahamilos	(from roadmap_EMG_phot_v1_3.m)
% 	Modified 12-5-17	ahamilos    
% 
%  USE: Used to make roadmap runner more compact - not a function, but just called as a script from roadmap_EMG_phot_v1_3.m
% 
% --------------------------------------------------------------------------------

% 0. Define all signals
	SNc_datastruct_name = genvarname(['d', daynum_, '_SNc_data_struct']);
	DLS_datastruct_name = genvarname(['d', daynum_, '_DLS_data_struct']);
	VTA_datastruct_name = genvarname(['d', daynum_, '_VTA_data_struct']);
	SNcred_datastruct_name = genvarname(['d', daynum_, '_SNcred_data_struct']);
	DLSred_datastruct_name = genvarname(['d', daynum_, '_DLSred_data_struct']);
	VTAred_datastruct_name = genvarname(['d', daynum_, '_VTAred_data_struct']);
	EMG_datastruct_name = genvarname(['d', daynum_, '_EMG_data_struct']);
	X_datastruct_name = genvarname(['d', daynum_, '_X_data_struct']);
	Y_datastruct_name = genvarname(['d', daynum_, '_Y_data_struct']);
	Z_datastruct_name = genvarname(['d', daynum_, '_Z_data_struct']);
	% Z_scored_name = genvarname(['d', daynum_, '_Zscored_struct']);
	eval([SNc_datastruct_name '= {};']);
	eval([DLS_datastruct_name '= {};']);
	eval([VTA_datastruct_name '= {};']);
	eval([SNcred_datastruct_name '= {};']);
	eval([DLSred_datastruct_name '= {};']);
	eval([VTAred_datastruct_name '= {};']);
	eval([EMG_datastruct_name '= {};']);
	eval([X_datastruct_name '= {};']);
	eval([Y_datastruct_name '= {};']);
	eval([Z_datastruct_name '= {};']);

% 1. SNc-------------------------------------------------------------------------------------------------------------------------------------------
	if snc_on
		% Signal Data:
		eval([SNc_datastruct_name '.gfit_SNc = gfit_SNc;']);
		eval([SNc_datastruct_name '.SNc_values_by_trial = SNc_values_by_trial;']);
		eval([SNc_datastruct_name '.SNc_times_by_trial = SNc_times_by_trial;']);
		eval([SNc_datastruct_name '.SNc_times_by_trial = SNc_times_by_trial;']);
		eval([SNc_datastruct_name '.SNc_ex_values_by_trial = SNc_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([SNc_datastruct_name '.SNc_ex_values_up_to_lick = SNc_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([SNc_datastruct_name '.lick_triggered_trials_struct.SNc_lick_triggered_trials = lick_triggered_trials_struct.SNc_lick_triggered_trials;']);
		eval([SNc_datastruct_name '.SNc_exZ = SNc_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([SNc_datastruct_name '.SNc_exZ_tolick = SNc_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([SNc_datastruct_name '.Z_scored_lick_triggered_structure.SNc_lick_triggered_trials = Z_scored_lick_triggered_structure.SNc_lick_triggered_trials;']);

		% Common Data:
		eval([SNc_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([SNc_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([SNc_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([SNc_datastruct_name '.num_trials = num_trials;']);
		eval([SNc_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([SNc_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([SNc_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([SNc_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([SNc_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([SNc_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([SNc_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([SNc_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([SNc_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([SNc_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([SNc_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([SNc_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([SNc_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([SNc_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([SNc_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([SNc_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Photom Specific:
		eval([SNc_datastruct_name '.time_array_1000hz = time_array_1000hz;']);

	end


% 2. DLS-------------------------------------------------------------------------------------------------------------------------------------------
	if dls_on
		% Signal Data:
		eval([DLS_datastruct_name '.gfit_DLS = gfit_DLS;']);
		eval([DLS_datastruct_name '.DLS_values_by_trial = DLS_values_by_trial;']);
		eval([DLS_datastruct_name '.DLS_times_by_trial = DLS_times_by_trial;']);
		eval([DLS_datastruct_name '.DLS_times_by_trial = DLS_times_by_trial;']);
		eval([DLS_datastruct_name '.DLS_ex_values_by_trial = DLS_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([DLS_datastruct_name '.DLS_ex_values_up_to_lick = DLS_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([DLS_datastruct_name '.lick_triggered_trials_struct.DLS_lick_triggered_trials = lick_triggered_trials_struct.DLS_lick_triggered_trials;']);
		eval([DLS_datastruct_name '.DLS_exZ = DLS_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([DLS_datastruct_name '.DLS_exZ_tolick = DLS_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([DLS_datastruct_name '.Z_scored_lick_triggered_structure.DLS_lick_triggered_trials = Z_scored_lick_triggered_structure.DLS_lick_triggered_trials;']);

		% Common Data:
		eval([DLS_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([DLS_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([DLS_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([DLS_datastruct_name '.num_trials = num_trials;']);
		eval([DLS_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([DLS_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([DLS_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([DLS_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([DLS_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([DLS_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([DLS_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([DLS_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([DLS_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([DLS_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([DLS_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([DLS_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([DLS_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([DLS_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([DLS_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([DLS_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Photom Specific:
		eval([DLS_datastruct_name '.time_array_1000hz = time_array_1000hz;']);

	end



% 3. VTA-------------------------------------------------------------------------------------------------------------------------------------------
	if vta_on
		% Signal Data:
		eval([VTA_datastruct_name '.gfit_VTA = gfit_VTA;']);
		eval([VTA_datastruct_name '.VTA_values_by_trial = VTA_values_by_trial;']);
		eval([VTA_datastruct_name '.VTA_times_by_trial = VTA_times_by_trial;']);
		eval([VTA_datastruct_name '.VTA_times_by_trial = VTA_times_by_trial;']);
		eval([VTA_datastruct_name '.VTA_ex_values_by_trial = VTA_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([VTA_datastruct_name '.VTA_ex_values_up_to_lick = VTA_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([VTA_datastruct_name '.lick_triggered_trials_struct.VTA_lick_triggered_trials = lick_triggered_trials_struct.VTA_lick_triggered_trials;']);
		eval([VTA_datastruct_name '.VTA_exZ = VTA_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([VTA_datastruct_name '.VTA_exZ_tolick = VTA_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([VTA_datastruct_name '.Z_scored_lick_triggered_structure.VTA_lick_triggered_trials = Z_scored_lick_triggered_structure.VTA_lick_triggered_trials;']);

		% Common Data:
		eval([VTA_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([VTA_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([VTA_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([VTA_datastruct_name '.num_trials = num_trials;']);
		eval([VTA_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([VTA_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([VTA_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([VTA_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([VTA_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([VTA_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([VTA_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([VTA_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([VTA_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([VTA_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([VTA_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([VTA_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([VTA_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([VTA_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([VTA_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([VTA_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Photom Specific:
		eval([VTA_datastruct_name '.time_array_1000hz = time_array_1000hz;']);

	end



% 4. SNcred-------------------------------------------------------------------------------------------------------------------------------------------
	if sncred_on
		% Signal Data:
		eval([SNcred_datastruct_name '.gfit_SNcred = gfit_SNcred;']);
		eval([SNcred_datastruct_name '.SNcred_values_by_trial = SNcred_values_by_trial;']);
		eval([SNcred_datastruct_name '.SNcred_times_by_trial = SNcred_times_by_trial;']);
		eval([SNcred_datastruct_name '.SNcred_times_by_trial = SNcred_times_by_trial;']);
		eval([SNcred_datastruct_name '.SNcred_ex_values_by_trial = SNcred_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([SNcred_datastruct_name '.SNcred_ex_values_up_to_lick = SNcred_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([SNcred_datastruct_name '.lick_triggered_trials_struct.SNcred_lick_triggered_trials = lick_triggered_trials_struct.SNcred_lick_triggered_trials;']);
		eval([SNcred_datastruct_name '.SNcred_exZ = SNcred_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([SNcred_datastruct_name '.SNcred_exZ_tolick = SNcred_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([SNcred_datastruct_name '.Z_scored_lick_triggered_structure.SNcred_lick_triggered_trials = Z_scored_lick_triggered_structure.SNcred_lick_triggered_trials;']);

		% Common Data:
		eval([SNcred_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([SNcred_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([SNcred_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([SNcred_datastruct_name '.num_trials = num_trials;']);
		eval([SNcred_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([SNcred_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([SNcred_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([SNcred_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([SNcred_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([SNcred_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([SNcred_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([SNcred_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([SNcred_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([SNcred_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([SNcred_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([SNcred_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([SNcred_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([SNcred_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([SNcred_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([SNcred_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Photom Specific:
		eval([SNcred_datastruct_name '.time_array_1000hz = time_array_1000hz;']);

	end





% 5. DLSred-------------------------------------------------------------------------------------------------------------------------------------------
	if dlsred_on
		% Signal Data:
		eval([DLSred_datastruct_name '.gfit_DLSred = gfit_DLSred;']);
		eval([DLSred_datastruct_name '.DLSred_values_by_trial = DLSred_values_by_trial;']);
		eval([DLSred_datastruct_name '.DLSred_times_by_trial = DLSred_times_by_trial;']);
		eval([DLSred_datastruct_name '.DLSred_times_by_trial = DLSred_times_by_trial;']);
		eval([DLSred_datastruct_name '.DLSred_ex_values_by_trial = DLSred_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([DLSred_datastruct_name '.DLSred_ex_values_up_to_lick = DLSred_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([DLSred_datastruct_name '.lick_triggered_trials_struct.DLSred_lick_triggered_trials = lick_triggered_trials_struct.DLSred_lick_triggered_trials;']);
		eval([DLSred_datastruct_name '.DLSred_exZ = DLSred_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([DLSred_datastruct_name '.DLSred_exZ_tolick = DLSred_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([DLSred_datastruct_name '.Z_scored_lick_triggered_structure.DLSred_lick_triggered_trials = Z_scored_lick_triggered_structure.DLSred_lick_triggered_trials;']);

		% Common Data:
		eval([DLSred_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([DLSred_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([DLSred_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([DLSred_datastruct_name '.num_trials = num_trials;']);
		eval([DLSred_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([DLSred_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([DLSred_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([DLSred_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([DLSred_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([DLSred_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([DLSred_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([DLSred_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([DLSred_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([DLSred_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([DLSred_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([DLSred_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([DLSred_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([DLSred_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([DLSred_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([DLSred_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Photom Specific:
		eval([DLSred_datastruct_name '.time_array_1000hz = time_array_1000hz;']);

	end



% 6. VTAred-------------------------------------------------------------------------------------------------------------------------------------------
	if vtared_on
		% Signal Data:
		eval([VTAred_datastruct_name '.gfit_VTAred = gfit_VTAred;']);
		eval([VTAred_datastruct_name '.VTAred_values_by_trial = VTAred_values_by_trial;']);
		eval([VTAred_datastruct_name '.VTAred_times_by_trial = VTAred_times_by_trial;']);
		eval([VTAred_datastruct_name '.VTAred_times_by_trial = VTAred_times_by_trial;']);
		eval([VTAred_datastruct_name '.VTAred_ex_values_by_trial = VTAred_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([VTAred_datastruct_name '.VTAred_ex_values_up_to_lick = VTAred_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([VTAred_datastruct_name '.lick_triggered_trials_struct.VTAred_lick_triggered_trials = lick_triggered_trials_struct.VTAred_lick_triggered_trials;']);
		eval([VTAred_datastruct_name '.VTAred_exZ = VTAred_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([VTAred_datastruct_name '.VTAred_exZ_tolick = VTAred_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([VTAred_datastruct_name '.Z_scored_lick_triggered_structure.VTAred_lick_triggered_trials = Z_scored_lick_triggered_structure.VTAred_lick_triggered_trials;']);

		% Common Data:
		eval([VTAred_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([VTAred_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([VTAred_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([VTAred_datastruct_name '.num_trials = num_trials;']);
		eval([VTAred_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([VTAred_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([VTAred_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([VTAred_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([VTAred_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([VTAred_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([VTAred_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([VTAred_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([VTAred_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([VTAred_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([VTAred_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([VTAred_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([VTAred_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([VTAred_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([VTAred_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([VTAred_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Photom Specific:
		eval([VTAred_datastruct_name '.time_array_1000hz = time_array_1000hz;']);

	end


% 7. EMG-------------------------------------------------------------------------------------------------------------------------------------------
	if emg_on
		% Signal Data:
		eval([EMG_datastruct_name '.EMG_values = EMG_values;']);
		eval([EMG_datastruct_name '.EMG_values_by_trial = EMG_values_by_trial;']);
		eval([EMG_datastruct_name '.EMG_times_by_trial = EMG_times_by_trial;']);
		eval([EMG_datastruct_name '.EMG_times_by_trial = EMG_times_by_trial;']);
		eval([EMG_datastruct_name '.EMG_ex_values_by_trial = EMG_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([EMG_datastruct_name '.EMG_ex_values_up_to_lick = EMG_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([EMG_datastruct_name '.lick_triggered_trials_struct.EMG_lick_triggered_trials = lick_triggered_trials_struct.EMG_lick_triggered_trials;']);
		eval([EMG_datastruct_name '.EMG_exZ = EMG_exZ;']);											% NOTE: this is backfilled and trimmed
		eval([EMG_datastruct_name '.EMG_exZ_tolick = EMG_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([EMG_datastruct_name '.Z_scored_lick_triggered_structure.EMG_lick_triggered_trials = Z_scored_lick_triggered_structure.EMG_lick_triggered_trials;']);

		% Common Data:
		eval([EMG_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([EMG_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([EMG_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([EMG_datastruct_name '.num_trials = num_trials;']);
		eval([EMG_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([EMG_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([EMG_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([EMG_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([EMG_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([EMG_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([EMG_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([EMG_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([EMG_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([EMG_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([EMG_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([EMG_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([EMG_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([EMG_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([EMG_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([EMG_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Movement Specific:
		eval([EMG_datastruct_name '.time_array_2000hz = time_array_2000hz;']);

	end



% 8. X-------------------------------------------------------------------------------------------------------------------------------------------
	if x_on
		% Signal Data:
		eval([X_datastruct_name '.X_values = X_values;']);
		eval([X_datastruct_name '.X_values_by_trial = X_values_by_trial;']);
		eval([X_datastruct_name '.X_times_by_trial = X_times_by_trial;']);
		eval([X_datastruct_name '.X_times_by_trial = X_times_by_trial;']);
		eval([X_datastruct_name '.X_ex_values_by_trial = X_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([X_datastruct_name '.X_ex_values_up_to_lick = X_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([X_datastruct_name '.lick_triggered_trials_struct.X_lick_triggered_trials = lick_triggered_trials_struct.X_lick_triggered_trials;']);
		eval([X_datastruct_name '.X_exZ = X_exZ;']);										% NOTE: this is backfilled and trimmed
		eval([X_datastruct_name '.X_exZ_tolick = X_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([X_datastruct_name '.Z_scored_lick_triggered_structure.X_lick_triggered_trials = Z_scored_lick_triggered_structure.X_lick_triggered_trials;']);

		% Common Data:
		eval([X_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([X_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([X_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([X_datastruct_name '.num_trials = num_trials;']);
		eval([X_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([X_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([X_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([X_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([X_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([X_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([X_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([X_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([X_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([X_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([X_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([X_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([X_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([X_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([X_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([X_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Movement Specific:
		eval([X_datastruct_name '.time_array_2000hz = time_array_2000hz;']);

	end



% 9. Y-------------------------------------------------------------------------------------------------------------------------------------------
	if y_on
		% Signal Data:
		eval([Y_datastruct_name '.Y_values = Y_values;']);
		eval([Y_datastruct_name '.Y_values_by_trial = Y_values_by_trial;']);
		eval([Y_datastruct_name '.Y_times_by_trial = Y_times_by_trial;']);
		eval([Y_datastruct_name '.Y_times_by_trial = Y_times_by_trial;']);
		eval([Y_datastruct_name '.Y_ex_values_by_trial = Y_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([Y_datastruct_name '.Y_ex_values_up_to_lick = Y_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([Y_datastruct_name '.lick_triggered_trials_struct.Y_lick_triggered_trials = lick_triggered_trials_struct.Y_lick_triggered_trials;']);
		eval([Y_datastruct_name '.Y_exZ = Y_exZ;']);										% NOTE: this is backfilled and trimmed
		eval([Y_datastruct_name '.Y_exZ_tolick = Y_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([Y_datastruct_name '.Z_scored_lick_triggered_structure.Y_lick_triggered_trials = Z_scored_lick_triggered_structure.Y_lick_triggered_trials;']);

		% Common Data:
		eval([Y_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([Y_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([Y_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([Y_datastruct_name '.num_trials = num_trials;']);
		eval([Y_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([Y_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([Y_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([Y_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([Y_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([Y_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([Y_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([Y_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([Y_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([Y_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([Y_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([Y_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([Y_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([Y_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([Y_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([Y_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Movement Specific:
		eval([Y_datastruct_name '.time_array_2000hz = time_array_2000hz;']);

	end


% 10. Z-------------------------------------------------------------------------------------------------------------------------------------------
	if z_on
		% Signal Data:
		eval([Z_datastruct_name '.Z_values = Z_values;']);
		eval([Z_datastruct_name '.Z_values_by_trial = Z_values_by_trial;']);
		eval([Z_datastruct_name '.Z_times_by_trial = Z_times_by_trial;']);
		eval([Z_datastruct_name '.Z_times_by_trial = Z_times_by_trial;']);
		eval([Z_datastruct_name '.Z_ex_values_by_trial = Z_ex_values_by_trial_fi_trim;']);	% NOTE: only take the back filled trimmed version
		eval([Z_datastruct_name '.Z_ex_values_up_to_lick = Z_ex_values_up_to_lick;']);		% NOTE: this is backfilled and trimmed
		eval([Z_datastruct_name '.lick_triggered_trials_struct.Z_lick_triggered_trials = lick_triggered_trials_struct.Z_lick_triggered_trials;']);
		eval([Z_datastruct_name '.Z_exZ = Z_exZ;']);										% NOTE: this is backfilled and trimmed
		eval([Z_datastruct_name '.Z_exZ_tolick = Z_exZ_tolick;']);							% NOTE: this is backfilled and trimmed
		eval([Z_datastruct_name '.Z_scored_lick_triggered_structure.Z_lick_triggered_trials = Z_scored_lick_triggered_structure.Z_lick_triggered_trials;']);

		% Common Data:
		eval([Z_datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
		eval([Z_datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);
		eval([Z_datastruct_name '.Excluded_Trials = Excluded_Trials;']);
		eval([Z_datastruct_name '.num_trials = num_trials;']);
		eval([Z_datastruct_name '.f_lick_rxn = f_lick_rxn;']);
		eval([Z_datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
		eval([Z_datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
		eval([Z_datastruct_name '.f_lick_ITI = f_lick_ITI;']);
		eval([Z_datastruct_name '.all_first_licks = all_first_licks;']);
		eval([Z_datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
		eval([Z_datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
		eval([Z_datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
		eval([Z_datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
		eval([Z_datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);
		
		% Pavlovian:
		if strcmp(exptype_, 'hyb')
			eval([Z_datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
			eval([Z_datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		end
		if rxnwin_ == 300
				eval([Z_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
				eval([Z_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
			
		elseif rxnwin_ == 500 & strcmp(exptype_,'op')
				eval([Z_datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
				eval([Z_datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
		end

		% Movement Specific:
		eval([Z_datastruct_name '.time_array_2000hz = time_array_2000hz;']);

	end