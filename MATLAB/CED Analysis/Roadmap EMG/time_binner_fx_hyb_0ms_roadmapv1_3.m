function [] = time_binner_fx_hyb_0ms_roadmapv1_3(signal_vbt,Hz,f_licks_rxn,f_licks_early,f_licks_oprew,f_licks_pav,f_licks_ITI, signalname)


% Roadmap TIME BINNER FOR HYBRID, 0ms-----------------------------------------------------------------------
% 
% 10-27-17 update: Added sample_scaling_factor to take movement inputs too
% 10-26-17 update: Made generic function for any input type
% 8-10-17 update: Updated Legend Configuration
% 8-07-17 update: Detected error in pav/oprew window cut off - should be 100ms, not 0.1 ms. Check other programs to fix
% 8-04-17 update: Created 0ms version for B3 - from the hyb (500ms) version 8-01-17
% 8-01-17 update: Roadmap version created from 7-24-17 version of time_binner_fx_hyb
% 7-24-17 update: Corrected to match other time_binner_fx updates from operant only (and new plot binned aves)
% 6-30-17 update: Made specific for Hybrid trials - use for early experiments 
% 
% 	created       6-03-17 ahamilos
% 	last modified 10-27-17 ahamilos
% 
% 
% SMOOTH = 50ms gauss - converted to gausssmooth fx 10-26-17
% 
% 
% 	Dependencies:
% 		1. gfitdF_F_fx --> dF/F calculation
%       2. put_data_into_trials_aligned_to_cue_on_fx = SNc_vbt, signal_vbt
% 		3. lick_times_by_trial_fx = lick_times_by_trial
% 		4. first_lick_grabber = any of the first lick result arrays can be used for f_licks, e.g., f_lick_operant_rew
% 
% 	Notes:
% 		nbins: the first bin is reserved for any trials in the array marked with 0. In f_licks, these are the rxn_train_abort trials. In other arrays, they are all other trial outcomes other than the principle one (e.g., f_lick_operant_rew has 0's for any non-operant rewarded trials)
% 		
% 	Next Steps: (5/22/17) - we want to plot median of each trial in each bin, color coded vs trial number. I'll attempt to do that in this modified file (trial_binner_test_fx)
% 
% ........................................................................................................
	% Hz = 2000; % sampling rate ****************************************************************************
	sample_scaling_factor = Hz/1000; % this is what will be used to transform time in ms to samples at the sampling rate *********************

	%........................................................................................................................................................
	cue_on_time = 1500*sample_scaling_factor;
	% The rest defined wrt cue-on=0, in ms:
	rxn_ok = 0*sample_scaling_factor;
	rxn_time = 500*sample_scaling_factor;
	buffer = 200*sample_scaling_factor; %realy what the buffer should be is how many ms to exclude from counting operant no rew, thus is rxn+200ms
	op_rew_open = 3333*sample_scaling_factor;
	target_time = 5000*sample_scaling_factor;
	ITI_time = 7000*sample_scaling_factor;
	total_time = 17000*sample_scaling_factor;
	nbins = 5;

    all_samples_in_ms = size(signal_vbt, 2);
	time_array_in_ms = [1:all_samples_in_ms]/sample_scaling_factor;


	% signal_vbt = signal_ex_values_by_trial;
	% SNc_vbt = SNc_ex_values_by_trial;

	% f_licks_rxn = f_ex_lick_rxn;
	% f_licks_early = f_ex_lick_operant_no_rew;
	% f_licks_oprew = f_ex_lick_operant_rew;
	% f_licks_pav = f_ex_lick_pavlovian;
	% f_licks_ITI = f_ex_lick_ITI;



	axisarray = [];






%% RXN CASE------------------------------------------------------------------------------------------
	f_licks = f_licks_rxn*sample_scaling_factor;
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
		signal_no_lick_bin(i_rxns, 1:size(signal_vbt, 2)) =  signal_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	signal_binned_data = {};
	signal_binned_trial_positions = {};
	signal_trial_positions_in_current_bin = {};
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
			
			signal_trial_positions_in_current_bin = trial_positions(signal_pos_in_sorted_array:signal_pos_in_sorted_array+signal_ntrials_bin-1);
			
			for i_rxns = 1:signal_ntrials_bin
				signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
				signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
			end
			signal_binned_data{i_bins} = signal_current_bin;
			signal_binned_trial_positions{i_bins} = signal_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	signal_binned_trial_positions{end+1} = trial_positions(signal_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:signal_ntrials_bin
		signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
		signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
	end
	signal_binned_data{nbins} = signal_current_bin;


	% Finally, take averages of binned data and plot:
	signal_bin_aves = {};
	for ibins = 1:nbins
		signal_bin_aves{ibins} = nanmean(signal_binned_data{ibins},1);
	end

	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end	

	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	% names{1} = 'Cue On';
	% names{2} = 'Target Time';
	plot([cue_on_time/sample_scaling_factor, cue_on_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor, cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array_in_ms, gausssmooth(signal_bin_aves{ibins}, 50, 'gauss'), 'linewidth', 3);
		% names{end+1} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time/sample_scaling_factor + total_time/sample_scaling_factor])
	title(['CTA Rxn - ', signalname, ' binned averages']);
	xlabel('time (ms)')
	ylabel('signal')





%% EARLY CASE------------------------------------------------------------------------------------------
	f_licks = f_licks_early*sample_scaling_factor;
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
		signal_no_lick_bin(i_rxns, 1:size(signal_vbt, 2)) =  signal_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	signal_binned_data = {};
	signal_binned_trial_positions = {};
	signal_trial_positions_in_current_bin = {};
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
			
			signal_trial_positions_in_current_bin = trial_positions(signal_pos_in_sorted_array:signal_pos_in_sorted_array+signal_ntrials_bin-1);
			
			for i_rxns = 1:signal_ntrials_bin
				signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
				signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
			end
			signal_binned_data{i_bins} = signal_current_bin;
			signal_binned_trial_positions{i_bins} = signal_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end

	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	signal_binned_trial_positions{end+1} = trial_positions(signal_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:signal_ntrials_bin
		signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
		signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
	end
	signal_binned_data{nbins} = signal_current_bin;



	% Finally, take averages of binned data and plot:
	signal_bin_aves = {};
	for ibins = 1:nbins
		signal_bin_aves{ibins} = nanmean(signal_binned_data{ibins},1);
	end

	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end	


	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time/sample_scaling_factor, cue_on_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor, cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array_in_ms, gausssmooth(signal_bin_aves{ibins}, 50, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time/sample_scaling_factor + total_time/sample_scaling_factor])
	title(['CTA Early - ', signalname, ' binned averages']);
	xlabel('time (ms)')
	ylabel('signal')





%% REWARDED OPERANT CASE------------------------------------------------------------------------------------------
	f_licks = f_licks_oprew*sample_scaling_factor;
	time_bound_1 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
	time_bound_2 = (cue_on_time + target_time + 100)/1000; % this is 5100 post cue *** error fixed 8-7-17


	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		signal_no_lick_bin(i_rxns, 1:size(signal_vbt, 2)) =  signal_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	signal_binned_data = {};
	signal_binned_trial_positions = {};
	signal_trial_positions_in_current_bin = {};
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
			
			signal_trial_positions_in_current_bin = trial_positions(signal_pos_in_sorted_array:signal_pos_in_sorted_array+signal_ntrials_bin-1);
			
			for i_rxns = 1:signal_ntrials_bin
				signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
				signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
			end
			signal_binned_data{i_bins} = signal_current_bin;
			signal_binned_trial_positions{i_bins} = signal_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end

	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	signal_binned_trial_positions{end+1} = trial_positions(signal_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:signal_ntrials_bin
		signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
		signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
	end
	signal_binned_data{nbins} = signal_current_bin;


	% Finally, take averages of binned data and plot:
	signal_bin_aves = {};
	for ibins = 1:nbins
		signal_bin_aves{ibins} = nanmean(signal_binned_data{ibins},1);
	end

	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end	

	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time/sample_scaling_factor, cue_on_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor, cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array_in_ms, gausssmooth(signal_bin_aves{ibins}, 50, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time/sample_scaling_factor + total_time/sample_scaling_factor])
	title(['CTA Op-Rew - ', signalname, ' binned averages']);
	xlabel('time (ms)')
	ylabel('signal')






%% PAVLOVIAN CASE-------------------------------------------------------------------------------------------------
	f_licks = f_licks_pav*sample_scaling_factor;
	time_bound_1 = (cue_on_time + target_time + 100)/1000; % this is 5100 post cue *** error fixed 8-7-17
	time_bound_2 = (cue_on_time + ITI_time)/1000; % this is 7000 post cue


	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		signal_no_lick_bin(i_rxns, 1:size(signal_vbt, 2)) =  signal_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	signal_binned_data = {};
	signal_binned_trial_positions = {};
	signal_trial_positions_in_current_bin = {};
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
			
			signal_trial_positions_in_current_bin = trial_positions(signal_pos_in_sorted_array:signal_pos_in_sorted_array+signal_ntrials_bin-1);
			
			for i_rxns = 1:signal_ntrials_bin
				signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
				signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
			end
			signal_binned_data{i_bins} = signal_current_bin;
			signal_binned_trial_positions{i_bins} = signal_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end

	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	signal_binned_trial_positions{end+1} = trial_positions(signal_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:signal_ntrials_bin
		signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
		signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
	end
	signal_binned_data{nbins} = signal_current_bin;


	% Finally, take averages of binned data and plot:
	signal_bin_aves = {};
	for ibins = 1:nbins
		signal_bin_aves{ibins} = nanmean(signal_binned_data{ibins},1);
	end


	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end	

	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time/sample_scaling_factor, cue_on_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor, cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array_in_ms, gausssmooth(signal_bin_aves{ibins}, 50, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time/sample_scaling_factor + total_time/sample_scaling_factor])
	title(['CTA Pavlovian - ', signalname, ' binned averages']);
	xlabel('time (ms)')
	ylabel('signal')






%% ITI CASE-------------------------------------------------------------------------------------------------
	f_licks = f_licks_ITI*sample_scaling_factor;
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
		signal_no_lick_bin(i_rxns, 1:size(signal_vbt, 2)) =  signal_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	signal_binned_data = {};
	signal_binned_trial_positions = {};
	signal_trial_positions_in_current_bin = {};
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
			
			signal_trial_positions_in_current_bin = trial_positions(signal_pos_in_sorted_array:signal_pos_in_sorted_array+signal_ntrials_bin-1);
			
			for i_rxns = 1:signal_ntrials_bin
				signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
				signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
			end
			signal_binned_data{i_bins} = signal_current_bin;
			signal_binned_trial_positions{i_bins} = signal_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end

	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	signal_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	signal_current_bin = NaN(signal_ntrials_bin, size(signal_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	signal_binned_trial_positions{end+1} = trial_positions(signal_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:signal_ntrials_bin
		signal_current_bin(i_rxns, :) = signal_vbt(trial_positions(signal_pos_in_sorted_array), :);
		signal_pos_in_sorted_array = signal_pos_in_sorted_array + 1;
	end
	signal_binned_data{nbins} = signal_current_bin;


	% Finally, take averages of binned data and plot:
	signal_bin_aves = {};
	for ibins = 1:nbins
		signal_bin_aves{ibins} = nanmean(signal_binned_data{ibins},1);
	end

	% Name bins by times within
	names = {};
	names{1} = 'Cue On';
	names{2} = 'Target Time';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end	

	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time/sample_scaling_factor, cue_on_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor, cue_on_time/sample_scaling_factor+target_time/sample_scaling_factor], [-1,1], 'r-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array_in_ms, gausssmooth(signal_bin_aves{ibins}, 50, 'gauss'), 'linewidth', 3);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time/sample_scaling_factor + total_time/sample_scaling_factor])
	title(['CTA ITI - ', signalname,' binned averages']);
	xlabel('time (ms)')
	ylabel('signal')


%% Link all axes
	linkaxes(axisarray, 'xy');

end



