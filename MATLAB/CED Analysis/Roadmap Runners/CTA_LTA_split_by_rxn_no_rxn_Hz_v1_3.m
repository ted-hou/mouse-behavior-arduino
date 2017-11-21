function [] = CTA_LTA_split_by_rxn_no_rxn_Hz_v1_3(time_array, Hz, all_ex_first_licks, f_ex_lick_rxn, signal_ex_values_by_trial_fi_trim, early_signal_lick_triggered_trials, rew_signal_lick_triggered_trials, signalname)

%% Plot to lick for rxn lick vs no rxn lick:
% 
% 	Intended for operant 500ms rxn window
% 
%  Modified 9-4-17: Disambiguated smooth method (gausssmooth.m)
%           11-15-17: made into fx that can deal with any sampling rate 
% 
smooth_kernel = 50;
nbins = 5;
sample_scaling_factor = Hz/1000; % this is what will be used to transform time in ms to samples at the sampling rate *********************
cue_on_time = 1500*sample_scaling_factor;


time_bound_1_early = (cue_on_time + 700*sample_scaling_factor)/1000;
time_bound_2_early = (cue_on_time + 3333*sample_scaling_factor)/1000;
time_bound_1_rew = (cue_on_time + 3333*sample_scaling_factor)/1000; 
time_bound_2_rew = (cue_on_time + 5000*sample_scaling_factor)/1000;%(cue_on_time + 7000)/1000;

time_bound_1_plot = time_bound_1_early;
time_bound_2_plot = time_bound_2_rew;




% DEBUG===========================================
% [f_ex_licks_with_rxn, f_ex_licks_no_rxn] = rxn_lick_or_no_rxn_lick_fx(d8_all_ex1_first_licks, d8_f_ex1_lick_rxn)
% signal_ex_values_by_trial_fi_trim = d8_signal_ex1_values_by_trial_fi_trim;
% SNc_ex_values_by_trial_fi_trim = d8_SNc_ex1_values_by_trial_fi_trim;
% all_ex_first_licks = d8_all_ex1_first_licks;
% time_array = d8_time_array;
% early_signal_lick_triggered_trials = d8_early_signal_lick_triggered_trials;
% early_SNc_lick_triggered_trials = d8_early_SNc_lick_triggered_trials;
% rew_signal_lick_triggered_trials = d8_rew_signal_lick_triggered_trials;
% rew_SNc_lick_triggered_trials = d8_rew_SNc_lick_triggered_trials;
%=================================================



[f_ex_licks_with_rxn, f_ex_licks_no_rxn] = rxn_lick_or_no_rxn_lick_fx(all_ex_first_licks, f_ex_lick_rxn);

% Plot Hxgram of trials with a rxn lick:
% plus_rxn_licks = f_ex_licks_with_rxn;
% nanswitch = find(plus_rxn_licks == 0);
% plus_rxn_licks(nanswitch) = NaN;
% plus_rxn_licks = plus_rxn_licks - 1.5;

% figure, histogram(plus_rxn_licks, 40)
% ylabel('# of licks/bin')
% xlabel('time (sec)')
% % title('Trials with Rxn Lick')

% % Plot Hxgram of trials with NO rxn lick:
% no_rxn_licks = f_ex_licks_no_rxn;
% nanswitch = find(no_rxn_licks == 0);
% no_rxn_licks(nanswitch) = NaN;
% no_rxn_licks = no_rxn_licks - 1.5;

% hold on, histogram(no_rxn_licks, 40)
% ylabel('# of licks/bin')
% xlabel('time (sec)')
% title('Trials with and without Rxn Lick')
% legend({'Trials With Rxn', 'Trials Without Rxn'})






signal_vbt = signal_ex_values_by_trial_fi_trim;


signal_ex_values_up_to_lick = NaN(size(signal_vbt));


% Clip data to up to lick time---------------------------------------------------------------

	for i_trial = 1:length(all_ex_first_licks)
		if all_ex_first_licks(i_trial) == 0
			% skip this one bc is rxn train abort, so all_first_licks == 0
		else		
			cutoff = floor((all_ex_first_licks(i_trial)*1000));
			signal_ex_values_up_to_lick(i_trial,1:cutoff) = signal_vbt(i_trial, 1:cutoff);
		end
	end


% CTA initialization:
	signal_vbt = signal_ex_values_up_to_lick;

	target_time = 5000;
	total_time = 17000;
	axisarray = [];

% LTA Initialization:
	xwin = [-7000, 0];
	pos1 = find(time_array==xwin(1));
	pos2 = find(time_array==xwin(2)); 
	dataSetEarlyAndRewsignal = cat(3,early_signal_lick_triggered_trials, rew_signal_lick_triggered_trials);
	dataSetEarlyAndRewsignal = nansum(dataSetEarlyAndRewsignal,3);

	
	axisarray2 = [];









%.CTA up to lick time.................................................................................................................................................


%% COMBINED (ALL OPERANTS) CASE--------PLUS LICK----------------------------------------------------------------------------------
	f_licks_plus = f_ex_licks_with_rxn;
	f_licks_minus = f_ex_licks_no_rxn;

	time_bound_1 = time_bound_1_plot; % this is 700 post cue
	time_bound_2 = time_bound_2_plot; % this is 5000 post cue
	

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_plus;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_plus));

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
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names = {};
	names{1} = 'cue on';
	names{2} = 'target';
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
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
	ax = subplot(2,1,1);
	axisarray(end+1) = ax;
	plot([cue_on_time-1500, cue_on_time-1500], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time-1500+target_time-1500, cue_on_time-1500+target_time-1500], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
		posa = bin_ends(ibins, 1);
		posb = bin_ends(ibins, 2);
		fxn = signal_bin_aves{ibins}(posa:posb);
		plot([1:size(fxn, 2)] - 1500, gausssmooth(fxn, smooth_kernel, 'gauss'), 'linewidth', 1);
	end
	legend(names);
	ylim([-1,1])
	xlim([-1500,cue_on_time + total_time-1500])
	title(['+RXN CTA All Operants - ', signalname]);
	xlabel('time (ms)')
	ylabel('signal')






%% COMBINED (ALL OPERANTS) CASE--------MINUE LICK----------------------------------------------------------------------------------
	f_licks_minus = f_ex_licks_no_rxn;

	time_bound_1 = time_bound_1_plot; % this is 700 post cue
	time_bound_2 = time_bound_2_plot; % this is 5000 post cue
	

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_minus;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_minus));

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


	% % Create the legend names (times in each bin wrt cue on)
	% startpos = time_bound_1-1.5;
	% endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	% names = {};
	% names{1} = 'cue on';
	% names{2} = 'target';
	% names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	% for i_bins = 2:nbins
	% 	startpos = startpos+time_in_ea_bin;
	% 	endpos = endpos + time_in_ea_bin;
	% 	names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	% end

	% % Only plot up to begin of bin-------------
	% binstart = time_bound_1_early;
	% binendnum = time_bound_1_early;


	% bin_ends = NaN(nbins, 2);
	% for ibin = 1:nbins
	% 	bin_ends(ibin, 1) = 0.001;
	% 	bin_ends(ibin, 2) = binendnum;
	% 	binendnum = binendnum + time_in_ea_bin;
	% end
	% bin_ends = (bin_ends*1000);
	% %-----------------------


	ax = subplot(2,1,2);
	axisarray(end+1) = ax;
	plot([cue_on_time-1500, cue_on_time-1500], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time-1500+target_time-1500, cue_on_time-1500+target_time-1500], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
		posa = bin_ends(ibins, 1);
		posb = bin_ends(ibins, 2);
		fxn = signal_bin_aves{ibins}(posa:posb);
		plot([1:size(fxn, 2)] - 1500, gausssmooth(fxn, smooth_kernel, 'gauss'), 'linewidth', 1);
	end
	legend(names);
	ylim([-1,1])
	xlim([-1500,cue_on_time + total_time-1500])
	title(['-RXN CTA All Operants - ', signalname]);
	xlabel('time (ms)')
	ylabel('signal')





%% Link all axes
	linkaxes(axisarray, 'xy');







% %% ----------------- CTA: plot the aves around peak and trough for each bin:

% 	signal_min_ave = NaN(1,nbins);
% 	signal_max_ave = NaN(1,nbins);
% 	SNc_min_ave = NaN(1,nbins);
% 	SNc_max_ave = NaN(1,nbins);
% 	signal_minpos = NaN(1,nbins);
% 	signal_maxpos = NaN(1,nbins);
% 	SNc_minpos = NaN(1,nbins);
% 	SNc_maxpos = NaN(1,nbins);


% 	% signal_minpositions = find(signal_bin_aves{1}(1500:end) == min(signal_bin_aves{1}(1500:end)));

% 	for ibins = 1:nbins
% 		signal_holder_min = signal_bin_aves{ibins}(1500:end);
% 		signal_holder_min = gausssmooth(signal_holder_min, smooth_kernel, 'gauss');
% 		SNc_holder_min = SNc_bin_aves{ibins}(1500:end);
% 		SNc_holder_min = gausssmooth(SNc_holder_min, smooth_kernel, 'gauss');
		
% 		signal_holder_max = signal_bin_aves{ibins}(2000:end);
% 		signal_holder_max = gausssmooth(signal_holder_max, smooth_kernel, 'gauss');
% 		SNc_holder_max = SNc_bin_aves{ibins}(2000:end);
% 		SNc_holder_max = gausssmooth(SNc_holder_max, smooth_kernel, 'gauss');


% 		[~,signal_minpos(ibins)] = min(signal_holder_min);
% 		[~,signal_maxpos(ibins)] = max(signal_holder_max);
% 		[~,SNc_minpos(ibins)] = min(SNc_holder_min);
% 		[~,SNc_maxpos(ibins)] = max(SNc_holder_max);
% 		signal_binpos1 = signal_minpos(ibins) - 200 + 1500;
% 		signal_binpos2 = signal_minpos(ibins) + 200 + 1500;
% 		signal_binpos3 = signal_maxpos(ibins) - 200 + 1500;
% 		signal_binpos4 = signal_maxpos(ibins) + 200 + 1500;
% 		SNc_binpos1 = SNc_minpos(ibins) - 200 + 1500;
% 		SNc_binpos2 = SNc_minpos(ibins) + 200 + 1500;
% 		SNc_binpos3 = SNc_maxpos(ibins) - 200 + 1500;
% 		SNc_binpos4 = SNc_maxpos(ibins) + 200 + 1500;

% 		signal_min_ave(ibins) = nanmean(signal_bin_aves{ibins}(signal_binpos1:signal_binpos2));
% 		signal_max_ave(ibins) = nanmean(signal_bin_aves{ibins}(signal_binpos3:signal_binpos4));
% 		SNc_min_ave(ibins) = nanmean(SNc_bin_aves{ibins}(SNc_binpos1:SNc_binpos2));
% 		SNc_max_ave(ibins) = nanmean(SNc_bin_aves{ibins}(SNc_binpos3:SNc_binpos4));
% 	end

% 	signal_minpos = signal_minpos + 1500;
% 	signal_maxpos = signal_maxpos + 2000;
% 	SNc_minpos = SNc_minpos + 1500;
% 	SNc_maxpos = SNc_maxpos + 2000;


% 	figure,
% 	ax = subplot(1,2,1);
% 	axisarray(end+1) = ax;
% 	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 1)
% 	hold on
% 	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 1)
% 	for ibins = 1:nbins
%         plot([signal_minpos(ibins), signal_maxpos(ibins)], [signal_min_ave(ibins), signal_max_ave(ibins)], '.-', 'markersize', 30);
% 	end
% 	legend(names);
% 	ylim([-1,1])
% 	xlim([0,cue_on_time + total_time])
% 	title('CTA All Operants - signal binned peak/trough averages');
% 	xlabel('time (ms)')
% 	ylabel('signal')


% 	ax = subplot(1,2,2);
% 	axisarray(end+1) = ax;
% 	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 1)
% 	hold on
% 	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 1)
% 	for ibins = 1:nbins
% 		 plot([SNc_minpos(ibins), SNc_maxpos(ibins)], [SNc_min_ave(ibins), SNc_max_ave(ibins)], '.-', 'markersize', 30);
% 	end
% 	legend(names);
% 	ylim([-1,1])
% 	xlim([0,cue_on_time + total_time])
% 	title('CTA All Operants - SNc binned peak/trough averages');
% 	xlabel('time (ms)')
% 	ylabel('signal')




% %% Link all axes
% 	linkaxes(axisarray, 'xy');










%%-------------------------------------LTA:---+ RXN--------------------------------------------------------
%% EARLY and REW CASE:---------------------------------------------
	signal_vbt = dataSetEarlyAndRewsignal;
	time_bound_1 = time_bound_1_plot;
	time_bound_2 = time_bound_2_plot;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	early_and_rew_times_with_trial_markers = f_licks_plus;
	early_and_rew_times_with_trial_markers(2, :) = (1:length(f_licks_plus));

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
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end






	figure,
	ax = subplot(2,1,1);
	axisarray2(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 1)
	for ibins = 1:nbins
		
		plot((time_array(pos1:pos2)), gausssmooth(signal_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 1);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title(['+RXN signal All Operant LTA - ', signalname]);
	xlabel('time (ms)')
	ylabel('signal')



%%-------------------------------------LTA:--- (-RXN)--------------------------------------------------------
%% EARLY and REW CASE:---------------------------------------------
	signal_vbt = dataSetEarlyAndRewsignal;
	time_bound_1 = time_bound_1_plot;
	time_bound_2 = time_bound_2_plot;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	early_and_rew_times_with_trial_markers = f_licks_minus;
	early_and_rew_times_with_trial_markers(2, :) = (1:length(f_licks_minus));

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
	startpos = time_bound_1-1.5;
	endpos = time_bound_1 - 1.5 + time_in_ea_bin;
	names{3} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	for i_bins = 2:nbins
		startpos = startpos+time_in_ea_bin;
		endpos = endpos + time_in_ea_bin;
		names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
	end






	ax = subplot(2,1,2);
	axisarray2(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 1)
	for ibins = 1:nbins
		
		plot((time_array(pos1:pos2)), gausssmooth(signal_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 1);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title(['-RXN signal All Operant LTA - ', signalname]);
	xlabel('time (ms)')
	ylabel('signal')



	linkaxes(axisarray2, 'xy')
