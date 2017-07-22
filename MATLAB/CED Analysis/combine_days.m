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

% 			1.5. axclusion = ExcluderInterface(d9_DLS_values_by_trial, d9_SNc_values_by_trial, d9_lick_times_by_trial)
%			1.51. check exclusions with 
% 				heatmap_3_fx(axclusion.Excluder.SNc_data, axclusion.Excluder.lick_times_by_trial_excluded, 1)
% 				Save the following:
					d8_gfit_SNc 			= gfit_SNc;
					d8_gfit_DLS 			= gfit_DLS;
					d8_SNc_ex1_values_by_trial	= axclusion.Excluder.SNc_data;
					d8_SNc_values_by_trial	= SNc_values_by_trial;
					d8_SNc_times_by_trial 	= SNc_times_by_trial;
					d8_DLS_ex1_values_by_trial 	= axclusion.Excluder.DLS_data;
					d8_DLS_values_by_trial 	= DLS_values_by_trial;
					d8_DLS_times_by_trial 	= SNc_times_by_trial;
					d8_SNc_times_by_trial	= SNc_times_by_trial;
% 			2. lick_times_by_trial_fx.m 										[lick_times_by_trial] = lick_times_by_trial_fx(lick_times, cue_on_times, 17, num_trials)
%				Save the following:
					d8_lick_times_by_trial 	= lick_times_by_trial;
					d8_lick_ex1_times_by_trial = axclusion.Excluder.lick_times_by_trial_excluded;
% 			3. first_lick_grabber_operant.m 									[f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_train, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx(lick_times_by_trial, num_trials)
% 				Save the following:
					d8_f_lick_rxn 			= f_lick_rxn;
					d8_f_lick_train_abort  	= f_lick_train_abort;
					d8_f_lick_operant_no_rew = f_lick_operant_no_rew;
					d8_f_lick_operant_rew 	= f_lick_operant_rew;
					% d8_f_lick_pavlovian     = f_lick_pavlovian;
					d8_f_lick_ITI			= f_lick_ITI;
					d8_all_first_licks 		= all_first_licks;
%			4. Run the appropriate first_lick_grabber with the excluded data 
%			and save this next (its the output of the fx, so dont need to type these in usually)
					d8_f_ex1_lick_rxn 			= f_lick_rxn;
					d8_f_ex1_lick_train_abort  	= f_lick_train_abort;
					d8_f_ex1_lick_operant_no_rew = f_lick_operant_no_rew;
					d8_f_ex1_lick_operant_rew 	= f_lick_operant_rew;
% 					d8_f_ex1_lick_pavlovian     = f_lick_pavlovian;
					d8_f_ex1_lick_ITI			= f_lick_ITI;
					d8_all_ex1_first_licks 		= all_first_licks;
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
combined_DLS_values_by_trial	= vertcat(d7_DLS_values_by_trial,...
										d8_DLS_values_by_trial,...
										DLS_values_by_trial);

combined_DLS_times_by_trial 	= vertcat(d7_DLS_times_by_trial,...
										d8_DLS_times_by_trial,...
										DLS_times_by_trial);

% SNc--------------------------------------------------------------------------------- 
combined_SNc_values_by_trial	= vertcat(d7_SNc_values_by_trial,...
										d8_SNc_values_by_trial,...
										SNc_values_by_trial);

combined_SNc_times_by_trial 	= vertcat(d7_SNc_times_by_trial,...
										d8_SNc_times_by_trial,...
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

combined_f_lick_operant_no_rew 	= horzcat(d7_f_lick_operant_no_rew,...
										d8_f_lick_operant_no_rew,...
										f_lick_operant_no_rew);	

combined_f_lick_operant_rew 	= horzcat(d7_f_lick_operant_rew,...
										d8_f_lick_operant_rew,...
										f_lick_operant_rew);			

% combined_f_lick_pavlovian	 	= [ 	,...
% 										,...
% 										];									

% combined_f_lick_ITI			 	= [ 	,...
% 										,...
% 										];

combined_all_first_licks	 	= horzcat(d7_all_first_licks,...
										d8_all_first_licks,...
										all_first_licks);										

										 