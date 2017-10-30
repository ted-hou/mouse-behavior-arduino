%% Automatically Combine Days

num_timepoints = 18501;
backfilltime = 5000;


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

%%
DLS_values_struct = {};
for idays = 1:length(daynum_)
	DLS_values_by_trial_name = genvarname(['DLS_values_by_trial']);
	eval([DLS_values_by_trial_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_DLS_values_by_trial;']);
	DLS_values_struct{idays} = DLS_values_by_trial(:,1:num_timepoints);
end

combined_data_struct.DLS_values_by_trial = DLS_values_struct{1};
for icell = 2:length(DLS_values_struct)
	combined_data_struct.DLS_values_by_trial = vertcat(combined_data_struct.DLS_values_by_trial, DLS_values_struct{icell})
end





SNc_values_by_trial_struct = {};
for idays = 1:length(daynum_)
	SNc_values_by_trial_name = genvarname(['SNc_values_by_trial']);
	eval([SNc_values_by_trial_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_SNc_values_by_trial;']);
	SNc_values_by_trial_struct{idays} = SNc_values_by_trial(:,1:num_timepoints);
end

combined_data_struct.SNc_values_by_trial = SNc_values_by_trial_struct{1};
for icell = 2:length(SNc_values_by_trial_struct)
	combined_data_struct.SNc_values_by_trial = vertcat(combined_data_struct.SNc_values_by_trial, SNc_values_by_trial_struct{icell})
end



DLS_ex_values_by_trial_struct = {};
for idays = 1:length(daynum_)
	DLS_ex_values_by_trial_name = genvarname(['DLS_ex_values_by_trial']);
	eval([DLS_ex_values_by_trial_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_DLS_ex', exclusion_criteria_version_, '_values_by_trial;']);
	DLS_ex_values_by_trial_struct{idays} = DLS_ex_values_by_trial(:,1:num_timepoints);
end

combined_data_struct.DLS_ex_values_by_trial = DLS_ex_values_by_trial_struct{1};
for icell = 2:length(DLS_ex_values_by_trial_struct)
	combined_data_struct.DLS_ex_values_by_trial = vertcat(combined_data_struct.DLS_ex_values_by_trial, DLS_ex_values_by_trial_struct{icell})
end



SNc_ex_values_by_trial_struct = {};
for idays = 1:length(daynum_)
	SNc_ex_values_by_trial_name = genvarname(['SNc_ex_values_by_trial']);
	eval([SNc_ex_values_by_trial_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_SNc_ex', exclusion_criteria_version_, '_values_by_trial;']);
	SNc_ex_values_by_trial_struct{idays} = SNc_ex_values_by_trial(:,1:num_timepoints);
end

combined_data_struct.SNc_ex_values_by_trial = SNc_ex_values_by_trial_struct{1};
for icell = 2:length(SNc_ex_values_by_trial_struct)
	combined_data_struct.SNc_ex_values_by_trial = vertcat(combined_data_struct.SNc_ex_values_by_trial, SNc_ex_values_by_trial_struct{icell})
end



all_ex_first_licks_struct = {};
for idays = 1:length(daynum_)
	all_ex_first_licks_name = genvarname(['all_ex_first_licks']);
	eval([all_ex_first_licks_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_all_ex', exclusion_criteria_version_, '_first_licks;']);
	all_ex_first_licks_struct{idays} = all_ex_first_licks;
end

combined_data_struct.all_ex_first_licks = all_ex_first_licks_struct{1};
for icell = 2:length(all_ex_first_licks_struct)
	combined_data_struct.all_ex_first_licks = horzcat(combined_data_struct.all_ex_first_licks, all_ex_first_licks_struct{icell})
end



f_ex_lick_rxn_struct = {};
for idays = 1:length(daynum_)
	f_ex_lick_rxn_name = genvarname(['f_ex_lick_rxn']);
	eval([f_ex_lick_rxn_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_f_ex', exclusion_criteria_version_, '_lick_rxn;']);
	f_ex_lick_rxn_struct{idays} = f_ex_lick_rxn;
end

combined_data_struct.f_ex_lick_rxn = f_ex_lick_rxn_struct{1};
for icell = 2:length(f_ex_lick_rxn_struct)
	combined_data_struct.f_ex_lick_rxn = horzcat(combined_data_struct.f_ex_lick_rxn, f_ex_lick_rxn_struct{icell})
end



f_ex_lick_operant_no_rew_struct = {};
for idays = 1:length(daynum_)
	f_ex_lick_operant_no_rew_name = genvarname(['f_ex_lick_operant_no_rew']);
	eval([f_ex_lick_operant_no_rew_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_f_ex', exclusion_criteria_version_, '_lick_operant_no_rew;']);
	f_ex_lick_operant_no_rew_struct{idays} = f_ex_lick_operant_no_rew;
end

combined_data_struct.f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew_struct{1};
for icell = 2:length(f_ex_lick_operant_no_rew_struct)
	combined_data_struct.f_ex_lick_operant_no_rew = horzcat(combined_data_struct.f_ex_lick_operant_no_rew, f_ex_lick_operant_no_rew_struct{icell})
end



f_ex_lick_operant_rew_struct = {};
for idays = 1:length(daynum_)
	f_ex_lick_operant_rew_name = genvarname(['f_ex_lick_operant_rew']);
	eval([f_ex_lick_operant_rew_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_f_ex', exclusion_criteria_version_, '_lick_operant_rew;']);
	f_ex_lick_operant_rew_struct{idays} = f_ex_lick_operant_rew;
end

combined_data_struct.f_ex_lick_operant_rew = f_ex_lick_operant_rew_struct{1};
for icell = 2:length(f_ex_lick_operant_rew_struct)
	combined_data_struct.f_ex_lick_operant_rew = horzcat(combined_data_struct.f_ex_lick_operant_rew, f_ex_lick_operant_rew_struct{icell})
end



f_ex_lick_ITI_struct = {};
for idays = 1:length(daynum_)
	f_ex_lick_ITI_name = genvarname(['f_ex_lick_ITI']);
	eval([f_ex_lick_ITI_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_f_ex', exclusion_criteria_version_, '_lick_ITI;']);
	f_ex_lick_ITI_struct{idays} = f_ex_lick_ITI;
end

combined_data_struct.f_ex_lick_ITI = f_ex_lick_ITI_struct{1};
for icell = 2:length(f_ex_lick_ITI_struct)
	combined_data_struct.f_ex_lick_ITI = horzcat(combined_data_struct.f_ex_lick_ITI, f_ex_lick_ITI_struct{icell})
end



time_array_name = genvarname(['time_array']);
eval([time_array_name '= data_set_holder{1}.d', num2str(daynum_(1)), '_time_array;']);
combined_data_struct.time_array = time_array;



early_DLS_lick_triggered_trials_struct = {};
for idays = 1:length(daynum_)
	early_DLS_lick_triggered_trials_name = genvarname(['early_DLS_lick_triggered_trials']);
	eval([early_DLS_lick_triggered_trials_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_early_DLS_lick_triggered_trials;']);
	early_DLS_lick_triggered_trials_struct{idays} = early_DLS_lick_triggered_trials(:,1:2*(num_timepoints+backfilltime));
end

combined_data_struct.early_DLS_lick_triggered_trials = early_DLS_lick_triggered_trials_struct{1};
for icell = 2:length(early_DLS_lick_triggered_trials_struct)
	combined_data_struct.early_DLS_lick_triggered_trials = vertcat(combined_data_struct.early_DLS_lick_triggered_trials, early_DLS_lick_triggered_trials_struct{icell})
end



rew_DLS_lick_triggered_trials_struct = {};
for idays = 1:length(daynum_)
	rew_DLS_lick_triggered_trials_name = genvarname(['rew_DLS_lick_triggered_trials']);
	eval([rew_DLS_lick_triggered_trials_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_rew_DLS_lick_triggered_trials;']);
	rew_DLS_lick_triggered_trials_struct{idays} = rew_DLS_lick_triggered_trials(:,1:2*(num_timepoints+backfilltime));
end

combined_data_struct.rew_DLS_lick_triggered_trials = rew_DLS_lick_triggered_trials_struct{1};
for icell = 2:length(rew_DLS_lick_triggered_trials_struct)
	combined_data_struct.rew_DLS_lick_triggered_trials = vertcat(combined_data_struct.rew_DLS_lick_triggered_trials, rew_DLS_lick_triggered_trials_struct{icell})
end

%%


early_SNc_lick_triggered_trials_struct = {};
for idays = 1:length(daynum_)
	early_SNc_lick_triggered_trials_name = genvarname(['early_SNc_lick_triggered_trials']);
	eval([early_SNc_lick_triggered_trials_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_early_SNc_lick_triggered_trials;']);
	early_SNc_lick_triggered_trials_struct{idays} = early_SNc_lick_triggered_trials(:,1:2*(num_timepoints+backfilltime));
end

combined_data_struct.early_SNc_lick_triggered_trials = early_SNc_lick_triggered_trials_struct{1};
for icell = 2:length(early_SNc_lick_triggered_trials_struct)
	combined_data_struct.early_SNc_lick_triggered_trials = vertcat(combined_data_struct.early_SNc_lick_triggered_trials, early_SNc_lick_triggered_trials_struct{icell})
end



rew_SNc_lick_triggered_trials_struct = {};
for idays = 1:length(daynum_)
	rew_SNc_lick_triggered_trials_name = genvarname(['rew_SNc_lick_triggered_trials']);
	eval([rew_SNc_lick_triggered_trials_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_rew_SNc_lick_triggered_trials;']);
	rew_SNc_lick_triggered_trials_struct{idays} = rew_SNc_lick_triggered_trials(:,1:2*(num_timepoints+backfilltime));
end

combined_data_struct.rew_SNc_lick_triggered_trials = rew_SNc_lick_triggered_trials_struct{1};
for icell = 2:length(rew_SNc_lick_triggered_trials_struct)
	combined_data_struct.rew_SNc_lick_triggered_trials = vertcat(combined_data_struct.rew_SNc_lick_triggered_trials, rew_SNc_lick_triggered_trials_struct{icell})
end



SNc_ex_values_by_trial_fi_trim_struct = {};
for idays = 1:length(daynum_)
	SNc_ex_values_by_trial_fi_trim_name = genvarname(['SNc_ex_values_by_trial_fi_trim']);
	eval([SNc_ex_values_by_trial_fi_trim_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_SNc_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim;']);
	SNc_ex_values_by_trial_fi_trim_struct{idays} = SNc_ex_values_by_trial_fi_trim(:,1:num_timepoints);
end

combined_data_struct.SNc_ex_values_by_trial_fi_trim = SNc_ex_values_by_trial_fi_trim_struct{1};
for icell = 2:length(SNc_ex_values_by_trial_fi_trim_struct)
	combined_data_struct.SNc_ex_values_by_trial_fi_trim = vertcat(combined_data_struct.SNc_ex_values_by_trial_fi_trim, SNc_ex_values_by_trial_fi_trim_struct{icell})
end



DLS_ex_values_by_trial_fi_trim_struct = {};
for idays = 1:length(daynum_)
	DLS_ex_values_by_trial_fi_trim_name = genvarname(['DLS_ex_values_by_trial_fi_trim']);
	eval([DLS_ex_values_by_trial_fi_trim_name '= data_set_holder{idays}.d', num2str(daynum_(idays)), '_DLS_ex', exclusion_criteria_version_, '_values_by_trial_fi_trim;']);
	DLS_ex_values_by_trial_fi_trim_struct{idays} = DLS_ex_values_by_trial_fi_trim(:,1:num_timepoints);
end

combined_data_struct.DLS_ex_values_by_trial_fi_trim = DLS_ex_values_by_trial_fi_trim_struct{1};
for icell = 2:length(DLS_ex_values_by_trial_fi_trim_struct)
	combined_data_struct.DLS_ex_values_by_trial_fi_trim = vertcat(combined_data_struct.DLS_ex_values_by_trial_fi_trim, DLS_ex_values_by_trial_fi_trim_struct{icell})
end


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
defaultans = {[mousename_, ' COMBINED Days ',strdays, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2, ' using roadmapv1_1 set of functions, which includes plot-to-lick and backfill fxs.'], ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Exclusion criteria version: ex', num2str(exclusion_criteria_version_)], 'Notes:'};
answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



fid = fopen([mousename_, ' Day ',strdays,' Header ', headernum_,' roadmapv1_1 ', todaysdate2,'.txt'], 'wt' );
fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
fclose(fid);

