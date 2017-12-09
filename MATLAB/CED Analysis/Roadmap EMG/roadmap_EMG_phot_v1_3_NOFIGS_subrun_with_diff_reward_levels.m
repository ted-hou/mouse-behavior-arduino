%% Run Analysis Roadmap-No Figures - Run after extracting data for diff reward levels-------------------------------------------------------------------
% 
% 	Created 	12-6-17 ahamilos (from v1_3 version on 12-6-17)
% 	Modified 	12-6-17 ahamilos 
% 
% UPDATE LOG:
% 		- 12-6-17: made a runner for different reward level splits. Run after running roadmapv1_3, either version
% previous versions:
% 		- 12-5-17: Suppress output of all but most essential summary figures (plot to lick LTAs)
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
%% ------------------------------------------------------------------------------------------- (section validated 12/5/17)



% Start of run: Prompt user for needed variables-------------------------------------------- (section validated 12/5/17)
	disp('Collecting user input...')
	collect_UI_handler_roadmapv1_3_subrun_diff_rew_levels
	disp('Collecting user input complete')



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



%% SKIPPED: Plot CTA and save figures---------------------------------------------------------------
	% disp('Plotting CTA and saving figures...')
	% roadmap_EMG_plotCTAsection_v1_3  % Just put into a script to make roadmapv1_3 more compact (10/30/17)
	% disp('Plotting CTA and saving figures complete.')




%% Plot LTA and save figures---------------------------------------------------------------
	% disp('Plotting LTA and saving figures...')
	NOFIGS_roadmap_EMG_plotLTAsection_v1_3  % Just put into a script to make roadmapv1_3 more compact (12/5/17)
	% disp('Plotting LTA and saving figures complete.')


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
	generate_variable_names_roadmap1_3
	disp('Generating variables complete.')






%% Save all variables to the header
	disp('Saving variables to header...')
	save_data_to_header_handler_roadmapv1_3
	disp('Saving variables to header complete.')


%% Generate the header file:
	disp('Generating Header.')
	generate_header_handler_roadmapv1_3
	disp('All files complete!!----------------------------------------------------------!')






