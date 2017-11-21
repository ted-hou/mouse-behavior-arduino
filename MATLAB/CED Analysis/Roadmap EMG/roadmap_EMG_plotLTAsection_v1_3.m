% roadmap_EMG_plotLTAsection_v1_3.m 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% 	Created  10-30-17 	ahamilos	(from roadmap_EMG_phot_v1_3.m)
% 	Modified 10-30-17	ahamilos
% 
%  USE: Used to make roadmap runner more compact - not a function, but just called as a script from roadmap_EMG_phot_v1_3.m
% 
% --------------------------------------------------------------------------------

	time_array_1000hz = [];
	time_array_2000hz = [];
	lick_triggered_trials_struct = {};
	lick_triggered_trials_struct.DLS_lick_triggered_trials = {};
	lick_triggered_trials_struct.SNc_lick_triggered_trials = {};
	lick_triggered_trials_struct.VTA_lick_triggered_trials = {};
	lick_triggered_trials_struct.DLSred_lick_triggered_trials = {};
	lick_triggered_trials_struct.SNcred_lick_triggered_trials = {};
	lick_triggered_trials_struct.VTAred_lick_triggered_trials = {};
	lick_triggered_trials_struct.EMG_lick_triggered_trials = {};
	lick_triggered_trials_struct.X_lick_triggered_trials = {};
	lick_triggered_trials_struct.Y_lick_triggered_trials = {};
	lick_triggered_trials_struct.Z_lick_triggered_trials = {};

	lick_triggered_trials_struct.DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.pav_DLS_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.N_rxn_DLS = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.N_early_DLS = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.N_rew_DLS = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.N_ITI_DLS = [];
	lick_triggered_trials_struct.DLS_lick_triggered_trials.N_pav_DLS = [];

	lick_triggered_trials_struct.SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.pav_SNc_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_rxn_SNc = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_early_SNc = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_rew_SNc = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_ITI_SNc = [];
	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_pav_SNc = [];

	lick_triggered_trials_struct.VTA_lick_triggered_trials.pav_VTA_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.N_rxn_VTA = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.N_early_VTA = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.N_rew_VTA = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.N_ITI_VTA = [];
	lick_triggered_trials_struct.VTA_lick_triggered_trials.N_pav_VTA = [];

	lick_triggered_trials_struct.DLSred_lick_triggered_trials.pav_DLSred_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_rxn_DLSred = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_early_DLSred = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_rew_DLSred = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_ITI_DLSred = [];
	lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_pav_DLSred = [];

	lick_triggered_trials_struct.SNcred_lick_triggered_trials.pav_SNcred_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_rxn_SNcred = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_early_SNcred = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_rew_SNcred = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_ITI_SNcred = [];
	lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_pav_SNcred = [];

	lick_triggered_trials_struct.VTAred_lick_triggered_trials.pav_VTAred_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_rxn_VTAred = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_early_VTAred = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_rew_VTAred = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_ITI_VTAred = [];
	lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_pav_VTAred = [];

	lick_triggered_trials_struct.X_lick_triggered_trials.rxn_X_lick_triggered_trials = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.pav_X_lick_triggered_trials = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.ITI_X_lick_triggered_trials = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.N_rxn_X = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.N_early_X = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.N_rew_X = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.N_ITI_X = [];
	lick_triggered_trials_struct.X_lick_triggered_trials.N_pav_X = [];

	lick_triggered_trials_struct.Y_lick_triggered_trials.rxn_Y_lick_triggered_trials = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.pav_Y_lick_triggered_trials = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.ITI_Y_lick_triggered_trials = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.N_rxn_Y = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.N_early_Y = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.N_rew_Y = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.N_ITI_Y = [];
	lick_triggered_trials_struct.Y_lick_triggered_trials.N_pav_Y = [];

	lick_triggered_trials_struct.Z_lick_triggered_trials.rxn_Z_lick_triggered_trials = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.pav_Z_lick_triggered_trials = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.ITI_Z_lick_triggered_trials = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.N_rxn_Z = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.N_early_Z = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.N_rew_Z = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.N_ITI_Z = [];
	lick_triggered_trials_struct.Z_lick_triggered_trials.N_pav_Z = [];

	lick_triggered_trials_struct.EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.pav_EMG_lick_triggered_trials = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.N_rxn_EMG = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.N_early_EMG = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.N_rew_EMG = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.N_ITI_EMG = [];
	lick_triggered_trials_struct.EMG_lick_triggered_trials.N_pav_EMG = [];
	
	
	






	if snc_on 
		signalname = 'SNc';
		Hz = 1000;
		if strcmp(exptype_,'hyb')
			[lick_triggered_trials_struct.SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials,lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials,	lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials,	lick_triggered_trials_struct.SNc_lick_triggered_trials.pav_signal_lick_triggered_trials,lick_triggered_trials_struct.SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials,	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_rxn_SNc,lick_triggered_trials_struct.SNc_lick_triggered_trials.N_early_SNc,	lick_triggered_trials_struct.SNc_lick_triggered_trials.N_rew_SNc,lick_triggered_trials_struct.SNc_lick_triggered_trials.N_pav_SNc,lick_triggered_trials_struct.SNc_lick_triggered_trials.N_ITI_SNc, time_array_1000hz] = LTA_extractor_photom_overlay_hyb_roadmap1_3_fx(SNc_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);
 


			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['SNc_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



			LTA_photom_time_binner_hyb_roadmap1_3_fx(time_array_1000hz,Hz,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.pav_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials,...
								f_lick_rxn,...
								f_lick_operant_no_rew,...
								f_lick_operant_rew,...
								f_lick_pavlovian,...
								f_lick_ITI,...
								signalname);
			%% Save all figures:
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		



		elseif strcmp(exptype_, 'op')
			[lick_triggered_trials_struct.SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.N_rxn_SNc,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.N_early_SNc,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.N_rew_SNc,...
    		lick_triggered_trials_struct.SNc_lick_triggered_trials.N_ITI_SNc,...
    		time_array_1000hz] = LTA_extractor_photom_overlay_op_roadmapv1_3_fx(SNc_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);

		
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;	
			print(figure_counter,'-depsc','-painters',['SNc_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

			LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_1000hz,Hz,... %************************************!!!!!!!!!!!!!!!!!!!!!!!!
								lick_triggered_trials_struct.SNc_lick_triggered_trials.rxn_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.early_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.rew_SNc_lick_triggered_trials,...
								lick_triggered_trials_struct.SNc_lick_triggered_trials.ITI_SNc_lick_triggered_trials,...
								f_lick_rxn,...
								f_lick_operant_no_rew,...
								f_lick_operant_rew,...
								f_lick_ITI,...
								signalname);

			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
		end
	else
		disp('No SNc LTAs to plot')
	end




	if dls_on 
			signalname = 'DLS';
			Hz = 1000;
			if strcmp(exptype_,'hyb')
				[lick_triggered_trials_struct.DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_rxn_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_early_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_rew_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_pav_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_ITI_DLS,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_hyb_roadmap1_3_fx(DLS_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters',['DLS_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



				LTA_photom_time_binner_hyb_roadmap1_3_fx(time_array_1000hz,Hz,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.pav_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);
				%% Save all figures:
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			



			elseif strcmp(exptype_, 'op')
				[lick_triggered_trials_struct.DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_rxn_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_early_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_rew_DLS,...
	    		lick_triggered_trials_struct.DLS_lick_triggered_trials.N_ITI_DLS,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_op_roadmapv1_3_fx(DLS_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);

			
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLS_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

				LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_1000hz,Hz,... %************************************!!!!!!!!!!!!!!!!!!!!!!!!
									lick_triggered_trials_struct.DLS_lick_triggered_trials.rxn_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.early_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.rew_DLS_lick_triggered_trials,...
									lick_triggered_trials_struct.DLS_lick_triggered_trials.ITI_DLS_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);

				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLS_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLS_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLS_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLS_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLS_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			else
				h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
			end
		else
			disp('No DLS LTAs to plot')
		end





	if vta_on 
			signalname = 'VTA';
			Hz = 1000;
			if strcmp(exptype_,'hyb')
				[lick_triggered_trials_struct.VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_rxn_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_early_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_rew_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_pav_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_ITI_VTA,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_hyb_roadmap1_3_fx(VTA_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters',['VTA_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



				LTA_photom_time_binner_hyb_roadmap1_3_fx(time_array_1000hz,Hz,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.pav_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);
				%% Save all figures:
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			



			elseif strcmp(exptype_, 'op')
				[lick_triggered_trials_struct.VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_rxn_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_early_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_rew_VTA,...
	    		lick_triggered_trials_struct.VTA_lick_triggered_trials.N_ITI_VTA,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_op_roadmapv1_3_fx(VTA_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);

			
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTA_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

				LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_1000hz,Hz,... %************************************!!!!!!!!!!!!!!!!!!!!!!!!
									lick_triggered_trials_struct.VTA_lick_triggered_trials.rxn_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.early_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.rew_VTA_lick_triggered_trials,...
									lick_triggered_trials_struct.VTA_lick_triggered_trials.ITI_VTA_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);

				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTA_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTA_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTA_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTA_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTA_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			else
				h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
			end
		else
			disp('No VTA LTAs to plot')
		end


	if sncred_on 
			signalname = 'SNcred';
			Hz = 1000;
			if strcmp(exptype_,'hyb')
				[lick_triggered_trials_struct.SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_rxn_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_early_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_rew_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_pav_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_ITI_SNcred,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_hyb_roadmap1_3_fx(SNcred_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



				LTA_photom_time_binner_hyb_roadmap1_3_fx(time_array_1000hz,Hz,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.pav_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);
				%% Save all figures:
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			



			elseif strcmp(exptype_, 'op')
				[lick_triggered_trials_struct.SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_rxn_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_early_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_rew_SNcred,...
	    		lick_triggered_trials_struct.SNcred_lick_triggered_trials.N_ITI_SNcred,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_op_roadmapv1_3_fx(SNcred_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);

			
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['SNcred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

				LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_1000hz,Hz,... %************************************!!!!!!!!!!!!!!!!!!!!!!!!
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.rxn_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.early_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.rew_SNcred_lick_triggered_trials,...
									lick_triggered_trials_struct.SNcred_lick_triggered_trials.ITI_SNcred_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);

				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['SNcred_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['SNcred_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['SNcred_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['SNcred_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['SNcred_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			else
				h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
			end
		else
			disp('No SNcred LTAs to plot')
		end




	if dlsred_on 
			signalname = 'DLSred';
			Hz = 1000;
			if strcmp(exptype_,'hyb')
				[lick_triggered_trials_struct.DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_rxn_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_early_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_rew_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_pav_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_ITI_DLSred,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_hyb_roadmap1_3_fx(DLSred_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



				LTA_photom_time_binner_hyb_roadmap1_3_fx(time_array_1000hz,Hz,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.pav_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);
				%% Save all figures:
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			



			elseif strcmp(exptype_, 'op')
				[lick_triggered_trials_struct.DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_rxn_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_early_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_rew_DLSred,...
	    		lick_triggered_trials_struct.DLSred_lick_triggered_trials.N_ITI_DLSred,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_op_roadmapv1_3_fx(DLSred_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);

			
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['DLSred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

				LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_1000hz,Hz,... %************************************!!!!!!!!!!!!!!!!!!!!!!!!
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.rxn_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.early_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.rew_DLSred_lick_triggered_trials,...
									lick_triggered_trials_struct.DLSred_lick_triggered_trials.ITI_DLSred_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);

				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLSred_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLSred_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLSred_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['DLSred_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['DLSred_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			else
				h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
			end
		else
			disp('No DLSred LTAs to plot')
		end





	if vtared_on 
			signalname = 'VTAred';
			Hz = 1000;
			if strcmp(exptype_,'hyb')
				[lick_triggered_trials_struct.VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_rxn_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_early_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_rew_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_pav_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_ITI_VTAred,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_hyb_roadmapv1_3_fx(VTAred_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



				LTA_photom_time_binner_hyb_roadmapv1_3_fx(time_array_1000hz,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.pav_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);
				%% Save all figures:
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			



			elseif strcmp(exptype_, 'op')
				[lick_triggered_trials_struct.VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_rxn_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_early_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_rew_VTAred,...
	    		lick_triggered_trials_struct.VTAred_lick_triggered_trials.N_ITI_VTAred,...
	    		time_array_1000hz] = LTA_extractor_photom_overlay_op_roadmapv1_3_fx(VTAred_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);
							  
			
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;	
				print(figure_counter,'-depsc','-painters',['VTAred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				
				LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_1000hz,Hz,... %************************************!!!!!!!!!!!!!!!!!!!!!!!!
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.rxn_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.early_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.rew_VTAred_lick_triggered_trials,...
									lick_triggered_trials_struct.VTAred_lick_triggered_trials.ITI_VTAred_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);

				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTAred_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTAred_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTAred_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
				figure_counter = figure_counter+1;
				print(figure_counter,'-depsc','-painters', ['VTAred_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
				saveas(figure_counter,['VTAred_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			else
				h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
			end
	else
		disp('No VTAred LTAs to plot')
	end


	if x_on 
		signalname = 'X';
		Hz = 2000;
		if strcmp(exptype_,'hyb')
			[lick_triggered_trials_struct.X_lick_triggered_trials.rxn_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.ITI_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_rxn_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_early_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_rew_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_pav_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_ITI_X,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_hyb_roadmapv1_3_fx(X_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



% 			LTA_EMGAC_extractor_overlay_hyb_roadmapv1_2
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


			LTA_photom_time_binner_hyb_roadmapv1_3_fx(time_array_2000hz,...
									lick_triggered_trials_struct.X_lick_triggered_trials.rxn_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.pav_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.ITI_X_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);

			% LTA_time_binner_hyb_roadmapv1 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		

		elseif strcmp(exptype_, 'op')
			[lick_triggered_trials_struct.X_lick_triggered_trials.rxn_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.ITI_X_lick_triggered_trials,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_rxn_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_early_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_rew_X,...
	    		lick_triggered_trials_struct.X_lick_triggered_trials.N_ITI_X,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_op_roadmapv1_3_fx(X_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);
							  
			% LTA_EMGAC_extractor_overlay_op_roadmapv1_2
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['X_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['X_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['X_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['X_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['X_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['X_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['X_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['X_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['X_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['X_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['X_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
			LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_2000hz,Hz,...
									lick_triggered_trials_struct.X_lick_triggered_trials.rxn_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.early_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.rew_X_lick_triggered_trials,...
									lick_triggered_trials_struct.X_lick_triggered_trials.ITI_X_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);
			% LTA_time_binner_op_roadmapv1 %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
		end
	else
		disp('No X LTAs to plot')
	end

	if y_on 
		signalname = 'Y';
		Hz = 2000;
		if strcmp(exptype_,'hyb')
			[lick_triggered_trials_struct.Y_lick_triggered_trials.rxn_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.ITI_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_rxn_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_early_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_rew_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_pav_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_ITI_Y,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_hyb_roadmapv1_3_fx(Y_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



			% LTA_EMGAC_extractor_overlay_hyb_roadmapv1_2
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


			LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_2000hz,Hz,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.rxn_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.pav_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.ITI_Y_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);

			% LTA_time_binner_hyb_roadmapv1 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		

		elseif strcmp(exptype_, 'op')
			[lick_triggered_trials_struct.Y_lick_triggered_trials.rxn_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.ITI_Y_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_rxn_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_early_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_rew_Y,...
	    		lick_triggered_trials_struct.Y_lick_triggered_trials.N_ITI_Y,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_op_roadmapv1_3_fx(Y_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);
							  
			% LTA_EMGAC_extractor_overlay_op_roadmapv1_2
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Y_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Y_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Y_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Y_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Y_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Y_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Y_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Y_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Y_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Y_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Y_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
			LTA_photom_time_binner_hyb_roadmapv1_3_fx(time_array_2000hz,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.rxn_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.early_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.rew_Y_lick_triggered_trials,...
									lick_triggered_trials_struct.Y_lick_triggered_trials.ITI_Y_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);
			% LTA_time_binner_op_roadmapv1 %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
		end
	else
		disp('No Y LTAs to plot')
	end

	if z_on 
		signalname = 'Z';
		Hz = 2000;
		if strcmp(exptype_,'hyb')
			[lick_triggered_trials_struct.Z_lick_triggered_trials.rxn_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.ITI_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_rxn_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_early_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_rew_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_pav_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_ITI_Z,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_hyb_roadmapv1_3_fx(Z_values_by_trial,num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



			% LTA_EMGAC_extractor_overlay_hyb_roadmapv1_2
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


			LTA_photom_time_binner_hyb_roadmapv1_3_fx(time_array_2000hz,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.rxn_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.pav_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.ITI_Z_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);

			% LTA_time_binner_hyb_roadmapv1 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		

		elseif strcmp(exptype_, 'op')
			[lick_triggered_trials_struct.Z_lick_triggered_trials.rxn_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.ITI_Z_lick_triggered_trials,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_rxn_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_early_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_rew_Z,...
	    		lick_triggered_trials_struct.Z_lick_triggered_trials.N_ITI_Z,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_op_roadmapv1_3_fx(Z_values_by_trial,num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);
							  
			% LTA_EMGAC_extractor_overlay_op_roadmapv1_2
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Z_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Z_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Z_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Z_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Z_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Z_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Z_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Z_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['Z_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Z_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['Z_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
			LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_2000hz,Hz,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.rxn_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.early_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.rew_Z_lick_triggered_trials,...
									lick_triggered_trials_struct.Z_lick_triggered_trials.ITI_Z_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);
			% LTA_time_binner_op_roadmapv1 %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
		end
	else
		disp('No Z LTAs to plot')
	end


	if emg_on 
		signalname = 'EMG';
		Hz = 2000;
		if strcmp(exptype_,'hyb')
			[lick_triggered_trials_struct.EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.pav_signal_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_rxn_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_early_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_rew_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_pav_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_ITI_EMG,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_hyb_roadmapv1_3_fx(abs(EMG_values_by_trial),num_trials,f_ex_lick_pavlovian,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);



			% LTA_EMGAC_extractor_overlay_hyb_roadmapv1_2
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


			LTA_photom_time_binner_hyb_roadmapv1_3_fx(time_array_2000hz,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.pav_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_pavlovian,...
									f_lick_ITI,...
									signalname);

			% LTA_time_binner_hyb_roadmapv1 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_REMGN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_REMGN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_EARLEMG_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_EARLEMG_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		

		elseif strcmp(exptype_, 'op')
			[lick_triggered_trials_struct.EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_rxn_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_early_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_rew_EMG,...
	    		lick_triggered_trials_struct.EMG_lick_triggered_trials.N_ITI_EMG,...
	    		time_array_2000hz] = LTA_EMGAC_extractor_overlay_op_roadmapv1_3_fx(abs(EMG_values_by_trial),num_trials,f_ex_lick_rxn,f_ex_lick_operant_no_rew,f_ex_lick_operant_rew,f_ex_lick_ITI, signalname);
							  
			% LTA_EMGAC_extractor_overlay_op_roadmapv1_2
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['EMG_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['EMG_LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['EMG_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['EMG_LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['EMG_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['EMG_LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['EMG_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['EMG_LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters',['EMG_LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['EMG_LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters',['EMG_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
			LTA_photom_time_binner_op_roadmapv1_3_fx(time_array_2000hz,Hz,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.rxn_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.early_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.rew_EMG_lick_triggered_trials,...
									lick_triggered_trials_struct.EMG_lick_triggered_trials.ITI_EMG_lick_triggered_trials,...
									f_lick_rxn,...
									f_lick_operant_no_rew,...
									f_lick_operant_rew,...
									f_lick_ITI,...
									signalname);
			% LTA_time_binner_op_roadmapv1 %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_REMGN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_REMGN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_EARLEMG_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_EARLEMG_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
		end
	else
		disp('No EMG LTAs to plot')
	end
