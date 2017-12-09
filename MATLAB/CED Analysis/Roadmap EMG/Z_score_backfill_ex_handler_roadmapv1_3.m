%% Z_score_backfill_ex_handler_roadmapv1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-9-17: small bug fix
%% -------------------------------------------------------------------------------------------
disp('Z scoring filled-in trimmed data by trial...')
	SNc_exZ = z_score_single_fx(SNc_ex_values_by_trial_fi_trim);
	DLS_exZ = z_score_single_fx(DLS_ex_values_by_trial_fi_trim);
	VTA_exZ = z_score_single_fx(VTA_ex_values_by_trial_fi_trim);
	SNcred_exZ = z_score_single_fx(SNcred_ex_values_by_trial_fi_trim);
	DLSred_exZ = z_score_single_fx(DLSred_ex_values_by_trial_fi_trim);
	VTAred_exZ = z_score_single_fx(VTAred_ex_values_by_trial_fi_trim);
	X_exZ = z_score_single_fx(X_ex_values_by_trial_fi_trim);
	Y_exZ = z_score_single_fx(Y_ex_values_by_trial_fi_trim);
	Z_exZ = z_score_single_fx(Z_ex_values_by_trial_fi_trim);
	EMG_exZ = z_score_single_fx(EMG_ex_values_by_trial_fi_trim);