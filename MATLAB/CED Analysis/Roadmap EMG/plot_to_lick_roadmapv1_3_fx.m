function [signal_ex_values_up_to_lick] = plot_to_lick_roadmapv1_3_fx(signal_vbt,Hz,all_ex_first_licks,time_array, early_signal_lick_triggered_trials, rew_signal_lick_triggered_trials, f_licks_early, f_licks_oprew, signalname)
%
% Input should be signal_vbt = signal_ex_values_by_trial_fi_trim
%

%-------------Plot up until Lick Time - any combo of first-licks--------------------
% 
%  Designed for use with 500ms op - but will work ok with any op I think
%  Right now will plot rew and early together as default
% 
% Created   8-08-17 ahamilos (from plot_to_lick_roadmapv1.m)
% Modified 10-30-17 ahamilos
% 
% UPDATE LOG:
% 	-10-30-17: Made general for photom and movement inputs
% 	-9-04-17: disambiguated smooth method (gausssmooth.m)
% 	-8-10-17: modified for use with roadmapv1 - small fixes, 400ms (200 ea side) mean window for points
% 
%  Based on:
% 		-extract_values_up_to_lick_fx.m
% 
% 
	% Hz = 1000; % sampling rate ****************************************************************************
    sample_scaling_factor = Hz/1000; % this is what will be used to transform time in ms to samples at the sampling rate *********************
%
	smooth_kernel = 50;
	nbins = 5;

	cue_on_time = 1500*sample_scaling_factor;

	time_bound_1_early = (cue_on_time + 700*sample_scaling_factor)/1000;
	time_bound_2_early = (cue_on_time + 3333*sample_scaling_factor)/1000;
	time_bound_1_rew = (cue_on_time + 3333*sample_scaling_factor)/1000; 
	time_bound_2_rew = (cue_on_time + 5000*sample_scaling_factor)/1000;%(cue_on_time + 7000)/1000;

	time_bound_1_plot = time_bound_1_early;
	time_bound_2_plot = time_bound_2_rew;


	target_time = 5000*sample_scaling_factor;
	total_time = 17000*sample_scaling_factor;
	axisarray = [];
% 
% 
% -----------------------------------------------------------------------------------




%% DEBUG-----------------------------------
	% % all_first_licks = all_ex_first_licks;
	% % f_ex_lick_rxn = f_ex_lick_rxn;
	% f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;
	% f_ex_lick_operant_rew = f_ex_lick_operant_rew;
	% % f_ex_lick_ITI = f_ex_lick_ITI;
	% time_array = time_array;
	% early_signal_lick_triggered_trials = early_signal_lick_triggered_trials;
	% rew_signal_lick_triggered_trials = rew_signal_lick_triggered_trials;
	% early_SNc_lick_triggered_trials = early_SNc_lick_triggered_trials;
	% rew_SNc_lick_triggered_trials = rew_SNc_lick_triggered_trials;
	%-----------------------------------------



signal_ex_values_up_to_lick = NaN(size(signal_vbt));


% Clip data to up to lick time---------------------------------------------------------------

	for i_trial = 1:length(all_ex_first_licks)
		if all_ex_first_licks(i_trial) == 0
			% skip this one bc is rxn train abort, so all_first_licks == 0
		else		
			cutoff = floor((all_ex_first_licks(i_trial)*1000*sample_scaling_factor));
			signal_ex_values_up_to_lick(i_trial,1:cutoff) = signal_vbt(i_trial, 1:cutoff);
		end
	end


% CTA initialization:
	signal_vbt = signal_ex_values_up_to_lick;
	all_samples_in_ms = size(signal_vbt, 2);
	time_array_in_ms = [1:all_samples_in_ms]/sample_scaling_factor;

% 	f_licks_rxn = f_ex_lick_rxn;
	% f_licks_early = f_ex_lick_operant_no_rew;
	% f_licks_oprew = f_ex_lick_operant_rew;
% 	f_licks_ITI = f_ex_lick_ITI;


% LTA Initialization:
	xwin = [-7000, 0];
	pos1 = find(time_array==xwin(1));
	pos2 = find(time_array==xwin(2)); 
	dataSetEarlyAndRewsignal = cat(3,early_signal_lick_triggered_trials, rew_signal_lick_triggered_trials);
	dataSetEarlyAndRewsignal = nansum(dataSetEarlyAndRewsignal,3);

	
	axisarray2 = [];









%.CTA up to lick time.................................................................................................................................................


%% COMBINED (ALL OPERANTS) CASE------------------------------------------------------------------------------------------
	f_licks_early_and_rew = f_licks_early.*sample_scaling_factor + f_licks_oprew.*sample_scaling_factor; 
	time_bound_1 = time_bound_1_plot; % this is 700 post cue
	time_bound_2 = time_bound_2_plot; % this is 5000 post cue
	

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_early_and_rew;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_early_and_rew));

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
    
    
    % This must advance further to match the time bounds. so find the
    % min position in the sorted array greater than time_bound_1
	signal_pos_in_sorted_array = min(find(sorted_times > time_bound_1));
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

	% Create the legend names (times in each bin wrt cue on)
	startpos = time_bound_1/sample_scaling_factor-1.5;
	endpos = time_bound_1/sample_scaling_factor - 1.5 + time_in_ea_bin/sample_scaling_factor;
	names = {};
	names{1} = 'cue on';
	names{2} = 'target';
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin/sample_scaling_factor;
		endpos = endpos + time_in_ea_bin/sample_scaling_factor;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end

	% Only plot up to begin of bin-------------
	binstart = time_bound_1_early;
	binendnum = time_bound_1_early;


	bin_ends = NaN(nbins, 2);
	for ibin = 1:nbins
		bin_ends(ibin, 1) = 0.001;
		bin_ends(ibin, 2) = binendnum;
		binendnum = binendnum + time_in_ea_bin;
	end
	bin_ends = (bin_ends*1000);
	%-----------------------


	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time-1500, cue_on_time-1500], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time-1500+target_time-1500, cue_on_time-1500+target_time-1500], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
		posa = bin_ends(ibins, 1);
		posb = bin_ends(ibins, 2);
		fxn = signal_bin_aves{ibins}(posa:posb);
		disp(length(posb-posa + 1))
		disp(length(fxn))
		% plot([1:size(fxn, 2)] - 1500, gausssmooth(fxn, smooth_kernel, 'gauss'), 'linewidth', 1);
		% plot(time_array_in_ms(1:(posb-posa)+1), gausssmooth(fxn, smooth_kernel, 'gauss'), 'linewidth', 1);
	end
	legend(names);
	ylim([-1,1])
	xlim([-1500,cue_on_time + total_time-1500])
	title(['CTA All Operants - ', signalname, ' binned averages']);
	xlabel('time (ms)')
	ylabel('signal')





%% Link all axes
	linkaxes(axisarray, 'xy');







%% ----------------- CTA: plot the aves around peak and trough for each bin:

	signal_min_ave = NaN(1,nbins);
	signal_max_ave = NaN(1,nbins);
	signal_minpos = NaN(1,nbins);
	signal_maxpos = NaN(1,nbins);


	% signal_minpositions = find(signal_bin_aves{1}(1500:end) == min(signal_bin_aves{1}(1500:end)));

	for ibins = 1:nbins
		signal_holder_min = signal_bin_aves{ibins}(1500:end);
		signal_holder_min = gausssmooth(signal_holder_min, smooth_kernel, 'gauss');
		
		signal_holder_max = signal_bin_aves{ibins}(2000:end);
		signal_holder_max = gausssmooth(signal_holder_max, smooth_kernel, 'gauss');


		[~,signal_minpos(ibins)] = min(signal_holder_min);
		[~,signal_maxpos(ibins)] = max(signal_holder_max);
		signal_binpos1 = signal_minpos(ibins) - 200 + 1500;
		signal_binpos2 = signal_minpos(ibins) + 200 + 1500;
		signal_binpos3 = signal_maxpos(ibins) - 200 + 1500;
		signal_binpos4 = signal_maxpos(ibins) + 200 + 1500;

		signal_min_ave(ibins) = nanmean(signal_bin_aves{ibins}(signal_binpos1:signal_binpos2));
		signal_max_ave(ibins) = nanmean(signal_bin_aves{ibins}(signal_binpos3:signal_binpos4));
	end

	signal_minpos = signal_minpos + 1500;
	signal_maxpos = signal_maxpos + 2000;


	figure,
	ax = subplot(1,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
        plot([signal_minpos(ibins), signal_maxpos(ibins)], [signal_min_ave(ibins), signal_max_ave(ibins)], '.-', 'markersize', 30);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title(['CTA All Operants - ', signalname ' binned peak/trough averages']);
	xlabel('time (ms)')
	ylabel('signal')



%% Link all axes
	linkaxes(axisarray, 'xy');










%%-------------------------------------LTA:-----------------------------------------------------------
%% EARLY and REW CASE:---------------------------------------------
	signal_vbt = dataSetEarlyAndRewsignal;
	time_bound_1 = time_bound_1_plot;
	time_bound_2 = time_bound_2_plot;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	early_and_rew_times_with_trial_markers = f_licks_early_and_rew;
	early_and_rew_times_with_trial_markers(2, :) = (1:length(f_licks_early_and_rew));

	[sorted_times,trial_positions]=sort(early_and_rew_times_with_trial_markers(1,:));

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

	
	% plot_bin_aves_fx(signal_bin_aves, SNc_bin_aves, nbins) 
	% axisarray = [];
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






	figure,
	ax = subplot(1,1,1);
	axisarray2(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 1)
	for ibins = 1:nbins
		% disp(pos1)
  %       disp(pos2)
  %       disp(length(time_array(pos1:pos2)))
  %       disp(length(signal_bin_aves{ibins}))
		plot((time_array(pos1:pos2)), gausssmooth(signal_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 1);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title([signalname, ' All Operant LTA Binned Averages']);
	xlabel('time (ms)')
	ylabel('signal')


	linkaxes(axisarray2, 'xy')
