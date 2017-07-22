function [DLS_binned_data, SNc_binned_data] = trial_binner(all_first_licks, nbins, DLS_values_by_trial, SNc_values_by_trial, lick_times_by_trial)

% all_first_licks = [0.6, 0.4, 1, 5.6, 7, 0, 10, 11.1, 2.2, 0, 6.1, 6.1, 5.8, 2.2, 0, 0, 0.99];
% nbins = 2;
% DLS_values_by_trial = magic(17);

% all_first_licks = all_first_licks;


% Add trial numbers to 2nd row to keep track of trial positions after sorting:
rxn_times_with_trial_markers = all_first_licks;
rxn_times_with_trial_markers(2, :) = (1:length(all_first_licks));

[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

% first shave of the rxn_trains: find the position of sorted times that is the last rxn_train:
last_rxn_train_position = max(find(sorted_times == 0));

% create the rxn train abort bin:
for i_rxns = 1:last_rxn_train_position
	DLS_abort_bin(i_rxns, 1:size(DLS_values_by_trial, 2)) =  DLS_values_by_trial(trial_positions(i_rxns), :);
	SNc_abort_bin(i_rxns, 1:size(SNc_values_by_trial, 2)) =  SNc_values_by_trial(trial_positions(i_rxns), :);
end

% now figure out how to split the remaining trials:
% floor(remaining trials / nbins) = how many per bin
% rem(remaining trials, nbins) = the remainder, ie how many to add to the last bin
remaining_trials = length(sorted_times) - last_rxn_train_position;
ntrials_bin = floor(remaining_trials/nbins);
ntrials_end = rem(remaining_trials, nbins);


DLS_binned_data = {};
DLS_binned_data{1} = DLS_abort_bin;
SNc_binned_data = {};
SNc_binned_data{1} = SNc_abort_bin;
DLS_pos_in_sorted_array = last_rxn_train_position + 1;
SNc_pos_in_sorted_array = last_rxn_train_position + 1;
% now split into nbins with cell array. Do all but the last bin in the first loop:
for i_bins = 1:nbins-1
	DLS_current_bin = NaN(ntrials_bin, size(DLS_values_by_trial,2));
	SNc_current_bin = NaN(ntrials_bin, size(SNc_values_by_trial,2));
	for i_rxns = 1:ntrials_bin
		DLS_current_bin(i_rxns, :) = DLS_values_by_trial(trial_positions(DLS_pos_in_sorted_array), :);
		DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
		SNc_current_bin(i_rxns, :) = SNc_values_by_trial(trial_positions(SNc_pos_in_sorted_array), :);
		SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
	end
	DLS_binned_data{i_bins+1} = DLS_current_bin;
	SNc_binned_data{i_bins+1} = SNc_current_bin;
end

% finally, do the last bin:
DLS_current_bin = NaN(ntrials_bin+ntrials_end, size(DLS_values_by_trial,2));
SNc_current_bin = NaN(ntrials_bin+ntrials_end, size(SNc_values_by_trial,2));
for i_rxns = 1:ntrials_bin+ntrials_end
	DLS_current_bin(i_rxns, :) = DLS_values_by_trial(trial_positions(DLS_pos_in_sorted_array), :);
	DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
	SNc_current_bin(i_rxns, :) = SNc_values_by_trial(trial_positions(SNc_pos_in_sorted_array), :);
	SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
end
DLS_binned_data{end+1} = DLS_current_bin;
SNc_binned_data{end+1} = SNc_current_bin;