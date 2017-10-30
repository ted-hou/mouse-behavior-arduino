%% Automatically Combine Days - use for already pre-combined days to make full stucture



combined_data_struct = {};

todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');

% Start of run: Prompt user for needed variables--------------------------------------------
	disp('Collecting user input...')
	prompt = {'Day #s:','Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Exclusion Criteria Version', 'Animal Name'};
	dlg_title = 'Inputs';
	num_lines = 1;
	defaultans = {'1,2,3','1', 'hyb', '500', '1', 'H5'};
	answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
	daynum_ = str2num(answer_{1});
	headernum_ = answer_{2};
	exptype_ = answer_{3};
	rxnwin_ = str2double(answer_{4});
	exclusion_criteria_version_ = answer_{5};
	mousename_ = answer_{6};
	disp('Collecting user input complete')













data_set_holder = {};

stillselex = true;
position = 1;
while stillselex == true
	selexmore = questdlg('Add More Datasets?', 'Keep Going?');
	if strcmp(selexmore, 'Yes')
		[FileName,PathName] = uigetfile('*.mat','Select the header file');
		data_set_holder{position} = load([PathName, FileName]);
	else
		stillselex = false;
		break
	end
	position = position + 1;
end

%% Initialize all the data fields
combined_data_struct.DLS_values_by_trial = [];
combined_data_struct.SNc_values_by_trial = [];
combined_data_struct.DLS_ex_values_by_trial = [];
combined_data_struct.SNc_ex_values_by_trial = [];
combined_data_struct.all_ex_first_licks = [];
combined_data_struct.f_ex_lick_rxn = [];
combined_data_struct.f_ex_lick_operant_no_rew = [];
combined_data_struct.f_ex_lick_operant_rew = [];
combined_data_struct.f_ex_lick_ITI = [];
combined_data_struct.early_DLS_lick_triggered_trials = [];
combined_data_struct.rew_DLS_lick_triggered_trials = [];
combined_data_struct.early_SNc_lick_triggered_trials = [];
combined_data_struct.rew_SNc_lick_triggered_trials = [];
combined_data_struct.SNc_ex_values_by_trial_fi_trim = [];
combined_data_struct.DLS_ex_values_by_trial_fi_trim = [];

%%
disp('combining data')
for iset = 1:length(data_set_holder)
	combined_data_struct.DLS_values_by_trial = vertcat(combined_data_struct.DLS_values_by_trial, data_set_holder{iset}.combined_data_struct.DLS_values_by_trial);
	combined_data_struct.SNc_values_by_trial = vertcat(combined_data_struct.SNc_values_by_trial, data_set_holder{iset}.combined_data_struct.SNc_values_by_trial);
	combined_data_struct.DLS_ex_values_by_trial = vertcat(combined_data_struct.DLS_ex_values_by_trial, data_set_holder{iset}.combined_data_struct.DLS_ex_values_by_trial);
	combined_data_struct.SNc_ex_values_by_trial = vertcat(combined_data_struct.SNc_ex_values_by_trial, data_set_holder{iset}.combined_data_struct.SNc_ex_values_by_trial);
	
	combined_data_struct.all_ex_first_licks = horzcat(combined_data_struct.all_ex_first_licks, data_set_holder{iset}.combined_data_struct.all_ex_first_licks);
	combined_data_struct.f_ex_lick_rxn = horzcat(combined_data_struct.f_ex_lick_rxn, data_set_holder{iset}.combined_data_struct.f_ex_lick_rxn);
	combined_data_struct.f_ex_lick_operant_no_rew = horzcat(combined_data_struct.f_ex_lick_operant_no_rew, data_set_holder{iset}.combined_data_struct.f_ex_lick_operant_no_rew);
	combined_data_struct.f_ex_lick_operant_rew = horzcat(combined_data_struct.f_ex_lick_operant_rew, data_set_holder{iset}.combined_data_struct.f_ex_lick_operant_rew);
	combined_data_struct.f_ex_lick_ITI = horzcat(combined_data_struct.f_ex_lick_ITI, data_set_holder{iset}.combined_data_struct.f_ex_lick_ITI);


	combined_data_struct.time_array = data_set_holder{iset}.combined_data_struct.time_array;

	combined_data_struct.early_DLS_lick_triggered_trials = vertcat(combined_data_struct.early_DLS_lick_triggered_trials, data_set_holder{iset}.combined_data_struct.early_DLS_lick_triggered_trials);
	combined_data_struct.rew_DLS_lick_triggered_trials = vertcat(combined_data_struct.rew_DLS_lick_triggered_trials, data_set_holder{iset}.combined_data_struct.rew_DLS_lick_triggered_trials);
	combined_data_struct.early_SNc_lick_triggered_trials = vertcat(combined_data_struct.early_SNc_lick_triggered_trials, data_set_holder{iset}.combined_data_struct.early_SNc_lick_triggered_trials);
	combined_data_struct.rew_SNc_lick_triggered_trials = vertcat(combined_data_struct.rew_SNc_lick_triggered_trials, data_set_holder{iset}.combined_data_struct.rew_SNc_lick_triggered_trials);
	combined_data_struct.SNc_ex_values_by_trial_fi_trim = vertcat(combined_data_struct.SNc_ex_values_by_trial_fi_trim, data_set_holder{iset}.combined_data_struct.SNc_ex_values_by_trial_fi_trim);
	combined_data_struct.DLS_ex_values_by_trial_fi_trim = vertcat(combined_data_struct.DLS_ex_values_by_trial_fi_trim, data_set_holder{iset}.combined_data_struct.DLS_ex_values_by_trial_fi_trim);
end
disp('combining data complete')



















% replace spaces with underscores:
strdays = num2str(daynum_);
daysforfile = '';
for ilen = 1:length(strdays)
	if strcmp(strdays(ilen), ' ')
		daysforfile(ilen) = '_';
	else
		daysforfile(ilen) = strdays(ilen);
	end
end



%% Save all variables to the header
disp('Saving variables to header...')
answ = questdlg(['Warning - about to create header file called:                                        ', mousename_, ' COMBINED Days ',strdays,' Header ', headernum_,' roadmapv1_1 ', todaysdate2,'.txt                                       and                                     ', mousename_, '_day', daysforfile, '_header', headernum_, '_roadmapv1_1_', todaysdate, '.mat                                              Check if exists - ok to overwrite?'],'Ready to Save?', 'No');
if strcmp(answ, 'Yes')
	disp('proceeding!')
else
	error('Figure out header you want and proceed from line 393')
end




savefilename = [mousename_, '_COMBO_days', daysforfile, '_header', headernum_, '_roadmapv1_', todaysdate];

save(savefilename, 'combined_data_struct', '-v7.3');
disp('Saving variables to header complete.')


%% Generate the header file:

prompt2 = {'Enter header file text:', 'Generation Codes', 'Exp Description', 'Excluded Trials Version:', 'Notes - don''t make any carriage returns!'};
dlg_title = 'Header file text';
num_lines = 5;
defaultans = {[mousename_, ' COMBINED Days ',strdays, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2, ' using roadmapv1_2 set of functions, which includes no rxn only trials, combining data structs of previously combined days, plot-to-lick and backfill fxs.'], ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Exclusion criteria version: ex', num2str(exclusion_criteria_version_)], 'Notes:'};
answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



fid = fopen([mousename_, ' Day ',strdays,' Header ', headernum_,' roadmapv1_1 ', todaysdate2,'.txt'], 'wt' );
fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
fclose(fid);

