%% Extract CED Data using the gfitdF_F_fx.m
%	Created:		6-3-17	ahamilos (from extract_trials_gfit_roadmapv1_2.m)
%	Last Updated:	10-26-17	ahamilos
%
% Generic for any kind of trial type (hyb, op, etc)
%
%   10-26-17: modified to handle VTA photometry
%   10-3-17: modfied to handle all possible types of analog data (photometry and movement)
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
% juice_struct = eval([filename, '_Juice']);
% juice_times = juice_struct.times;

% Extract the LampON structure and timepoints
lampOn_struct = eval([filename, '_LampON']);
lampOn_times = lampOn_struct.times;

% Extract the Lick structure and timepoints
lick_struct = eval([filename, '_Lick']);
lick_times = lick_struct.times;

% Extract the Trigger structure and timepoints
% trigger_struct = eval([filename, '_Trigger']);
% trigger_times = trigger_struct.times;

% Extract the Keyboard structure and timepoints and codes
% keyboard_struct = eval([filename, '_Keyboard']);
% keyboard_times = keyboard_struct.times;
% keyboard_codes = keyboard_struct.codes;

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)




% time resolution in 2000Hz rate is 0.005 sec
% 	thus for each trial start time, take the value: time +/- 0.005 sec
% Extract the X,Y,Z and EMG signal structure, timepoints and analog values

eval(['x_on = exist(''', filename, '_X'')'])
eval(['y_on = exist(''', filename, '_Y'')'])
eval(['z_on = exist(''', filename, '_Z'')'])
eval(['emg_on = exist(''', filename, '_EMG'')'])
eval(['dls_on = exist(''', filename, '_DLS'')'])
eval(['snc_on = exist(''', filename, '_SNc'')'])
eval(['vta_on = exist(''', filename, '_VTA'')'])
eval(['dlsred_on = exist(''', filename, '_DLSred'')'])
eval(['sncred_on = exist(''', filename, '_SNcred'')'])
eval(['vtared_on = exist(''', filename, '_VTAred'')'])
fprintf(['Detected the following signals: \n\t DLS = ', num2str(dls_on), '\n\t SNc = ', num2str(snc_on), '\n\t VTA = ', num2str(vta_on), '\n\t DLSred = ', num2str(dlsred_on), '\n\t SNcred = ', num2str(sncred_on), '\n\t VTAred = ', num2str(vtared_on), '\n\t X = ', num2str(x_on), '\n\t Y = ', num2str(y_on), '\n\t Z = ', num2str(z_on), '\n\t EMG = ', num2str(emg_on), '\n\n'])

if x_on == 1
	X_struct = eval([filename, '_X']);
	X_values = X_struct.values;
	X_times = X_struct.times;
else
	X_values = [];
	X_times = [];
end

if y_on == 1
	Y_struct = eval([filename, '_Y']);
	Y_values = Y_struct.values;
	Y_times = Y_struct.times;
else
	Y_values = [];
	Y_times = [];
end

if z_on == 1
	Z_struct = eval([filename, '_Z']);
	Z_values = Z_struct.values;
	Z_times = Z_struct.times;
else
	Z_values = [];
	Z_times = [];
end


if emg_on == 1
	EMG_struct = eval([filename, '_EMG']);
	EMG_values = EMG_struct.values;
	EMG_times = EMG_struct.times;
else
	EMG_values = [];
	EMG_times = [];
end


% time resolution in 100Hz rate is 0.001 sec
% 	thus for each trial start time, take the value: time +/- 0.001 sec
% Extract the DLS signal structure, timepoints and analog values
% % Extract the DLS signal structure, timepoints and analog values
if dls_on == 1	
	DLS_struct = eval([filename, '_DLS']);
	DLS_values = DLS_struct.values;
	DLS_times = DLS_struct.times;
else
	DLS_values = [];
	DLS_times = [];
end

% % Extract the SNc signal structure, timepoints and analog values
if snc_on == 1
	SNc_struct = eval([filename, '_SNc']);
	SNc_values = SNc_struct.values;
	SNc_times = SNc_struct.times;
else
	SNc_values = [];
	SNc_times = [];
end


% % Extract the VTA signal structure, timepoints and analog values
if vta_on == 1
	VTA_struct = eval([filename, '_VTA']);
	VTA_values = VTA_struct.values;
	VTA_times = VTA_struct.times;
else
	VTA_values = [];
	VTA_times = [];
end


% % Extract the DLSred signal structure, timepoints and analog values
if dlsred_on == 1
	DLSred_struct = eval([filename, '_DLSred']);
	DLSred_values = DLSred_struct.values;
	DLSred_times = DLSred_struct.times;
else
	DLSred_values = [];
	DLSred_times = [];
end


% % Extract the SNcred signal structure, timepoints and analog values
if sncred_on == 1
	SNcred_struct = eval([filename, '_SNcred']);
	SNcred_values = SNcred_struct.values;
	SNcred_times = SNcred_struct.times;
else
	SNcred_values = [];
	SNcred_times = [];
end

% % Extract the VTAred signal structure, timepoints and analog values
if vtared_on == 1
	VTAred_struct = eval([filename, '_VTAred']);
	VTAred_values = VTAred_struct.values;
	VTAred_times = VTAred_struct.times;
else
	VTAred_values = [];
	VTAred_times = [];
end


%********************correction for bleaching**********************
if snc_on == 1
    [gfit_SNc] = gfitdF_F_fx_roadmap1_3(SNc_values);
else
    gfit_SNc = [];
end

if dls_on == 1
    [gfit_DLS] = gfitdF_F_fx_roadmap1_3(DLS_values);
else
    gfit_DLS = [];
end

if vta_on == 1
    [gfit_VTA] = gfitdF_F_fx_roadmap1_3(VTA_values);
else
    gfit_VTA = [];
end

if sncred_on == 1
    [gfit_SNcred] = gfitdF_F_fx_roadmap1_3(SNcred_values);
else
    gfit_SNcred = [];
end

if dlsred_on == 1
    [gfit_DLSred] = gfitdF_F_fx_roadmap1_3(DLSred_values);
else
    gfit_DLSred = [];
end

if vtared_on == 1
    [gfit_VTAred] = gfitdF_F_fx_roadmap1_3(VTAred_values);
else
    gfit_VTAred = [];
end

if dls_on == 1
    [DLS_times_by_trial, DLS_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(DLS_times,...
																					 gfit_DLS,...
																					 trial_start_times,...
																					 cue_on_times);
else
    DLS_times_by_trial = [];
    DLS_values_by_trial = [];
end

if snc_on == 1
    [SNc_times_by_trial, SNc_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(SNc_times,...
																					 gfit_SNc,...
																					 trial_start_times,...
																					 cue_on_times);
else
    SNc_times_by_trial = [];
    SNc_values_by_trial = [];   
end



if vta_on == 1
    [VTA_times_by_trial, VTA_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(VTA_times,...
																					 gfit_VTA,...
																					 trial_start_times,...
																					 cue_on_times);
else
    VTA_times_by_trial = [];
    VTA_values_by_trial = [];   
end
       

if dlsred_on == 1
    [DLSred_times_by_trial, DLSred_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(DLSred_times,...
																					 gfit_DLSred,...
																					 trial_start_times,...
																					 cue_on_times);
else
    DLSred_times_by_trial = [];
    DLSred_values_by_trial = [];   
end

if sncred_on == 1
    [SNcred_times_by_trial, SNcred_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(SNcred_times,...
																					 gfit_SNcred,...
																					 trial_start_times,...
																					 cue_on_times);
else
    SNcred_times_by_trial = [];
    SNcred_values_by_trial = [];   
end

if vtared_on == 1
    [VTAred_times_by_trial, VTAred_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(VTAred_times,...
																					 gfit_VTAred,...
																					 trial_start_times,...
																					 cue_on_times);
else
    VTAred_times_by_trial = [];
    VTAred_values_by_trial = [];   
end


    
if x_on == 1
    [X_times_by_trial, X_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(X_times,...
																					 X_values,...
																					 trial_start_times,...
																					 cue_on_times,...
    																				 2000);
else
    X_times_by_trial = [];
    X_values_by_trial = [];   
end

if y_on == 1    
    [Y_times_by_trial, Y_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(Y_times,...
																					 Y_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);
else
    Y_times_by_trial = [];
    Y_values_by_trial = [];   
end
     
if z_on == 1
    [Z_times_by_trial, Z_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(Z_times,...
																					 Z_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);
else
    Z_times_by_trial = [];
    Z_values_by_trial = [];   
end 
%%

if emg_on == 1
    [EMG_times_by_trial, EMG_values_by_trial] = put_move_data_into_trials_aligned_to_cue_on_fx_roadmapv1_2(EMG_times,...
																					 EMG_values,...
																					 trial_start_times,...
																					 cue_on_times,...
																					 2000);
else
    EMG_times_by_trial = [];
    EMG_values_by_trial = [];   
end

% CUE ON marker @ column position 1501!!!
 
h_alert = msgbox('Extracting Trials Complete');


