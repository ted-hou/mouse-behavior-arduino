% roadmap_EMG_plotCTAsection_v1_3.m 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% 	Created  10-30-17 	ahamilos	(from roadmap_EMG_phot_v1_3.m)
% 	Modified 10-30-17	ahamilos
% 
%  USE: Used to make roadmap runner more compact - not a function, but just called as a script from roadmap_EMG_phot_v1_3.m
% 
% --------------------------------------------------------------------------------


	if snc_on 
		signalname = 'SNc';
		Hz = 1000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(SNc_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(SNc_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(SNc_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(SNc_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(SNc_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNc_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['SNc_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No SNc CTAs to plot')
	end


	if dls_on
		signalname = 'DLS';
		Hz = 1000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(DLS_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(DLS_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(DLS_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(DLS_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(DLS_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLS_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['DLS_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No DLS CTAs to plot')
	end



	if vta_on
		signalname = 'VTA';
		Hz = 1000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(VTA_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(VTA_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(VTA_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(VTA_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(VTA_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTA_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['VTA_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No VTA CTAs to plot')
	end



	if sncred_on
		signalname = 'SNcred';
		Hz = 1000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(SNcred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(SNcred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(SNcred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(SNcred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(SNcred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['SNcred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['SNcred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No SNcred CTAs to plot')
	end

	if dlsred_on
		signalname = 'DLSred';
		Hz = 1000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(DLSred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(DLSred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(DLSred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(DLSred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(DLSred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['DLSred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['DLSred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No DLSred CTAs to plot')
	end


	if vtared_on
		signalname = 'VTAred';
		Hz = 1000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(VTAred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')


		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(VTAred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_pav,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(VTAred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(VTAred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(VTAred_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_ex_lick_operant_rew,f_lick_ITI, signalname)
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['VTAred_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['VTAred_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No VTAred CTAs to plot')
	end


			
			
	if emg_on
		signalname = 'EMG';
		Hz = 2000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(abs(EMG_ex_values_by_trial),Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(abs(EMG_ex_values_by_trial),Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_0ms_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(abs(EMG_ex_values_by_trial),Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_500_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(abs(EMG_ex_values_by_trial),Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_300_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(abs(EMG_ex_values_by_trial),Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_0_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['EMG_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['EMG_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No EMG CTAs to plot')
	end


	if x_on
		signalname = 'X';
		Hz = 2000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(X_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(X_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_0ms_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(X_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_500_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(X_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_300_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(X_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_0_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['X_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['X_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No X CTAs to plot')
	end



	if y_on
		signalname = 'Y';
		Hz = 2000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(Y_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(Y_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_0ms_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(Y_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_500_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(Y_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_300_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(Y_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_0_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_RYN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Y_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Y_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No Y CTAs to plot')
	end



	if z_on
		signalname = 'Z';
		Hz = 2000;
		if strcmp(exptype_,'hyb') && rxnwin_ == 500
			time_binner_fx_hyb_roadmapv1_3(Z_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
			time_binner_fx_hyb_0ms_roadmapv1_3(Z_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_pavlovian,f_lick_ITI, signalname)
			% time_binner_fx_MOVE_hyb_0ms_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
			h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
		elseif strcmp(exptype_,'op') && rxnwin_ == 500
			time_binner_op_500_roadmapv1_3(Z_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_500_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		elseif strcmp(exptype_,'op') && rxnwin_ == 300
			time_binner_op_300_roadmapv1_3(Z_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_300_roadmapv1_2 
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op') && rxnwin_ == 0
			time_binner_op_0_roadmapv1_3(Z_ex_values_by_trial,Hz,f_lick_rxn,f_lick_operant_no_rew,f_lick_operant_rew,f_lick_ITI, signalname)
			% time_binner_MOVE_op_0_roadmapv1_2
			%% Save all figures:
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_RZN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_EARLZ_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			figure_counter = figure_counter+1;
			print(figure_counter,'-depsc','-painters', ['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
			saveas(figure_counter,['Z_CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
% 			figure_counter = figure_counter+1;
% 			print(figure_counter,'-depsc','-painters', ['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
% 			saveas(figure_counter,['Z_CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
			
		elseif strcmp(exptype_,'op')
			h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
		else
			h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
		end
	else
		disp('No Z CTAs to plot')
	end
