%% Make pure no-rxn dataset for combining across days:

%% Roadmap v1.2 addendum:
% 
% 	Run this on Roadmap v1_1 data to complete the v1.2 dataset
% 
% 	Created: 8-15-17
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
	defaultans = {'13', '1', 'op', '0', '1', 'H5'};
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
	if strcmp(exptype_, 'hyb')
		f_ex_lick_pavlovian_name = genvarname('f_ex_lick_pavlovian');
		eval([f_ex_lick_pavlovian_name '= d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_pavlovian;']);
	end


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

	disp('Vars regenerated')


%% Close all figures-----------------------------------------------------------------------
	waiter = questdlg('Need to close all figures before proceeding - ok?','Ready to plot?', 'No');
	if strcmp(waiter, 'Yes')
		close all
		disp('proceeding!')
	else
		error('Close everything, then proceed from line 51')
	end



%% Separate Trials by Rxn+/Rxn-
	disp('Pulling out +/- Rxn trials')
	[f_ex_licks_with_rxn, f_ex_licks_no_rxn] = rxn_lick_or_no_rxn_lick_fx(all_ex_first_licks, f_ex_lick_rxn);

%% Correct early, rew and pav first licks based on these:

trials_without_rxn = find(f_ex_licks_no_rxn);
trials_with_rxn = find(f_ex_licks_with_rxn);

all_ex_first_licks(trials_with_rxn) = 0;
f_ex_lick_operant_no_rew(trials_with_rxn) = 0;
f_ex_lick_operant_rew(trials_with_rxn) = 0;
if strcmp(exptype_, 'hyb')
	f_ex_licks_pavlovian(trials_with_rxn) = 0;
end



%% Generated Numbered Variable Names--------------------------------------------------------
	
    disp('Generating additional numbered vars...')
    trials_without_rxn_name = genvarname(['d', daynum_, '_trials_without_rxn']);
	eval([trials_without_rxn_name '= trials_without_rxn;']);
	

	all_ex_first_licks_name = genvarname(['d', daynum_, '_all_ex', exclusion_criteria_version_, '_first_licks']);
	eval([all_ex_first_licks_name '= all_ex_first_licks;']);


	f_ex_lick_operant_no_rew_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew']);
	eval([f_ex_lick_operant_no_rew_name '= f_ex_lick_operant_no_rew;']);


	f_ex_lick_operant_rew_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_lick_operant_rew']);
	eval([f_ex_lick_operant_rew_name '= f_ex_lick_operant_rew;']);


	if strcmp(exptype_, 'hyb')
		f_ex_licks_pavlovian_name = genvarname(['d', daynum_, '_f_ex', exclusion_criteria_version_, '_licks_pavlovian']);
		eval([f_ex_licks_pavlovian_name '= f_ex_licks_pavlovian;']);
	end


    disp('New vars complete.')






%% Save all variables to the header
disp('Saving variables to header...')
answ = questdlg(['Warning - about to create header file called:                                        ', mousename_, ' Day ',daynum_,' NO RXN LICK Header ', headernum_,' roadmapv1_1 ', todaysdate2,'.txt                                       and                                     ', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_1_', todaysdate, '.mat                                              Check if exists - ok to overwrite?'],'Ready to Save?', 'No');
if strcmp(answ, 'Yes')
	disp('proceeding!')
else
	error('Figure out header you want and proceed from line 138')
end

savefilename = [mousename_, '_day', daynum_, '_NORXNLICK_header', headernum_, 'add_roadmapv1_2add', todaysdate];

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
		['d', daynum_, '_trials_without_rxn'],...
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
		['d', daynum_, '_trials_without_rxn'],...
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
		['d', daynum_, '_trials_without_rxn'],...
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
		['d', daynum_, '_trials_without_rxn'],...
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
defaultans = {[mousename_, ' Day ',daynum_, ' NO RXN LICK Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2, ' using make_no_rxn_only_dataset (roadmapv1_2_addendum) set of functions from roadmapv1 version.'], ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Excluded trials: ', excluded_trials_{1}], 'Notes:'};
answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



fid = fopen([mousename_, ' Day ',daynum_,' Header ', headernum_,' NO RXN LICK roadmapv1_1 ', todaysdate2,'.txt'], 'wt' );
fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
fclose(fid);