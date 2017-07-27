%% Combine Data Across Days........................................................
% 
%	Goal: Combine Data Variables Across Days for Plotting/Analysis 
% 
% 	Created:		6-3-17	ahamilos
% 	Last Modified:	6-3-17 	ahamilos
% 
% 	Instructions:
% 		Use the following functions to generate variables for a given day:
% 			1. extract_trials_gfit_v1.m --> Gets values_by_trial with global smooth-fit dF/F

% 			1.5. axclusion = ExcluderInterface(d13_DLS_values_by_trial, d13_SNc_values_by_trial, d13_lick_times_by_trial)
%			1.51. check exclusions with 
% 				heatmap_3_fx(axclusion.Excluder.SNc_data, axclusion.Excluder.lick_times_by_trial_excluded, 1)
% 				Save the following:
					d13_gfit_SNc 			= gfit_SNc;
					d13_gfit_DLS 			= gfit_DLS;
					d13_SNc_ex1_values_by_trial	= axclusion.Excluder.SNc_data;
					d13_SNc_values_by_trial	= SNc_values_by_trial;
					d13_SNc_times_by_trial 	= SNc_times_by_trial;
					d13_DLS_ex1_values_by_trial 	= axclusion.Excluder.DLS_data;
					d13_DLS_values_by_trial 	= DLS_values_by_trial;
					d13_DLS_times_by_trial 	= SNc_times_by_trial;
					d13_SNc_times_by_trial	= SNc_times_by_trial;
% 			2. lick_times_by_trial_fx.m 										[lick_times_by_trial] = lick_times_by_trial_fx(lick_times, cue_on_times, 17, num_trials)
%				Save the following:
					d13_lick_times_by_trial 	= lick_times_by_trial;
					d13_lick_ex1_times_by_trial = axclusion.Excluder.lick_times_by_trial_excluded;
% 			3. first_lick_grabber_operant.m 									[f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_train, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx(lick_times_by_trial, num_trials)
% 				Save the following:
					d13_f_lick_rxn 			= f_lick_rxn;
					d13_f_lick_train_abort  	= f_lick_train_abort;
					d13_f_lick_operant_no_rew = f_lick_operant_no_rew;
					d13_f_lick_operant_rew 	= f_lick_operant_rew;
					% d13_f_lick_pavlovian     = f_lick_pavlovian;
					d13_f_lick_ITI			= f_lick_ITI;
					d13_all_first_licks 		= all_first_licks;
%			4. Run the appropriate first_lick_grabber with the excluded data 
%			and save this next (its the output of the fx, so dont need to type these in usually)
					d13_f_ex1_lick_rxn 			= f_lick_rxn;
					d13_f_ex1_lick_train_abort  	= f_lick_train_abort;
					d13_f_ex1_lick_operant_no_rew = f_lick_operant_no_rew;
					d13_f_ex1_lick_operant_rew 	= f_lick_operant_rew;
% 					d13_f_ex1_lick_pavlovian     = f_lick_pavlovian;
					d13_f_ex1_lick_ITI			= f_lick_ITI;
					d13_all_ex1_first_licks 		= all_first_licks;


% 			5. Run the LTA file to also get the LTA arrays and save:
% 					1. lick_triggered_ave.m - run for each type
% 					2. lta_normalized_overlay - run for each type
 					d22_rxn_DLS_lick_triggered_ave_ignore_NaN = rxn_DLS_lick_triggered_ave_ignore_NaN;
					d22_rxn_SNc_lick_triggered_ave_ignore_NaN = rxn_SNc_lick_triggered_ave_ignore_NaN;
					d22_early_DLS_lick_triggered_ave_ignore_NaN = early_DLS_lick_triggered_ave_ignore_NaN;
					d22_early_SNc_lick_triggered_ave_ignore_NaN = early_SNc_lick_triggered_ave_ignore_NaN;
					d22_rew_DLS_lick_triggered_ave_ignore_NaN = 	rew_DLS_lick_triggered_ave_ignore_NaN;
					d22_rew_SNc_lick_triggered_ave_ignore_NaN = 	rew_SNc_lick_triggered_ave_ignore_NaN;
					% d22_pav_DLS_lick_triggered_ave_ignore_NaN = 	pav_DLS_lick_triggered_ave_ignore_NaN;
					% d22_pav_SNc_lick_triggered_ave_ignore_NaN = 	pav_SNc_lick_triggered_ave_ignore_NaN;
					d22_N_rxn_DLS = 	N_rxn_DLS;
					d22_N_rxn_SNc = 	N_rxn_SNc;
					d22_N_early_DLS = 	N_early_DLS;
					d22_N_early_SNc = 	N_early_SNc;
					d22_N_rew_DLS = 	N_rew_DLS;
					d22_N_rew_SNc = 	N_rew_SNc;
					% d22_N_pav_DLS = 	N_pav_DLS;
					% d22_N_pav_SNc = 	N_pav_SNc;
					d22_time_array = time_array;
% 				
% 
% 
% 		Create a Header in the Folder (include date run and versions of files)
% 		
% 		Open variables from each day you want to consider into workspace
% 
% 		Paste in names into the categories below and run!
% 
% 		Then use time_binner_fx with the combined data
% print('-depsc','-painters','-loose','Figure 4')
%-------------------------------------------------------------------------------------

% DLS--------------------------------------------------------------------------------- 
combined_DLS_values_by_trial	= vertcat(d13_DLS_values_by_trial,...
										d13_DLS_values_by_trial,...
										DLS_values_by_trial);

combined_DLS_times_by_trial 	= vertcat(d13_DLS_times_by_trial,...
										d13_DLS_times_by_trial,...
										DLS_times_by_trial);

% SNc--------------------------------------------------------------------------------- 
combined_SNc_values_by_trial	= vertcat(d13_SNc_values_by_trial,...
										d13_SNc_values_by_trial,...
										SNc_values_by_trial);

combined_SNc_times_by_trial 	= vertcat(d13_SNc_times_by_trial,...
										d13_SNc_times_by_trial,...
										SNc_times_by_trial);

% Both-------------------------------------------------------------------------------- 
% combined_lick_times_by_trial 	= [ 	,...
% 										,...
% 										];									

% combined_f_lick_rxn			 	= [ 	,...
% 										,...
% 										];

% combined_f_lick_train_abort  	= [ 	,...
% 										,...
										% ];

combined_f_lick_operant_no_rew 	= horzcat(d13_f_lick_operant_no_rew,...
										d13_f_lick_operant_no_rew,...
										f_lick_operant_no_rew);	

combined_f_lick_operant_rew 	= horzcat(d13_f_lick_operant_rew,...
										d13_f_lick_operant_rew,...
										f_lick_operant_rew);			

% combined_f_lick_pavlovian	 	= [ 	,...
% 										,...
% 										];									

% combined_f_lick_ITI			 	= [ 	,...
% 										,...
% 										];

combined_all_first_licks	 	= horzcat(d13_all_first_licks,...
										d13_all_first_licks,...
										all_first_licks);										

										 