% Roadmap TIME BINNER FOR OPERANT, 500ms-----------------------------------------------------------------------
% 
% UPDATE LOG:
% 	10-3-17: Fixed smooth windows, etc
%   8-10-17: Updated legend config
% 	8-01-17: Roadmap version created from 7-24-17 version of time_binner_fx_500op
% 	7-14-17: For use with 500ms rxn time operant only
% 	7-21-17: Updated to match 300 and 0ms operant versions - corrected some bugs
% 
% 	created       6-3-17 ahamilos
% 	last modified 10-3-17 ahamilos
%
% SMOOTH = 50ms gauss
smoothwin = 50; %*********************search smooth -> gausssmooth*****************************************************************
% 
% 
% 	Dependencies:
% 		1. gfitdF_F_fx --> dF/F calculation
%       2. put_data_into_trials_aligned_to_cue_on_fx = SNc_vbt, DLS_vbt
% 		3. lick_times_by_trial_fx = lick_times_by_trial
% 		4. first_lick_grabber_operant = any of the first lick result arrays can be used for f_licks, e.g., f_lick_operant_rew
% 
% ........................................................................................................

%........................................................................................................................................................
cue_on_time = 1500;
% The rest defined wrt cue-on=0, in ms:
rxn_time = 500;
buffer = 200; %realy what the buffer should be is how many ms to exclude from counting operant no rew, thus is rxn+200ms
op_rew_open = 3333;
target_time = 5000;
ITI_time = 7000;
total_time = 17000;

nbins = 5;



% X_ex_values_by_trial = X_ex_values_by_trial;
% Y_ex_values_by_trial = Y_ex_values_by_trial; % *********************
% Z_ex_values_by_trial = Z_ex_values_by_trial; % *********************
% EMG_ex_values_by_trial = EMG_ex_values_by_trial;

f_licks_rxn = f_ex_lick_rxn;
f_licks_early = f_ex_lick_operant_no_rew;
f_licks_oprew = f_ex_lick_operant_rew;
f_licks_ITI = f_ex_lick_ITI;



axisarray = [];


%% RXN CASE------------------------------------------------------------------------------------------
	f_licks = f_licks_rxn;
	% For rxn licks:
	time_bound_1 = (cue_on_time)/1000; % this is cue
	time_bound_2 = (cue_on_time + rxn_time)/1000; % this is 500 post cue

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		X_no_lick_bin(i_rxns, 1:size(X_ex_values_by_trial, 2)) =  X_ex_values_by_trial(trial_positions(i_rxns), :);
		Y_no_lick_bin(i_rxns, 1:size(Y_ex_values_by_trial, 2)) =  Y_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		Z_no_lick_bin(i_rxns, 1:size(Z_ex_values_by_trial, 2)) =  Z_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		EMG_no_lick_bin(i_rxns, 1:size(EMG_ex_values_by_trial, 2)) =  EMG_ex_values_by_trial(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	X_binned_data = {};
	Y_binned_data = {};  % *********************
	Z_binned_data = {};  % *********************
	EMG_binned_data = {};

	X_binned_trial_positions = {};
	Y_binned_trial_positions = {}; % *********************
	Z_binned_trial_positions = {}; % *********************
	EMG_binned_trial_positions = {};

	X_trial_positions_in_current_bin = {};
	Y_trial_positions_in_current_bin = {}; % *********************
	Z_trial_positions_in_current_bin = {}; % *********************
	EMG_trial_positions_in_current_bin = {};
	
	X_pos_in_sorted_array = last_no_lick_position + 1;
	Y_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	Z_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	EMG_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
			Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));	% *********************	    
		    Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
		    EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
			Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2));	% *********************	 
			Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2));	% *********************	 
			EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
			
			X_trial_positions_in_current_bin = trial_positions(X_pos_in_sorted_array:X_pos_in_sorted_array+X_ntrials_bin-1);
			Y_trial_positions_in_current_bin = trial_positions(Y_pos_in_sorted_array:Y_pos_in_sorted_array+Y_ntrials_bin-1); % *********************
			Z_trial_positions_in_current_bin = trial_positions(Z_pos_in_sorted_array:Z_pos_in_sorted_array+Z_ntrials_bin-1); % *********************
		    EMG_trial_positions_in_current_bin = trial_positions(EMG_pos_in_sorted_array:EMG_pos_in_sorted_array+EMG_ntrials_bin-1);
			
			for i_rxns = 1:X_ntrials_bin
				X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
				X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
			end
			for i_rxns = 1:Y_ntrials_bin % *********************
				Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
				Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
			end % *********************
			for i_rxns = 1:Z_ntrials_bin % *********************
				Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
				Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
			end % *********************
		    for i_rxns = 1:EMG_ntrials_bin
		        EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
		        EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
		    end
			X_binned_data{i_bins} = X_current_bin;
			Y_binned_data{i_bins} = Y_current_bin; % *********************
			Z_binned_data{i_bins} = Z_current_bin; % *********************
			EMG_binned_data{i_bins} = EMG_current_bin;
			
			X_binned_trial_positions{i_bins} = X_trial_positions_in_current_bin;
		    Y_binned_trial_positions{i_bins} = Y_trial_positions_in_current_bin; % *********************
		    Z_binned_trial_positions{i_bins} = Z_trial_positions_in_current_bin; % *********************
		    EMG_binned_trial_positions{i_bins} = EMG_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
	Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2)); % *********************
	Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2)); % *********************
	EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	X_binned_trial_positions{end+1} = trial_positions(X_pos_in_sorted_array:end);
	Y_binned_trial_positions{end+1} = trial_positions(Y_pos_in_sorted_array:end); % *********************
	Z_binned_trial_positions{end+1} = trial_positions(Z_pos_in_sorted_array:end); % *********************
	EMG_binned_trial_positions{end+1} = trial_positions(EMG_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:X_ntrials_bin
		X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
		X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:Y_ntrials_bin % *********************
		Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
		Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:Z_ntrials_bin % *********************
		Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
		Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:EMG_ntrials_bin
	    EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
	    EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
	end
	X_binned_data{nbins} = X_current_bin;
	Y_binned_data{nbins} = Y_current_bin; % *********************
	Z_binned_data{nbins} = Z_current_bin; % *********************
	EMG_binned_data{nbins} = EMG_current_bin;


	% Finally, take averages of binned data and plot:
	X_bin_aves = {};
	Y_bin_aves = {}; % *********************
	Z_bin_aves = {}; % *********************
	EMG_bin_aves = {};
	for ibins = 1:nbins
		X_bin_aves{ibins} = nanmean(X_binned_data{ibins},1);
		Y_bin_aves{ibins} = nanmean(Y_binned_data{ibins},1); % *********************
		Z_bin_aves{ibins} = nanmean(Z_binned_data{ibins},1); % *********************
		EMG_bin_aves{ibins} = nanmean(EMG_binned_data{ibins},1);
	end


	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	figure,
	ax = subplot(1,4,1); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(X_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA Rxn - X binned averages');
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,2); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Y_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA Rxn - Y binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,3); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Z_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA Rxn - Z binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,4,4); % *********************
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(EMG_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA Rxn - EMG binned averages');
	xlabel('time (ms)')
	ylabel('signal')








%% EARLY CASE------------------------------------------------------------------------------------------
	f_licks = f_licks_early;
	time_bound_1 = (cue_on_time + rxn_time + buffer)/1000; % this is 700 post cue
	time_bound_2 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue


	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		X_no_lick_bin(i_rxns, 1:size(X_ex_values_by_trial, 2)) =  X_ex_values_by_trial(trial_positions(i_rxns), :);
		Y_no_lick_bin(i_rxns, 1:size(Y_ex_values_by_trial, 2)) =  Y_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		Z_no_lick_bin(i_rxns, 1:size(Z_ex_values_by_trial, 2)) =  Z_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		EMG_no_lick_bin(i_rxns, 1:size(EMG_ex_values_by_trial, 2)) =  EMG_ex_values_by_trial(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	X_binned_data = {};
	Y_binned_data = {};  % *********************
	Z_binned_data = {};  % *********************
	EMG_binned_data = {};

	X_binned_trial_positions = {};
	Y_binned_trial_positions = {}; % *********************
	Z_binned_trial_positions = {}; % *********************
	EMG_binned_trial_positions = {};

	X_trial_positions_in_current_bin = {};
	Y_trial_positions_in_current_bin = {}; % *********************
	Z_trial_positions_in_current_bin = {}; % *********************
	EMG_trial_positions_in_current_bin = {};
	
	X_pos_in_sorted_array = last_no_lick_position + 1;
	Y_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	Z_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	EMG_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
			Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));	% *********************	    
		    Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
		    EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
			Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2));	% *********************	 
			Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2));	% *********************	 
			EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
			
			X_trial_positions_in_current_bin = trial_positions(X_pos_in_sorted_array:X_pos_in_sorted_array+X_ntrials_bin-1);
			Y_trial_positions_in_current_bin = trial_positions(Y_pos_in_sorted_array:Y_pos_in_sorted_array+Y_ntrials_bin-1); % *********************
			Z_trial_positions_in_current_bin = trial_positions(Z_pos_in_sorted_array:Z_pos_in_sorted_array+Z_ntrials_bin-1); % *********************
		    EMG_trial_positions_in_current_bin = trial_positions(EMG_pos_in_sorted_array:EMG_pos_in_sorted_array+EMG_ntrials_bin-1);
			
			for i_rxns = 1:X_ntrials_bin
				X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
				X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
			end
			for i_rxns = 1:Y_ntrials_bin % *********************
				Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
				Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
			end % *********************
			for i_rxns = 1:Z_ntrials_bin % *********************
				Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
				Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
			end % *********************
		    for i_rxns = 1:EMG_ntrials_bin
		        EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
		        EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
		    end
			X_binned_data{i_bins} = X_current_bin;
			Y_binned_data{i_bins} = Y_current_bin; % *********************
			Z_binned_data{i_bins} = Z_current_bin; % *********************
			EMG_binned_data{i_bins} = EMG_current_bin;
			
			X_binned_trial_positions{i_bins} = X_trial_positions_in_current_bin;
		    Y_binned_trial_positions{i_bins} = Y_trial_positions_in_current_bin; % *********************
		    Z_binned_trial_positions{i_bins} = Z_trial_positions_in_current_bin; % *********************
		    EMG_binned_trial_positions{i_bins} = EMG_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
	Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2)); % *********************
	Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2)); % *********************
	EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	X_binned_trial_positions{end+1} = trial_positions(X_pos_in_sorted_array:end);
	Y_binned_trial_positions{end+1} = trial_positions(Y_pos_in_sorted_array:end); % *********************
	Z_binned_trial_positions{end+1} = trial_positions(Z_pos_in_sorted_array:end); % *********************
	EMG_binned_trial_positions{end+1} = trial_positions(EMG_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:X_ntrials_bin
		X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
		X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:Y_ntrials_bin % *********************
		Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
		Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:Z_ntrials_bin % *********************
		Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
		Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:EMG_ntrials_bin
	    EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
	    EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
	end
	X_binned_data{nbins} = X_current_bin;
	Y_binned_data{nbins} = Y_current_bin; % *********************
	Z_binned_data{nbins} = Z_current_bin; % *********************
	EMG_binned_data{nbins} = EMG_current_bin;


	% Finally, take averages of binned data and plot:
	X_bin_aves = {};
	Y_bin_aves = {}; % *********************
	Z_bin_aves = {}; % *********************
	EMG_bin_aves = {};
	for ibins = 1:nbins
		X_bin_aves{ibins} = nanmean(X_binned_data{ibins},1);
		Y_bin_aves{ibins} = nanmean(Y_binned_data{ibins},1); % *********************
		Z_bin_aves{ibins} = nanmean(Z_binned_data{ibins},1); % *********************
		EMG_bin_aves{ibins} = nanmean(EMG_binned_data{ibins},1);
	end


	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	figure,
	ax = subplot(1,4,1); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(X_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA EARLY - X binned averages');
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,2); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Y_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA EARLY - Y binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,3); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Z_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA EARLY - Z binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,4,4); % *********************
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(EMG_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA EARLY - EMG binned averages');
	xlabel('time (ms)')
	ylabel('signal')







%% REWARDED OPERANT CASE------------------------------------------------------------------------------------------
	f_licks = f_licks_oprew;
	time_bound_1 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
	time_bound_2 = (cue_on_time + ITI_time)/1000; % this is 7000 post cue


	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		X_no_lick_bin(i_rxns, 1:size(X_ex_values_by_trial, 2)) =  X_ex_values_by_trial(trial_positions(i_rxns), :);
		Y_no_lick_bin(i_rxns, 1:size(Y_ex_values_by_trial, 2)) =  Y_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		Z_no_lick_bin(i_rxns, 1:size(Z_ex_values_by_trial, 2)) =  Z_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		EMG_no_lick_bin(i_rxns, 1:size(EMG_ex_values_by_trial, 2)) =  EMG_ex_values_by_trial(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:
	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	X_binned_data = {};
	Y_binned_data = {};  % *********************
	Z_binned_data = {};  % *********************
	EMG_binned_data = {};

	X_binned_trial_positions = {};
	Y_binned_trial_positions = {}; % *********************
	Z_binned_trial_positions = {}; % *********************
	EMG_binned_trial_positions = {};

	X_trial_positions_in_current_bin = {};
	Y_trial_positions_in_current_bin = {}; % *********************
	Z_trial_positions_in_current_bin = {}; % *********************
	EMG_trial_positions_in_current_bin = {};
	
	X_pos_in_sorted_array = last_no_lick_position + 1;
	Y_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	Z_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	EMG_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
			Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));	% *********************	    
		    Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
		    EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
			Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2));	% *********************	 
			Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2));	% *********************	 
			EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
			
			X_trial_positions_in_current_bin = trial_positions(X_pos_in_sorted_array:X_pos_in_sorted_array+X_ntrials_bin-1);
			Y_trial_positions_in_current_bin = trial_positions(Y_pos_in_sorted_array:Y_pos_in_sorted_array+Y_ntrials_bin-1); % *********************
			Z_trial_positions_in_current_bin = trial_positions(Z_pos_in_sorted_array:Z_pos_in_sorted_array+Z_ntrials_bin-1); % *********************
		    EMG_trial_positions_in_current_bin = trial_positions(EMG_pos_in_sorted_array:EMG_pos_in_sorted_array+EMG_ntrials_bin-1);
			
			for i_rxns = 1:X_ntrials_bin
				X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
				X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
			end
			for i_rxns = 1:Y_ntrials_bin % *********************
				Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
				Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
			end % *********************
			for i_rxns = 1:Z_ntrials_bin % *********************
				Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
				Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
			end % *********************
		    for i_rxns = 1:EMG_ntrials_bin
		        EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
		        EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
		    end
			X_binned_data{i_bins} = X_current_bin;
			Y_binned_data{i_bins} = Y_current_bin; % *********************
			Z_binned_data{i_bins} = Z_current_bin; % *********************
			EMG_binned_data{i_bins} = EMG_current_bin;
			
			X_binned_trial_positions{i_bins} = X_trial_positions_in_current_bin;
		    Y_binned_trial_positions{i_bins} = Y_trial_positions_in_current_bin; % *********************
		    Z_binned_trial_positions{i_bins} = Z_trial_positions_in_current_bin; % *********************
		    EMG_binned_trial_positions{i_bins} = EMG_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
	Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2)); % *********************
	Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2)); % *********************
	EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	X_binned_trial_positions{end+1} = trial_positions(X_pos_in_sorted_array:end);
	Y_binned_trial_positions{end+1} = trial_positions(Y_pos_in_sorted_array:end); % *********************
	Z_binned_trial_positions{end+1} = trial_positions(Z_pos_in_sorted_array:end); % *********************
	EMG_binned_trial_positions{end+1} = trial_positions(EMG_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:X_ntrials_bin
		X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
		X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:Y_ntrials_bin % *********************
		Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
		Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:Z_ntrials_bin % *********************
		Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
		Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:EMG_ntrials_bin
	    EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
	    EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
	end
	X_binned_data{nbins} = X_current_bin;
	Y_binned_data{nbins} = Y_current_bin; % *********************
	Z_binned_data{nbins} = Z_current_bin; % *********************
	EMG_binned_data{nbins} = EMG_current_bin;


	% Finally, take averages of binned data and plot:
	X_bin_aves = {};
	Y_bin_aves = {}; % *********************
	Z_bin_aves = {}; % *********************
	EMG_bin_aves = {};
	for ibins = 1:nbins
		X_bin_aves{ibins} = nanmean(X_binned_data{ibins},1);
		Y_bin_aves{ibins} = nanmean(Y_binned_data{ibins},1); % *********************
		Z_bin_aves{ibins} = nanmean(Z_binned_data{ibins},1); % *********************
		EMG_bin_aves{ibins} = nanmean(EMG_binned_data{ibins},1);
	end


	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	figure,
	ax = subplot(1,4,1); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(X_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA OPrew - X binned averages');
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,2); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Y_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA OPrew - Y binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,3); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Z_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA OPrew - Z binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,4,4); % *********************
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(EMG_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA OPrew - EMG binned averages');
	xlabel('time (ms)')
	ylabel('signal')





%% ITI CASE-------------------------------------------------------------------------------------------------
	f_licks = f_licks_ITI;
	time_bound_1 = (cue_on_time + ITI_time)/1000; % this is 7000 post cue
	time_bound_2 = (cue_on_time + total_time)/1000; % this is 17000 post cue


	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		X_no_lick_bin(i_rxns, 1:size(X_ex_values_by_trial, 2)) =  X_ex_values_by_trial(trial_positions(i_rxns), :);
		Y_no_lick_bin(i_rxns, 1:size(Y_ex_values_by_trial, 2)) =  Y_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		Z_no_lick_bin(i_rxns, 1:size(Z_ex_values_by_trial, 2)) =  Z_ex_values_by_trial(trial_positions(i_rxns), :); % *********************
		EMG_no_lick_bin(i_rxns, 1:size(EMG_ex_values_by_trial, 2)) =  EMG_ex_values_by_trial(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	X_binned_data = {};
	Y_binned_data = {};  % *********************
	Z_binned_data = {};  % *********************
	EMG_binned_data = {};

	X_binned_trial_positions = {};
	Y_binned_trial_positions = {}; % *********************
	Z_binned_trial_positions = {}; % *********************
	EMG_binned_trial_positions = {};

	X_trial_positions_in_current_bin = {};
	Y_trial_positions_in_current_bin = {}; % *********************
	Z_trial_positions_in_current_bin = {}; % *********************
	EMG_trial_positions_in_current_bin = {};
	
	X_pos_in_sorted_array = last_no_lick_position + 1;
	Y_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	Z_pos_in_sorted_array = last_no_lick_position + 1; % *********************
	EMG_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
			Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));	% *********************	    
		    Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
		    EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
			Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2));	% *********************	 
			Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2));	% *********************	 
			EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
			
			X_trial_positions_in_current_bin = trial_positions(X_pos_in_sorted_array:X_pos_in_sorted_array+X_ntrials_bin-1);
			Y_trial_positions_in_current_bin = trial_positions(Y_pos_in_sorted_array:Y_pos_in_sorted_array+Y_ntrials_bin-1); % *********************
			Z_trial_positions_in_current_bin = trial_positions(Z_pos_in_sorted_array:Z_pos_in_sorted_array+Z_ntrials_bin-1); % *********************
		    EMG_trial_positions_in_current_bin = trial_positions(EMG_pos_in_sorted_array:EMG_pos_in_sorted_array+EMG_ntrials_bin-1);
			
			for i_rxns = 1:X_ntrials_bin
				X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
				X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
			end
			for i_rxns = 1:Y_ntrials_bin % *********************
				Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
				Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
			end % *********************
			for i_rxns = 1:Z_ntrials_bin % *********************
				Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
				Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
			end % *********************
		    for i_rxns = 1:EMG_ntrials_bin
		        EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
		        EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
		    end
			X_binned_data{i_bins} = X_current_bin;
			Y_binned_data{i_bins} = Y_current_bin; % *********************
			Z_binned_data{i_bins} = Z_current_bin; % *********************
			EMG_binned_data{i_bins} = EMG_current_bin;
			
			X_binned_trial_positions{i_bins} = X_trial_positions_in_current_bin;
		    Y_binned_trial_positions{i_bins} = Y_trial_positions_in_current_bin; % *********************
		    Z_binned_trial_positions{i_bins} = Z_trial_positions_in_current_bin; % *********************
		    EMG_binned_trial_positions{i_bins} = EMG_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	X_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	Y_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	Z_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end)); % *********************
	EMG_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	X_current_bin = NaN(X_ntrials_bin, size(X_ex_values_by_trial,2));
	Y_current_bin = NaN(Y_ntrials_bin, size(Y_ex_values_by_trial,2)); % *********************
	Z_current_bin = NaN(Z_ntrials_bin, size(Z_ex_values_by_trial,2)); % *********************
	EMG_current_bin = NaN(EMG_ntrials_bin, size(EMG_ex_values_by_trial,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	X_binned_trial_positions{end+1} = trial_positions(X_pos_in_sorted_array:end);
	Y_binned_trial_positions{end+1} = trial_positions(Y_pos_in_sorted_array:end); % *********************
	Z_binned_trial_positions{end+1} = trial_positions(Z_pos_in_sorted_array:end); % *********************
	EMG_binned_trial_positions{end+1} = trial_positions(EMG_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:X_ntrials_bin
		X_current_bin(i_rxns, :) = X_ex_values_by_trial(trial_positions(X_pos_in_sorted_array), :);
		X_pos_in_sorted_array = X_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:Y_ntrials_bin % *********************
		Y_current_bin(i_rxns, :) = Y_ex_values_by_trial(trial_positions(Y_pos_in_sorted_array), :); % *********************
		Y_pos_in_sorted_array = Y_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:Z_ntrials_bin % *********************
		Z_current_bin(i_rxns, :) = Z_ex_values_by_trial(trial_positions(Z_pos_in_sorted_array), :); % *********************
		Z_pos_in_sorted_array = Z_pos_in_sorted_array + 1; % *********************
	end % *********************
	for i_rxns = 1:EMG_ntrials_bin
	    EMG_current_bin(i_rxns, :) = EMG_ex_values_by_trial(trial_positions(EMG_pos_in_sorted_array), :);
	    EMG_pos_in_sorted_array = EMG_pos_in_sorted_array + 1;
	end
	X_binned_data{nbins} = X_current_bin;
	Y_binned_data{nbins} = Y_current_bin; % *********************
	Z_binned_data{nbins} = Z_current_bin; % *********************
	EMG_binned_data{nbins} = EMG_current_bin;


	% Finally, take averages of binned data and plot:
	X_bin_aves = {};
	Y_bin_aves = {}; % *********************
	Z_bin_aves = {}; % *********************
	EMG_bin_aves = {};
	for ibins = 1:nbins
		X_bin_aves{ibins} = nanmean(X_binned_data{ibins},1);
		Y_bin_aves{ibins} = nanmean(Y_binned_data{ibins},1); % *********************
		Z_bin_aves{ibins} = nanmean(Z_binned_data{ibins},1); % *********************
		EMG_bin_aves{ibins} = nanmean(EMG_binned_data{ibins},1);
	end


	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	figure,
	ax = subplot(1,4,1); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(X_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA ITI - X binned averages');
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,2); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Y_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA ITI - Y binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')

	ax = subplot(1,4,3); % *********************
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(Z_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3); % *********************
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA ITI - Z binned averages'); % *********************
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,4,4); % *********************
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(gausssmooth(EMG_bin_aves{ibins}, smoothwin, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA ITI - EMG binned averages');
	xlabel('time (ms)')
	ylabel('signal')





%% Link all axes
	linkaxes(axisarray, 'xy');

