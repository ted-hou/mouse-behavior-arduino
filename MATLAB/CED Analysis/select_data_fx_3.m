% function [] = select_data_fx_3(analog_times, analog_values, filename)
% copy this for default: select_data_fx_3(SNc_struct.times, SNc_struct.values, 'Day1_A1')
% 
% Created 			4-24-17 - ahamilos
% Last Modified 	4-25-17 - ahamilos
% 
% Takes raw analog data from CED
% 	1. divide all data into trials by cue on
% 	2. ave last 3 sec of each trial
% 	3. subtract each trial by ave of last 3 sec to make flat at zero
% 	4. Look at everything global normalized and local normalized by heatmaps
% 
%% Debug defaults
filename = 'Day6_A1';
DLS_struct = eval([filename, '_DLS']);
analog_values = DLS_struct.values;
analog_times = DLS_struct.times;

% %% Open file:
% response = inputdlg('Enter CED filename (don''t include *_lick, etc)');
% filename = response{1};
%-----------------------------------------------------------------------------------------
%% Extract DIGITAL variables from file

% Extract the lamp_off structure and timepoints
lamp_off_struct = eval([filename, '_Lamp_OFF']);
trial_start_times = lamp_off_struct.times;

% Extract the cue_on structure and timepoints
cue_on_struct = eval([filename, '_Start_Cu']);
cue_on_times = cue_on_struct.times;

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)

%------------------------------------------------------------------------------------------
%% 1. Divide all data into trials by cue on:
[times_by_trial, values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(analog_times, analog_values, trial_start_times, cue_on_times);

%% 2. Plot as heatmap...
[h_heatmap, heat_by_trial] = heatmap_3_fx(values_by_trial, [], false);


%% 3. Find the ave of last 3 sec in each trial and subtract that from every datapoint in that trial:
df_f_values = NaN(size(values_by_trial));
for i_trial = 1:num_trials
	% take ave of last 3 sec:
	ave_last_3 = nanmean(values_by_trial(i_trial, end-3000:end));
	% subtract this from every datapoint in the trial:
	df_f_values(i_trial, :) = values_by_trial(i_trial, :) - ave_last_3;
end

%% 3. Check heatmap now...
[h_heatmap2, heat_by_trial] = heatmap_3_fx(df_f_values, [], false);
title('Globally-normalized heatmap of df/f')

% Allow user to select trials they want to ignore from consideration:
button = questdlg('Did the light intensity change during the experiment?','Hey!','Yes','No','Yes');
answer = strcmp(button, 'Yes');
if answer ~= 1
	close(h_heatmap);
end

%% If light level was changed, allow user to select timepoint to split data on:
split_times = [];
split_trials = []; 
num = 1;
keep_checking = answer;
while keep_checking == 1
	title('Select trials to split data by clicking (choose in order small->large)');
	[split_times(num), split_trials(num)] = ginput(1);
	
	button2 = questdlg(strcat('You selected trial #', num2str(split_trials(num))) ,'Hey!','Continue','Redo', 'Select More Trials', 'Continue');
	if strcmp(button2, 'Select More Trials');
		disp('checking again')
		num = num + 1;
		keep_checking = 1;	
	elseif strcmp(button2, 'Continue');
		disp('don''t check again')
		keep_checking = false;
		break
	elseif strcmp(button2, 'Redo');
		disp('Pick again...')
		num = num;
		keep_checking = 1;
    end
end
% Take the floor of the trial # so it is a whole #:
split_trials = floor(split_trials);

ignore_split_trials = df_f_values;
for i = split_trials
	ignore_split_trials(i, :) = NaN;
end

%% 3. Check heatmap now...
[h_heatmap3, heat_by_trial] = heatmap_3_fx(ignore_split_trials, [], false);
title('Globally-normalized heatmap of df/f')

%% 4. Plot trial-normalized heatmap for comparison...
[h_heatmap4, heat_by_trial] = heatmap_fx(df_f_values, [], false);












