% function [DLS_binned_data, SNc_binned_data,ntrials_per_bin] = trial_binner_test_fx(all_first_licks, nbins, DLS_values_by_trial, SNc_values_by_trial, lick_times_by_trial)%, DLS_values, SNc_values)
% 
% ** For use with Roadmap Processed Data
% 
% 	created          9-3-17  ahamilosfrom 5-22-17 version of trial_binner_test_fx
% 	last modified    9-3-17  ahamilos
% 
% 
%  SMOOTH method gausssmooth 100
smoothwindow = 100;
asym_window = [700, 3333];

%........................................................................................................................................................

cue_on_time = 1500;
% The rest defined wrt cue-on=0, in ms:
rxn_time = 500;
rxn_ok = 0;
buffer = 200;
op_rew_open = 3333;
target_time = 5000;
ITI_time = 7000;
total_time = 17000;
nbins = 5;

DLS_vbt = DLS_ex_values_by_trial;
SNc_vbt = SNc_ex_values_by_trial;

f_licks_rxn = f_ex_lick_rxn;
f_licks_early = f_ex_lick_operant_no_rew;
f_licks_oprew = f_ex_lick_operant_rew;
f_licks_ITI = f_ex_lick_ITI;



axisarray = [];





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
    DLS_pos_in_sorted_array = last_no_lick_position + 1;
    SNc_pos_in_sorted_array = last_no_lick_position + 1;
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
    DLS_binned_trial_positions{end+1} = trial_positions(DLS_pos_in_sorted_array:DLS_pos_in_sorted_array+DLS_ntrials_bin-1);
    SNc_binned_trial_positions{end+1} = trial_positions(SNc_pos_in_sorted_array:SNc_pos_in_sorted_array+SNc_ntrials_bin-1);
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


    % figure,
    % ax = subplot(1,2,1);
    % axisarray(end+1) = ax;
    % plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
    % hold on
    % plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
    % for ibins = 1:nbins
    %     plot(gausssmooth(DLS_bin_aves{ibins}, smoothwindow, 'gauss'), 'linewidth', 3);
    % end
    % legend(names);
    % ylim([-1,1])
    % xlim([0,cue_on_time + total_time])
    % title('CTA Early - DLS binned averages');
    % xlabel('time (ms)')
    % ylabel('signal')


    % ax = subplot(1,2,2);
    % axisarray(end+1) = ax;
    % plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
    % hold on
    % plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
    % for ibins = 1:nbins
    %     plot(gausssmooth(SNc_bin_aves{ibins}, smoothwindow, 'gauss'), 'linewidth', 3);
    % end
    % legend(names);
    % ylim([-1,1])
    % xlim([0,cue_on_time + total_time])
    % title('CTA Early - SNc binned averages');
    % xlabel('time (ms)')
    % ylabel('signal')



% %% REWARDED OPERANT CASE-------------------------------------------------------------------------------
%     f_licks = f_licks_oprew;
%     time_bound_1 = (cue_on_time + op_rew_open)/1000; % this is 3333 post cue
%     time_bound_2 = (cue_on_time + ITI_time)/1000; % this is 7000 post cue
% 
%     % Add trial numbers to 2nd row to keep track of trial positions after sorting:
%     rxn_times_with_trial_markers = f_licks;
%     rxn_times_with_trial_markers(2, :) = (1:length(f_licks));
% 
%     [sorted_times,trial_positions]=sort(rxn_times_with_trial_markers(1,:));
% 
%     % first shave of the trials with no lick in the category: find the position of sorted times that is the last 0 in the array:
%     last_no_lick_position = max(find(sorted_times == 0));
% 
%     % create the bin with trials with no licks in it:
%     for i_rxns = 1:last_no_lick_position
%         DLS_no_lick_bin(i_rxns, 1:size(DLS_vbt, 2)) =  DLS_vbt(trial_positions(i_rxns), :);
%         SNc_no_lick_bin(i_rxns, 1:size(SNc_vbt, 2)) =  SNc_vbt(trial_positions(i_rxns), :);
%     end
% 
%     no_lick_bin_trial_positions = trial_positions(1:last_no_lick_position);
% 
% 
%     % now figure out how to split the remaining trials:
% 
%     % Determine time range of bin:
%     total_range = time_bound_2 - time_bound_1;
%     % Divide the range by nbins:
%     time_in_ea_bin = total_range / nbins;
% 
%     DLS_binned_data = {};
%     SNc_binned_data = {};
%     DLS_binned_trial_positions = {};
%     SNc_binned_trial_positions = {};
%     DLS_trial_positions_in_current_bin = {};
%     SNc_trial_positions_in_current_bin = {};
%     DLS_pos_in_sorted_array = last_no_lick_position + 1;
%     SNc_pos_in_sorted_array = last_no_lick_position + 1;
%     % now split into nbins with cell array. Do all but the last bin in the first loop:
%     current_time_start = time_bound_1;
%     current_time_end = time_bound_1 + time_in_ea_bin;
%     % we will do the min time inclusive:
%     if nbins > 1
%         for i_bins = 1:nbins-1
%             % Figure out how many trials will go in the bin:
%             DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
%             SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
%             % Prep the containers for trials in this bin:
%             DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
%             SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
%             
%             DLS_trial_positions_in_current_bin = trial_positions(DLS_pos_in_sorted_array:DLS_pos_in_sorted_array+DLS_ntrials_bin-1);
%             SNc_trial_positions_in_current_bin = trial_positions(SNc_pos_in_sorted_array:SNc_pos_in_sorted_array+SNc_ntrials_bin-1);
%             
%             for i_rxns = 1:DLS_ntrials_bin
%                 DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
%                 DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
%             end
%             for i_rxns = 1:SNc_ntrials_bin
%                 SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
%                 SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
%             end
%             DLS_binned_data{i_bins} = DLS_current_bin;
%             SNc_binned_data{i_bins} = SNc_current_bin;
%             DLS_binned_trial_positions{i_bins} = DLS_trial_positions_in_current_bin;
%             SNc_binned_trial_positions{i_bins} = SNc_trial_positions_in_current_bin;
%             % Move to next time range:
%             current_time_start = current_time_end;
%             current_time_end = current_time_end + time_in_ea_bin;
%             % %% check this---------------------------------------------------------------------------------------
%             % binned_trial_positions{i_bins} = trial_positions_in_current_bin;
%             % %%--------------------------------------------------------------------------------------------------
%         end
%     end
% 
%     % finally, do the last bin:
% 
%     % Figure out how many trials will go in the bin: (inclusivity fixed to match first_lick_grabber_fx 7-24-17)
%     DLS_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
%     SNc_ntrials_bin = length(find(sorted_times > current_time_start & sorted_times <= current_time_end));
%     % Prep the containers for trials in this bin:
%     DLS_current_bin = NaN(DLS_ntrials_bin, size(DLS_vbt,2));
%     SNc_current_bin = NaN(SNc_ntrials_bin, size(SNc_vbt,2));
%     %% check this--(ok 7-21-17-------------------------------------------------------------------------------------
%     DLS_binned_trial_positions{end+1} = trial_positions(DLS_pos_in_sorted_array:end);
%     SNc_binned_trial_positions{end+1} = trial_positions(SNc_pos_in_sorted_array:end);
%     %%--------------------------------------------------------------------------------------------------
%     for i_rxns = 1:DLS_ntrials_bin
%         DLS_current_bin(i_rxns, :) = DLS_vbt(trial_positions(DLS_pos_in_sorted_array), :);
%         DLS_pos_in_sorted_array = DLS_pos_in_sorted_array + 1;
%     end
%     for i_rxns = 1:SNc_ntrials_bin
%         SNc_current_bin(i_rxns, :) = SNc_vbt(trial_positions(SNc_pos_in_sorted_array), :);
%         SNc_pos_in_sorted_array = SNc_pos_in_sorted_array + 1;
%     end
%     DLS_binned_data{nbins} = DLS_current_bin;
%     SNc_binned_data{nbins} = SNc_current_bin;
%     % %% check this---------------------------------------------------------------------------------------
%     % binned_trial_positions{end+1} = trial_positions_in_current_bin;
%     % %%--------------------------------------------------------------------------------------------------
% 
% 
%     % Finally, take averages of binned data and plot:
%     DLS_bin_aves = {};
%     SNc_bin_aves = {};
%     for ibins = 1:nbins
%         DLS_bin_aves{ibins} = nanmean(DLS_binned_data{ibins},1);
%         SNc_bin_aves{ibins} = nanmean(SNc_binned_data{ibins},1);
%     end

%     figure,
%     ax = subplot(1,2,1);
%     axisarray(end+1) = ax;
%     plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
%     hold on
%     plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
%     for ibins = 1:nbins
%         plot(gausssmooth(DLS_bin_aves{ibins}, smoothwindow, 'gauss'), 'linewidth', 3);
%     end
%     legend(names);
%     ylim([-1,1])
%     xlim([0,cue_on_time + total_time])
%     title('CTA Op-Rew - DLS binned averages');
%     xlabel('time (ms)')
%     ylabel('signal')


%     ax = subplot(1,2,2);
%     axisarray(end+1) = ax;
%     plot([cue_on_time, cue_on_time], [-1,1], 'r-', 'linewidth', 3)
%     hold on
%     plot([cue_on_time+target_time, cue_on_time+target_time], [-1,1], 'r-', 'linewidth', 3)
%     for ibins = 1:nbins
%         plot(gausssmooth(SNc_bin_aves{ibins}, smoothwindow, 'gauss'), 'linewidth', 3);
%     end
%     legend(names);
%     ylim([-1,1])
%     xlim([0,cue_on_time + total_time])
%     title('CTA Op-Rew - SNc binned averages');
%     xlabel('time (ms)')
%     ylabel('signal')

% %% Link all axes
%     linkaxes(axisarray, 'xy');









%% trial asymmetry plot---------------------------------------------------------------------------------

    %% Here's the median-value vs trial number plot with categories:
    DLS_median_values_by_bin = {};
    % for each bin, pull out the median value of each trial in the bin
    %----------------DLS--------------------------------
    for ibin = 1:nbins
        ntrials_bin = size(DLS_binned_data{ibin}, 1);
    	median_array = nan(ntrials_bin, 1);
    	for itrial = 1:ntrials_bin
    		median_array(itrial) = nanmedian(DLS_binned_data{ibin}(itrial,asym_window(1):asym_window(2)));%nanmedian(DLS_binned_data{ibin}(itrial,1500:17000));
    	end
    	DLS_median_values_by_bin{ibin} = median_array;
    end

    SNc_median_values_by_bin = {};
    % for each bin, pull out the median value of each trial in the bin
    %----------------DLS--------------------------------
    for ibin = 1:nbins
        ntrials_bin = size(SNc_binned_data{ibin}, 1);
    	median_array = nan(ntrials_bin, 1);
    	for itrial = 1:ntrials_bin
    		median_array(itrial) = nanmedian(SNc_binned_data{ibin}(itrial,asym_window(1):asym_window(2))); %nanmedian(SNc_binned_data{ibin}(itrial,1500:17000));
    	end
    	SNc_median_values_by_bin{ibin} = median_array;
    end


    % Name bins by times within
    names = {};
    % Create the legend names (times in each bin wrt cue on)
    startpos = time_bound_1-1.5;
    endpos = time_bound_1 - 1.5 + time_in_ea_bin;
    names{1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
    for i_bins = 2:nbins
        startpos = startpos+time_in_ea_bin;
        endpos = endpos + time_in_ea_bin;
        names{end+1} = [num2str(startpos*1000), ' - ', num2str(endpos*1000), ' ms'];
    end 


    % Now we need to plot the medians for each bin vs the trial number
    %% NOTE: on 5/23/17 - likely will need to come back and bin the trial positions as well so you can do this
    figure,
    ax_a = subplot(1,2,1) % DLS
    hold on
    for ibin = 1:nbins
    	x = DLS_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
    	y = DLS_median_values_by_bin{ibin};
    	plot(x, y, '.', 'markersize', 30)
    	hold on
    end
    title('DLS trial median fluorescence by bin');
    xlabel('trial #');
    ylabel('median fluorescence signal');
    legend(names);



    ax_b = subplot(1,2,2) % SNc
    hold on
    for ibin = 1:nbins
    	x = SNc_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
    	y = SNc_median_values_by_bin{ibin};
    	plot(x, y, '.', 'markersize', 30)
    	hold on
    end
    title('SNc trial median fluorescence by bin');
    xlabel('trial #');
    ylabel('median fluorescence signal');
    legend(names);

    colorsii = get(gca, 'colororder');
    %% Now do just for bins 1 and 5:


    figure,
    ax_c = subplot(1,2,1) % DLS
    % names{1} = 'n/a';
    % colorsii = {'b',' ',' ',' ', 'g'};
    for ibin = [1,5]
    	x = DLS_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
    	y = DLS_median_values_by_bin{ibin};
    	plot(x, y, '.', 'markersize', 30, 'color', colorsii(ibin, :))
    	hold on
    end
    title('DLS trial median fluorescence by bin');
    xlabel('trial #');
    ylabel('median fluorescence signal');
    legend(names{1}, names{5});


    ax_d = subplot(1,2,2) % SNc
    for ibin = [1,5]
    	x = SNc_binned_trial_positions{ibin}; 	%%% THIS IS THE THING YOU'LL NEED TO FIND on 5/23/17
    	y = SNc_median_values_by_bin{ibin};
    	plot(x, y, '.', 'markersize', 30, 'color', colorsii(ibin, :))
    	hold on
    end
    title('SNc trial median fluorescence by bin');
    xlabel('trial #');
    ylabel('median fluorescence signal');
    legend(names{1}, names{5});

    linkaxes([ax_a, ax_b, ax_c, ax_d]);