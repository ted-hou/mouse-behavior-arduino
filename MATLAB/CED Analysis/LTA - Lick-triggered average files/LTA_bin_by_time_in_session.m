% ---------------------------LICK TRIGGERED AVERAGE, binned by trial # in session-----------------------------
% 
%	Goal = check and see if pattern of LTA differs early vs late in the same day (a signal validation measure) 
% 
%
% 
% 
% Created  ahamilos 7-27-17
% Modified ahamilos 7-27-17
% 
% 
%
%
%
% Uses output of lick_triggered_ave_allplots_fx.m (lick_triggered_trials)
% =============================================================================================================

%% Debugging test case: Dummy Data:
%  Step 1: Run lick_triggered_ave_allplots_fx.m with dummy test data
% 
%  Now in workspace you have:
% 
% 	rxn_DLS_lick_triggered_trials
% 	early_DLS_lick_triggered_trials
% 	rew_DLS_lick_triggered_trials
% 	rxn_SNc_lick_triggered_trials
% 	early_SNc_lick_triggered_trials
% 	rew_SNc_lick_triggered_trials
%  
%  These are the values by trial for each condition in each channel
% 
% 
% Step 2: Bin the trials within the day

% %% First pass: look at individual trials - plot ave of lick peak (-30ms to 30ms in the lick_triggered_trials) vs trial #
% % 
% peak_ave_window_bounds = [100,160];
% pos1 = find(time_array==peak_ave_window_bounds(1));
% pos2 = find(time_array==peak_ave_window_bounds(2));
% % plot vs trial number
% trial_numbers = (1:num_trials);
% 
% 
% % Rxn cases:
% 	%% DLS:
% 	rxn_DLS_peak_ave_by_trials = NaN(num_trials, 1);
% 
% 	% fill in the peak ave: (VERIFIED)
% 	for i_trial = 1:num_trials
% 		rxn_DLS_peak_ave_by_trials(i_trial) = nanmean(rxn_DLS_lick_triggered_trials(i_trial,pos1:pos2));
% 	end
% 
% 	%% SNc:
% 	rxn_SNc_peak_ave_by_trials = NaN(num_trials, 1);
% 
% 	for i_trial = 1:num_trials
% 		rxn_SNc_peak_ave_by_trials(i_trial) = nanmean(rxn_SNc_lick_triggered_trials(i_trial,pos1:pos2));
% 	end
% 
% 	%% Rxn Figure
% 	figure
% 	ax_rxnDLS = subplot(2,1,1)
% 	plot([0,num_trials], [nanmean(rxn_DLS_peak_ave_by_trials),nanmean(rxn_DLS_peak_ave_by_trials)], 'k-', 'linewidth', 2)
% 	hold on
% 	plot(trial_numbers, rxn_DLS_peak_ave_by_trials, 'b--o', 'markersize', 10, 'linewidth', 3)
% 	title('DLS rxn peak ave')
% 	
% 	ax_rxnSNc = subplot(2,1,2)
% 	plot([0,num_trials], [nanmean(rxn_SNc_peak_ave_by_trials),nanmean(rxn_SNc_peak_ave_by_trials)], 'k-', 'linewidth', 2)
% 	hold on
% 	plot(trial_numbers, rxn_SNc_peak_ave_by_trials, 'r--o', 'markersize', 10, 'linewidth', 3)
% 	title('SNc rxn peak ave')
% 
% 
% 
% % Early cases:
% 	%% DLS:
% 	early_DLS_peak_ave_by_trials = NaN(num_trials, 1);
% 
% 	% fill in the peak ave: (VERIFIED)
% 	for i_trial = 1:num_trials
% 		early_DLS_peak_ave_by_trials(i_trial) = nanmean(early_DLS_lick_triggered_trials(i_trial,pos1:pos2));
% 	end
% 
% 	%% SNc:
% 	early_SNc_peak_ave_by_trials = NaN(num_trials, 1);
% 
% 	for i_trial = 1:num_trials
% 		early_SNc_peak_ave_by_trials(i_trial) = nanmean(early_SNc_lick_triggered_trials(i_trial,pos1:pos2));
% 	end
% 
% 	%% Rxn Figure
% 	figure
% 	ax_earlyDLS = subplot(2,1,1)
% 	plot([0,num_trials], [nanmean(early_DLS_peak_ave_by_trials),nanmean(early_DLS_peak_ave_by_trials)], 'k-', 'linewidth', 2)
% 	hold on
% 	plot(trial_numbers, early_DLS_peak_ave_by_trials, 'b--o', 'markersize', 10, 'linewidth', 3)
% 	title('DLS early peak ave')
% 	
% 	ax_earlySNc = subplot(2,1,2)
% 	plot([0,num_trials], [nanmean(early_SNc_peak_ave_by_trials),nanmean(early_SNc_peak_ave_by_trials)], 'k-', 'linewidth', 2)
% 	hold on
% 	plot(trial_numbers, early_SNc_peak_ave_by_trials, 'r--o', 'markersize', 10, 'linewidth', 3)
% 	title('SNc early peak ave')
% 
% 
% 
% 
% % Rew cases:
% 	%% DLS:
% 	rew_DLS_peak_ave_by_trials = NaN(num_trials, 1);
% 
% 	% fill in the peak ave: (VERIFIED)
% 	for i_trial = 1:num_trials
% 		rew_DLS_peak_ave_by_trials(i_trial) = nanmean(rew_DLS_lick_triggered_trials(i_trial,pos1:pos2));
% 	end
% 
% 	%% SNc:
% 	rew_SNc_peak_ave_by_trials = NaN(num_trials, 1);
% 
% 	for i_trial = 1:num_trials
% 		rew_SNc_peak_ave_by_trials(i_trial) = nanmean(rew_SNc_lick_triggered_trials(i_trial,pos1:pos2));
% 	end
% 
% 	%% Rxn Figure
% 	figure
% 	ax_rewDLS = subplot(2,1,1)
% 	plot([0,num_trials], [nanmean(rew_DLS_peak_ave_by_trials),nanmean(rew_DLS_peak_ave_by_trials)], 'k-', 'linewidth', 2)
% 	hold on
% 	plot(trial_numbers, rew_DLS_peak_ave_by_trials, 'b--o', 'markersize', 10, 'linewidth', 3)
% 	title('DLS rew peak ave')
% 	
% 	ax_rewSNc = subplot(2,1,2)
% 	plot([0,num_trials], [nanmean(rew_SNc_peak_ave_by_trials),nanmean(rew_SNc_peak_ave_by_trials)], 'k-', 'linewidth', 2)
% 	hold on
% 	plot(trial_numbers, rew_SNc_peak_ave_by_trials, 'r--o', 'markersize', 10, 'linewidth', 3)
% 	title('SNc rew peak ave')
% 
% 
% 
% %% Link axes to see swing:
% 
% linkaxes([ax_rewSNc, ax_rxnSNc, ax_earlySNc, ax_rewDLS, ax_earlyDLS, ax_rxnDLS], 'xy')
% 
% 
% 
% % print(1,'-depsc','-painters','lta_rxn_3030peakavevstrial_ex1_h3.eps')
% % saveas(1,'lta_rxn_3030peakavevstrial_ex1_h3.fig','fig')
% 
% % print(2,'-depsc','-painters','lta_early_3030peakavevstrial_ex1_h3.eps')
% % saveas(2,'lta_early_3030peakavevstrial_ex1_h3.fig','fig')
% 
% % print(4,'-depsc','-painters','lta_rew_3030peakavevstrial_ex1_h3.eps')
% % saveas(4,'lta_rew_3030peakavevstrial_ex1_h3.fig','fig')
% 
% 
% 
% % print(5,'-depsc','-painters','lta_rxn_100_160peakavevstrial_ex1_h3.eps')
% % saveas(5,'lta_rxn_100_160peakavevstrial_ex1_h3.fig','fig')
% % print(10,'-depsc','-painters','lta_early_100_160peakavevstrial_ex1_h3.eps')
% % saveas(10,'lta_early_100_160peakavevstrial_ex1_h3.fig','fig')
% % print(11,'-depsc','-painters','lta_rew_100_160peakavevstrial_ex1_h3.eps')
% % saveas(11,'lta_rew_100_160peakavevstrial_ex1_h3.fig','fig')


%-----------------------------------------------------------------------------------------------
% %% Plot the peak of every trial - neat, we can do this now if we want to. 

% % We'll do this by making subplots of 10/figure

% winpeak = [-1000, 500];
% pos1 = find(time_array==winpeak(1));
% pos2 = find(time_array==winpeak(2));
% linkarray = [];

% % 10 trials at a time left to right, (1,10,i_trial)
% i_trial = 1;
% num_plots = 0;
% fig = figure,
% set(fig,'Units', 'Normalized', 'Position',[0 0 1 .3]);
% for i_trial = 1:num_trials
% 	% if this is a trial with licks in it:
% 	if d22_rxn_SNc_lick_triggered_trials(i_trial,pos1)> -100000
% 		% If we are still on the same figure
% 		if num_plots < 10 % continue plotting on same figure
% 			num_plots = num_plots + 1;
% 			ax = subplot(1,10,num_plots);
% 			plot([0,0], [-1,1], 'g-', 'linewidth', 2)
% 			hold on
% 			lick_time_ms = -1*(d22_f_ex1_lick_rxn(i_trial)*1000 - 1500);
% 			plot([lick_time_ms,lick_time_ms], [-1,1], 'k-', 'linewidth', 2)
% 			plot(time_array(pos1:pos2), smooth(d22_rxn_SNc_lick_triggered_trials(i_trial,pos1:pos2), 50, 'gauss'), 'linewidth', 3)
% 			linkarray(end+1) = ax;
% 			xlim(winpeak)
% 			title(num2str(i_trial))
% 		% If not in the same figure, plot the next figure
% 		else
% 			num_plots = 1;
% 			fig = figure
% 			set(fig,'Units', 'Normalized', 'Position',[0 0 1 .3]);
% 			ax = subplot(1,10,num_plots);
% 			plot([0,0], [-1,1], 'g-', 'linewidth', 2)
% 			hold on
% 			lick_time_ms = -1*(d22_f_ex1_lick_rxn(i_trial)*1000 - 1500);
% 			plot([lick_time_ms,lick_time_ms], [-1,1], 'k-', 'linewidth', 2)
% 			plot(time_array(pos1:pos2), smooth(d22_rxn_SNc_lick_triggered_trials(i_trial,pos1:pos2), 50, 'gauss'), 'linewidth', 3)
% 			linkarray(end+1) = ax;
% 			xlim(winpeak)
% 			title(num2str(i_trial))
%         end
%     end
% end

% linkaxes(linkarray, 'xy')
			



% % print(1,'-depsc','-painters','lta_rxn_SNc_singletrials1.eps')
% % saveas(1,'lta_rxn_SNc_singletrials1.fig','fig')

% % print(2,'-depsc','-painters','lta_rxn_SNc_singletrials2.eps')
% % saveas(2,'lta_rxn_SNc_singletrials2.fig','fig')

% % print(3,'-depsc','-painters','lta_rxn_SNc_singletrials3.eps')
% % saveas(3,'lta_rxn_SNc_singletrials3.fig','fig')

% % print(4,'-depsc','-painters','lta_rxn_SNc_singletrials4.eps')
% % saveas(4,'lta_rxn_SNc_singletrials4.fig','fig')

% % print(5,'-depsc','-painters','lta_rxn_SNc_singletrials5.eps')
% % saveas(5,'lta_rxn_SNc_singletrials5.fig','fig')

% % print(6,'-depsc','-painters','lta_rxn_SNc_singletrials6.eps')
% % saveas(6,'lta_rxn_SNc_singletrials6.fig','fig')

% % print(7,'-depsc','-painters','lta_rxn_SNc_singletrials7.eps')
% % saveas(7,'lta_rxn_SNc_singletrials7.fig','fig')

% % print(8,'-depsc','-painters','lta_rxn_SNc_singletrials8.eps')
% % saveas(8,'lta_rxn_SNc_singletrials8.fig','fig')

% % print(9,'-depsc','-painters','lta_rxn_SNc_singletrials9.eps')
% % saveas(9,'lta_rxn_SNc_singletrials9.fig','fig')

% % print(10,'-depsc','-painters','lta_rxn_SNc_singletrials10.eps')
% % saveas(10,'lta_rxn_SNc_singletrials10.fig','fig')

% % print(11,'-depsc','-painters','lta_rxn_SNc_singletrials11.eps')
% % saveas(11,'lta_rxn_SNc_singletrials11.fig','fig')

% % print(12,'-depsc','-painters','lta_rxn_SNc_singletrials12.eps')
% % saveas(12,'lta_rxn_SNc_singletrials12.fig','fig')

% % print(13,'-depsc','-painters','lta_rxn_SNc_singletrials12.eps')
% % saveas(13,'lta_rxn_SNc_singletrials12.fig','fig')

% % print(14,'-depsc','-painters','lta_rxn_SNc_singletrials12.eps')
% % saveas(14,'lta_rxn_SNc_singletrials12.fig','fig')

% Cool, that worked well!


%% Divide the LTA by time in the trial--------------------------------------------------------------------------------------------------------------------
winpeak = [-4000, 1000];
pos1 = find(time_array==winpeak(1));
pos2 = find(time_array==winpeak(2));
dataSetRxn = d22_rxn_DLS_lick_triggered_trials;
dataSetEarly = d22_early_DLS_lick_triggered_trials;
dataSetRew = d22_rew_DLS_lick_triggered_trials;
n_divs = 5; % divide the trials into n_divs # of bins

%% Rxn Cases:
	rxn_trials_with_lick = find(dataSetRxn(:,pos1)> -100000); % finds all the no NaN trials

	n_rxn_trials_with_lick = length(rxn_trials_with_lick);

	% n_trials_per_div = floor(n_rxn_trials_with_lick/n_divs)
	% n_extra_trials_in_last_bin = rem(n_rxn_trials_with_lick, n_divs) % remainder of that division operation

	% Calculate the bin edges:
	bin_edges = NaN(n_divs, 2);
	n_trials_per_div = floor(num_trials/n_divs);
	n_extra_trials_in_last_bin = rem(num_trials, n_divs);

	if n_divs > 2
		bin_edges(1,:) = [1, n_trials_per_div];
		% for bin 2 to all but the last bin:
		for n_bin = 2:n_divs-1
			left_edge = bin_edges(n_bin-1, 2) + 1;
			right_edge = bin_edges(n_bin-1, 2) + n_trials_per_div;
			bin_edges(n_bin, :) = [left_edge, right_edge];
		end
		% now for the last trial:
		left_edge = bin_edges(n_bin+1-1, 2) + 1;
		right_edge = bin_edges(n_bin+1-1, 2) + n_trials_per_div + n_extra_trials_in_last_bin;
		bin_edges(n_bin+1, :) = [left_edge, right_edge];


		% Create bins of trials with a structure:
		rxn_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			rxn_trials_in_ea_bin{n_bin} = rxn_trials_with_lick(find(rxn_trials_with_lick >= bin_edges(n_bin, 1) & rxn_trials_with_lick <= bin_edges(n_bin, 2)));
			rxn_binned_trials_by_time_in_session{n_bin} = dataSetRxn(rxn_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_rxn_trials_in_ea_bin{n_bin} = nanmean(dataSetRxn(rxn_trials_in_ea_bin{n_bin}, :));
		end

	elseif n_divs == 2
		bin_edges(1,:) = [1, n_trials_per_div];
		bin_edges(2,:) = [n_trials_per_div + 1, num_trials];

		% Create bins of trials with a structure:
		rxn_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			rxn_trials_in_ea_bin{n_bin} = rxn_trials_with_lick(find(rxn_trials_with_lick >= bin_edges(n_bin, 1) & rxn_trials_with_lick <= bin_edges(n_bin, 2)));
			rxn_binned_trials_by_time_in_session{n_bin} = dataSetRxn(rxn_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_rxn_trials_in_ea_bin{n_bin} = nanmean(dataSetRxn(rxn_trials_in_ea_bin{n_bin}, :));
		end

	elseif n_divs == 1
		bin_edges(1,:) = [1, num_trials];

		% Create bins of trials with a structure:
		rxn_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			rxn_trials_in_ea_bin{n_bin} = rxn_trials_with_lick(find(rxn_trials_with_lick >= bin_edges(n_bin, 1) & rxn_trials_with_lick <= bin_edges(n_bin, 2)));
			rxn_binned_trials_by_time_in_session{n_bin} = dataSetRxn(rxn_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_rxn_trials_in_ea_bin{n_bin} = nanmean(dataSetRxn(rxn_trials_in_ea_bin{n_bin}, :));
		end
	end




%% Early Cases:
	early_trials_with_lick = find(dataSetEarly(:,pos1)> -100000); % finds all the no NaN trials

	n_early_trials_with_lick = length(early_trials_with_lick);

	% n_trials_per_div = floor(n_early_trials_with_lick/n_divs)
	% n_extra_trials_in_last_bin = rem(n_early_trials_with_lick, n_divs) % remainder of that division operation

	% Calculate the bin edges:
	bin_edges = NaN(n_divs, 2);
	n_trials_per_div = floor(num_trials/n_divs);
	n_extra_trials_in_last_bin = rem(num_trials, n_divs);

	if n_divs > 2
		bin_edges(1,:) = [1, n_trials_per_div];
		% for bin 2 to all but the last bin:
		for n_bin = 2:n_divs-1
			left_edge = bin_edges(n_bin-1, 2) + 1;
			right_edge = bin_edges(n_bin-1, 2) + n_trials_per_div;
			bin_edges(n_bin, :) = [left_edge, right_edge];
		end
		% now for the last trial:
		left_edge = bin_edges(n_bin+1-1, 2) + 1;
		right_edge = bin_edges(n_bin+1-1, 2) + n_trials_per_div + n_extra_trials_in_last_bin;
		bin_edges(n_bin+1, :) = [left_edge, right_edge];


		% Create bins of trials with a structure:
		early_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			early_trials_in_ea_bin{n_bin} = early_trials_with_lick(find(early_trials_with_lick >= bin_edges(n_bin, 1) & early_trials_with_lick <= bin_edges(n_bin, 2)));
			early_binned_trials_by_time_in_session{n_bin} = dataSetEarly(early_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_early_trials_in_ea_bin{n_bin} = nanmean(dataSetEarly(early_trials_in_ea_bin{n_bin}, :));
		end

	elseif n_divs == 2
		bin_edges(1,:) = [1, n_trials_per_div];
		bin_edges(2,:) = [n_trials_per_div + 1, num_trials];

		% Create bins of trials with a structure:
		early_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			early_trials_in_ea_bin{n_bin} = early_trials_with_lick(find(early_trials_with_lick >= bin_edges(n_bin, 1) & early_trials_with_lick <= bin_edges(n_bin, 2)));
			early_binned_trials_by_time_in_session{n_bin} = dataSetEarly(early_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_early_trials_in_ea_bin{n_bin} = nanmean(dataSetEarly(early_trials_in_ea_bin{n_bin}, :));
		end

	elseif n_divs == 1
		bin_edges(1,:) = [1, num_trials];

		% Create bins of trials with a structure:
		early_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			early_trials_in_ea_bin{n_bin} = early_trials_with_lick(find(early_trials_with_lick >= bin_edges(n_bin, 1) & early_trials_with_lick <= bin_edges(n_bin, 2)));
			early_binned_trials_by_time_in_session{n_bin} = dataSetEarly(early_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_early_trials_in_ea_bin{n_bin} = nanmean(dataSetEarly(early_trials_in_ea_bin{n_bin}, :));
		end
	end


%% Rew Cases:
	rew_trials_with_lick = find(dataSetRew(:,pos1)> -100000); % finds all the no NaN trials

	n_rew_trials_with_lick = length(rew_trials_with_lick);

	% n_trials_per_div = floor(n_rew_trials_with_lick/n_divs)
	% n_extra_trials_in_last_bin = rem(n_rew_trials_with_lick, n_divs) % remainder of that division operation

	% Calculate the bin edges:
	bin_edges = NaN(n_divs, 2);
	n_trials_per_div = floor(num_trials/n_divs);
	n_extra_trials_in_last_bin = rem(num_trials, n_divs);

	if n_divs > 2
		bin_edges(1,:) = [1, n_trials_per_div];
		% for bin 2 to all but the last bin:
		for n_bin = 2:n_divs-1
			left_edge = bin_edges(n_bin-1, 2) + 1;
			right_edge = bin_edges(n_bin-1, 2) + n_trials_per_div;
			bin_edges(n_bin, :) = [left_edge, right_edge];
		end
		% now for the last trial:
		left_edge = bin_edges(n_bin+1-1, 2) + 1;
		right_edge = bin_edges(n_bin+1-1, 2) + n_trials_per_div + n_extra_trials_in_last_bin;
		bin_edges(n_bin+1, :) = [left_edge, right_edge];


		% Create bins of trials with a structure:
		rew_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			rew_trials_in_ea_bin{n_bin} = rew_trials_with_lick(find(rew_trials_with_lick >= bin_edges(n_bin, 1) & rew_trials_with_lick <= bin_edges(n_bin, 2)));
			rew_binned_trials_by_time_in_session{n_bin} = dataSetRew(rew_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_rew_trials_in_ea_bin{n_bin} = nanmean(dataSetRew(rew_trials_in_ea_bin{n_bin}, :));
		end

	elseif n_divs == 2
		bin_edges(1,:) = [1, n_trials_per_div];
		bin_edges(2,:) = [n_trials_per_div + 1, num_trials];

		% Create bins of trials with a structure:
		rew_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			rew_trials_in_ea_bin{n_bin} = rew_trials_with_lick(find(rew_trials_with_lick >= bin_edges(n_bin, 1) & rew_trials_with_lick <= bin_edges(n_bin, 2)));
			rew_binned_trials_by_time_in_session{n_bin} = dataSetRew(rew_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_rew_trials_in_ea_bin{n_bin} = nanmean(dataSetRew(rew_trials_in_ea_bin{n_bin}, :));
		end

	elseif n_divs == 1
		bin_edges(1,:) = [1, num_trials];

		% Create bins of trials with a structure:
		rew_binned_trials_by_time_in_session = {};

		for n_bin = 1:n_divs
			rew_trials_in_ea_bin{n_bin} = rew_trials_with_lick(find(rew_trials_with_lick >= bin_edges(n_bin, 1) & rew_trials_with_lick <= bin_edges(n_bin, 2)));
			rew_binned_trials_by_time_in_session{n_bin} = dataSetRew(rew_trials_in_ea_bin{n_bin}, :);
			% take averages of each bin:
			ave_of_rew_trials_in_ea_bin{n_bin} = nanmean(dataSetRew(rew_trials_in_ea_bin{n_bin}, :));
		end
	end







% Now plot the averages separately:
linkarray = [];


names = {'licktime', 'zero', 'rxn', 'early', 'rew'};
figure,
for n_bin = 1:n_divs
	ax = subplot(1,n_divs,n_bin);
	plot([0,0], [-1,1], 'g-', 'linewidth', 2)
	hold on
	plot(winpeak, [0,0], 'k-', 'linewidth', 2)
	plot(time_array(pos1:pos2), smooth(ave_of_rxn_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
	plot(time_array(pos1:pos2), smooth(ave_of_early_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
	plot(time_array(pos1:pos2), smooth(ave_of_rew_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
	linkarray(end+1) = ax;
    legend(names);
    xlim(winpeak);
end


linkaxes(linkarray, 'xy')



% print(1,'-depsc','-painters','lta_DLS_overlay_1bin.eps')
% saveas(1,'lta_DLS_overlay_1bin.fig','fig')

% print(2,'-depsc','-painters','lta_DLS_overlay_2bin.eps')
% saveas(2,'lta_DLS_overlay_2bin.fig','fig')

% print(3,'-depsc','-painters','lta_DLS_overlay_3bin.eps')
% saveas(3,'lta_DLS_overlay_3bin.fig','fig')

% print(4,'-depsc','-painters','lta_DLS_overlay_4bin.eps')
% saveas(4,'lta_DLS_overlay_4bin.fig','fig')

% print(5,'-depsc','-painters','lta_DLS_overlay_5bin.eps')
% saveas(5,'lta_DLS_overlay_5bin.fig','fig')



%% Plot end vs begin of session trials across different categories
% % Mixed - Inverted RXN------------------------------------------------
% linkarray = [];


% names = {'licktime', 'zero', 'rxn', 'early', 'rew'};
% figure,
% title('Rxn backwards, Early and Rew in correct order')
% for n_bin = 1:n_divs
% 	ax = subplot(1,n_divs,n_bin);
% 	plot([0,0], [-1,1], 'g-', 'linewidth', 2)
% 	hold on
% 	plot(winpeak, [0,0], 'k-', 'linewidth', 2)
% 	plot(time_array(pos1:pos2), smooth(ave_of_rxn_trials_in_ea_bin{n_divs+1-n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
% 	plot(time_array(pos1:pos2), smooth(ave_of_early_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
% 	plot(time_array(pos1:pos2), smooth(ave_of_rew_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
% 	linkarray(end+1) = ax;
%     legend(names);
%     xlim(winpeak);

% end


% linkaxes(linkarray, 'xy')


% Mixed - Inverted RXN--------------------------------------
linkarray = [];


names = {'licktime', 'zero', 'rxn', 'early', 'rew'};
figure,

for n_bin = 1:n_divs
	ax = subplot(1,n_divs,n_bin);
	plot([0,0], [-1,1], 'g-', 'linewidth', 2)
	hold on
	plot(winpeak, [0,0], 'k-', 'linewidth', 2)
	plot(time_array(pos1:pos2), smooth(ave_of_rxn_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
	plot(time_array(pos1:pos2), smooth(ave_of_early_trials_in_ea_bin{n_divs+1-n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
	plot(time_array(pos1:pos2), smooth(ave_of_rew_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
	linkarray(end+1) = ax;
    legend(names);
    xlim(winpeak);
    title('Early backwards, Rxn and Rew in correct order')
end


linkaxes(linkarray, 'xy')

% % Mixed - Inverted REW--------------------------------------
% linkarray = [];


% names = {'licktime', 'zero', 'rxn', 'early', 'rew'};
% figure,
% title('Rxn and Early in correct order, Rew backwards')
% for n_bin = 1:n_divs
% 	ax = subplot(1,n_divs,n_bin);
% 	plot([0,0], [-1,1], 'g-', 'linewidth', 2)
% 	hold on
% 	plot(winpeak, [0,0], 'k-', 'linewidth', 2)
% 	plot(time_array(pos1:pos2), smooth(ave_of_rxn_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
% 	plot(time_array(pos1:pos2), smooth(ave_of_early_trials_in_ea_bin{n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
% 	plot(time_array(pos1:pos2), smooth(ave_of_rew_trials_in_ea_bin{n_divs+1-n_bin}(pos1:pos2), 50, 'gauss'), 'linewidth', 2)
% 	linkarray(end+1) = ax;
%     legend(names);
%     xlim(winpeak);

% end


% linkaxes(linkarray, 'xy')

% +1-n_bin



% print(2,'-depsc','-painters','lta_DLS_mixed_inverseEARLY_5bin.eps')
% saveas(2,'lta_DLS_mixed_inverseEARLY_5bin.fig','fig')