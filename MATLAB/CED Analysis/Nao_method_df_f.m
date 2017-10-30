% Modifiable trial structure vars:
total_trial_duration_in_sec = 17;




todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');

% Start of run: Prompt user for needed variables--------------------------------------------
	disp('Collecting user input...')
	prompt = {'Day # prefix:','CED filename_ (don''t include *_lick, etc):', 'Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Exclusion Criteria Version', 'Animal Name'};
	dlg_title = 'Inputs';
	num_lines = 1;
	defaultans = {'18','b3_day18_0ms_allop','1', 'op', '0', '1', 'B3'};
	answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
	daynum_ = answer_{1};
	filename_ = answer_{2};
	headernum_ = answer_{3};
	exptype_ = answer_{4};
	rxnwin_ = str2double(answer_{5});
	exclusion_criteria_version_ = answer_{6};
	mousename_ = answer_{7};
	disp('Collecting user input complete')



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





[DLS_times_by_trial, DLS_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(DLS_times,...
																					 DLS_values,...
																					 trial_start_times,...
																					 cue_on_times);
[SNc_times_by_trial, SNc_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(SNc_times,...
																					 SNc_values,...
																					 trial_start_times,...
																					 cue_on_times);





%% Nao method of dF/F


%% For each trial, grab the average of the last second of the ITI (exclude trial #1):


% Array of Nao F0's
Nao_baseline_by_trial_DLS = NaN(num_trials, 18501);
Nao_baseline_by_trial_SNc = NaN(num_trials, 18501);

for i_trial = 2:num_trials
	Nao_baseline_by_trial_DLS(i_trial) = nanmean(DLS_values_by_trial((i_trial-1), 17500:end));
	Nao_baseline_by_trial_SNc(i_trial) = nanmean(SNc_values_by_trial((i_trial-1), 17500:end));
end



%% Now apply F0:
% Fvalue - F0
dF = NaN(size(DLS_values_by_trial));
dF_F = NaN(size(DLS_values_by_trial));
for i_trial = 2:num_trials
	dF_DLS(i_trial, :) = DLS_values_by_trial(i_trial, :) - Nao_baseline_by_trial_DLS(i_trial);
	dF_F_DLS(i_trial, :) = dF_DLS(i_trial, :) ./ Nao_baseline_by_trial_DLS(i_trial);
	dF_SNc(i_trial, :) = SNc_values_by_trial(i_trial, :) - Nao_baseline_by_trial_SNc(i_trial);
	dF_F_SNc(i_trial, :) = dF_SNc(i_trial, :) ./ Nao_baseline_by_trial_SNc(i_trial);
end


DLS_values_by_trial_original = DLS_values_by_trial;
SNc_values_by_trial_original = SNc_values_by_trial;
DLS_values_by_trial = dF_F_DLS;
SNc_values_by_trial = dF_F_SNc;








[lick_times_by_trial] = lick_times_by_trial_fx(lick_times,cue_on_times, total_trial_duration_in_sec, num_trials);
		[f_lick_rxn, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, ~, ~, all_first_licks] = first_lick_grabber_operant_fx_0msv(lick_times_by_trial, num_trials);


%% 
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
		    	error('Redo exclusion and proceed from line 99')
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



	%%    
    [DLS_values_by_trial_fi, DLS_ex_values_by_trial_fi,DLS_values_by_trial_fi_trim, DLS_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx_WEIRD_FIX_Mr8comp(DLS_values_by_trial, DLS_ex_values_by_trial, num_trials);
	[SNc_values_by_trial_fi, SNc_ex_values_by_trial_fi,SNc_values_by_trial_fi_trim, SNc_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx_WEIRD_FIX_Mr8comp(SNc_values_by_trial, SNc_ex_values_by_trial, num_trials);
			%%
            [f_ex_lick_rxn, f_ex_lick_operant_no_rew, f_ex_lick_operant_rew, f_ex_lick_ITI, ~, ~, all_ex_first_licks] = first_lick_grabber_operant_fx_0msv(lick_ex_times_by_trial, num_trials);


				time_binner_op_0_roadmapv1MOVING
				LTA_extractor_overlay_op_roadmapv1MOVING
				LTA_time_binner_op_roadmapv1MOVING
				plot_to_lick_roadmapv1MOVING
				hxgram_single_roadmapv1