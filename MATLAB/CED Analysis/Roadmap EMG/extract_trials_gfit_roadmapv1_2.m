%% Extract CED Data using the gfitdF_F_fx.m
%	Created:		6-3-17	ahamilos (from extract_trials_gfit_roadmapv1.m)
%	Last Updated:	9-22-17	ahamilos
%
% Generic for any kind of trial type (hyb, op, etc)
%
% 	9-22-17: modified for movement control only
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




% time resolution in 100Hz rate is 0.01 sec
% 	thus for each trial start time, take the value: time +/- 0.01 sec
% Extract the X,Y,Z and EMG signal structure, timepoints and analog values
X_struct = eval([filename, '_X']);
X_values = X_struct.values;
X_times = X_struct.times;

Y_struct = eval([filename, '_Y']);
Y_values = Y_struct.values;
Y_times = Y_struct.times;

Z_struct = eval([filename, '_Z']);
Z_values = Z_struct.values;
Z_times = Z_struct.times;

EMG_struct = eval([filename, '_EMG']);
EMG_values = EMG_struct.values;
EMG_times = EMG_struct.times;

% time resolution in 100Hz rate is 0.001 sec
% 	thus for each trial start time, take the value: time +/- 0.001 sec
% Extract the DLS signal structure, timepoints and analog values
% % Extract the DLS signal structure, timepoints and analog values
% DLS_struct = eval([filename, '_DLS']);
% DLS_values = DLS_struct.values;
% DLS_times = DLS_struct.times;

% % Extract the SNc signal structure, timepoints and analog values
% SNc_struct = eval([filename, '_SNc']);
% SNc_values = SNc_struct.values;
% SNc_times = SNc_struct.times;

%********************correction for bleaching**********************
% [gfit_SNc, gfit_DLS] = gfitdF_F_fx(SNc_values, DLS_values);


% [DLS_times_by_trial, DLS_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(DLS_times,...
% 																					 gfit_DLS,...
% 																					 trial_start_times,...
% 																					 cue_on_times);
% [SNc_times_by_trial, SNc_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(SNc_times,...
% 																					 gfit_SNc,...
% 																					 trial_start_times,...
% 																					 cue_on_times);
[X_times_by_trial, X_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(X_times,...
																					 X_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);
[Y_times_by_trial, Y_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(Y_times,...
																					 Y_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);
[Z_times_by_trial, Z_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(Z_times,...
																					 Z_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);
[EMG_times_by_trial, EMG_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(EMG_times,...
																					 EMG_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);


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