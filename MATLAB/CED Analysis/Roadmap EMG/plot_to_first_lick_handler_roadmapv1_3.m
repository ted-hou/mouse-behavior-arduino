%% plot_to_first_lick_handler_roadmapv1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-5-17: 
%% -------------------------------------------------------------------------------------------


	if snc_on 
		signalname = 'SNc';
		Hz = 1000;

		[SNc_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(SNc_ex_values_by_trial_fi_trim,Hz,all_ex_first_licks,time_array_1000hz, lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials, lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials, f_lick_operant_no_rew, f_lick_operant_rew, signalname);
		% plot_to_lick_roadmapv1
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['SNc_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNc_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['SNc_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['SNc_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['SNc_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['DLS_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['DLS_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['DLS_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['DLS_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['DLS_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['VTA_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['VTA_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['VTA_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['VTA_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['VTA_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['SNcred_CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['SNcred_CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['SNcred_LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
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
		% print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 		figure_counter = figure_counter+1;
% 		print(figure_counter,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 		saveas(figure_counter,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		figure_counter = figure_counter+1;
		% print(figure_counter,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(figure_counter,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	else
		disp('No EMG signals to plot')
		EMG_ex_values_up_to_lick = [];
	end