%% Extract CED Data using the gfitdF_F_fx.m
%	Created:		6-3-17	ahamilos
%	Last Updated:	8-1-17	ahamilos
%
% Generic for any kind of trial type (hyb, op, etc)
%
% 	8-01-17: generated from the 6-3-17 version of extract_trials_gfit_v1.m - only difference so far is no Open File part
%	6-03-17: added gfitdF_F_fx delF
%   4-25-17: no del F
%   4-18-17: added SEM calculation and plots for SNc and DLS total
%-----------------------------------------------------------------------------------------
% %% Open file: this now happens in the roadmap runner
% response = inputdlg('Enter CED filename (don''t include *_lick, etc)');
filename = filename_;
%-----------------------------------------------------------------------------------------
%% Extract DIGITAL variables from file

% Extract the lamp_off structure and timepoints
lamp_off_struct = eval([filename, '_Lamp_OFF']);
trial_start_times = lamp_off_struct.times;

% Extract the cue_on structure and timepoints
cue_on_struct = eval([filename, '_Start_Cu']);
cue_on_times = cue_on_struct.times;

% Extract the Juice structure and timepoints
juice_struct = eval([filename, '_Juice']);
juice_times = juice_struct.times;

% Extract the LampON structure and timepoints
lampOn_struct = eval([filename, '_LampON']);
lampOn_times = lampOn_struct.times;

% Extract the Lick structure and timepoints
lick_struct = eval([filename, '_Lick']);
lick_times = lick_struct.times;

% Extract the Trigger structure and timepoints
trigger_struct = eval([filename, '_Trigger']);
trigger_times = trigger_struct.times;

% Extract the Keyboard structure and timepoints and codes
keyboard_struct = eval([filename, '_Keyboard']);
keyboard_times = keyboard_struct.times;
keyboard_codes = keyboard_struct.codes;

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)




% time resolution in 1000Hz rate is 0.001 sec
% 	thus for each trial start time, take the value: time +/- 0.001 sec

% Extract the DLS signal structure, timepoints and analog values
DLS_struct = eval([filename, '_DLS']);
DLS_values = DLS_struct.values;
DLS_times = DLS_struct.times;

% Extract the SNc signal structure, timepoints and analog values
SNc_struct = eval([filename, '_SNc']);
SNc_values = SNc_struct.values;
SNc_times = SNc_struct.times;

%********************correction for bleaching**********************
[gfit_SNc, gfit_DLS] = gfitdF_F_fx(SNc_values, DLS_values);


[DLS_times_by_trial, DLS_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(DLS_times,...
																					 gfit_DLS,...
																					 trial_start_times,...
																					 cue_on_times);
[SNc_times_by_trial, SNc_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(SNc_times,...
																					 gfit_SNc,...
																					 trial_start_times,...
																					 cue_on_times);
% CUE ON marker @ column position 1501!!!
 
h_alert = msgbox('Extracting Trials Complete');




% [DLS_times_by_trial, DLS_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx_H5DAY13WEIRDFIX(DLS_times,...
% 																					 gfit_DLS,...
% 																					 trial_start_times,...
% 																					 cue_on_times);

% [SNc_times_by_trial, SNc_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx_H5DAY13WEIRDFIX(SNc_times,...
% 					 gfit_SNc,...
% 					 trial_start_times,...
% 					 cue_on_times);