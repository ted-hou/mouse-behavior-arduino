%% Run Analysis Roadmap-------------------------------------------------------------------
% 
% 	Created 	8-1-17 ahamilos
% 	Modified 	8-1-17 ahamilos
% 
% 	Outline:
% 		* open directory you want to save to in matlab workspace
% 		* write in the day # you want to use for everything
% 		1. extract_trials_gfit_v1.m
% 		2. lick_times_by_trial_fx
% 		3. first_lick_grabber (need to input which version to use at beginning)
% 		4. axclusion = Excluder Interface (wait for user input to continue)
% 		5. heatmap_3_fx 
%		6. gets excluded first licks  
% 		6. CTA and plots saved
% 		7. LTA and plots saved
% 		8. save ALL VARS
%%-------------------------------------------------------------------------------------------
% Modifiable trial structure vars:
total_trial_duration_in_sec = 17;




todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');

% Start of run: Prompt user for needed variables--------------------------------------------
	disp('Collecting user input...')
	prompt = {'Day # prefix:','CED filename_ (don''t include *_lick, etc):', 'Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Exclusion Criteria Version', 'Animal Name'};
	dlg_title = 'Inputs';
	num_lines = 1;
	defaultans = {'5','b2_day5','1', 'hyb', '500', '1', 'B2'};
	answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
	daynum_ = answer_{1};
	filename_ = answer_{2};
	headernum_ = answer_{3};
	exptype_ = answer_{4};
	rxnwin_ = str2double(answer_{5});
	exclusion_criteria_version_ = answer_{6};
	mousename_ = answer_{7};
	disp('Collecting user input complete')



%% Extract trials with gfit:-----------------------------------------------------------------
	disp('Extracting trials with gfit_roadmapv1...')
	extract_trials_gfit_roadmapv1
	disp('Extracting trials complete')




%% Extract lick_times_by_trial:--------------------------------------------------------------
	disp('Collecting lick_times_by_trial, no exclusions...')
	[lick_times_by_trial] = lick_times_by_trial_fx(lick_times,cue_on_times, total_trial_duration_in_sec, num_trials);
	disp('Collecting lick_times_by_trial, no exclusions complete')



%% First lick grabber: No exlcusions---------------------------------------------------------
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




%% Deal with exclusions---------------------------------------------------------------------
	disp('User: complete exclusions manually...')
	h_alert3 = msgbox('Open MouseBehaviorInterface of today''s raster to do exclusions');
	exclusioncomplete = false;
	axclusion = ExcluderInterface(DLS_values_by_trial, SNc_values_by_trial, lick_times_by_trial);
    uiwait(figure)
	while ~exclusioncomplete
		disp('Redoing exclusions... enter new version of exclusions into axclusion interface')
		
		h_alert3 = msgbox('When done excluding, press ok to continue');
		heatmap_3_fx(axclusion.Excluder.SNc_data, axclusion.Excluder.lick_times_by_trial_excluded, 1);

		choice = questdlg('Plot heatmap again with updated exclusions?', ...
		'Need more exclusions?', ...
		'Yes','No','No');
		% Handle response
		switch choice
		    case 'Yes'
		        heatmap_3_fx(axclusion.Excluder.SNc_data, axclusion.Excluder.lick_times_by_trial_excluded, 1);
		    case 'No'
		        exclusioncomplete = true;
		end
	end
	disp('User input complete')
	% Update the excluded trials:
	disp('Generating lick_times_by_trial without excluded trials...')
	lick_ex_times_by_trial = axclusion.Excluder.lick_times_by_trial_excluded;
	SNc_ex_values_by_trial	= axclusion.Excluder.SNc_data;
	DLS_ex_values_by_trial 	= axclusion.Excluder.DLS_data;
	disp('lick_times_by_trial without excluded trials complete')





%% First lick grabber with exclusions-------------------------------------------------------
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




%% Close all figures-----------------------------------------------------------------------
	uiwait(msgbox('Need to close all figures before proceeding - ok?','Ok','modal'));
	close all



%% Plot CTA and save figures---------------------------------------------------------------
	disp('Plotting CTA and saving figures...')
	if strcmp(exptype_,'hyb') && rxnwin_ == 500
		time_binner_fx_hyb_roadmapv1
		%% Save all figures:
		print(1,'-depsc','-painters', ['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(4,'-depsc','-painters', ['CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(4,['CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(5,'-depsc','-painters', ['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(5,['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
	elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
		time_binner_fx_hyb_0ms_roadmapv1
		%% Save all figures:
		print(1,'-depsc','-painters', ['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(4,'-depsc','-painters', ['CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(4,['CTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(5,'-depsc','-painters', ['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(5,['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

	elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
		h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 181 in roadmapv1 and debug');
	elseif strcmp(exptype_,'op') && rxnwin_ == 500
		time_binner_op_500_roadmapv1
		%% Save all figures:
		print(1,'-depsc','-painters', ['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(4,'-depsc','-painters', ['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(4,['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

	elseif strcmp(exptype_,'op') && rxnwin_ == 300
		time_binner_op_300_roadmapv1
		%% Save all figures:
		print(1,'-depsc','-painters', ['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(4,'-depsc','-painters', ['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(4,['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
	elseif strcmp(exptype_,'op') && rxnwin_ == 0
		time_binner_op_0_roadmapv1
		%% Save all figures:
		print(1,'-depsc','-painters', ['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['CTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(4,'-depsc','-painters', ['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(4,['CTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
	elseif strcmp(exptype_,'op')
		h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 219 in roadmapv1 and debug');
	else
		h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 170');
	end

	disp('Plotting CTA and saving figures complete.')




%% Plot LTA and save figures---------------------------------------------------------------
	disp('Plotting LTA and saving figures...')
	if strcmp(exptype_,'hyb') && rxnwin_ == 500
		LTA_extractor_overlay_hyb_roadmapv1
		% prev fig was #5:
		print(6,'-depsc','-painters',['LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(6,['LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(7,'-depsc','-painters',['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(7,['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(8,'-depsc','-painters',['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(8,['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(9,'-depsc','-painters',['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(9,['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(10,'-depsc','-painters',['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(10,['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		print(11,'-depsc','-painters',['LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(11,['LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(12,'-depsc','-painters',['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(12,['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



		LTA_time_binner_hyb_roadmapv1
		%% Save all figures:
		print(13,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(13,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(14,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(14,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(15,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(15,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(16,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(16,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(17,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(17,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		


	elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
		LTA_extractor_overlay_hyb_roadmapv1
		% prev fig was #5:
		print(6,'-depsc','-painters',['LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(6,['LTA_pav_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(7,'-depsc','-painters',['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(7,['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(8,'-depsc','-painters',['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(8,['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(9,'-depsc','-painters',['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(9,['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(10,'-depsc','-painters',['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(10,['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

		print(11,'-depsc','-painters',['LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(11,['LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
		print(12,'-depsc','-painters',['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(12,['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')



		LTA_time_binner_hyb_roadmapv1
		%% Save all figures:
		print(13,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(13,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(14,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(14,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(15,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(15,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(16,'-depsc','-painters', ['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(16,['LTA_PAV_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(17,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(17,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

	elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
		h_alert2 = msgbox('Warning - not prepared to deal with a hybrid session with rxn window ~= 0 or 500ms. Go to line 312 in roadmapv1 and debug');

	elseif strcmp(exptype_, 'op') && rxnwin_ == 500
		LTA_extractor_overlay_op_roadmapv1
		% prev fig was #4:
		print(5,'-depsc','-painters',['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(5,['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(6,'-depsc','-painters',['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(6,['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(7,'-depsc','-painters',['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(7,['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(8,'-depsc','-painters',['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(8,['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(9,'-depsc','-painters',['LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(9,['LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(10,'-depsc','-painters',['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(10,['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		LTA_time_binner_op_roadmapv1
		%% Save all figures:
		print(11,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(11,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(12,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(12,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(13,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(13,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(14,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(14,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')

	elseif strcmp(exptype_, 'op') && rxnwin_ == 300
		LTA_extractor_overlay_op_roadmapv1
		% prev fig was #4:
		print(5,'-depsc','-painters',['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(5,['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(6,'-depsc','-painters',['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(6,['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(7,'-depsc','-painters',['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(7,['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(8,'-depsc','-painters',['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(8,['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(9,'-depsc','-painters',['LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(9,['LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(10,'-depsc','-painters',['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(10,['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		LTA_time_binner_op_roadmapv1
		%% Save all figures:
		print(11,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(11,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(12,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(12,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(13,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(13,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(14,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(14,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
	elseif strcmp(exptype_, 'op') && rxnwin_ == 0
		LTA_extractor_overlay_op_roadmapv1
		% prev fig was #4:
		print(5,'-depsc','-painters',['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(5,['LTA_rxn_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(6,'-depsc','-painters',['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(6,['LTA_early_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(7,'-depsc','-painters',['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(7,['LTA_oprew_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(8,'-depsc','-painters',['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(8,['LTA_ITI_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(9,'-depsc','-painters',['LTA_overlay_noise_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(9,['LTA_overlay_noise_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(10,'-depsc','-painters',['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(10,['LTA_overlay_smooth_single_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		LTA_time_binner_op_roadmapv1
		%% Save all figures:
		print(11,'-depsc','-painters', ['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(11,['LTA_RXN_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(12,'-depsc','-painters', ['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(12,['LTA_EARLY_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(13,'-depsc','-painters', ['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(13,['LTA_OPREW_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(14,'-depsc','-painters', ['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(14,['LTA_ITI_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		
	elseif strcmp(exptype_, 'op')
		h_alert2 = msgbox('Warning - not prepared to deal with an operant session with rxn window ~= 0, 300 or 500ms. Go to line 393 in roadmapv1 and debug');
	else
		h_alert2 = msgbox('Warning - error with exptype_ - must be either hyb or op at input. Update exptype_ as appropriate and rerun roadmapv1 from line 300');
	end

	disp('Plotting LTA and saving figures complete.')





%% Generate all variables for the header:
	disp('Generating variables...')
	% 1. extracted data
	gfit_SNc_name = genvarname(['d', daynum_, '_gfit_SNc']);
	eval([gfit_SNc_name '= gfit_SNc;']);
	gfit_DLS_name = genvarname(['d', daynum_, '_gfit_DLS']);
	eval([gfit_DLS_name '= gfit_DLS;']);
	SNc_ex_values_by_trial_name = genvarname(['d', daynum_, '_SNc', '_ex', exclusion_criteria_version_, '_values_by_trial']);
	eval([SNc_ex_values_by_trial_name '= axclusion.Excluder.SNc_data;']);
	DLS_ex_values_by_trial_name = genvarname(['d', daynum_, '_DLS', '_ex', exclusion_criteria_version_, '_values_by_trial']);
	eval([DLS_ex_values_by_trial_name '= axclusion.Excluder.DLS_data;']);
	SNc_values_by_trial_name = genvarname(['d', daynum_, '_SNc_values_by_trial']);
	eval([SNc_values_by_trial_name '= SNc_values_by_trial;']);
	SNc_times_by_trial_name = genvarname(['d', daynum_, '_SNc_times_by_trial']);
	eval([SNc_times_by_trial_name '= SNc_times_by_trial;']);
	DLS_values_by_trial_name = genvarname(['d', daynum_, '_DLS_values_by_trial']);
	eval([DLS_values_by_trial_name '= DLS_values_by_trial;']);
	DLS_times_by_trial_name = genvarname(['d', daynum_, '_DLS_times_by_trial']);
	eval([DLS_times_by_trial_name '= DLS_times_by_trial;']);
	
	%2. Lick times by trial data
	lick_times_by_trial_name = genvarname(['d', daynum_, '_lick_times_by_trial']);
	eval([lick_times_by_trial_name '= lick_times_by_trial;']);				
	lick_ex_times_by_trial_name = genvarname(['d', daynum_, '_lick', '_ex', exclusion_criteria_version_, '_times_by_trial']);
	eval([lick_ex_times_by_trial_name '= axclusion.Excluder.lick_times_by_trial_excluded;']);				
									
	%3. First lick grabber - no exclusions			
	f_lick_rxn_name = genvarname(['d', daynum_, '_f_lick_rxn']);
	eval([f_lick_rxn_name '= f_lick_rxn;']);
	f_lick_operant_no_rew_name = genvarname(['d', daynum_, '_f_lick_operant_no_rew']);
	eval([f_lick_operant_no_rew_name '= f_lick_operant_no_rew;']);
	f_lick_operant_rew_name = genvarname(['d', daynum_, '_f_lick_operant_rew']);
	eval([f_lick_operant_rew_name '= f_lick_operant_rew;']);
	f_lick_ITI_name = genvarname(['d', daynum_, '_f_lick_ITI']);
	eval([f_lick_ITI_name '= f_lick_ITI;']);
	all_first_licks_name = genvarname(['d', daynum_, '_all_first_licks']);
	eval([all_first_licks_name '= all_first_licks;']);

	%4. First lick grabber - exclusions	
	f_ex_lick_rxn_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn']);
	eval([f_ex_lick_rxn_name '= f_ex_lick_rxn;']);
	f_ex_lick_operant_no_rew_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew']);
	eval([f_ex_lick_operant_no_rew_name '= f_ex_lick_operant_no_rew;']);
	f_ex_lick_operant_rew_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew']);
	eval([f_ex_lick_operant_rew_name '= f_ex_lick_operant_rew;']);
	f_ex_lick_ITI_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_ITI']);
	eval([f_ex_lick_ITI_name '= f_ex_lick_ITI;']);
	all_ex_first_licks_name = genvarname(['d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks']);
	eval([all_ex_first_licks_name '= all_ex_first_licks;']);




	%5. LTA
	% rxn_DLS_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_rxn_DLS_lick_triggered_ave_ignore_NaN']);
	% eval([rxn_DLS_lick_triggered_ave_ignore_NaN_name '= rxn_DLS_lick_triggered_ave_ignore_NaN']);
	% rxn_SNc_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_rxn_SNc_lick_triggered_ave_ignore_NaN']);
	% eval([rxn_SNc_lick_triggered_ave_ignore_NaN_name '= rxn_SNc_lick_triggered_ave_ignore_NaN']);
	% early_DLS_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_early_DLS_lick_triggered_ave_ignore_NaN']);
	% eval([early_DLS_lick_triggered_ave_ignore_NaN_name '= early_DLS_lick_triggered_ave_ignore_NaN']);
	% early_SNc_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_early_SNc_lick_triggered_ave_ignore_NaN']);
	% eval([early_SNc_lick_triggered_ave_ignore_NaN_name '= early_SNc_lick_triggered_ave_ignore_NaN']);
	% rew_DLS_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_rew_DLS_lick_triggered_ave_ignore_NaN']);
	% eval([rew_DLS_lick_triggered_ave_ignore_NaN_name '= rew_DLS_lick_triggered_ave_ignore_NaN']);
	% rew_SNc_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_rew_SNc_lick_triggered_ave_ignore_NaN']);
	% eval([rew_SNc_lick_triggered_ave_ignore_NaN_name '= rew_SNc_lick_triggered_ave_ignore_NaN']);
	%these below are same as above with shorter name
	N_rxn_DLS_name = genvarname(['d', daynum_, '_N_rxn_DLS']);
	eval([N_rxn_DLS_name '= N_rxn_DLS;']);
	N_rxn_SNc_name = genvarname(['d', daynum_, '_N_rxn_SNc']);
	eval([N_rxn_SNc_name '= N_rxn_SNc;']);
	N_early_DLS_name = genvarname(['d', daynum_, '_N_early_DLS']);
	eval([N_early_DLS_name '= N_early_DLS;']);
	N_early_SNc_name = genvarname(['d', daynum_, '_N_early_SNc']);
	eval([N_early_SNc_name '= N_early_SNc;']);
	N_rew_DLS_name = genvarname(['d', daynum_, '_N_rew_DLS']);
	eval([N_rew_DLS_name '= N_rew_DLS;']);
	N_rew_SNc_name = genvarname(['d', daynum_, '_N_rew_SNc']);
	eval([N_rew_SNc_name '= N_rew_SNc;']);
	N_ITI_DLS_name = genvarname(['d', daynum_, '_N_ITI_DLS']);
	eval([N_ITI_DLS_name '= N_ITI_DLS;']);
	N_ITI_SNc_name = genvarname(['d', daynum_, '_N_ITI_SNc']);
	eval([N_ITI_SNc_name '= N_ITI_SNc;']);
	time_array_name = genvarname(['d', daynum_, '_time_array']);
	eval([time_array_name '= time_array;']);
	
	rxn_DLS_lick_triggered_trials_name = genvarname(['d', daynum_, '_rxn_DLS_lick_triggered_trials']);
	eval([rxn_DLS_lick_triggered_trials_name '= rxn_DLS_lick_triggered_trials;']);
	early_DLS_lick_triggered_trials_name = genvarname(['d', daynum_, '_early_DLS_lick_triggered_trials']);
	eval([early_DLS_lick_triggered_trials_name '= early_DLS_lick_triggered_trials;']);
	rew_DLS_lick_triggered_trials_name = genvarname(['d', daynum_, '_rew_DLS_lick_triggered_trials']);
	eval([rew_DLS_lick_triggered_trials_name '= rew_DLS_lick_triggered_trials;']);
	rxn_SNc_lick_triggered_trials_name = genvarname(['d', daynum_, '_rxn_SNc_lick_triggered_trials']);
	eval([rxn_SNc_lick_triggered_trials_name '= rxn_SNc_lick_triggered_trials;']);
	early_SNc_lick_triggered_trials_name = genvarname(['d', daynum_, '_early_SNc_lick_triggered_trials']);
	eval([early_SNc_lick_triggered_trials_name '= early_SNc_lick_triggered_trials;']);
	rew_SNc_lick_triggered_trials_name = genvarname(['d', daynum_, '_rew_SNc_lick_triggered_trials']);
	eval([rew_SNc_lick_triggered_trials_name '= rew_SNc_lick_triggered_trials;']);

	%6. Pavlovian
	if strcmp(exptype_, 'hyb')
		f_lick_pavlovian_name = genvarname(['d', daynum_, '_f_lick_pavlovian']);
		eval([f_lick_pavlovian_name '= f_lick_pavlovian;']);
		f_ex_lick_pavlovian_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_pavlovian']);
		eval([f_ex_lick_pavlovian_name '= f_ex_lick_pavlovian;']);
		% pav_DLS_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_pav_DLS_lick_triggered_ave_ignore_NaN']);
		% eval([pav_DLS_lick_triggered_ave_ignore_NaN_name '= pav_DLS_lick_triggered_ave_ignore_NaN;']);
		% pav_SNc_lick_triggered_ave_ignore_NaN_name = genvarname(['d', daynum_, '_pav_SNc_lick_triggered_ave_ignore_NaN']);
		% eval([pav_SNc_lick_triggered_ave_ignore_NaN_name '= pav_SNc_lick_triggered_ave_ignore_NaN;']);
		N_pav_DLS_name = genvarname(['d', daynum_, '_N_pav_DLS']);
		eval([N_pav_DLS_name '= N_pav_DLS;']);
		N_pav_SNc_name = genvarname(['d', daynum_, '_N_pav_SNc']);
		eval([N_pav_SNc_name '= N_pav_SNc;']);
		pav_DLS_lick_triggered_trials_name = genvarname(['d', daynum_, '_pav_DLS_lick_triggered_trials']);
		eval([pav_DLS_lick_triggered_trials_name '= pav_DLS_lick_triggered_trials;']);
		pav_SNc_lick_triggered_trials_name = genvarname(['d', daynum_, '_pav_SNc_lick_triggered_trials']);
		eval([pav_SNc_lick_triggered_trials_name '= pav_SNc_lick_triggered_trials;']);
        f_lick_rxn_abort_name = genvarname(['d', daynum_, '_f_lick_rxn_abort']);
		eval([f_lick_rxn_abort_name '= f_lick_train_abort + f_lick_rxn_abort;']);
        f_ex_lick_rxn_abort_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn_abort']);
		eval([f_ex_lick_rxn_abort_name '= f_ex_lick_train_abort + f_ex_lick_rxn_abort;']);
	end
	
	if rxnwin_ == 300
			f_lick_rxn_abort_name = genvarname(['d', daynum_, '_f_lick_rxn_abort']);
			eval([f_lick_rxn_abort_name '= f_lick_rxn_abort + f_ex_lick_train_abort;']);
			f_ex_lick_rxn_abort_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn_abort']);
			eval([f_ex_lick_rxn_abort_name '= f_ex_lick_train_abort + f_ex_lick_rxn_fail;']);
	elseif rxnwin_ == 500 & exptype_ == 'op'
			f_lick_rxn_abort_name = genvarname(['d', daynum_, '_f_lick_rxn_abort']);
            eval([f_lick_rxn_abort_name '= f_lick_rxn_abort;']);
            f_ex_lick_rxn_abort_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn_abort']);
            eval([f_ex_lick_rxn_abort_name '= f_ex_lick_rxn_abort;']);	
	end

	disp('Generating variables complete.')






%% Save all variables to the header
disp('Saving variables to header...')
uiwait(msgbox(['Warning - about to create header file called:                                        ', mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1 ', todaysdate2,'.txt                                       and                                     ', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_', todaysdate, '.mat                                              Check if exists - ok to overwrite?'],'Ok','modal'));

savefilename = [mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_', todaysdate];

if strcmp(exptype_, 'hyb') && rxnwin_ > 0
	save(savefilename,...
		['d', daynum_, '_gfit_SNc'],...
		['d', daynum_, '_gfit_DLS'],...
		['d', daynum_, '_SNc', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_DLS', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_SNc_values_by_trial'],...
		['d', daynum_, '_SNc_times_by_trial'],...
		['d', daynum_, '_DLS_values_by_trial'],...
		['d', daynum_, '_DLS_times_by_trial'],...
		['d', daynum_, '_lick_times_by_trial'],...
		['d', daynum_, '_lick', '_ex', exclusion_criteria_version_, '_times_by_trial'],...
		['d', daynum_, '_f_lick_rxn'],...
		['d', daynum_, '_f_lick_rxn_abort'],...
		['d', daynum_, '_f_lick_operant_no_rew'],...
		['d', daynum_, '_f_lick_operant_rew'],...
		['d', daynum_, '_f_lick_ITI'],...
		['d', daynum_, '_all_first_licks'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn_abort'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_ITI'],...
		['d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks'],...
		['d', daynum_, '_N_rxn_DLS'],...
		['d', daynum_, '_N_rxn_SNc'],...
		['d', daynum_, '_N_early_DLS'],...
		['d', daynum_, '_N_early_SNc'],...
		['d', daynum_, '_N_rew_DLS'],...
		['d', daynum_, '_N_rew_SNc'],...
		['d', daynum_, '_N_ITI_DLS'],...
		['d', daynum_, '_N_ITI_SNc'],...
		['d', daynum_, '_time_array'],...
		['d', daynum_, '_rxn_DLS_lick_triggered_trials'],...
		['d', daynum_, '_early_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rew_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rxn_SNc_lick_triggered_trials'],...
		['d', daynum_, '_early_SNc_lick_triggered_trials'],...
		['d', daynum_, '_rew_SNc_lick_triggered_trials'],...
		['d', daynum_, '_f_lick_pavlovian'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_pavlovian'],...
		['d', daynum_, '_N_pav_DLS'],...
		['d', daynum_, '_N_pav_SNc'],...
		['d', daynum_, '_pav_DLS_lick_triggered_trials'],...
		['d', daynum_, '_pav_SNc_lick_triggered_trials'],...
		['axclusion'],...
		['num_trials']);

elseif strcmp(exptype_, 'hyb') && rxnwin_ == 0 
	save(savefilename,...
		['d', daynum_, '_gfit_SNc'],...
		['d', daynum_, '_gfit_DLS'],...
		['d', daynum_, '_SNc', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_DLS', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_SNc_values_by_trial'],...
		['d', daynum_, '_SNc_times_by_trial'],...
		['d', daynum_, '_DLS_values_by_trial'],...
		['d', daynum_, '_DLS_times_by_trial'],...
		['d', daynum_, '_lick_times_by_trial'],...
		['d', daynum_, '_lick', '_ex', exclusion_criteria_version_, '_times_by_trial'],...
		['d', daynum_, '_f_lick_rxn'],...
		['d', daynum_, '_f_lick_operant_no_rew'],...
		['d', daynum_, '_f_lick_operant_rew'],...
		['d', daynum_, '_f_lick_ITI'],...
		['d', daynum_, '_all_first_licks'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_ITI'],...
		['d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks'],...
		['d', daynum_, '_N_rxn_DLS'],...
		['d', daynum_, '_N_rxn_SNc'],...
		['d', daynum_, '_N_early_DLS'],...
		['d', daynum_, '_N_early_SNc'],...
		['d', daynum_, '_N_rew_DLS'],...
		['d', daynum_, '_N_rew_SNc'],...
		['d', daynum_, '_N_ITI_DLS'],...
		['d', daynum_, '_N_ITI_SNc'],...
		['d', daynum_, '_time_array'],...
		['d', daynum_, '_rxn_DLS_lick_triggered_trials'],...
		['d', daynum_, '_early_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rew_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rxn_SNc_lick_triggered_trials'],...
		['d', daynum_, '_early_SNc_lick_triggered_trials'],...
		['d', daynum_, '_rew_SNc_lick_triggered_trials'],...
		['d', daynum_, '_f_lick_pavlovian'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_pavlovian'],...
		['d', daynum_, '_N_pav_DLS'],...
		['d', daynum_, '_N_pav_SNc'],...
		['d', daynum_, '_pav_DLS_lick_triggered_trials'],...
		['d', daynum_, '_pav_SNc_lick_triggered_trials'],...
		['axclusion'],...
		['num_trials']);    
    
    
    
elseif strcmp(exptype_, 'op') && rxnwin_ > 0 && rxnwin_ < 500
	save(savefilename,...
		['d', daynum_, '_gfit_SNc'],...
		['d', daynum_, '_gfit_DLS'],...
		['d', daynum_, '_SNc', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_DLS', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_SNc_values_by_trial'],...
		['d', daynum_, '_SNc_times_by_trial'],...
		['d', daynum_, '_DLS_values_by_trial'],...
		['d', daynum_, '_DLS_times_by_trial'],...
		['d', daynum_, '_lick_times_by_trial'],...
		['d', daynum_, '_lick', '_ex', exclusion_criteria_version_, '_times_by_trial'],...
		['d', daynum_, '_f_lick_rxn'],...
		['d', daynum_, '_f_lick_rxn_abort'],...
		['d', daynum_, '_f_lick_operant_no_rew'],...
		['d', daynum_, '_f_lick_operant_rew'],...
		['d', daynum_, '_f_lick_ITI'],...
		['d', daynum_, '_all_first_licks'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn_abort'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_ITI'],...
		['d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks'],...
		['d', daynum_, '_N_rxn_DLS'],...
		['d', daynum_, '_N_rxn_SNc'],...
		['d', daynum_, '_N_early_DLS'],...
		['d', daynum_, '_N_early_SNc'],...
		['d', daynum_, '_N_rew_DLS'],...
		['d', daynum_, '_N_rew_SNc'],...
		['d', daynum_, '_N_ITI_DLS'],...
		['d', daynum_, '_N_ITI_SNc'],...
		['d', daynum_, '_time_array'],...
		['d', daynum_, '_rxn_DLS_lick_triggered_trials'],...
		['d', daynum_, '_early_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rew_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rxn_SNc_lick_triggered_trials'],...
		['d', daynum_, '_early_SNc_lick_triggered_trials'],...
		['d', daynum_, '_rew_SNc_lick_triggered_trials'],...
		['axclusion'],...
		['num_trials']);

elseif strcmp(exptype_, 'op') && rxnwin_ == 0 || rxnwin_ == 500
	save(savefilename,...
		['d', daynum_, '_gfit_SNc'],...
		['d', daynum_, '_gfit_DLS'],...
		['d', daynum_, '_SNc', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_DLS', '_ex', exclusion_criteria_version_, '_values_by_trial'],...
		['d', daynum_, '_SNc_values_by_trial'],...
		['d', daynum_, '_SNc_times_by_trial'],...
		['d', daynum_, '_DLS_values_by_trial'],...
		['d', daynum_, '_DLS_times_by_trial'],...
		['d', daynum_, '_lick_times_by_trial'],...
		['d', daynum_, '_lick', '_ex', exclusion_criteria_version_, '_times_by_trial'],...
		['d', daynum_, '_f_lick_rxn'],...
		['d', daynum_, '_f_lick_operant_no_rew'],...
		['d', daynum_, '_f_lick_operant_rew'],...
		['d', daynum_, '_f_lick_ITI'],...
		['d', daynum_, '_all_first_licks'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew'],...
		['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_ITI'],...
		['d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks'],...
		['d', daynum_, '_N_rxn_DLS'],...
		['d', daynum_, '_N_rxn_SNc'],...
		['d', daynum_, '_N_early_DLS'],...
		['d', daynum_, '_N_early_SNc'],...
		['d', daynum_, '_N_rew_DLS'],...
		['d', daynum_, '_N_rew_SNc'],...
		['d', daynum_, '_N_ITI_DLS'],...
		['d', daynum_, '_N_ITI_SNc'],...
		['d', daynum_, '_time_array'],...
		['d', daynum_, '_rxn_DLS_lick_triggered_trials'],...
		['d', daynum_, '_early_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rew_DLS_lick_triggered_trials'],...
		['d', daynum_, '_rxn_SNc_lick_triggered_trials'],...
		['d', daynum_, '_early_SNc_lick_triggered_trials'],...
		['d', daynum_, '_rew_SNc_lick_triggered_trials'],...
		['axclusion'],...
		['num_trials']);	
else
	hbox = msgbox('WARNING, no data saved because of exptype_ input error (see line 478)');
end
disp('Saving variables to header complete.')


%% Generate the header file:

excluded_trials_ = axclusion.Excluder.TrialValues;

prompt2 = {'Enter header file text:', 'Generation Codes', 'Exp Description', 'Excluded Trials:', 'Notes - don''t make any carriage returns!'};
dlg_title = 'Header file text';
num_lines = 5;
defaultans = {[mousename_, ' Day ',daynum_, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2, ' using roadmapv1 set of functions.'], ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Excluded trials: ', excluded_trials_{1}], 'Notes:'};
answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



fid = fopen([mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1 ', todaysdate2,'.txt'], 'wt' );
fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
fclose(fid);





