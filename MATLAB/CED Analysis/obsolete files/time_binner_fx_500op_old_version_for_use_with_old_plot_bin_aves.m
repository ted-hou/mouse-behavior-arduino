% function [DLS_binned_data, SNc_binned_data,ntrials_per_bin] = time_binner_test_fx(f_licks, nbins, DLS_vbt, SNc_vbt, lick_times_by_trial)%, DLS_values, SNc_values)
% 
% UPDATE 7-14-17: For use with 500ms rxn time operant only
% 
% 	created       6-3-17 ahamilos
% 	last modified 7-14-17 ahamilos
% 
% 	Dependencies:
% 		1. gfitdF_F_fx --> dF/F calculation
%       2. put_data_into_trials_aligned_to_cue_on_fx = SNc_vbt, DLS_vbt
% 		3. lick_times_by_trial_fx = lick_times_by_trial
% 		4. first_lick_grabber_operant = any of the first lick result arrays can be used for f_licks, e.g., f_lick_operant_rew
% 
% 	Notes:
% 		nbins: the first bin is reserved for any trials in the array marked with 0. In f_licks, these are the rxn_train_abort trials. In other arrays, they are all other trial outcomes other than the principle one (e.g., f_lick_operant_rew has 0's for any non-operant rewarded trials)
% 		
% 	Next Steps: (5/22/17) - we want to plot median of each trial in each bin, color coded vs trial number. I'll attempt to do that in this modified file (trial_binner_test_fx)
% 
% ........................................................................................................

%........................................................................................................................................................

cue_on_time = 1500;
% The rest defined wrt cue-on=0, in ms:
rxn_time = 500;
buffer = 200;
op_rew_open = 3333;
target_time = 5000;
ITI_time = 7000;

% for debug:
% nbins = 5;
% f_licks = d15_f_ex1_lick_operant_rew;
% % For op rew:
% time_bound_1 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
% time_bound_2 = (cue_on_time + ITI_time)/1000; % this is 7000 post cue
% DLS_vbt = d15_DLS_ex1_values_by_trial;%combined_DLS_values_by_trial;
% SNc_vbt = d15_SNc_ex1_values_by_trial;%combined_SNc_values_by_trial;

nbins = 3;
f_licks = d15_f_ex1_lick_operant_no_rew;
% For op no rew:
time_bound_1 = (cue_on_time + rxn_time + buffer)/1000; % this is 500 post cue
time_bound_2 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
DLS_vbt = d15_DLS_ex1_values_by_trial;%combined_DLS_values_by_trial;
SNc_vbt = d15_SNc_ex1_values_by_trial;%combined_SNc_values_by_trial;



% 
% % for debug:
% nbins = 5;
% f_licks = f_lick_operant_rew;
% % For op rew:
% time_bound_1 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
% time_bound_2 = (cue_on_time + ITI_time)/1000; % this is 7000 post cue
% DLS_vbt = DLS_values_by_trial;%combined_DLS_values_by_trial;
% SNc_vbt = SNc_values_by_trial;%combined_SNc_values_by_trial;

% nbins = 5;
% f_licks = f_lick_operant_no_rew;
% % For op no rew:
% time_bound_1 = (cue_on_time + rxn_time + buffer)/1000; % this is 500 post cue
% time_bound_2 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
% DLS_vbt = DLS_values_by_trial;%combined_DLS_values_by_trial;
% SNc_vbt = SNc_values_by_trial;%combined_SNc_values_by_trial;








% Add trial numbers to 2nd row to keep track of trial positions after sorting:
rxn_times_with_trial_markers = f_licks;
rxn_times_with_trial_markers(2, :) = (1:length(f_licks));

[sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));

% first shave of the rxn_trains: find the position of sorted times that is the last rxn_train:
last_rxn_train_position = max(find(sorted_times == 0));

% create the rxn train abort bin:
for i_rxns = 1:last_rxn_train_position
	DLS_abort_bin(i_rxns, 1:size(DLS_vbt, 2)) =  DLS_vbt(trial_positions(i_rxns), :);
	SNc_abort_bin(i_rxns, 1:size(SNc_vbt, 2)) =  SNc_vbt(trial_positions(i_rxns), :);
end

abort_bin_trial_positions = trial_positions(1:last_rxn_train_position);


% now figure out how to split the remaining trials:
% floor(remaining trials / nbins) = how many per bin
% rem(remaining trials, nbins) = the remainder, ie how many to add to the last bin
% remaining_trials = length(sorted_times) - last_rxn_train_position;
% ntrials_bin = floor(remaining_trials/nbins);
% ntrials_end = rem(remaining_trials, nbins);

% Determine time range of bin:
total_range = time_bound_2 - time_bound_1;
% Divide the range by nbins:
time_in_ea_bin = total_range / nbins;


DLS_binned_data = {};
DLS_binned_data{1} = DLS_abort_bin;
SNc_binned_data = {};
SNc_binned_data{1} = SNc_abort_bin;

DLS_binned_trial_positions{1} = abort_bin_trial_positions;
SNc_binned_trial_positions{1} = abort_bin_trial_positions;



DLS_pos_in_sorted_array = last_rxn_train_position + 1;
SNc_pos_in_sorted_array = last_rxn_train_position + 1;
% now split into nbins with cell array. Do all but the last bin in the first loop:
current_time_start = time_bound_1;
current_time_end = time_bound_1 + time_in_ea_bin;
% we will do the min time inclusive:
for i_bins = 1:nbins-1
    % Figure out how many trials will go in the bin:
    DLS_ntrials_bin = length(find(sorted_times >= current_time_start & sorted_times < current_time_end));
    SNc_ntrials_bin = length(find(sorted_times >= current_time_start & sorted_times < current_time_end));
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
	DLS_binned_data{i_bins+1} = DLS_current_bin;
	SNc_binned_data{i_bins+1} = SNc_current_bin;
	DLS_binned_trial_positions{i_bins+1} = DLS_trial_positions_in_current_bin;
    SNc_binned_trial_positions{i_bins+1} = SNc_trial_positions_in_current_bin;
    % Move to next time range:
    current_time_start = current_time_end;
    current_time_end = current_time_end + time_in_ea_bin;
end

% finally, do the last bin:

% Figure out how many trials will go in the bin: (now inclusive on both side)
DLS_ntrials_bin = length(find(sorted_times >= current_time_start & sorted_times <= current_time_end));
SNc_ntrials_bin = length(find(sorted_times >= current_time_start & sorted_times <= current_time_end));
% Prep the containers for trials in this bin:
DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
%% check this---------------------------------------------------------------------------------------
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
DLS_binned_data{nbins+1} = DLS_current_bin;
SNc_binned_data{nbins+1} = SNc_current_bin;


% Finally, take averages of binned data and plot:
DLS_bin_aves = {};
SNc_bin_aves = {};
for ibins = 2:nbins+1
	DLS_bin_aves{ibins} = nanmean(DLS_binned_data{ibins},1);
	SNc_bin_aves{ibins} = nanmean(SNc_binned_data{ibins},1);
end

plot_bin_aves_fx(DLS_bin_aves, SNc_bin_aves, nbins)


%% Find the centers of each bin (i.e., the movement time range:)
bin_ranges = {};
bin_centers = [];
start_point = time_bound_1;
for ibin = 2:nbins+1 %only going to look at stuff with actual time ranges, not the zeros
    bin_ranges{ibin}(1) = start_point;
    bin_ranges{ibin}(2) = start_point + time_in_ea_bin;
    bin_centers(ibin) = start_point + time_in_ea_bin/2;
    start_point = start_point + time_in_ea_bin;
end



%% Here's the median-value vs trial number plot with categories:
DLS_median_values_by_bin = {};
% for each bin, pull out the median value of each trial in the bin
%----------------DLS--------------------------------
for ibin = 1:nbins+1
	median_array = nan(DLS_ntrials_bin, 1);
	for itrial = 1:DLS_ntrials_bin
		median_array(itrial) = nanmedian(DLS_binned_data{ibin}(itrial,time_bound_1:time_bound_2));%nanmedian(DLS_binned_data{ibin}(itrial,1500:17000));
	end
	DLS_median_values_by_bin{ibin} = median_array;
end

SNc_median_values_by_bin = {};
% for each bin, pull out the median value of each trial in the bin
%----------------SNc--------------------------------
for ibin = 1:nbins+1
	median_array = nan(SNc_ntrials_bin, 1);
	for itrial = 1:SNc_ntrials_bin
		median_array(itrial) = nanmedian(SNc_binned_data{ibin}(itrial,time_bound_1:time_bound_2)); %nanmedian(SNc_binned_data{ibin}(itrial,1500:17000));
	end
	SNc_median_values_by_bin{ibin} = median_array;
end



%--------------------------------start debugging here on 6/3/17!--------******************************-----------------------
% Now we need to plot the medians for each bin vs the trial number
%% NOTE: on 5/23/17 - likely will need to come back and bin the trial positions as well so you can do this
% figure,
% subplot(1,2,1) % DLS
% names{1} = 'n/a';
% plot([0],[0]);
% hold on
% for ibin = 2:nbins+1
% 	x = DLS_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
% 	y = DLS_median_values_by_bin{ibin};
% 	plot(x, y, '.', 'markersize', 30)
% 	hold on
%     names{ibin} = ['Bin # ', num2str(ibin)];
% end
% title('DLS trial median fluorescence by bin');
% xlabel('trial #');
% ylabel('median fluorescence signal');
% legend(names);



% subplot(1,2,2) % SNc
% names{1} = 'n/a';
% plot([0],[0]);
% hold on
% for ibin = 2:nbins
% 	x = SNc_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
% 	y = SNc_median_values_by_bin{ibin};
% 	plot(x, y, '.', 'markersize', 30)
% 	hold on
%     names{ibin} = ['Bin # ', num2str(ibin)];
% end
% title('SNc trial median fluorescence by bin');
% xlabel('trial #');
% ylabel('median fluorescence signal');
% legend(names);


% %% Now do just for bins 2 and 6:


% figure,
% subplot(1,2,1) % DLS
% % names{1} = 'n/a';
% for ibin = [2,6]
% 	x = DLS_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
% 	y = DLS_median_values_by_bin{ibin};
% 	plot(x, y, '.', 'markersize', 30)
% 	hold on
% end
% names = {['Bin # ', num2str(2)], ['Bin # ', num2str(6)]};
% title('DLS trial median fluorescence by bin');
% xlabel('trial #');
% ylabel('median fluorescence signal');
% legend(names);


% subplot(1,2,2) % SNc
% for ibin = [2,6]
% 	x = SNc_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
% 	y = SNc_median_values_by_bin{ibin};
% 	plot(x, y, '.', 'markersize', 30)
% 	hold on
% end
% names = {['Bin # ', num2str(2)], ['Bin # ', num2str(6)]};
% title('SNc trial median fluorescence by bin');
% xlabel('trial #');
% ylabel('median fluorescence signal');
% legend(names);