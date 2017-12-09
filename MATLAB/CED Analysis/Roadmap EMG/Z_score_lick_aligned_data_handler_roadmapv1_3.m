%% Z_score_lick_aligned_data_handler_roadmapv1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-6-17: Had to fix so that it Z scored all the not-averages in the structure
%% -------------------------------------------------------------------------------------------

	Z_scored_lick_triggered_structure = {};

% DLS -----------------------------------------------------
disp(['Calculating global Z score for DLS...'])
	Z_scored_lick_triggered_structure.Z_scored_DLS_lick_triggered_trials.pav_DLS_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.DLS_lick_triggered_trials.pav_DLS_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLS_lick_triggered_trials.early_DLS_lick_triggered_trials 		= z_score_single_fx(lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials	 		= z_score_single_fx(lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials);

% SNc ------------------------------------------------------
disp(['Calculating global Z score for SNc...'])
	Z_scored_lick_triggered_structure.Z_scored_SNc_lick_triggered_trials.pav_SNc_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.SNc_lick_triggered_trials.pav_SNc_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNc_lick_triggered_trials.early_SNc_lick_triggered_trials 		= z_score_single_fx(lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials	 		= z_score_single_fx(lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials);

% VTA -------------------------------------------------------
disp(['Calculating global Z score for VTA...'])
	Z_scored_lick_triggered_structure.Z_scored_VTA_lick_triggered_trials.pav_VTA_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.VTA_lick_triggered_trials.pav_VTA_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTA_lick_triggered_trials.early_VTA_lick_triggered_trials 		= z_score_single_fx(lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials	 		= z_score_single_fx(lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials);

% DLSred ----------------------------------------------------
disp(['Calculating global Z score for DLSred...'])
	Z_scored_lick_triggered_structure.Z_scored_DLSred_lick_triggered_trials.pav_DLSred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.DLSred_lick_triggered_trials.pav_DLSred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials	= z_score_single_fx(lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials);

% SNcred ----------------------------------------------------
disp(['Calculating global Z score for SNcred...'])
	Z_scored_lick_triggered_structure.Z_scored_SNcred_lick_triggered_trials.pav_SNcred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.SNcred_lick_triggered_trials.pav_SNcred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials	= z_score_single_fx(lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials);

% VTAred ----------------------------------------------------
disp(['Calculating global Z score for VTAred...'])
	Z_scored_lick_triggered_structure.Z_scored_VTAred_lick_triggered_trials.pav_VTAred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.VTAred_lick_triggered_trials.pav_VTAred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials	= z_score_single_fx(lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials 	= z_score_single_fx(lick_triggered_trials_struct.VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials);

% EMG -------------------------------------------------------
disp(['Calculating global Z score for EMG...'])
	Z_scored_lick_triggered_structure.Z_scored_EMG_lick_triggered_trials.pav_EMG_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.EMG_lick_triggered_trials.pav_EMG_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials 		    = z_score_single_fx(lick_triggered_trials_struct.EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_EMG_lick_triggered_trials.early_EMG_lick_triggered_trials 		= z_score_single_fx(lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials	 		= z_score_single_fx(lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials);

% X ---------------------------------------------------------
disp(['Calculating global Z score for X...'])
	Z_scored_lick_triggered_structure.Z_scored_X_lick_triggered_trials.pav_X_lick_triggered_trials 		    	= z_score_single_fx(lick_triggered_trials_struct.X_lick_triggered_trials.pav_X_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_X_lick_triggered_trials.rxn_X_lick_triggered_trials 		   		= z_score_single_fx(lick_triggered_trials_struct.X_lick_triggered_trials.rxn_X_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_X_lick_triggered_trials.early_X_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_X_lick_triggered_trials.rew_X_lick_triggered_trials	 			= z_score_single_fx(lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_X_lick_triggered_trials.ITI_X_lick_triggered_trials 				= z_score_single_fx(lick_triggered_trials_struct.X_lick_triggered_trials.ITI_X_lick_triggered_trials);

% Y ---------------------------------------------------------
disp(['Calculating global Z score for Y...'])
	Z_scored_lick_triggered_structure.Z_scored_Y_lick_triggered_trials.pav_Y_lick_triggered_trials 		    	= z_score_single_fx(lick_triggered_trials_struct.Y_lick_triggered_trials.pav_Y_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Y_lick_triggered_trials.rxn_Y_lick_triggered_trials 		   		= z_score_single_fx(lick_triggered_trials_struct.Y_lick_triggered_trials.rxn_Y_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Y_lick_triggered_trials.early_Y_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Y_lick_triggered_trials.rew_Y_lick_triggered_trials	 			= z_score_single_fx(lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Y_lick_triggered_trials.ITI_Y_lick_triggered_trials 				= z_score_single_fx(lick_triggered_trials_struct.Y_lick_triggered_trials.ITI_Y_lick_triggered_trials);

% Z ---------------------------------------------------------
disp(['Calculating global Z score for Z...'])
	Z_scored_lick_triggered_structure.Z_scored_Z_lick_triggered_trials.pav_Z_lick_triggered_trials 		    	= z_score_single_fx(lick_triggered_trials_struct.Z_lick_triggered_trials.pav_Z_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Z_lick_triggered_trials.rxn_Z_lick_triggered_trials 		    	= z_score_single_fx(lick_triggered_trials_struct.Z_lick_triggered_trials.rxn_Z_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Z_lick_triggered_trials.early_Z_lick_triggered_trials 			= z_score_single_fx(lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Z_lick_triggered_trials.rew_Z_lick_triggered_trials	 			= z_score_single_fx(lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials);
	Z_scored_lick_triggered_structure.Z_scored_Z_lick_triggered_trials.ITI_Z_lick_triggered_trials 				= z_score_single_fx(lick_triggered_trials_struct.Z_lick_triggered_trials.ITI_Z_lick_triggered_trials);




