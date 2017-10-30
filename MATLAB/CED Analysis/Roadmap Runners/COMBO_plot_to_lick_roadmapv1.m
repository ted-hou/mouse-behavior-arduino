%-------------Plot up until Lick Time - any combo of first-licks--------------------
% 
%  Designed for use with 500ms op - but will work ok with any op I think
%  Right now will plot rew and early together as default
% 
% Created  8-08-17 ahamilos
% Modified 8-11-17 ahamilos
% 
% UPDATE LOG:
%	-8-11-17: modified for combined datasets 
% 	-8-10-17: modified for use with roadmapv1 - small fixes, 400ms (200 ea side) mean window for points
% 
%  Based on:
% 		-extract_values_up_to_lick_fx.m
% 
% 
smooth_kernel = 100;
nbins = 5;
cue_on_time = 1500;

time_bound_1_early = (cue_on_time + 700)/1000;
time_bound_2_early = (cue_on_time + 3333)/1000;
time_bound_1_rew = (cue_on_time + 3333)/1000; 
time_bound_2_rew = (cue_on_time + 5000)/1000;%(cue_on_time + 7000)/1000;

time_bound_1_plot = time_bound_1_early;
time_bound_2_plot = time_bound_2_rew;
% 
% 

% 	f_licks_rxn = f_ex_lick_rxn;
	f_licks_early = combined_data_struct.f_ex_lick_operant_no_rew;
	f_licks_oprew = combined_data_struct.f_ex_lick_operant_rew;
% 	f_licks_ITI = f_ex_lick_ITI;
	all_first_licks = combined_data_struct.all_ex_first_licks;
    time_array = combined_data_struct.time_array;
% -----------------------------------------------------------------------------------

DLS_vbt = combined_data_struct.DLS_ex_values_by_trial_fi_trim;
SNc_vbt = combined_data_struct.SNc_ex_values_by_trial_fi_trim;


%% DEBUG-----------------------------------
	% % all_first_licks = all_ex_first_licks;
	% % f_ex_lick_rxn = f_ex_lick_rxn;
	% f_ex_lick_operant_no_rew = f_ex_lick_operant_no_rew;
	% f_ex_lick_operant_rew = f_ex_lick_operant_rew;
	% % f_ex_lick_ITI = f_ex_lick_ITI;
	% time_array = time_array;
	% early_DLS_lick_triggered_trials = early_DLS_lick_triggered_trials;
	% rew_DLS_lick_triggered_trials = rew_DLS_lick_triggered_trials;
	% early_SNc_lick_triggered_trials = early_SNc_lick_triggered_trials;
	% rew_SNc_lick_triggered_trials = rew_SNc_lick_triggered_trials;
	%-----------------------------------------



DLS_ex_values_up_to_lick = NaN(size(DLS_vbt));
SNc_ex_values_up_to_lick = NaN(size(SNc_vbt));


% Clip data to up to lick time---------------------------------------------------------------

	for i_trial = 1:length(all_first_licks)
		if all_first_licks(i_trial) == 0
			% skip this one bc is rxn train abort, so all_first_licks == 0
		else		
			cutoff = floor((all_first_licks(i_trial)*1000));
			DLS_ex_values_up_to_lick(i_trial,1:cutoff) = DLS_vbt(i_trial, 1:cutoff);
			SNc_ex_values_up_to_lick(i_trial,1:cutoff) = SNc_vbt(i_trial, 1:cutoff);
		end
	end


% CTA initialization:
	DLS_vbt = DLS_ex_values_up_to_lick;
	SNc_vbt = SNc_ex_values_up_to_lick;



	target_time = 5000;
	total_time = 17000;
	axisarray = [];

% LTA Initialization:
	xwin = [-7000, 0];
	pos1 = find(time_array==xwin(1));
	pos2 = find(time_array==xwin(2)); 
	dataSetEarlyAndRewDLS = cat(3,combined_data_struct.early_DLS_lick_triggered_trials, combined_data_struct.rew_DLS_lick_triggered_trials);
	dataSetEarlyAndRewDLS = nansum(dataSetEarlyAndRewDLS,3);
	dataSetEarlyAndRewSNc = cat(3,combined_data_struct.early_SNc_lick_triggered_trials, combined_data_struct.rew_SNc_lick_triggered_trials);
	dataSetEarlyAndRewSNc = nansum(dataSetEarlyAndRewSNc,3);

	
	axisarray2 = [];









%.CTA up to lick time.................................................................................................................................................


%% COMBINED (ALL OPERANTS) CASE------------------------------------------------------------------------------------------
	f_licks_early_and_rew = f_licks_early + f_licks_oprew; 
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
	DLS_binned_trial_positions = {};
	SNc_binned_trial_positions = {};
	DLS_trial_positions_in_current_bin = {};
	SNc_trial_positions_in_current_bin = {};
    
    
    % This must advance further to match the time bounds. so find the
    % min position in the sorted array greater than time_bound_1
	DLS_pos_in_sorted_array = min(find(sorted_times > time_bound_1));
	SNc_pos_in_sorted_array = min(find(sorted_times > time_bound_1));
	% now split into nbins with cell array. Do all but the last bin in the first loop:
	current_time_start = time_bound_1;
	current_time_end = time_bound_1 + time_in_ea_bin;
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
	ax = subplot(1,2,1);
	axisarray(end+1) = ax;
	plot([cue_on_time-1500, cue_on_time-1500], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time-1500+target_time-1500, cue_on_time-1500+target_time-1500], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
		posa = bin_ends(ibins, 1);
		posb = bin_ends(ibins, 2);
		fxn = DLS_bin_aves{ibins}(posa:posb);
		plot([1:size(fxn, 2)] - 1500, smooth(fxn, smooth_kernel, 'gauss'), 'linewidth', 1);
	end
	legend(names);
	ylim([-1,1])
	xlim([-1500,cue_on_time + total_time-1500])
	title('CTA All Operants - DLS binned averages');
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,2,2);
	axisarray(end+1) = ax;
	plot([cue_on_time-1500, cue_on_time-1500], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time-1500+target_time-1500, cue_on_time-1500+target_time-1500], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
		posa = bin_ends(ibins, 1);
		posb = bin_ends(ibins, 2);
		fxn = SNc_bin_aves{ibins}(posa:posb);
		plot([1:size(fxn, 2)] - 1500, smooth(fxn, smooth_kernel, 'gauss'), 'linewidth', 1);
	end
	legend(names);
	ylim([-1,1])
	xlim([-1500,cue_on_time + total_time])
	title('CTA All Operants - SNc binned averages');
	xlabel('time (ms)')
	ylabel('signal')




%% Link all axes
	linkaxes(axisarray, 'xy');







%% ----------------- CTA: plot the aves around peak and trough for each bin:

	DLS_min_ave = NaN(1,nbins);
	DLS_max_ave = NaN(1,nbins);
	SNc_min_ave = NaN(1,nbins);
	SNc_max_ave = NaN(1,nbins);
	DLS_minpos = NaN(1,nbins);
	DLS_maxpos = NaN(1,nbins);
	SNc_minpos = NaN(1,nbins);
	SNc_maxpos = NaN(1,nbins);


	% DLS_minpositions = find(DLS_bin_aves{1}(1500:end) == min(DLS_bin_aves{1}(1500:end)));

	for ibins = 1:nbins
		DLS_holder_min = DLS_bin_aves{ibins}(1500:end);
		DLS_holder_min = smooth(DLS_holder_min, smooth_kernel, 'gauss');
		SNc_holder_min = SNc_bin_aves{ibins}(1500:end);
		SNc_holder_min = smooth(SNc_holder_min, smooth_kernel, 'gauss');
		
		DLS_holder_max = DLS_bin_aves{ibins}(2000:end);
		DLS_holder_max = smooth(DLS_holder_max, smooth_kernel, 'gauss');
		SNc_holder_max = SNc_bin_aves{ibins}(2000:end);
		SNc_holder_max = smooth(SNc_holder_max, smooth_kernel, 'gauss');


		[~,DLS_minpos(ibins)] = min(DLS_holder_min);
		[~,DLS_maxpos(ibins)] = max(DLS_holder_max);
		[~,SNc_minpos(ibins)] = min(SNc_holder_min);
		[~,SNc_maxpos(ibins)] = max(SNc_holder_max);
		DLS_binpos1 = DLS_minpos(ibins) - 200 + 1500;
		DLS_binpos2 = DLS_minpos(ibins) + 200 + 1500;
		DLS_binpos3 = DLS_maxpos(ibins) - 200 + 1500;
		DLS_binpos4 = DLS_maxpos(ibins) + 200 + 1500;
		SNc_binpos1 = SNc_minpos(ibins) - 200 + 1500;
		SNc_binpos2 = SNc_minpos(ibins) + 200 + 1500;
		SNc_binpos3 = SNc_maxpos(ibins) - 200 + 1500;
		SNc_binpos4 = SNc_maxpos(ibins) + 200 + 1500;

		DLS_min_ave(ibins) = nanmean(DLS_bin_aves{ibins}(DLS_binpos1:DLS_binpos2));
		DLS_max_ave(ibins) = nanmean(DLS_bin_aves{ibins}(DLS_binpos3:DLS_binpos4));
		SNc_min_ave(ibins) = nanmean(SNc_bin_aves{ibins}(SNc_binpos1:SNc_binpos2));
		SNc_max_ave(ibins) = nanmean(SNc_bin_aves{ibins}(SNc_binpos3:SNc_binpos4));
	end

	DLS_minpos = DLS_minpos + 1500;
	DLS_maxpos = DLS_maxpos + 2000;
	SNc_minpos = SNc_minpos + 1500;
	SNc_maxpos = SNc_maxpos + 2000;


	figure,
	ax = subplot(1,2,1);
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
        plot([DLS_minpos(ibins), DLS_maxpos(ibins)], [DLS_min_ave(ibins), DLS_max_ave(ibins)], '.-', 'markersize', 30);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA All Operants - DLS binned peak/trough averages');
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,2,2);
	axisarray(end+1) = ax;
	plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 1)
	for ibins = 1:nbins
		 plot([SNc_minpos(ibins), SNc_maxpos(ibins)], [SNc_min_ave(ibins), SNc_max_ave(ibins)], '.-', 'markersize', 30);
	end
	legend(names);
	ylim([-1,1])
	xlim([0,cue_on_time + total_time])
	title('CTA All Operants - SNc binned peak/trough averages');
	xlabel('time (ms)')
	ylabel('signal')




%% Link all axes
	linkaxes(axisarray, 'xy');










%%-------------------------------------LTA:-----------------------------------------------------------
%% EARLY and REW CASE:---------------------------------------------
	DLS_vbt = dataSetEarlyAndRewDLS;
	SNc_vbt = dataSetEarlyAndRewSNc;
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
	ax = subplot(1,2,1);
	axisarray2(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 1)
	for ibins = 1:nbins
		
		plot((time_array(pos1:pos2)), smooth(DLS_bin_aves{ibins}(pos1:pos2), smooth_kernel, 'gauss'), 'linewidth', 1);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('DLS All Operant LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	ax = subplot(1,2,2);
	axisarray2(end+1) = ax;
	plot([0, 0], [-1,1], 'r-', 'linewidth', 1)
	hold on
	plot([xwin], [0,0], 'k-', 'linewidth', 1)
	for ibins = 1:nbins
		plot(time_array(pos1:pos2), smooth(SNc_bin_aves{ibins}(pos1:pos2), smooth_kernel, 'gauss'), 'linewidth', 1);
		hold on;
		% names{ibins+2} = ['Bin # ', num2str(ibins)];
	end
	legend(names);
	xlim(xwin)
	ylim([-1,1])
	title('SNc All Operant LTA Binned Averages');
	xlabel('time (ms)')
	ylabel('signal')


	linkaxes(axisarray2, 'xy')
