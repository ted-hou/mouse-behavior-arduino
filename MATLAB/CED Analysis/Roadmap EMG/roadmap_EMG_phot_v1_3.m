%% Run Analysis Roadmap-------------------------------------------------------------------
% 
% 	Created 	8-01-17 ahamilos (roadmap v1)
% 	Modified 	10-30-17 ahamilos
% 
% UPDATE LOG:
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
% Modifiable trial structure vars:
total_trial_duration_in_sec = 17;




todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');

% Start of run: Prompt user for needed variables-------------------------------------------- (section validated 10/26/17)
	disp('Collecting user input...')
	prompt = {'Day # prefix:','CED filename_ (don''t include *_lick, etc):', 'Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Exclusion Criteria Version', 'Animal Name', 'Excluded Trials'};
	dlg_title = 'Inputs';
	num_lines = 1;
	defaultans = {'7','h6_day7_sncvta_dlsred','1', 'op', '500', '1', 'H6', '###'};
	answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
	daynum_ = answer_{1};
	filename_ = answer_{2};
	headernum_ = answer_{3};
	exptype_ = answer_{4};
	rxnwin_ = str2double(answer_{5});
	exclusion_criteria_version_ = answer_{6};
	mousename_ = answer_{7};
	excludedtrials_ = answer_{8};


	waiter = questdlg('WARNING: Need to close all figures before proceeding - ok?','Ready to plot?', 'No');
	if strcmp(waiter, 'Yes')
		close all
		disp('proceeding!')
	else
		error('Close everything, then proceed from line 59')
	end
	disp('Collecting user input complete')



%% Extract trials with gfit:----------------------------------------------------------------- (section validated 10/26/17)
	disp('Extracting trials with gfit_roadmapv1_3...')
    extract_trials_gfit_roadmapv1_3
	disp('Extracting trials complete')




%% Extract lick_times_by_trial:-------------------------------------------------------------- (section validated 10/26/17)
	disp('Collecting lick_times_by_trial, no exclusions...')
	[lick_times_by_trial] = lick_times_by_trial_fx(lick_times,cue_on_times, total_trial_duration_in_sec, num_trials);
	disp('Collecting lick_times_by_trial, no exclusions complete')



%% First lick grabber: No exlcusions--------------------------------------------------------- (section validated 10/26/17)
	disp('First lick grabbing...')
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
	disp('First lick grabbing complete')




%% Deal with exclusions--------------------------------------------------------------------- (section validated 10/26/17)
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


%% Back-fill the values_by_time arrays------------------------------------------------------ (section validated 10/26/17)
	disp('Executing backfill of nans in values_by_trial arrays...')
    if dls_on
        [DLS_values_by_trial_fi, DLS_ex_values_by_trial_fi,DLS_values_by_trial_fi_trim, DLS_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(DLS_values_by_trial, DLS_ex_values_by_trial, num_trials);
    else
        DLS_values_by_trial_fi = [];
        DLS_ex_values_by_trial_fi = [];
        DLS_values_by_trial_fi_trim = [];
        DLS_ex_values_by_trial_fi_trim = [];
    end
    if snc_on
    	[SNc_values_by_trial_fi, SNc_ex_values_by_trial_fi,SNc_values_by_trial_fi_trim, SNc_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(SNc_values_by_trial, SNc_ex_values_by_trial, num_trials);
    else
        SNc_values_by_trial_fi = [];
        SNc_ex_values_by_trial_fi = [];
        SNc_values_by_trial_fi_trim = [];
        SNc_ex_values_by_trial_fi_trim = [];
    end
    if vta_on
    	[VTA_values_by_trial_fi, VTA_ex_values_by_trial_fi,VTA_values_by_trial_fi_trim, VTA_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(VTA_values_by_trial, VTA_ex_values_by_trial, num_trials);
    else
        VTA_values_by_trial_fi = [];
        VTA_ex_values_by_trial_fi = [];
        VTA_values_by_trial_fi_trim = [];
        VTA_ex_values_by_trial_fi_trim = [];
    end

    if dlsred_on
        [DLSred_values_by_trial_fi, DLSred_ex_values_by_trial_fi,DLSred_values_by_trial_fi_trim, DLSred_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(DLSred_values_by_trial, DLSred_ex_values_by_trial, num_trials);
    else
        DLSred_values_by_trial_fi = [];
        DLSred_ex_values_by_trial_fi = [];
        DLSred_values_by_trial_fi_trim = [];
        DLSred_ex_values_by_trial_fi_trim = [];
    end
    if sncred_on
        [SNcred_values_by_trial_fi, SNcred_ex_values_by_trial_fi,SNcred_values_by_trial_fi_trim, SNcred_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(SNcred_values_by_trial, SNcred_ex_values_by_trial, num_trials);
    else
        SNcred_values_by_trial_fi = [];
        SNcred_ex_values_by_trial_fi = [];
        SNcred_values_by_trial_fi_trim = [];
        SNcred_ex_values_by_trial_fi_trim = [];
    end
    if vtared_on
        [VTAred_values_by_trial_fi, VTAred_ex_values_by_trial_fi,VTAred_values_by_trial_fi_trim, VTAred_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(VTAred_values_by_trial, VTAred_ex_values_by_trial, num_trials);
    else
        VTAred_values_by_trial_fi = [];
        VTAred_ex_values_by_trial_fi = [];
        VTAred_values_by_trial_fi_trim = [];
        VTAred_ex_values_by_trial_fi_trim = [];
    end


    if x_on && y_on && z_on
    	[X_values_by_trial_fi, X_ex_values_by_trial_fi,X_values_by_trial_fi_trim, X_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(X_values_by_trial, X_ex_values_by_trial, num_trials);
        [Y_values_by_trial_fi, Y_ex_values_by_trial_fi,Y_values_by_trial_fi_trim, Y_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(Y_values_by_trial, Y_ex_values_by_trial, num_trials);
        [Z_values_by_trial_fi, Z_ex_values_by_trial_fi,Z_values_by_trial_fi_trim, Z_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(Z_values_by_trial, Z_ex_values_by_trial, num_trials);
    else
        X_values_by_trial_fi = [];
        X_ex_values_by_trial_fi = [];
        X_values_by_trial_fi_trim = [];
        X_ex_values_by_trial_fi_trim = [];
        
        Y_values_by_trial_fi = [];
        Y_ex_values_by_trial_fi = [];
        Y_values_by_trial_fi_trim = [];
        Y_ex_values_by_trial_fi_trim = [];
        
        Z_values_by_trial_fi = [];
        Z_ex_values_by_trial_fi = [];
        Z_values_by_trial_fi_trim = [];
        Z_ex_values_by_trial_fi_trim = [];
    end
        
    if emg_on
    	[EMG_values_by_trial_fi, EMG_ex_values_by_trial_fi,EMG_values_by_trial_fi_trim, EMG_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(EMG_values_by_trial, EMG_ex_values_by_trial, num_trials);
    else
        EMG_values_by_trial_fi = [];
        EMG_ex_values_by_trial_fi = [];
        EMG_values_by_trial_fi_trim = [];
        EMG_ex_values_by_trial_fi_trim = [];
    end
	disp('Backfill complete.')





%% First lick grabber with exclusions------------------------------------------------------- (section validated 10/26/17)
	disp('Grabbing first licks without excluded trials...')
	if strcmp(exptype_,'hyb') && rxnwin_ == 500
		[f_ex_lick_rxn, f_ex_lick_train_abort, f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_pavlovian, f_ex_lick_ITI,~,~,~,~, all_ex_first_licks] = first_lick_grabber_hyb(lick_ex_times_by_trial, num_trials);
	elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
		[f_ex_lick_rxn,f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_pavlovian, f_ex_lick_ITI,~, ~, ~, all_ex_first_licks] = first_lick_grabber_hyb_0ms(lick_ex_times_by_trial, num_trials);
	elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
		h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 127 in roadmapv1 and debug');
	elseif strcmp(exptype_,'op') && rxnwin_ == 500
		[f_ex_lick_rxn, f_ex_lick_rxn_abort, f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_ITI,~,~,~,all_ex_first_licks] = first_lick_grabber_operant_fx(lick_ex_times_by_trial, num_trials);
	elseif strcmp(exptype_,'op') && rxnwin_ == 300
		[f_ex_lick_rxn, f_ex_lick_rxn_fail, f_ex_lick_train_abort, f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_ITI, ~, ~, ~, all_ex_first_licks] = first_lick_grabber_operant_fx_300msv(lick_ex_times_by_trial, num_trials);
	elseif strcmp(exptype_,'op') && rxnwin_ == 0
		[f_ex_lick_rxn, f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_ITI, ~, ~, all_ex_first_licks] = first_lick_grabber_operant_fx_0msv(lick_ex_times_by_trial, num_trials);
	elseif strcmp(exptype_,'op')
		h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 135 in roadmapv1 and debug');
	else
		h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 120');
	end
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



%% Now generate plots up until first lick:
	disp('Plotting CTA and LTA up to first lick and saving figures')


	if snc_on 
		signalname = 'SNc';
		Hz = 1000;

		[SNc_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(SNc_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials, lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['SNc_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNc_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['SNc_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNc_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['SNc_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNc_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No SNc signals to plot')
		SNc_ex_values_up_to_lick = [];
	end

	if dls_on 
		signalname = 'DLS';
		Hz = 1000;

		[DLS_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(DLS_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials, lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['DLS_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['DLS_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['DLS_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['DLS_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['DLS_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['DLS_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No DLS signals to plot')
		DLS_ex_values_up_to_lick = [];
	end

	if vta_on 
		signalname = 'VTA';
		Hz = 1000;

		[VTA_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(VTA_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials, lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['VTA_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['VTA_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['VTA_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['VTA_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['VTA_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['VTA_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No VTA signals to plot')
		VTA_ex_values_up_to_lick = [];
	end



	if sncred_on 
		signalname = 'SNcred';
		Hz = 1000;

		[SNcred_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(SNcred_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials, lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNcred_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNcred_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['SNcred_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNcred_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No SNcred signals to plot')
		SNcred_ex_values_up_to_lick = [];
	end


	if dlsred_on 
		signalname = 'DLSred';
		Hz = 1000;

		[DLSred_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(DLSred_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials, lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No DLSred signals to plot')
		DLSred_ex_values_up_to_lick = [];
	end

	if vtared_on 
		signalname = 'VTAred';
		Hz = 1000;

		[VTAred_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(VTAred_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials, lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No VTAred signals to plot')
		VTAred_ex_values_up_to_lick = [];
	end


	if x_on 
		signalname = 'X';
		Hz = 2000;

		[X_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(X_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_2000hz, lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials, lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No X signals to plot')
		X_ex_values_up_to_lick = [];
	end

	if y_on 
		signalname = 'Y';
		Hz = 2000;

		[Y_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(Y_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_2000hz, lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials, lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No Y signals to plot')
		Y_ex_values_up_to_lick = [];
	end
	
	if z_on 
		signalname = 'Z';
		Hz = 2000;

		[Z_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(Z_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_2000hz, lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials, lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No Z signals to plot')
		Z_ex_values_up_to_lick = [];
	end
	
	if emg_on 
		signalname = 'EMG';
		Hz = 2000;

		[EMG_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(abs(EMG_ex_values_by_trial_fi_trim),Hz,all_ex_first_licks,time_array_2000hz, lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials, lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No EMG signals to plot')
		EMG_ex_values_up_to_lick = [];
	end

	disp('Plotting and saving complete')




%% Split up rxn+ and rxn- trials for CTA/LTA-------------------------------------------------
	disp('Plotting CTA and LTA split by rxn/no rxn and saving figures')
	
	if snc_on && dls_on
		CTA_LTA_split_by_rxn_no_rxn

		if strcmp(exptype_, 'hyb')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		elseif strcmp(exptype_, 'op')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		end
	else
		disp('No DLS/SNc CTA/LTA to plot')
	end

	if x_on && y_on && z_on && emg_on
		CTA_LTA_split_by_rxn_no_rxn %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

		if strcmp(exptype_, 'hyb')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		elseif strcmp(exptype_, 'op')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Move_CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Move_LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		end
	else
		disp('No Movement CTA/LTA to plot')
	end

	disp('Saving figures complete.')

%% Plot Hxgrams (note not saved!)-----------------------------------------------------------
	disp('Plotting Hxgrams')
	hxgram_single_roadmapv1
	disp('Plotting complete.')


%% Generate all variables for the header: -- using new structure strategy
	disp('Generating variables...')
	datastruct_name = genvarname(['d', daynum_, '_data_struct']);
	eval([datastruct_name '= {};']);

	% 1. extracted data
	eval([datastruct_name '.gfit_SNc = gfit_SNc;']);
	eval([datastruct_name '.gfit_DLS = gfit_DLS;']);
	eval([datastruct_name '.SNc_ex_values_by_trial = SNc_ex_values_by_trial;']);
	eval([datastruct_name '.DLS_ex_values_by_trial = DLS_ex_values_by_trial;']);
	eval([datastruct_name '.SNc_values_by_trial = SNc_values_by_trial;']);
	eval([datastruct_name '.DLS_values_by_trial = DLS_values_by_trial;']);
	eval([datastruct_name '.SNc_times_by_trial = SNc_times_by_trial;']);
	eval([datastruct_name '.DLS_times_by_trial = DLS_times_by_trial;']);
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
	eval([datastruct_name '.DLS_ex_values_by_trial_fi = DLS_ex_values_by_trial_fi;']);
	eval([datastruct_name '.DLS_ex_values_by_trial_fi_trim = DLS_ex_values_by_trial_fi_trim;']);
	eval([datastruct_name '.SNc_values_by_trial_fi = SNc_values_by_trial_fi;']);
	eval([datastruct_name '.SNc_values_by_trial_fi_trim = SNc_values_by_trial_fi_trim;']);
	eval([datastruct_name '.SNc_ex_values_by_trial_fi = SNc_ex_values_by_trial_fi;']);
	eval([datastruct_name '.SNc_ex_values_by_trial_fi_trim = SNc_ex_values_by_trial_fi_trim;']);

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
	save(savefilename, datastruct_name, '-v7.3');
	disp('Saving variables to header complete.')


%% Generate the header file:
	disp('Generating Header.')
	excluded_trials_ = Excluded_Trials;

	prompt2 = {'Enter header file text:', 'Generation Codes', 'Exp Description', 'Excluded Trials:', 'Notes - don''t make any carriage returns!'};
	dlg_title = 'Header file text';
	num_lines = 5;
	defaultans = {[mousename_, ' Day ',daynum_, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2,...
				 ' using roadmapv1_3 set of functions, which includes plot-to-lick and backfill fxs and is for MOVEMENT and photometry.'],...
				  ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Excluded trials: ', num2str(excluded_trials_)], 'Notes:'};
	answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



	fid = fopen([mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1_3 ', todaysdate2,'.txt'], 'wt' );
	fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
	fclose(fid);
	disp('All files complete!!----------------------------------------------------------!')






