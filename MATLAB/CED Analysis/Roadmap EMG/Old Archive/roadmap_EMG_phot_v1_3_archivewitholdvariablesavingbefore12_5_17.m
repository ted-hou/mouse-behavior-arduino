%% Run Analysis Roadmap-------------------------------------------------------------------
% 
% 	Created 	8-01-17 ahamilos (roadmap v1)
% 	Modified 	12-5-17 ahamilos
% 
% UPDATE LOG:
% 		- 12-5-17: Updated to take more scripts for chunks so that file is consistent across versions (e.g., no lick)
% 		- 12-4-17: Fixed saving for red and VTA data - was not saved before. Also added Z-scoring and saving this as a separate data-file
%       - 11-29-17: Allowed variable sampling rate input
% 		- 10-28-17: Fixed LTA and CTA for generic inputs of any sampling rate, including updates to dependent fxs.
%       - 10-26-17: Added capacity to handle VTA
% 		- 10-03-17: Added capacity to handle photometry data as well as movement controls. Made exclusions something entered at beginning of the run
% 		-  9-22-17: changed for movement controls, save vars as structure
% 		-  8-14-17: added the plot to lick CTA and LTA, hxgrams
% 		-  8-10-17: added the backfill option so that values_by_trial are filled in from left to right
% 
% 	Outline:
% 		* open directory you want to save to in matlab workspace
% 		* write in the day # you want to use for everything
% 		1. extract_trials_gfit_v1.m
% 		2. lick_times_by_trial_fx
% 		3. first_lick_grabber (need to input which version to use at beginning)
% 		4. axclusion = Excluder Interface (wait for user input to continue)
% 		5. heatmap_3_fx 
% 		6. back fill nans in the values_by_trial files
%		6. gets excluded first licks  
% 		6. CTA and plots saved
% 		7. LTA and plots saved
% 		8. save ALL VARS
%% ------------------------------------------------------------------------------------------- (section validated 10/26/17)





todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');

% Start of run: Prompt user for needed variables-------------------------------------------- (section validated 10/26/17)
	disp('Collecting user input...')
	prompt = {'Day # prefix:','CED filename_ (don''t include *_lick, etc):', 'Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Trial Duration (ms)', 'Target (ms)', 'Exclusion Criteria Version', 'Animal Name', 'Excluded Trials', 'Photometry Hz', 'Movement Hz'};
	dlg_title = 'Inputs';
	num_lines = 1;
	defaultans = {'7','h6_day7_sncvta_dlsred','1', 'op', '500', '17000', '5000', '1', 'H6', '###', '1000', '2000'};
	answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
	daynum_ = answer_{1};
	filename_ = answer_{2};
	headernum_ = answer_{3};
	exptype_ = answer_{4};
	rxnwin_ = str2double(answer_{5});
    trial_duration_ = str2double(answer_{6});
    target_ = str2double(answer_{7});
	exclusion_criteria_version_ = answer_{8};
	mousename_ = answer_{9};
	excludedtrials_ = answer_{10};
    p_Hz_ = answer_{11};
    m_Hz_ = answer_{12};
    
% Modifiable trial structure vars:
total_trial_duration_in_sec = trial_duration_/1000;


	waiter = questdlg('WARNING: Need to close all figures before proceeding - ok?','Ready to plot?', 'No');
	if strcmp(waiter, 'Yes')
		close all
		disp('proceeding!')
	else
		error('Close everything, then proceed from line 59')
	end
	disp('Collecting user input complete')



%% Extract trials with gfit:----------------------------------------------------------------- (section validated 12/5/17)
	disp('Extracting trials with gfit_roadmapv1_3...')
    extract_trials_gfit_roadmapv1_3
	disp('Extracting trials complete')



%% Extract lick_times_by_trial:-------------------------------------------------------------- (section validated 12/5/17)
	disp('Collecting lick_times_by_trial, no exclusions...')
	[lick_times_by_trial] = lick_times_by_trial_fx(lick_times,cue_on_times, total_trial_duration_in_sec, num_trials);
	disp('Collecting lick_times_by_trial, no exclusions complete')



%% First lick grabber: No exlcusions--------------------------------------------------------- (section validated 12/5/17)
	disp('First lick grabbing...')
	first_lick_handler_roadmap1_3
	disp('First lick grabbing complete')




%% Deal with exclusions--------------------------------------------------------------------- (section validated 12/5/17)
	disp('Executing exclusions...')
	auto_exclude_roadmapv1_3
    if snc_on == 1
        heatmap_3_fx(SNc_ex_values_by_trial, lick_ex_times_by_trial, 1); % to check if exclusions good
    elseif vta_on == 1
        heatmap_3_fx(VTA_ex_values_by_trial, lick_ex_times_by_trial, 1); % to check if exclusions good
    else
        heatmap_3_fx(EMG_ex_values_by_trial, lick_ex_times_by_trial, 1); % to check if exclusions good
    end
	disp('Excluded trials complete')


%% Back-fill the values_by_time arrays------------------------------------------------------ (section validated ???)
	disp('Executing backfill of nans in values_by_trial arrays...')
 	backfill_handler_roadmap1_3
	disp('Backfill complete.')


%% Z score back-filled data (global variance and STD over the session - exclusions):-------- (section validated ???)
	disp('Z-scoring backfilled values_by_trial with exclusions... (signal_exZ)')
	Z_score_backfill_ex_handler_roadmapv1_3
	disp('Z scoring complete.')





%% First lick grabber with exclusions------------------------------------------------------- (section validated ???)
	disp('Grabbing first licks without excluded trials...')
	first_lick_handler_exclusions_roadmap1_3
	disp('Grabbing first licks without excluded trials complete')






%% Close all figures----------------------------------------------------------------------- (section validated 10/26/17)
	% waiter = questdlg('Need to close all figures before proceeding - ok?','Ready to plot?', 'No');
	% if strcmp(waiter, 'Yes')
	% 	close all
	% 	disp('proceeding!')
	% else
	% 	error('Close everything, then proceed from line 160')
	% end
	close all
	figure_counter = 0;



%% Plot CTA and save figures---------------------------------------------------------------
	disp('Plotting CTA and saving figures...')
	roadmap_EMG_plotCTAsection_v1_3  % Just put into a script to make roadmapv1_3 more compact (10/30/17)
	disp('Plotting CTA and saving figures complete.')




%% Plot LTA and save figures---------------------------------------------------------------
	disp('Plotting LTA and saving figures...')
	roadmap_EMG_plotLTAsection_v1_3  % Just put into a script to make roadmapv1_3 more compact (10/30/17)
	disp('Plotting LTA and saving figures complete.')


%% Z score Lick-Aligned Data---------------------------------------------------------------- (section validated ???)
	disp('Z-scoring Lick-Aligned Data');
	Z_score_lick_aligned_data_handler_roadmapv1_3
	disp('Z-scoring Lick Aligned Data Complete');


%% Now generate plots up until first lick:--------------------------------------------------- (section validated ???)
	disp('Plotting CTA and LTA up to first lick and saving figures')
	plot_to_first_lick_handler_roadmapv1_3
	disp('Plotting and saving complete')

%% Z score up-to-lick data (global variance and STD over the session):----------------------- (section validated ???)
	disp('Z-scoring Lick-Aligned Data');
	Z_score_data_up_to_lick_handler_roadmapv1_3
	disp('Z-scoring Lick Aligned Data Complete');


%% Split up rxn+ and rxn- trials for CTA/LTA-------------------------------------------------
	% 	disp('Plotting CTA and LTA split by rxn/no rxn and saving figures')
	% %%%%%%%%%%%%%%THIS SECTION REQ DEBUG AND NOT DONE YET - USE CTA_LTA_split_by_rxn_no_rxn_Hz_v1_3(time_array, Hz, all_ex_first_licks, f_ex_lick_rxn, signal_ex_values_by_trial_fi_trim, early_signal_lick_triggered_trials, rew_signal_lick_triggered_trials, signalname)
	% % (11/15/17)
	% 	if snc_on && dls_on
	% 		CTA_LTA_split_by_rxn_no_rxn
	% 
	% 		if strcmp(exptype_, 'hyb')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 		elseif strcmp(exptype_, 'op')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 		end
	% 	else
	% 		disp('No DLS/SNc CTA/LTA to plot')
	% 	end
	% 
	% 	if x_on && y_on && z_on && emg_on
	% 		CTA_LTA_split_by_rxn_no_rxn %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
	% 
	% 		if strcmp(exptype_, 'hyb')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 		elseif strcmp(exptype_, 'op')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 			figure_counter = figure_counter+1;
	% 			print(figure_counter,'-depsc','-painters', ['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	% 			saveas(figure_counter,['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	% 		end
	% 	else
	% 		disp('No Movement CTA/LTA to plot')
	% 	end
	% 
	% 	disp('Saving figures complete.')

%% Plot Hxgrams (note not saved!)-----------------------------------------------------------
	% 	disp('Plotting Hxgrams')
	% 	hxgram_single_roadmapv1
	% 	disp('Plotting complete.')
	% 

%% Generate all variables for the header: -- using new structure strategy
	disp('Generating variables...')
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
	eval([datastruct_name '.SNc_ex_values_by_trial = SNc_ex_values_by_trial;']);
	eval([datastruct_name '.DLS_ex_values_by_trial = DLS_ex_values_by_trial;']);
	eval([datastruct_name '.VTA_ex_values_by_trial = VTA_ex_values_by_trial;']);
	eval([datastruct_name '.VTAred_ex_values_by_trial = VTAred_ex_values_by_trial;']);
	eval([datastruct_name '.SNcred_ex_values_by_trial = SNcred_ex_values_by_trial;']);
	eval([datastruct_name '.DLSred_ex_values_by_trial = DLSred_ex_values_by_trial;']);
	eval([datastruct_name '.SNc_values_by_trial = SNc_values_by_trial;']);
	eval([datastruct_name '.DLS_values_by_trial = DLS_values_by_trial;']);
	eval([datastruct_name '.VTA_values_by_trial = VTA_values_by_trial;']);
	eval([datastruct_name '.VTAred_values_by_trial = VTAred_values_by_trial;']);
	eval([datastruct_name '.SNcred_values_by_trial = SNcred_values_by_trial;']);
	eval([datastruct_name '.DLSred_values_by_trial = DLSred_values_by_trial;']);
	eval([datastruct_name '.SNc_times_by_trial = SNc_times_by_trial;']);
	eval([datastruct_name '.VTA_times_by_trial = VTA_times_by_trial;']);
	% note, not saving all the photom times by trial to save space
	eval([datastruct_name '.X_values = X_values;']);
	eval([datastruct_name '.Y_values = Y_values;']);
	eval([datastruct_name '.Z_values = Z_values;']);
	eval([datastruct_name '.EMG_values = EMG_values;']);
	eval([datastruct_name '.X_times = X_times;']);
	eval([datastruct_name '.X_values_by_trial = X_values_by_trial;']);
	eval([datastruct_name '.Y_values_by_trial = Y_values_by_trial;']);
	eval([datastruct_name '.Z_values_by_trial = Z_values_by_trial;']);
	eval([datastruct_name '.EMG_values_by_trial = EMG_values_by_trial;']);
	eval([datastruct_name '.X_times_by_trial = X_times_by_trial;']);
	eval([datastruct_name '.X_ex_values_by_trial = X_ex_values_by_trial;']);
	eval([datastruct_name '.Y_ex_values_by_trial = Y_ex_values_by_trial;']);
	eval([datastruct_name '.Z_ex_values_by_trial = Z_ex_values_by_trial;']);
	eval([datastruct_name '.EMG_ex_values_by_trial = EMG_ex_values_by_trial;']);
	eval([datastruct_name '.Excluded_Trials = Excluded_Trials;']);
	eval([datastruct_name '.num_trials = num_trials;']);

	%2. Lick times by trial data
	eval([datastruct_name '.lick_times_by_trial = lick_times_by_trial;']);
	eval([datastruct_name '.lick_ex_times_by_trial = lick_ex_times_by_trial;']);

	%3. First lick grabber - no exclusions		
	eval([datastruct_name '.f_lick_rxn = f_lick_rxn;']);
	eval([datastruct_name '.f_lick_operant_no_rew = f_lick_operant_no_rew;']);
	eval([datastruct_name '.f_lick_operant_rew = f_lick_operant_rew;']);
	eval([datastruct_name '.f_lick_ITI = f_lick_ITI;']);
	eval([datastruct_name '.all_first_licks = all_first_licks;']);

	%4. First lick grabber - exclusions	
	eval([datastruct_name '.f_ex_lick_rxn = f_ex_lick_rxn;']);
	eval([datastruct_name '.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;']);
	eval([datastruct_name '.f_ex_lick_operant_rew = f_ex_lick_operant_rew;']);
	eval([datastruct_name '.f_ex_lick_ITI = f_ex_lick_ITI;']);
	eval([datastruct_name '.all_ex_first_licks = all_ex_first_licks;']);

	%4.5 Backfilled:
	eval([datastruct_name '.DLS_values_by_trial_fi = DLS_values_by_trial_fi;']);
	eval([datastruct_name '.DLS_values_by_trial_fi_trim = DLS_values_by_trial_fi_trim;']);
	eval([datastruct_name '.VTA_values_by_trial_fi = VTA_values_by_trial_fi;']);
	eval([datastruct_name '.VTA_values_by_trial_fi_trim = VTA_values_by_trial_fi_trim;']);
	eval([datastruct_name '.VTAred_values_by_trial_fi = VTAred_values_by_trial_fi;']);
	eval([datastruct_name '.VTAred_values_by_trial_fi_trim = VTAred_values_by_trial_fi_trim;']);
	eval([datastruct_name '.DLSred_values_by_trial_fi = DLSred_values_by_trial_fi;']);
	eval([datastruct_name '.DLSred_values_by_trial_fi_trim = DLSred_values_by_trial_fi_trim;']);

	eval([datastruct_name '.DLS_ex_values_by_trial_fi = DLS_ex_values_by_trial_fi;']);
	eval([datastruct_name '.DLS_ex_values_by_trial_fi_trim = DLS_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.VTA_ex_values_by_trial_fi = VTA_ex_values_by_trial_fi;']);
	eval([datastruct_name '.VTA_ex_values_by_trial_fi_trim = VTA_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.DLSred_ex_values_by_trial_fi = DLSred_ex_values_by_trial_fi;']);
	eval([datastruct_name '.DLSred_ex_values_by_trial_fi_trim = DLSred_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.VTAred_ex_values_by_trial_fi = VTAred_ex_values_by_trial_fi;']);
	eval([datastruct_name '.VTAred_ex_values_by_trial_fi_trim = VTAred_ex_values_by_trial_fi_trim;']);

	eval([datastruct_name '.SNc_values_by_trial_fi = SNc_values_by_trial_fi;']);
	eval([datastruct_name '.SNc_values_by_trial_fi_trim = SNc_values_by_trial_fi_trim;']);
	eval([datastruct_name '.SNc_ex_values_by_trial_fi = SNc_ex_values_by_trial_fi;']);
	eval([datastruct_name '.SNc_ex_values_by_trial_fi_trim = SNc_ex_values_by_trial_fi_trim;']);

	eval([datastruct_name '.SNcred_values_by_trial_fi = SNcred_values_by_trial_fi;']);
	eval([datastruct_name '.SNcred_values_by_trial_fi_trim = SNcred_values_by_trial_fi_trim;']);
	eval([datastruct_name '.SNcred_ex_values_by_trial_fi = SNcred_ex_values_by_trial_fi;']);
	eval([datastruct_name '.SNcred_ex_values_by_trial_fi_trim = SNcred_ex_values_by_trial_fi_trim;']);

	eval([datastruct_name '.X_values_by_trial_fi = X_values_by_trial_fi;']);
	eval([datastruct_name '.X_values_by_trial_fi_trim = X_values_by_trial_fi_trim;']);
	eval([datastruct_name '.X_ex_values_by_trial_fi = X_ex_values_by_trial_fi;']);
	eval([datastruct_name '.X_ex_values_by_trial_fi_trim = X_ex_values_by_trial_fi_trim;']);

	eval([datastruct_name '.Y_values_by_trial_fi = Y_values_by_trial_fi;']);
	eval([datastruct_name '.Y_values_by_trial_fi_trim = Y_values_by_trial_fi_trim;']);
	eval([datastruct_name '.Y_ex_values_by_trial_fi = Y_ex_values_by_trial_fi;']);
	eval([datastruct_name '.Y_ex_values_by_trial_fi_trim = Y_ex_values_by_trial_fi_trim;']);

	eval([datastruct_name '.Z_values_by_trial_fi = Z_values_by_trial_fi;']);
	eval([datastruct_name '.Z_values_by_trial_fi_trim = Z_values_by_trial_fi_trim;']);
	eval([datastruct_name '.Z_ex_values_by_trial_fi = Z_ex_values_by_trial_fi;']);
	eval([datastruct_name '.Z_ex_values_by_trial_fi_trim = Z_ex_values_by_trial_fi_trim;']);

	eval([datastruct_name '.EMG_values_by_trial_fi = EMG_values_by_trial_fi;']);
	eval([datastruct_name '.EMG_values_by_trial_fi_trim = EMG_values_by_trial_fi_trim;']);
	eval([datastruct_name '.EMG_ex_values_by_trial_fi = EMG_ex_values_by_trial_fi;']);
	eval([datastruct_name '.EMG_ex_values_by_trial_fi_trim = EMG_ex_values_by_trial_fi_trim;']);

	% 4.55 values by trial up to lick:
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

	%5. LTA
	eval([datastruct_name '.lick_triggered_trials_struct = lick_triggered_trials_struct;']);
	
	%5. LTA
	% eval([datastruct_name '.N_rxn_DLS = N_rxn_DLS;']);
	% eval([datastruct_name '.N_rxn_SNc = N_rxn_SNc;']);
	% eval([datastruct_name '.N_early_DLS = N_early_DLS;']);
	% eval([datastruct_name '.N_early_SNc = N_early_SNc;']);
	% eval([datastruct_name '.N_rew_DLS = N_rew_DLS;']);
	% eval([datastruct_name '.N_rew_SNc = N_rew_SNc;']);
	% eval([datastruct_name '.N_ITI_DLS = N_ITI_DLS;']);
	% eval([datastruct_name '.N_ITI_SNc = N_ITI_SNc;']);
	% eval([datastruct_name '.time_array = time_array;']);
	% eval([datastruct_name '.rxn_DLS_lick_triggered_trials = rxn_DLS_lick_triggered_trials;']);
	% eval([datastruct_name '.early_DLS_lick_triggered_trials = early_DLS_lick_triggered_trials;']);
	% eval([datastruct_name '.rew_DLS_lick_triggered_trials = rew_DLS_lick_triggered_trials;']);
	% eval([datastruct_name '.rxn_SNc_lick_triggered_trials = rxn_SNc_lick_triggered_trials;']);
	% eval([datastruct_name '.early_SNc_lick_triggered_trials = early_SNc_lick_triggered_trials;']);
	% eval([datastruct_name '.rew_SNc_lick_triggered_trials = rew_SNc_lick_triggered_trials;']);

	% eval([rxn_X_lick_triggered_trials '.rxn_X_lick_triggered_trials = rxn_X_lick_triggered_trials;']);
	% eval([early_X_lick_triggered_trials '.early_X_lick_triggered_trials = early_X_lick_triggered_trials;']);
	% eval([rew_X_lick_triggered_trials '.rew_X_lick_triggered_trials = rew_X_lick_triggered_trials;']);
	% eval([rxn_Y_lick_triggered_trials '.rxn_Y_lick_triggered_trials = rxn_Y_lick_triggered_trials;']);
	% eval([early_Y_lick_triggered_trials '.early_Y_lick_triggered_trials = early_Y_lick_triggered_trials;']);
	% eval([rew_Y_lick_triggered_trials '.rew_Y_lick_triggered_trials = rew_Y_lick_triggered_trials;']);
	% eval([rxn_Z_lick_triggered_trials '.rxn_Z_lick_triggered_trials = rxn_Z_lick_triggered_trials;']);
	% eval([early_Z_lick_triggered_trials '.early_Z_lick_triggered_trials = early_Z_lick_triggered_trials;']);
	% eval([rew_Z_lick_triggered_trials '.rew_Z_lick_triggered_trials = rew_Z_lick_triggered_trials;']);
	% eval([rxn_EMG_lick_triggered_trials '.rxn_EMG_lick_triggered_trials = rxn_EMG_lick_triggered_trials;']);
	% eval([early_EMG_lick_triggered_trials '.early_EMG_lick_triggered_trials = early_EMG_lick_triggered_trials;']);
	% eval([rew_EMG_lick_triggered_trials '.rew_EMG_lick_triggered_trials = rew_EMG_lick_triggered_trials;']);
	% eval([pav_X_lick_triggered_trials '.pav_X_lick_triggered_trials = pav_X_lick_triggered_trials;']);
	% eval([pav_Y_lick_triggered_trials '.pav_Y_lick_triggered_trials = pav_Y_lick_triggered_trials;']);
	% eval([pav_Z_lick_triggered_trials '.pav_Z_lick_triggered_trials = pav_Z_lick_triggered_trials;']);
	% eval([pav_EMG_lick_triggered_trials '.pav_EMG_lick_triggered_trials = pav_EMG_lick_triggered_trials;']);
	% eval([N_rxn_X '.N_rxn_X = N_rxn_X;']);
	% eval([N_rxn_Y '.N_rxn_Y = N_rxn_Y;']);
	% eval([N_rxn_Z '.N_rxn_Z = N_rxn_Z;']);
	% eval([N_rxn_EMG '.N_rxn_EMG = N_rxn_EMG;']);
	% eval([N_early_X '.N_early_X = N_early_X;']);
	% eval([N_early_Y '.N_early_Y = N_early_Y;']);
	% eval([N_early_Z '.N_early_Z = N_early_Z;']);
	% eval([N_early_EMG '.N_early_EMG = N_early_EMG;']);
	% eval([N_rew_X '.N_rew_X = N_rew_X;']);
	% eval([N_rew_Y '.N_rew_Y = N_rew_Y;']);
	% eval([N_rew_Z '.N_rew_Z = N_rew_Z;']);
	% eval([N_rew_EMG '.N_rew_EMG = N_rew_EMG;']);
	% eval([N_ITI_X '.N_ITI_X = N_ITI_X;']);
	% eval([N_ITI_Y '.N_ITI_Y = N_ITI_Y;']);
	% eval([N_ITI_Z '.N_ITI_Z = N_ITI_Z;']);
	% eval([N_ITI_EMG '.N_ITI_EMG = N_ITI_EMG;']);
	% eval([N_pav_X '.N_pav_X = N_pav_X;']);
	% eval([N_pav_Y '.N_pav_Y = N_pav_Y;']);
	% eval([N_pav_Z '.N_pav_Z = N_pav_Z;']);
	% eval([N_pav_EMG '.N_pav_EMG = N_pav_EMG;']);


	%6. Pavlovian
	if strcmp(exptype_, 'hyb')
		eval([datastruct_name '.f_lick_pavlovian = f_lick_pavlovian;']);
		eval([datastruct_name '.f_ex_lick_pavlovian = f_ex_lick_pavlovian;']);
		% eval([datastruct_name '.N_pav_DLS = N_pav_DLS;']);
		% eval([datastruct_name '.N_pav_SNc = N_pav_SNc;']);
		% eval([datastruct_name '.pav_DLS_lick_triggered_trials = pav_DLS_lick_triggered_trials;']);
		% eval([datastruct_name '.pav_SNc_lick_triggered_trials = pav_SNc_lick_triggered_trials;']);
	end
	
	if rxnwin_ == 300
			eval([datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort + f_ex_lick_train_abort;']);
			eval([datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
		
	elseif rxnwin_ == 500 & strcmp(exptype_,'op')
			eval([datastruct_name '.f_lick_rxn_abort = f_lick_rxn_abort;']);
			eval([datastruct_name '.f_ex_lick_rxn_abort = f_ex_lick_rxn_abort;']);
	end


	%7. Z scored data structure:

	eval([Z_scored_name '.SNc_exZ = SNc_exZ;']);
	eval([Z_scored_name '.DLS_exZ = DLS_exZ;']);
	eval([Z_scored_name '.VTA_exZ = VTA_exZ;']);
	eval([Z_scored_name '.SNcred_exZ = SNcred_exZ;']);
	eval([Z_scored_name '.DLSred_exZ = DLSred_exZ;']);
	eval([Z_scored_name '.VTAred_exZ = VTAred_exZ;']);
	eval([Z_scored_name '.X_exZ = X_exZ;']);
	eval([Z_scored_name '.Y_exZ = Y_exZ;']);
	eval([Z_scored_name '.Z_exZ = Z_exZ;']);
	eval([Z_scored_name '.EMG_exZ = EMG_exZ;']);


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

	disp('Generating variables complete.')






%% Save all variables to the header
	disp('Saving variables to header...')
	answ = questdlg(['Warning - about to create header file called:                                        ', mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1_3 ',...
						 todaysdate2,'.txt                                       and                                     ',...
						 mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate,...
						 '.mat                                              Check if exists - ok to overwrite?'],'Ready to Save?', 'No');
	if strcmp(answ, 'Yes')
		disp('proceeding!')
	else
		error('Figure out header you want and proceed from line 648')
	end


	savefilename = [mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	saveZname = ['Z_score_', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(savefilename, datastruct_name, '-v7.3');
	save(saveZname, Z_scored_name, '-v7.3');

	disp('Saving variables to header complete.')


%% Generate the header file:
	disp('Generating Header.')
	excluded_trials_ = Excluded_Trials;

	prompt2 = {'Enter header file text:', 'Generation Codes', 'Exp Description', 'Excluded Trials:', 'Notes - don''t make any carriage returns!'};
	dlg_title = 'Header file text';
	num_lines = 5;
	defaultans = {[mousename_, ' Day ',daynum_, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2,...
				 ' using roadmapv1_3 - version 12-4-17 - set of functions, which includes Z-scored data (plot-to-lick and backfilled) and is for movement and photometry.'],...
				  ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Excluded trials: ', num2str(excluded_trials_)], 'Notes:'};
	answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



	fid = fopen([mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1_3 ', todaysdate2,'.txt'], 'wt' );
	fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
	fclose(fid);
	disp('All files complete!!----------------------------------------------------------!')






