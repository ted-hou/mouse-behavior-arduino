%---------LTA Time Binner (analogous for CTA time_binner_fx.m)----------------------
% 	Based on time_binner_fx.m (0ms op version)
% 
% 	created       7-31-17 ahamilos
% 	last modified 7-31-17 ahamilos
% 
% 	Dependencies:
% 		1. lick_triggered_ave_allplots_fx.m
% 

% print(4,'-depsc','-painters','lta_rxn_time_binner_5bin.eps')
% saveas(4,'lta_rxn_time_binner_5bin.fig','fig')

% print(5,'-depsc','-painters','lta_early_time_binner_5bin.eps')
% saveas(5,'lta_early_time_binner_5bin.fig','fig')

% print(6,'-depsc','-painters','lta_rew_time_binner_5bin.eps')
% saveas(6,'lta_rew_time_binner_5bin.fig','fig')

% 
% 
% 
% ........................................................................................................

%........................................................................................................................................................
time_array = d22_time_array;
dataSetRxnDLS = d22_rxn_DLS_lick_triggered_trials;
dataSetEarlyDLS = d22_early_DLS_lick_triggered_trials;
dataSetRewDLS = d22_rew_DLS_lick_triggered_trials;
dataSetRxnSNc = d22_rxn_SNc_lick_triggered_trials;
dataSetEarlySNc = d22_early_SNc_lick_triggered_trials;
dataSetRewSNc = d22_rew_SNc_lick_triggered_trials;
nbins = 5; % divide the trials into n_divs # of bins

f_licks_rxn = d22_f_ex1_lick_rxn;
f_licks_early = d22_f_ex1_lick_operant_no_rew;
f_licks_oprew = d22_f_ex1_lick_operant_rew;
% f_licks_pav =
% f_licks_ITI =

cue_on_time = 1500;
time_bound_1_rxn = (cue_on_time + 0)/1000; % must be in terms of ms to match lick times in sec
time_bound_2_rxn = (cue_on_time + 500)/1000;
time_bound_1_early = (cue_on_time + 700)/1000;
time_bound_2_early = (cue_on_time + 3333)/1000;
time_bound_1_rew = (cue_on_time + 3333)/1000; 
time_bound_2_rew = (cue_on_time + 7000)/1000;


xwin = [-4000, 1000];
pos1 = find(time_array==xwin(1));
pos2 = find(time_array==xwin(2)); 


%% RXN CASE:---------------------------------------------
	DLS_vbt = dataSetRxnDLS;
	SNc_vbt = dataSetRxnSNc;
	time_bound_1 = time_bound_1_rxn;
	time_bound_2 = time_bound_2_rxn;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_rxn;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_rxn));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		DLS_no_lick_bin(i_rxns, 1:size(DLS_vbt, 2)) =  DLS_vbt(trial_positions(i_rxns), :);
		SNc_no_lick_bin(i_rxns, 1:size(SNc_vbt, 2)) =  SNc_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	DLS_binned_data = {};
	SNc_binned_data = {};
	
	DLS_pos_in_sorted_array = last_no_lick_position + 1;
	SNc_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	DLS_binned_trial_positions = {};
	SNc_binned_trial_positions = {};
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
			SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
			
			DLS_trial_positions_in_current_bin = trial_positions(DLS_pos_in_sorted_array:DLS_pos_in_sorted_array+DLS_ntrials_bin-1);
		    SNc_trial_positions_in_current_bin = trial_positions(SNc_pos_in_sorted_array:SNc_pos_in_sorted_array+SNc_ntrials_bin-1);
			
			for i_rxns = 1:DLS_ntrials_bin
				DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
				DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
			end
		    for i_rxns = 1:SNc_ntrials_bin
		        SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
		        SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
		    end
			DLS_binned_data{i_bins} = DLS_current_bin;
			SNc_binned_data{i_bins} = SNc_current_bin;
			DLS_binned_trial_positions{i_bins} = DLS_trial_positions_in_current_bin;
		    SNc_binned_trial_positions{i_bins} = SNc_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
	SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	DLS_binned_trial_positions{end+1} = trial_positions(DLS_pos_in_sorted_array:end);
	SNc_binned_trial_positions{end+1} = trial_positions(SNc_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:DLS_ntrials_bin
		DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
		DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:SNc_ntrials_bin
	    SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
	    SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
	end
	DLS_binned_data{nbins} = DLS_current_bin;
	SNc_binned_data{nbins} = SNc_current_bin;


	% Finally, take averages of binned data and plot:
	DLS_bin_aves = {};
	SNc_bin_aves = {};
	for ibins = 1:nbins
		DLS_bin_aves{ibins} = nanmean(DLS_binned_data{ibins},1);
		SNc_bin_aves{ibins} = nanmean(SNc_binned_data{ibins},1);
	end

	
	% plot_bin_aves_fx(DLS_bin_aves, SNc_bin_aves, nbins) 
	linkarray = [];
	names{1} = 'lick time';
	names{2} = 'zero';
	figure,
	ax = subplot(1,2,1)
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(DLS_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 3);
		hold on;
		names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('DLS Reaction LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,2,2)
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(SNc_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 3);
		hold on;
		names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('SNc Reaction LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	% linkaxes(linkarray, 'xy')










	%% EARLY CASE:---------------------------------------------
	DLS_vbt = dataSetEarlyDLS;
	SNc_vbt = dataSetEarlySNc;
	time_bound_1 = time_bound_1_early;
	time_bound_2 = time_bound_2_early;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	early_times_with_trial_markers = f_licks_early;
	early_times_with_trial_markers(2, :) = (1:length(f_licks_early));

	[sorted_times,trial_positions]=sort(early_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		DLS_no_lick_bin(i_rxns, 1:size(DLS_vbt, 2)) =  DLS_vbt(trial_positions(i_rxns), :);
		SNc_no_lick_bin(i_rxns, 1:size(SNc_vbt, 2)) =  SNc_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	DLS_binned_data = {};
	SNc_binned_data = {};
	
	DLS_pos_in_sorted_array = last_no_lick_position + 1;
	SNc_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	DLS_binned_trial_positions = {};
	SNc_binned_trial_positions = {};
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
			SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
			
			DLS_trial_positions_in_current_bin = trial_positions(DLS_pos_in_sorted_array:DLS_pos_in_sorted_array+DLS_ntrials_bin-1);
		    SNc_trial_positions_in_current_bin = trial_positions(SNc_pos_in_sorted_array:SNc_pos_in_sorted_array+SNc_ntrials_bin-1);
			
			for i_rxns = 1:DLS_ntrials_bin
				DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
				DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
			end
		    for i_rxns = 1:SNc_ntrials_bin
		        SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
		        SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
		    end
			DLS_binned_data{i_bins} = DLS_current_bin;
			SNc_binned_data{i_bins} = SNc_current_bin;
			DLS_binned_trial_positions{i_bins} = DLS_trial_positions_in_current_bin;
		    SNc_binned_trial_positions{i_bins} = SNc_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
	SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	DLS_binned_trial_positions{end+1} = trial_positions(DLS_pos_in_sorted_array:end);
	SNc_binned_trial_positions{end+1} = trial_positions(SNc_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:DLS_ntrials_bin
		DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
		DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:SNc_ntrials_bin
	    SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
	    SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
	end
	DLS_binned_data{nbins} = DLS_current_bin;
	SNc_binned_data{nbins} = SNc_current_bin;


	% Finally, take averages of binned data and plot:
	DLS_bin_aves = {};
	SNc_bin_aves = {};
	for ibins = 1:nbins
		DLS_bin_aves{ibins} = nanmean(DLS_binned_data{ibins},1);
		SNc_bin_aves{ibins} = nanmean(SNc_binned_data{ibins},1);
	end

	
	% plot_bin_aves_fx(DLS_bin_aves, SNc_bin_aves, nbins) 
	% linkarray = [];
	names{1} = 'lick time';
	names{2} = 'zero';
	figure,
	ax = subplot(1,2,1)
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(DLS_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 3);
		hold on;
		names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('DLS Early LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,2,2)
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(SNc_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 3);
		hold on;
		names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('SNc Early LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	% linkaxes(linkarray, 'xy')






%% REW CASE---------------------------------------------
	DLS_vbt = dataSetRewDLS;
	SNc_vbt = dataSetRewSNc;
	time_bound_1 = time_bound_1_rew;
	time_bound_2 = time_bound_2_rew;

	% Add trial numbers to 2nd row to keep track of trial positions after sorting:
	rxn_times_with_trial_markers = f_licks_oprew;
	rxn_times_with_trial_markers(2, :) = (1:length(f_licks_oprew));

	[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

	% first shave off the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
	last_no_lick_position = max(find(sorted_times == 0));

	% create the bin with trials with no licks in it:
	for i_rxns = 1:last_no_lick_position
		DLS_no_lick_bin(i_rxns, 1:size(DLS_vbt, 2)) =  DLS_vbt(trial_positions(i_rxns), :);
		SNc_no_lick_bin(i_rxns, 1:size(SNc_vbt, 2)) =  SNc_vbt(trial_positions(i_rxns), :);
	end

	no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);


	% now figure out how to split the remaining trials:

	% Determine time range of bin:
	total_range = time_bound_2 - time_bound_1;
	% Divide the range by nbins:
	time_in_ea_bin = total_range / nbins;

	DLS_binned_data = {};
	SNc_binned_data = {};
	
	DLS_pos_in_sorted_array = last_no_lick_position + 1;
	SNc_pos_in_sorted_array = last_no_lick_position + 1;
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
	DLS_binned_trial_positions = {};
	SNc_binned_trial_positions = {};
	% we will do the min time inclusive:
	if nbins > 1
		for i_bins = 1:nbins-1
		    % Figure out how many trials will go in the bin:
		    DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
		    % Prep the containers for trials in this bin:
			DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
			SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
			
			DLS_trial_positions_in_current_bin = trial_positions(DLS_pos_in_sorted_array:DLS_pos_in_sorted_array+DLS_ntrials_bin-1);
		    SNc_trial_positions_in_current_bin = trial_positions(SNc_pos_in_sorted_array:SNc_pos_in_sorted_array+SNc_ntrials_bin-1);
			
			for i_rxns = 1:DLS_ntrials_bin
				DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
				DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
			end
		    for i_rxns = 1:SNc_ntrials_bin
		        SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
		        SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
		    end
			DLS_binned_data{i_bins} = DLS_current_bin;
			SNc_binned_data{i_bins} = SNc_current_bin;
			DLS_binned_trial_positions{i_bins} = DLS_trial_positions_in_current_bin;
		    SNc_binned_trial_positions{i_bins} = SNc_trial_positions_in_current_bin;
		    % Move to next time range:
		    current_time_start = current_time_end;
		    current_time_end = current_time_end + time_in_ea_bin;
		end
	end
	% finally, do the last bin:

	% Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
	DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
	% Prep the containers for trials in this bin:
	DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
	SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
	%% check this--(ok 7-21-17-------------------------------------------------------------------------------------
	DLS_binned_trial_positions{end+1} = trial_positions(DLS_pos_in_sorted_array:end);
	SNc_binned_trial_positions{end+1} = trial_positions(SNc_pos_in_sorted_array:end);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:DLS_ntrials_bin
		DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
		DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
	end
	for i_rxns = 1:SNc_ntrials_bin
	    SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
	    SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
	end
	DLS_binned_data{nbins} = DLS_current_bin;
	SNc_binned_data{nbins} = SNc_current_bin;


	% Finally, take averages of binned data and plot:
	DLS_bin_aves = {};
	SNc_bin_aves = {};
	for ibins = 1:nbins
		DLS_bin_aves{ibins} = nanmean(DLS_binned_data{ibins},1);
		SNc_bin_aves{ibins} = nanmean(SNc_binned_data{ibins},1);
	end

	
	% plot_bin_aves_fx(DLS_bin_aves, SNc_bin_aves, nbins) 
	% linkarray = [];
	names{1} = 'lick time';
	names{2} = 'zero';
	figure,
	ax = subplot(1,2,1)
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(DLS_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 3);
		hold on;
		names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('DLS Rewarded LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,2,2)
	linkarray(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 3)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 3)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(SNc_bin_aves{ibins}(pos1:pos2), 50, 'gauss'), 'linewidth', 3);
		hold on;
		names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('SNc Rewarded LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	linkaxes(linkarray, 'xy')