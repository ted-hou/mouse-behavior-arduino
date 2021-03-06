%% Roadmap v1.1 addendum:
% 
% 	Run this on Roadmap v1 data to complete the v1.1 dataset
% 
% 	Created: 8-10-17
% 
% --------------------------------------------------------
% Modifiable trial structure vars:
total_trial_duration_in_sec = 17;

todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');

% Start of run: Prompt user for needed variables--------------------------------------------
	disp('Collecting user input...')
	prompt = {'Day # prefix:', 'Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Exclusion Criteria Version', 'Animal Name'};
	dlg_title = 'Inputs';
	num_lines = 1;
	defaultans = {'3', '1', 'hyb', '500', '1', 'H5'};
	answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
	daynum_ = answer_{1};
	headernum_ = answer_{2};
	exptype_ = answer_{3};
	rxnwin_ = str2double(answer_{4});
	exclusion_criteria_version_ = answer_{5};
	mousename_ = answer_{6};
	disp('Collecting user input complete')


%% Regenerate needed var names without date prefix:
    DLS_values_by_trial_name = genvarname(['DLS_values_by_trial']);
	eval([DLS_values_by_trial_name '= d', daynum_, '_DLS_values_by_trial;']);
	SNc_values_by_trial_name = genvarname(['SNc_values_by_trial']);
	eval([SNc_values_by_trial_name '= d', daynum_, '_SNc_values_by_trial;']);


    DLS_ex_values_by_trial_name = genvarname(['DLS_ex_values_by_trial']);
	eval([DLS_ex_values_by_trial_name '= d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial;']);
	SNc_ex_values_by_trial_name = genvarname(['SNc_ex_values_by_trial']);
	eval([SNc_ex_values_by_trial_name '= d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial;']);
    all_ex_first_licks_name = genvarname(['all_ex_first_licks']);
	eval([all_ex_first_licks_name '= d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks;']);
	f_ex_lick_rxn_name = genvarname('f_ex_lick_rxn');
	eval([f_ex_lick_rxn_name '= d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_rxn;']);
	f_ex_lick_operant_no_rew_name = genvarname('f_ex_lick_operant_no_rew');
	eval([f_ex_lick_operant_no_rew_name '= d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew;']);
	f_ex_lick_operant_rew_name = genvarname('f_ex_lick_operant_rew');
	eval([f_ex_lick_operant_rew_name '= d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew;']);


    early_DLS_lick_triggered_trials_name = genvarname(['early_DLS_lick_triggered_trials']);
	eval([early_DLS_lick_triggered_trials_name '= d', daynum_, '_early_DLS_lick_triggered_trials;']);
	rew_DLS_lick_triggered_trials_name = genvarname(['rew_DLS_lick_triggered_trials']);
	eval([rew_DLS_lick_triggered_trials_name '= d', daynum_, '_rew_DLS_lick_triggered_trials;']);
	early_SNc_lick_triggered_trials_name = genvarname(['early_SNc_lick_triggered_trials']);
	eval([early_SNc_lick_triggered_trials_name '= d', daynum_, '_early_SNc_lick_triggered_trials;']);
	rew_SNc_lick_triggered_trials_name = genvarname(['rew_SNc_lick_triggered_trials']);
	eval([rew_SNc_lick_triggered_trials_name '= d', daynum_, '_rew_SNc_lick_triggered_trials;']);

	time_array_name = genvarname(['time_array']);
	eval([time_array_name '= d', daynum_, '_time_array;']);





%% Back-fill the values_by_time arrays------------------------------------------------------
    [DLS_values_by_trial_fi, DLS_ex_values_by_trial_fi,DLS_values_by_trial_fi_trim, DLS_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(DLS_values_by_trial, DLS_ex_values_by_trial, num_trials);
	[SNc_values_by_trial_fi, SNc_ex_values_by_trial_fi,SNc_values_by_trial_fi_trim, SNc_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(SNc_values_by_trial, SNc_ex_values_by_trial, num_trials);





%% Close all figures-----------------------------------------------------------------------
	waiter = questdlg('Need to close all figures before proceeding - ok?','Ready to plot?', 'No');
	if strcmp(waiter, 'Yes')
		close all
		disp('proceeding!')
	else
		error('Close everything, then proceed from line 51')
	end






%% Now generate plots up until first lick:
	disp('Plotting CTA and LTA up to first lick and saving figures')
	plot_to_lick_roadmapv1

	if strcmp(exptype_,'hyb') && rxnwin_ == 500
		print(1,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	elseif strcmp(exptype_,'hyb') && rxnwin_ == 0
		print(1,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	elseif strcmp(exptype_,'hyb') && rxnwin_ ~= 500 && rxnwin_ ~= 0
		print(1,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	elseif strcmp(exptype_, 'op') && rxnwin_ == 500
		print(1,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	elseif strcmp(exptype_, 'op') && rxnwin_ == 300
		print(1,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	elseif strcmp(exptype_, 'op') && rxnwin_ == 0
		print(1,'-depsc','-painters', ['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(1,['CTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(2,'-depsc','-painters', ['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(2,['CTA_ALLOP_points_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
		print(3,'-depsc','-painters', ['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
		saveas(3,['LTA_ALLOP_5bin_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	end
	disp('Plotting and saving complete')


%% Split up rxn+ and rxn- trials for CTA/LTA
	disp('Plotting CTA and LTA split by rxn/no rxn and saving figures')
	CTA_LTA_split_by_rxn_no_rxn
	print(4,'-depsc','-painters', ['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	saveas(4,['CTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	print(5,'-depsc','-painters', ['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	saveas(5,['LTA_w_wo_rxn_ALLOP_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	disp('Saving figured complete.')

    
%% Run Histograms
    disp('Plotting Hxgrams and saving figures')
    hxgram_single_roadmapv1
	
    print(6,'-depsc','-painters', ['hxg_allfirst_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	saveas(6,['hxg_allfirst_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	print(7,'-depsc','-painters', ['hxg_rxn_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	saveas(7,['hxg_rxn_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
    print(8,'-depsc','-painters', ['hxg_allop_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	saveas(8,['hxg_allop_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
    print(9,'-depsc','-painters', ['hxg_p_m_rxn_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.eps'])
	saveas(9,['hxg_p_m_rxn_ex', exclusion_criteria_version_, '_header', headernum_, '__', todaysdate, '_', mousename_ '.fig'],'fig')
	disp('Saving figured complete.')

%% Generated Numbered Variable Names--------------------------------------------------------
	
    disp('Generating additional numbered vars...')
    DLS_values_by_trial_fi_name = genvarname(['d', daynum_, '_DLS_values_by_trial_fi']);
	eval([DLS_values_by_trial_fi_name '= DLS_values_by_trial_fi;']);
	DLS_values_by_trial_fi_trim_name = genvarname(['d', daynum_, '_DLS_values_by_trial_fi_trim']);
	eval([DLS_values_by_trial_fi_trim_name '= DLS_values_by_trial_fi_trim;']);
	
	DLS_ex_values_by_trial_fi_name = genvarname(['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi']);
	eval([DLS_ex_values_by_trial_fi_name '= DLS_ex_values_by_trial_fi;']);
	DLS_ex_values_by_trial_fi_trim_name = genvarname(['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim']);	
	eval([DLS_ex_values_by_trial_fi_trim_name '= DLS_ex_values_by_trial_fi_trim;']);


	SNc_values_by_trial_fi_name = genvarname(['d', daynum_, '_SNc_values_by_trial_fi']);
	eval([SNc_values_by_trial_fi_name '= SNc_values_by_trial_fi;']);
	SNc_values_by_trial_fi_trim_name = genvarname(['d', daynum_, '_SNc_values_by_trial_fi_trim']);
	eval([SNc_values_by_trial_fi_trim_name '= SNc_values_by_trial_fi_trim;']);
	
	SNc_ex_values_by_trial_fi_name = genvarname(['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi']);
	eval([SNc_ex_values_by_trial_fi_name '= SNc_ex_values_by_trial_fi;']);
	SNc_ex_values_by_trial_fi_trim_name = genvarname(['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim']);
	eval([SNc_ex_values_by_trial_fi_trim_name '= SNc_ex_values_by_trial_fi_trim;']);


	% 4.55 values by trial up to lick:
	DLS_ex_values_up_to_lick_name = genvarname(['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_up_to_lick']);
	eval([DLS_ex_values_up_to_lick_name '= DLS_ex_values_up_to_lick;']);
	SNc_ex_values_up_to_lick_name = genvarname(['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_up_to_lick']);
	eval([SNc_ex_values_up_to_lick_name '= SNc_ex_values_up_to_lick;']);
    disp('New vars complete.')

    





%% Save all variables to the header
disp('Saving variables to header...')
answ = questdlg(['Warning - about to create header file called:                                        ', mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1_1 ', todaysdate2,'.txt                                       and                                     ', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_1_', todaysdate, '.mat                                              Check if exists - ok to overwrite?'],'Ready to Save?', 'No');
if strcmp(answ, 'Yes')
	disp('proceeding!')
else
	error('Figure out header you want and proceed from line 151')
end

savefilename = [mousename_, '_day', daynum_, '_header', headernum_, 'add_roadmapv1_1add', todaysdate];

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
		['d', daynum_, '_DLS_values_by_trial_fi'],...
		['d', daynum_, '_DLS_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_values_by_trial_fi'],...
		['d', daynum_, '_SNc_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
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
		['d', daynum_, '_DLS_values_by_trial_fi'],...
		['d', daynum_, '_DLS_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_values_by_trial_fi'],...
		['d', daynum_, '_SNc_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
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
		['d', daynum_, '_DLS_values_by_trial_fi'],...
		['d', daynum_, '_DLS_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_values_by_trial_fi'],...
		['d', daynum_, '_SNc_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
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
		['d', daynum_, '_DLS_values_by_trial_fi'],...
		['d', daynum_, '_DLS_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_values_by_trial_fi'],...
		['d', daynum_, '_SNc_values_by_trial_fi_trim'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim'],...
		['d', daynum_, '_DLS_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
		['d', daynum_, '_SNc_ex', exclusion_criteria_version_, '_values_up_to_lick'],...
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
defaultans = {[mousename_, ' Day ',daynum_, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2, ' using roadmapv1_1_addendum set of functions from roadmapv1 version.'], ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Excluded trials: ', excluded_trials_{1}], 'Notes:'};
answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



fid = fopen([mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1_1 ', todaysdate2,'.txt'], 'wt' );
fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
fclose(fid);