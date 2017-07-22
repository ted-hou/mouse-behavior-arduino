% function [DLS_binned_data, SNc_binned_data,ntrials_per_bin] = trial_binner_test_fx(all_first_licks, nbins, DLS_values_by_trial, SNc_values_by_trial, lick_times_by_trial)%, DLS_values, SNc_values)
% 
% ****SEE NEXT STEPS FOR EXPLANATION: this file is to protect working version, trial_binner_fx
% 
% 	created 5-22-17 ahamilos
% 	last modified 5-22-17 ahamilos
% 
% 	Dependencies:
% 		1. extract trials (any version) - DLS_values_by_trial, SNc_values_by_trial
% 		2. lick_times_by_trial_fx = lick_times_by_trial
% 		3. first_lick_grabber = any of the first lick result arrays can be used for all_first_licks, e.g., f_lick_operant_rew
% 
% 	Notes:
% 		nbins: the first bin is reserved for any trials in the array marked with 0. In all_first_licks, these are the rxn_train_abort trials. In other arrays, they are all other trial outcomes other than the principle one (e.g., f_lick_operant_rew has 0's for any non-operant rewarded trials)
% 		
% 	Next Steps: (5/22/17) - we want to plot median of each trial in each bin, color coded vs trial number. I'll attempt to do that in this modified file (trial_binner_test_fx)
% 
% ........................................................................................................
%  TESTING:
% all_first_licks = [0.6, 0.4, 1, 5.6, 7, 0, 10, 11.1, 2.2, 0, 6.1, 6.1, 5.8, 2.2, 0, 0, 0.99];
% nbins = 2;
% DLS_values_by_trial = magic(17);

% all_first_licks = all_first_licks;
%..........................................................................................................
% %% For local dF/F correction:
% num_trials = length(all_first_licks);
% 
% DLS_df_f_values = NaN(size(DLS_values_by_trial));
% for i_trial = 1:num_trials
%   % take ave of last 3 sec:
%   ave_last_3 = nanmean(DLS_values_by_trial(i_trial, end-3000:end));
%   % subtract this from every datapoint in the trial:
%   DLS_df_f_values(i_trial, :) = DLS_values_by_trial(i_trial, :) - ave_last_3;
% end
% 
% SNc_df_f_values = NaN(size(SNc_values_by_trial));
% for i_trial = 1:num_trials
%   % take ave of last 3 sec:
%   ave_last_3 = nanmean(SNc_values_by_trial(i_trial, end-3000:end));
%   % subtract this from every datapoint in the trial:
%   SNc_df_f_values(i_trial, :) = SNc_values_by_trial(i_trial, :) - ave_last_3;
% end
% 
% DLS_values_by_trial = DLS_df_f_values;
% SNc_values_by_trial = SNc_df_f_values;


%% Trying to put in global exp.........................................................................................................................
        %% Now fit each timeseries with exp:
        %   DLS_fitobject = {}; % saves each fit
        %   DLS_gof = {};   % saves goodness of fit stats for each fit
        %   DLS_output = {};  % saves output for each fit
        %   DLS_coefficient_array = []; % saves the coeffs as rows = fit, col = a,b
        %   % split_time_begin = start_time;
        %   % for i_fit = 1:length(belly)
        %     % Make x and y and then transpose:
        %     DLS_x = (1:length(DLS_values));
        %     DLS_x = x';
        %     DLS_y = DLS_values;
        %     [DLS_fitobject,DLS_gof,DLS_output] = fit(DLS_x,DLS_y,'exp2');
        %     figure, hold on, plot(DLS_values), plot(DLS_fitobject);
        %     DLS_coefficient_array = coeffvalues(DLS_fitobject);
        %   end



        % %% Now, use the coefficients to get a correction function for each fit
        %   DLS_correction_functions = {}; % each cell has a 1xn array of multipliers based on the exp fit
        %   DLS_a = DLS_coefficient_array(1, 1);
        %   DLS_b = DLS_coefficient_array(1, 2);
	       %  for i_timestamp = 1:length(belly{i_fit})+18501
	       %    correction_functions{i_fit}(i_timestamp) = a*exp(b*i_timestamp);  % note if a = 0, then this will end up reading as NaN - basically if the end of the light function is not exp, this will give a meaningless exp fit
	       %  end
        %   end



        % % Now correct each datapoint:
        %   df_f_values = NaN(size(values_by_trial));
        %   start_trial = 1;
        %   for i_fit = 1:length(belly)-1
        %     end_trial = split_trials(i_fit);
        %     expcount = 1;

        %     for i_trial = start_trial:end_trial
        %       for i_col = 1:size(values_by_trial,2)
        %         % for each timestamp, check if not NaN. Remember to increment the exp counter
        %         if values_by_trial(i_trial, i_col) > -10000
        %           df_f_values(i_trial, i_col) = values_by_trial(i_trial, i_col) ./ correction_functions{i_fit}(expcount);
        %           expcount = expcount + 1;
        %         end
        %       end
        %     end

        %     start_trial = end_trial + 1
        %   end
        %   % now do the final fit:
        %   end_trial = size(values_by_trial,1);
        %   expcount = 1;
        %   for i_trial = start_trial:end_trial
        %     for i_col = 1:size(values_by_trial,2)
        %       % for each timestamp, check if not NaN. Remember to increment the exp counter
        %       if values_by_trial(i_trial, i_col) > -10000
        %         df_f_values(i_trial, i_col) = values_by_trial(i_trial, i_col) ./ correction_functions{i_fit}(expcount);
        %         expcount = expcount + 1;
        %       end
        %     end
        %   end


        %     %% Check heatmap now...
        %     [h_heatmap_df_f, heat_by_trial_df_f] = heatmap_3_fx(df_f_values, [], false);
        %     title([channel, ' Globally-normalized heatmap of dF/F now in use'])

        %     if strcmp(button, 'DLS')
        %       dF_F_style_DLS = 'Global';
        %      elseif strcmp(button, 'SNc')
        %       dF_F_style_SNc = 'Global';
        %     end


%........................................................................................................................................................

% for debug:
all_first_licks = f_lick_operant_rew;% + f_lick_operant_no_rew; 
DLS_values_by_trial = DLS_values_by_trial_gfit;
SNc_values_by_trial = SNc_values_by_trial_gfit;








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

%%---------------------------------------------------------check this-------------------------------------
abort_bin_trial_positions = trial_positions(1:last_rxn_train_position);
%%--------------------------------------------------------------------------------------------------------

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
%--------------------------------------------check--------------------------------------------
binned_trial_positions{1} = abort_bin_trial_positions;
%---------------------------------------------------------------------------------------------
DLS_pos_in_sorted_array = last_rxn_train_position + 1;
SNc_pos_in_sorted_array = last_rxn_train_position + 1;
% now split into nbins with cell array. Do all but the last bin in the first loop:
for i_bins = 1:nbins-1
	DLS_current_bin = NaN(ntrials_bin, size(DLS_values_by_trial,2));
	SNc_current_bin = NaN(ntrials_bin, size(SNc_values_by_trial,2));
	%% check this---------------------------------------------------------------------------------------
	trial_positions_in_current_bin = trial_positions(DLS_pos_in_sorted_array:DLS_pos_in_sorted_array+ntrials_bin-1);
	%%--------------------------------------------------------------------------------------------------
	for i_rxns = 1:ntrials_bin
		DLS_current_bin(i_rxns, :) = DLS_values_by_trial(trial_positions(DLS_pos_in_sorted_array), :);
		DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
		SNc_current_bin(i_rxns, :) = SNc_values_by_trial(trial_positions(SNc_pos_in_sorted_array), :);
		SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
	end
	DLS_binned_data{i_bins+1} = DLS_current_bin;
	SNc_binned_data{i_bins+1} = SNc_current_bin;
	%% check this---------------------------------------------------------------------------------------
	binned_trial_positions{i_bins+1} = trial_positions_in_current_bin;
	%%--------------------------------------------------------------------------------------------------
end

% finally, do the last bin:
DLS_current_bin = NaN(ntrials_bin+ntrials_end, size(DLS_values_by_trial,2));
SNc_current_bin = NaN(ntrials_bin+ntrials_end, size(SNc_values_by_trial,2));
%% check this---------------------------------------------------------------------------------------
binned_trial_positions{end+1} = trial_positions(DLS_pos_in_sorted_array:end);
%%--------------------------------------------------------------------------------------------------
for i_rxns = 1:ntrials_bin+ntrials_end
	DLS_current_bin(i_rxns, :) = DLS_values_by_trial(trial_positions(DLS_pos_in_sorted_array), :);
	DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
	SNc_current_bin(i_rxns, :) = SNc_values_by_trial(trial_positions(SNc_pos_in_sorted_array), :);
	SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
end
DLS_binned_data{end+1} = DLS_current_bin;
SNc_binned_data{end+1} = SNc_current_bin;


% Finally, take averages of binned data and plot:
DLS_bin_aves = {};
SNc_bin_aves = {};
for ibins = 1:nbins
	DLS_bin_aves{ibins} = nanmean(DLS_binned_data{ibins},1);
	SNc_bin_aves{ibins} = nanmean(SNc_binned_data{ibins},1);
end

plot_bin_aves_fx(DLS_bin_aves, SNc_bin_aves, nbins)


%--------------------------------start debugging here on 5/23/17!-------------------------------
%% Here's the median-value vs trial number plot with categories:
DLS_median_values_by_bin = {};
% for each bin, pull out the median value of each trial in the bin
%----------------DLS--------------------------------
for ibin = 1:nbins
	median_array = nan(ntrials_bin, 1);
	for itrial = 1:ntrials_bin
		median_array(itrial) = nanmedian(DLS_binned_data{ibin}(itrial,3500:5500));%nanmedian(DLS_binned_data{ibin}(itrial,1500:17000));
	end
	DLS_median_values_by_bin{ibin} = median_array;
end

SNc_median_values_by_bin = {};
% for each bin, pull out the median value of each trial in the bin
%----------------DLS--------------------------------
for ibin = 1:nbins
	median_array = nan(ntrials_bin, 1);
	for itrial = 1:ntrials_bin
		median_array(itrial) = nanmedian(SNc_binned_data{ibin}(itrial,3500:5500)); %nanmedian(SNc_binned_data{ibin}(itrial,1500:17000));
	end
	SNc_median_values_by_bin{ibin} = median_array;
end

% Now we need to plot the medians for each bin vs the trial number
%% NOTE: on 5/23/17 - likely will need to come back and bin the trial positions as well so you can do this
figure,
subplot(1,2,1) % DLS
names{1} = 'n/a';
plot([0],[0]);
hold on
for ibin = 2:nbins
	x = binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
	y = DLS_median_values_by_bin{ibin};
	plot(x, y, '.', 'markersize', 30)
	hold on
    names{ibin} = ['Bin # ', num2str(ibin)];
end
title('DLS trial median fluorescence by bin');
xlabel('trial #');
ylabel('median fluorescence signal');
legend(names);



subplot(1,2,2) % SNc
names{1} = 'n/a';
plot([0],[0]);
hold on
for ibin = 2:nbins
	x = binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
	y = SNc_median_values_by_bin{ibin};
	plot(x, y, '.', 'markersize', 30)
	hold on
    names{ibin} = ['Bin # ', num2str(ibin)];
end
title('SNc trial median fluorescence by bin');
xlabel('trial #');
ylabel('median fluorescence signal');
legend(names);


%% Now do just for bins 2 and 6:


figure,
subplot(1,2,1) % DLS
% names{1} = 'n/a';
for ibin = [2,6]
	x = binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
	y = DLS_median_values_by_bin{ibin};
	plot(x, y, '.', 'markersize', 30)
	hold on
end
names = {['Bin # ', num2str(2)], ['Bin # ', num2str(6)]};
title('DLS trial median fluorescence by bin');
xlabel('trial #');
ylabel('median fluorescence signal');
legend(names);


subplot(1,2,2) % SNc
for ibin = [2,6]
	x = binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
	y = SNc_median_values_by_bin{ibin};
	plot(x, y, '.', 'markersize', 30)
	hold on
end
names = {['Bin # ', num2str(2)], ['Bin # ', num2str(6)]};
title('SNc trial median fluorescence by bin');
xlabel('trial #');
ylabel('median fluorescence signal');
legend(names);