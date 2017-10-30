function [] = LTA_photom_time_binner_hyb_roadmap1_3_fx(time_array,...
												Hz,...
												dataSetRxnsignal,...
												dataSetEarlysignal,...
												dataSetRewsignal,...
												dataSetPavsignal,...
												dataSetITIsignal,...
												f_licks_rxn,...
												f_licks_early,...
												f_licks_oprew,...
												f_licks_pav,...
												f_licks_ITI,...
												signalname)


%---------Roadmapv1 LTA Time Binner (analogous for CTA time_binner_fx.m)----------------------
% 	Based on LTA_time_binner_v1_op0ms.m -- should work fine for any hyb version
% 
% 	created       7-31-17 ahamilos
% 	last modified 10-28-17 ahamilos (from LTA_time_binner_hyb_roadmapv1.m)
%
% UPDATE LOG
%  10-28-17: Updated to take any sampling rate input
%  10-27-17: Modified to be generic for any photom input, updated smoothing window 
%	8-10-17: Updated Legend Names to Match Times in Bin
% 
% 	Dependencies:
% 		1. lick_triggered_ave_allplots_fx.m
% 
%  SMOOTH = 50ms gausssmooth(
	smoothwin = 50;
% 
% ........................................................................................................

%........................................................................................................................................................
% time_array = time_array;
% dataSetRxnsignal = rxn_signal_lick_triggered_trials;
% dataSetEarlysignal = early_signal_lick_triggered_trials;
% dataSetRewsignal = rew_signal_lick_triggered_trials;
% dataSetPavsignal = pav_signal_lick_triggered_trials;
% dataSetITIsignal = ITI_signal_lick_triggered_trials;
	% Hz = 2000; % sampling rate ****************************************************************************
	sample_scaling_factor = Hz/1000; % this is what will be used to transform time in ms to samples at the sampling rate *********************


	nbins = 5; % divide the trials into n_divs # of bins

% f_licks_rxn = f_ex_lick_rxn;
% f_licks_early = f_ex_lick_operant_no_rew;
% f_licks_oprew = f_ex_lick_operant_rew;
% f_licks_pav = f_ex_lick_pavlovian;
% f_licks_ITI = f_ex_lick_ITI;

	cue_on_time = 1500*sample_scaling_factor;
	time_bound_1_rxn = (cue_on_time + 0*sample_scaling_factor)/1000; % must be in terms of ms to match lick times in sec
	time_bound_2_rxn = (cue_on_time + 500*sample_scaling_factor)/1000;
	time_bound_1_early = (cue_on_time + 700*sample_scaling_factor)/1000;
	time_bound_2_early = (cue_on_time + 3333*sample_scaling_factor)/1000;
	time_bound_1_rew = (cue_on_time + 3333*sample_scaling_factor)/1000; 
	time_bound_2_rew = (cue_on_time + 5100*sample_scaling_factor)/1000;
	time_bound_1_pav = (cue_on_time + 5100*sample_scaling_factor)/1000; 
	time_bound_2_pav = (cue_on_time + 7000*sample_scaling_factor)/1000;
	time_bound_1_ITI = (cue_on_time + 7000*sample_scaling_factor)/1000; 
	time_bound_2_ITI = (cue_on_time + 17000*sample_scaling_factor)/1000;


	xwin = [-7000, 4000];
	pos1 = find(time_array==xwin(1));
	pos2 = find(time_array==xwin(2)); 

%% RXN CASE:---------------------------------------------
	signal_vbt = dataSetRxnsignal;
	time_bound_1 = time_bound_1_rxn;
	time_bound_2 = time_bound_2_rxn;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_rxn.*sample_scaling_factor;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_rxn));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
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
	
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	signal_binned_trial_positions = {};
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
	names{1} = 'lick time';
	names{2} = 'zero';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end
	
	% plot_bin_aves_fx(signal_bin_aves, SNc_bin_aves, nbins) 
	linkarray = [];
	% // names{1} = 'lick time';
	% // names{2} = 'zero';
	figure,
	ax = subplot(1,1,1);
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), gausssmooth((signal_bin_aves{ibins}(pos1:pos2), smoothwin, 'gauss'), 'linewidth', 3);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title([signalname, ' Reaction LTA Binned Averages']);
	xlabel('time (ms)')
	ylabel('signal')


	linkaxes(linkarray, 'xy')







%% EARLY CASE:---------------------------------------------
	signal_vbt = dataSetEarlysignal;
	time_bound_1 = time_bound_1_early;
	time_bound_2 = time_bound_2_early;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_early.*sample_scaling_factor;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_early));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
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
	
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	signal_binned_trial_positions = {};
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
	names{1} = 'lick time';
	names{2} = 'zero';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end
	
	% plot_bin_aves_fx(signal_bin_aves, SNc_bin_aves, nbins) 
	linkarray = [];
	% // names{1} = 'lick time';
	% // names{2} = 'zero';
	figure,
	ax = subplot(1,1,1);
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), gausssmooth((signal_bin_aves{ibins}(pos1:pos2), smoothwin, 'gauss'), 'linewidth', 3);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title([signalname, ' Early LTA Binned Averages']);
	xlabel('time (ms)')
	ylabel('signal')



%% REW CASE---------------------------------------------
	signal_vbt = dataSetRewsignal;
	time_bound_1 = time_bound_1_rew;
	time_bound_2 = time_bound_2_rew;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_oprew.*sample_scaling_factor;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_oprew));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
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
	
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	signal_binned_trial_positions = {};
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
	names{1} = 'lick time';
	names{2} = 'zero';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	% plot_bin_aves_fx(signal_bin_aves, SNc_bin_aves, nbins) 
	% linkarray = [];
	% names{1} = 'lick time';
	% names{2} = 'zero';
	figure,
	ax = subplot(1,1,1);
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), gausssmooth((signal_bin_aves{ibins}(pos1:pos2), smoothwin, 'gauss'), 'linewidth', 3);
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title([signalname, ' Rewarded LTA Binned Averages']);
	xlabel('time (ms)')
	ylabel('signal')



%% PAV CASE---------------------------------------------
	signal_vbt = dataSetPavsignal;
	time_bound_1 = time_bound_1_pav;
	time_bound_2 = time_bound_2_pav;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_pav.*sample_scaling_factor;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_pav));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
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
	
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	signal_binned_trial_positions = {};
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
	names{1} = 'lick time';
	names{2} = 'zero';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	% plot_bin_aves_fx(signal_bin_aves, SNc_bin_aves, nbins) 
	% linkarray = [];
	% // names{1} = 'lick time';
	% // names{2} = 'zero';
	figure,
	ax = subplot(1,1,1);
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), gausssmooth((signal_bin_aves{ibins}(pos1:pos2), smoothwin, 'gauss'), 'linewidth', 3);
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title([signalname, ' Pavlovian LTA Binned Averages']);
	xlabel('time (ms)')
	ylabel('signal')




%% ITI CASE:---------------------------------------------
	signal_vbt = dataSetITIsignal;
	time_bound_1 = time_bound_1_ITI;
	time_bound_2 = time_bound_2_ITI;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	ITI_times_with_trial_markers = f_licks_ITI.*sample_scaling_factor;
	ITI_times_with_trial_markers(2, :) = (1:length(f_licks_ITI));

	[sorted_times,trial_positions]=sort(ITI_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
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
	
	signal_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	signal_binned_trial_positions = {};
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
	names{1} = 'lick time';
	names{2} = 'zero';
	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end


	% plot_bin_aves_fx(signal_bin_aves, SNc_bin_aves, nbins) 
	% linkarray = [];
	% names{1} = 'lick time';
	% names{2} = 'zero';
	figure,
	ax = subplot(1,1,1);
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), gausssmooth((signal_bin_aves{ibins}(pos1:pos2), smoothwin, 'gauss'), 'linewidth', 3);
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title([signalname, ' ITI LTA Binned Averages']);
	xlabel('time (ms)')
	ylabel('signal')





%% Link all axes:
	linkaxes(linkarray, 'xy')


end