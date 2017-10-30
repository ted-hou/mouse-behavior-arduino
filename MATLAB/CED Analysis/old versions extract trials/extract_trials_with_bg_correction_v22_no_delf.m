%% Extract CED Data
%	Created:		4-4-17	ahamilos
%	Last Updated:	4-25-17	ahamilos
%
%   4-25-17: no del F
%   4-18-17: added SEM calculation and plots for SNc and DLS total
%-----------------------------------------------------------------------------------------
%% Open file:
response = inputdlg('Enter CED filename (don''t include *_lick, etc)');
filename = response{1};
%-----------------------------------------------------------------------------------------
%% Extract DIGITAL variables from file

% Extract the lamp_off structure and timepoints
lamp_off_struct = eval([filename, '_Lamp_OFF']);
trial_start_times = lamp_off_struct.times;

% Extract the cue_on structure and timepoints
cue_on_struct = eval([filename, '_Start_Cu']);
cue_on_times = cue_on_struct.times;

% Extract the Juice structure and timepoints
juice_struct = eval([filename, '_Juice']);
juice_times = juice_struct.times;

% Extract the LampON structure and timepoints
lampOn_struct = eval([filename, '_LampON']);
lampOn_times = lampOn_struct.times;

% Extract the Lick structure and timepoints
lick_struct = eval([filename, '_Lick']);
lick_times = lick_struct.times;

% Extract the Trigger structure and timepoints
trigger_struct = eval([filename, '_Trigger']);
trigger_times = trigger_struct.times;

% Extract the Keyboard structure and timepoints and codes
keyboard_struct = eval([filename, '_Keyboard']);
keyboard_times = keyboard_struct.times;
keyboard_codes = keyboard_struct.codes;

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)



%%------------------------------------DLS---------------------------------------------------
% time resolution in 1000Hz rate is 0.001 sec
% 	thus for each trial start time, take the value: time +/- 0.001 sec

% Extract the DLS signal structure, timepoints and analog values
DLS_struct = eval([filename, '_DLS']);
DLS_values = DLS_struct.values;
DLS_times = DLS_struct.times;

%********************correction for bleaching**********************
%[~, DLS_values] = background_correction_fit_fx(DLS_values);

% Find the DLS times when trial starting:
DLS_trial_start_positions = []; % to track which positions should be the split points
trial_num = 1;

for i_starttime = 1:length(trial_start_times)
	positions = find(DLS_times<trial_start_times(trial_num)+0.001 & DLS_times>trial_start_times(trial_num)-0.001);
    DLS_trial_start_positions(trial_num) = positions(1);
	trial_num = trial_num + 1;
end

% Find the DLS times when start cue on:
DLS_cue_on_positions = []; % to track which positions should be the split points
trial_num = 1;

for i_starttime = 1:length(cue_on_times)
	positions = find(DLS_times<cue_on_times(trial_num)+0.001 & DLS_times>cue_on_times(trial_num)-0.001);
    DLS_cue_on_positions(trial_num) = positions(1);
	trial_num = trial_num + 1;
end


% Trim DLS to remove non-trial data: delete all times before first trial start and after last trial start
% first_trial_start_time = DLS_trial_start_positions(1);
% last_trial_start_time = DLS_trial_start_positions(end); % don't include last incomplete trial

DLS_times_trimmed = DLS_times(DLS_trial_start_positions(1):DLS_trial_start_positions(end)); %doesn't include the last incomplete trial
DLS_values_trimmed = DLS_values(DLS_trial_start_positions(1):DLS_trial_start_positions(end));


% Divide DLS into trials 
%	Easiest way may be to make pre-cue and post-cue arrays so that it's aligned to the start cue

% For 5 sec interval -> total post-cue length = 1000samples/s * (7 + 10) s = 17000 samples/trial
% Precue delay: 400-1500 ms = 1.5 sec * 1000samples/s = 1500 samples/precue

DLS_pre_cue_times_by_trial = NaN(num_trials_plus_1-1, 1500);
DLS_post_cue_times_by_trial = NaN(num_trials_plus_1-1, 17001);		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

DLS_pre_cue_values_by_trial = NaN(num_trials_plus_1-1, 1500);
DLS_post_cue_values_by_trial = NaN(num_trials_plus_1-1, 17001);


trimmed_DLS_trial_start_positions = DLS_trial_start_positions - DLS_trial_start_positions(1) + 1;
trimmed_DLS_cue_on_positions = DLS_cue_on_positions - DLS_trial_start_positions(1) + 1;


% Do the precue files first: try doing the whole thing in reverse
DLS_position = length(DLS_times_trimmed);
rev_order_trials = abs(-(length(trial_start_times)-1) : 0);
rev_order_times = abs(-18500: -1);
rev_order_time_markers = abs(-1500:-1);
rev_order_DLS_times = DLS_times_trimmed';
rev_order_DLS_values = DLS_values_trimmed';
lasttrialdone = false;
dontupdate = false;

for i_trial = rev_order_trials
	pastcue = true;
	newtrial = false;
	precue_position = 1;
	for i_time = rev_order_times % fill the array from the bottom and end (1499:1)
		if find(trimmed_DLS_trial_start_positions == DLS_position)
			% Need to ignore the last trial start time because is not a full trial:
			if lasttrialdone == false
				lasttrialdone = true;
                DLS_position = DLS_position - 1;
			else
				newtrial = true;
				DLS_pre_cue_times_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_DLS_times(DLS_position);
				DLS_pre_cue_values_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_DLS_values(DLS_position);
				DLS_position = DLS_position - 1;
				break
			end
		elseif find(trimmed_DLS_cue_on_positions == DLS_position)
			pastcue = false;
			dontupdate = true;
            DLS_position = DLS_position - 1;
		end

		if dontupdate
            dontupdate = false;
        elseif ~pastcue && ~newtrial
			DLS_pre_cue_times_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_DLS_times(DLS_position);
			DLS_pre_cue_values_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_DLS_values(DLS_position);
			DLS_position = DLS_position - 1;
			precue_position = precue_position+1;
        else
			DLS_position = DLS_position - 1;
		end
		if DLS_position > length(rev_order_DLS_times)
			break
		end
	end
	if DLS_position > length(rev_order_DLS_times)
		break
	end
end




% Now the postcue:
DLS_position = 1;
positions_array = [1:17001];
dontupdate = false;

for i_trial = 0:(length(trial_start_times)-1)
	pastcue = false;
	newtrial = false;
	for i_time = 1:18500 % fill the array from the front
		if find(trimmed_DLS_trial_start_positions == DLS_position)
			newtrial = true;
			DLS_position = DLS_position + 1;
			postcue_position = 1;
			break
		elseif find(trimmed_DLS_cue_on_positions == DLS_position)
            DLS_post_cue_times_by_trial(i_trial, postcue_position) = DLS_times_trimmed(DLS_position);
			DLS_post_cue_values_by_trial(i_trial, postcue_position) = DLS_values_trimmed(DLS_position);
			pastcue = true;
			dontupdate = true;
            DLS_position = DLS_position + 1;
            postcue_position = postcue_position + 1;
		end

		if pastcue && ~dontupdate
			DLS_post_cue_times_by_trial(i_trial, positions_array(postcue_position)) = DLS_times_trimmed(DLS_position);
			DLS_post_cue_values_by_trial(i_trial, positions_array(postcue_position)) = DLS_values_trimmed(DLS_position);
			DLS_position = DLS_position + 1;
			postcue_position = postcue_position+1;
        elseif dontupdate
        % do nothing
            dontupdate = false;
        else
			DLS_position = DLS_position + 1;
		end
		if DLS_position > length(DLS_times_trimmed)
			break
		end
	end
	if DLS_position > length(DLS_times_trimmed)
		break
	end
end


%% Combine into one vector:
DLS_times_by_trial = horzcat(DLS_pre_cue_times_by_trial, DLS_post_cue_times_by_trial);
DLS_values_by_trial = horzcat(DLS_pre_cue_values_by_trial, DLS_post_cue_values_by_trial);
% CUE ON marker @ column position 1501!!!
 



%%------------------------------------SNc---------------------------------------------------
% time resolution in 1000Hz rate is 0.001 sec
% 	thus for each trial start time, take the value: time +/- 0.001 sec

% Extract the SNc signal structure, timepoints and analog values
SNc_struct = eval([filename, '_SNc']);
SNc_values = SNc_struct.values;
SNc_times = SNc_struct.times;


%********************correction for bleaching**********************
%[~, SNc_values] = background_correction_fit_fx(SNc_values);

% Find the SNc times when trial starting:
SNc_trial_start_positions = []; % to track which positions should be the split points
trial_num = 1;

for i_starttime = 1:length(trial_start_times)
	positions = find(SNc_times<trial_start_times(trial_num)+0.001 & SNc_times>trial_start_times(trial_num)-0.001);
    SNc_trial_start_positions(trial_num) = positions(1);
	trial_num = trial_num + 1;
end

% Find the SNc times when start cue on:
SNc_cue_on_positions = []; % to track which positions should be the split points
trial_num = 1;

for i_starttime = 1:length(cue_on_times)
	positions = find(SNc_times<cue_on_times(trial_num)+0.001 & SNc_times>cue_on_times(trial_num)-0.001);
    SNc_cue_on_positions(trial_num) = positions(1);
	trial_num = trial_num + 1;
end


% Trim SNc to remove non-trial data: delete all times before first trial start and after last trial start

SNc_times_trimmed = SNc_times(SNc_trial_start_positions(1):SNc_trial_start_positions(end)); %doesn't include the last incomplete trial
SNc_values_trimmed = SNc_values(SNc_trial_start_positions(1):SNc_trial_start_positions(end));


% Divide SNc into trials 
%	Easiest way may be to make pre-cue and post-cue arrays so that it's aligned to the start cue

% For 5 sec interval -> total post-cue length = 1000samples/s * (7 + 10) s = 17000 samples/trial
% Precue delay: 400-1500 ms = 1.5 sec * 1000samples/s = 1500 samples/precue

SNc_pre_cue_times_by_trial = NaN(num_trials_plus_1-1, 1500);
SNc_post_cue_times_by_trial = NaN(num_trials_plus_1-1, 17001);		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

SNc_pre_cue_values_by_trial = NaN(num_trials_plus_1-1, 1500);
SNc_post_cue_values_by_trial = NaN(num_trials_plus_1-1, 17001);


trimmed_SNc_trial_start_positions = SNc_trial_start_positions - SNc_trial_start_positions(1) + 1;
trimmed_SNc_cue_on_positions = SNc_cue_on_positions - SNc_trial_start_positions(1) + 1;


% Do the precue files first: try doing the whole thing in reverse
SNc_position = length(SNc_times_trimmed);
rev_order_trials = abs(-(length(trial_start_times)-1) : 0);
rev_order_times = abs(-18500: -1);
rev_order_time_markers = abs(-1500:-1);
rev_order_SNc_times = SNc_times_trimmed';
rev_order_SNc_values = SNc_values_trimmed';
lasttrialdone = false;

for i_trial = rev_order_trials
	pastcue = true;
	newtrial = false;
	precue_position = 1;
	for i_time = rev_order_times % fill the array from the bottom and end (1499:1)
		if find(trimmed_SNc_trial_start_positions == SNc_position)
			% Need to ignore the last trial start time because is not a full trial:
			if lasttrialdone == false
				lasttrialdone = true;
                SNc_position = SNc_position - 1;
			else
				newtrial = true;
				SNc_pre_cue_times_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_SNc_times(SNc_position);
				SNc_pre_cue_values_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_SNc_values(SNc_position);
				SNc_position = SNc_position - 1;
				break
			end
		elseif find(trimmed_SNc_cue_on_positions == SNc_position)
			pastcue = false;
			dontupdate = true;
            SNc_position = SNc_position - 1;
		end

		if dontupdate
            dontupdate = false;
        elseif ~pastcue && ~newtrial
			SNc_pre_cue_times_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_SNc_times(SNc_position);
			SNc_pre_cue_values_by_trial(i_trial, rev_order_time_markers(precue_position)) = rev_order_SNc_values(SNc_position);
			SNc_position = SNc_position - 1;
			precue_position = precue_position+1;
        else
			SNc_position = SNc_position - 1;
		end
		if SNc_position > length(rev_order_SNc_times)
			break
		end
	end
	if SNc_position > length(rev_order_SNc_times)
		break
	end
end




% Now the postcue:
SNc_position = 1;
positions_array = [1:17001];
dontupdate = false;

for i_trial = 0:(length(trial_start_times)-1)
	pastcue = false;
	newtrial = false;
	for i_time = 1:18500 % fill the array from the front
		if find(trimmed_SNc_trial_start_positions == SNc_position)
			newtrial = true;
			SNc_position = SNc_position + 1;
			postcue_position = 1;
			break
		elseif find(trimmed_SNc_cue_on_positions == SNc_position)
            SNc_post_cue_times_by_trial(i_trial, postcue_position) = SNc_times_trimmed(SNc_position);
			SNc_post_cue_values_by_trial(i_trial, postcue_position) = SNc_values_trimmed(SNc_position);
			pastcue = true;
			dontupdate = true;
            SNc_position = SNc_position + 1;
            postcue_position = postcue_position + 1;
		end

		if pastcue && ~dontupdate
			SNc_post_cue_times_by_trial(i_trial, positions_array(postcue_position)) = SNc_times_trimmed(SNc_position);
			SNc_post_cue_values_by_trial(i_trial, positions_array(postcue_position)) = SNc_values_trimmed(SNc_position);
			SNc_position = SNc_position + 1;
			postcue_position = postcue_position+1;
        elseif dontupdate
        % do nothing
            dontupdate = false;
        else
			SNc_position = SNc_position + 1;
		end
		if SNc_position > length(SNc_times_trimmed)
			break
		end
	end
	if SNc_position > length(SNc_times_trimmed)
		break
	end
end


%% Combine into one vector:
SNc_times_by_trial = horzcat(SNc_pre_cue_times_by_trial, SNc_post_cue_times_by_trial);
SNc_values_by_trial = horzcat(SNc_pre_cue_values_by_trial, SNc_post_cue_values_by_trial);
% CUE ON marker @ column position 1501!!!
 

%% ----------------------------------------------Trial Analysis-------------------------------------------------------


%% Average the trials together:

SNc_sum = sum(SNc_values_by_trial,1);
SNc_ave = SNc_sum/(num_trials_plus_1-1);


DLS_sum = sum(DLS_values_by_trial,1);
DLS_ave = DLS_sum/(num_trials_plus_1-1);


%% Determine if trial is operant (defined as a trial in which mouse licked between no-lick and target and scored as first lick on PSTH)
hybrid_trial_is_operant = hybrid_trial_is_operant_fx(obj);
operant_trial_numbers = find(hybrid_trial_is_operant == 1);

hybrid_trial_is_not_operant = hybrid_trial_is_NOT_operant_fx(obj);
NOToperant_trial_numbers = find(hybrid_trial_is_not_operant == 1);

% Average trials based on pav vs operant:

SNc_sum_operant = sum(SNc_values_by_trial(operant_trial_numbers,:),1);
SNc_ave_operant = SNc_sum_operant/length(operant_trial_numbers);

DLS_sum_operant = sum(DLS_values_by_trial(operant_trial_numbers,:),1);
DLS_ave_operant = DLS_sum_operant/length(operant_trial_numbers);


SNc_sum_NOToperant = sum(SNc_values_by_trial(NOToperant_trial_numbers(1:end-1),:),1);
SNc_ave_NOToperant = SNc_sum_NOToperant/length(NOToperant_trial_numbers(1:end-1));

DLS_sum_NOToperant = sum(DLS_values_by_trial(NOToperant_trial_numbers(1:end-1),:),1);
DLS_ave_NOToperant = DLS_sum_NOToperant/length(NOToperant_trial_numbers(1:end-1));

% Calculate SEM:
% SEM will also be a 1xn vector, where the SEM is calc'd for each timepoint
SEM_SNc = [];
SEM_DLS = [];

std_SNc = std(SNc_values_by_trial);
std_DLS = std(DLS_values_by_trial);

SEM_SNc = std_SNc ./ sqrt(num_trials);
SEM_DLS = std_DLS ./ sqrt(num_trials);


%%-------------------------------------FILTER DATA---------------------------------------------
% f_SNc_ave = cedBandpass2(SNc_ave);
% f_DLS_ave = cedBandpass2(DLS_ave);
% f_SNc_ave_operant = cedBandpass2(SNc_ave_operant);
% f_DLS_ave_operant = cedBandpass2(DLS_ave_operant);
% f_SNc_ave_NOToperant = cedBandpass2(SNc_ave_NOToperant);
% f_DLS_ave_NOToperant = cedBandpass2(DLS_ave_NOToperant);


f_SNc_ave = smooth(SNc_ave, 50, 'gauss');
f_DLS_ave = smooth(DLS_ave, 50, 'gauss');
f_SNc_ave_operant = smooth(SNc_ave_operant, 50, 'gauss');
f_DLS_ave_operant = smooth(DLS_ave_operant, 50, 'gauss');
f_SNc_ave_NOToperant = smooth(SNc_ave_NOToperant, 50, 'gauss');
f_DLS_ave_NOToperant = smooth(DLS_ave_NOToperant, 50, 'gauss');


%%--------------------------------------PLOTS--------------------------------------------------
% Averaged trial plots: SNc
figure,
subplot(2,1,1)
plot(f_SNc_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(f_SNc_ave)-.01,max(f_SNc_ave)+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(f_SNc_ave)-.01,max(f_SNc_ave)+.01], 'r-', 'linewidth', 3)
ylim([min(f_SNc_ave)-.001,max(f_SNc_ave)+.001])
xlim([0,18500])
xlabel('Time (ms)', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
title('SNc Average Across Trials', 'fontsize', 20)
set(gca, 'fontsize', 20)

% Averaged trial plots: DLS
subplot(2,1,2)
plot(f_DLS_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(f_DLS_ave)-.01,max(f_DLS_ave)+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(f_DLS_ave)-.01,max(f_DLS_ave)+.01], 'r-', 'linewidth', 3)
xlim([0,18500])
ylim([min(f_DLS_ave)-.001,max(f_DLS_ave)+.001])
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
title('Striatal Average Across Trials', 'fontsize', 20)
set(gca, 'fontsize', 20)

% Separate averaged trial plots into pav and op trials:-------------------
figure,
subplot(2,2,1)
plot(f_SNc_ave_operant, 'linewidth', 3)
hold on
plot([1500, 1500], [min(f_SNc_ave_operant)-.01,max(f_SNc_ave_operant)+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(f_SNc_ave_operant)-.01,max(f_SNc_ave_operant)+.01], 'r-', 'linewidth', 3)
xlim([0,18500])
ylim([min(f_SNc_ave_operant)-.001,max(f_SNc_ave_operant)+.001])
title('SNc OPERANT Average Across Trials', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
set(gca, 'fontsize', 20)

subplot(2,2,2)
plot(f_SNc_ave_NOToperant, 'linewidth', 3)
hold on
plot([1500, 1500], [min(f_SNc_ave_NOToperant)-.01,max(f_SNc_ave_NOToperant)+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(f_SNc_ave_NOToperant)-.01,max(f_SNc_ave_NOToperant)+.01], 'r-', 'linewidth', 3)
xlim([0,18500])
ylim([min(f_SNc_ave_NOToperant)-.001,max(f_SNc_ave_NOToperant)+.001])
title('SNc Pavlovian Average Across Trials', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
set(gca, 'fontsize', 20)

subplot(2,2,3)
plot(f_DLS_ave_operant, 'linewidth', 3)
hold on
plot([1500, 1500], [min(f_DLS_ave_operant)-.01,max(f_DLS_ave_operant)+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(f_DLS_ave_operant)-.01,max(f_DLS_ave_operant)+.01], 'r-', 'linewidth', 3)
xlim([0,18500])
ylim([min(f_DLS_ave_operant)-.001,max(f_DLS_ave_operant)+.001])
title('Striatal OPERANT Average Across Trials', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
set(gca, 'fontsize', 20)

subplot(2,2,4)
plot(f_DLS_ave_NOToperant, 'linewidth', 3)
hold on
plot([1500, 1500], [min(f_DLS_ave_NOToperant)-.01,max(f_DLS_ave_NOToperant)+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(f_DLS_ave_NOToperant)-.01,max(f_DLS_ave_NOToperant)+.01], 'r-', 'linewidth', 3)
xlim([0,18500])
ylim([min(f_DLS_ave_NOToperant)-.001,max(f_DLS_ave_NOToperant)+.001])
title('Striatal Pavlovian Average Across Trials', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
set(gca, 'fontsize', 20)
















% %---------PLOT SNc----------
% plot_SNc_times = SNc_times_by_trial';
% plot_SNc_values = SNc_values_by_trial';

% % Generate a plot for each trial:
% 	figure
% 	for i_plot = 1:50
% 		subplot(10, 5, i_plot)
% 		% plot(plot_SNc_times(:,i_plot), plot_SNc_values(:,i_plot))
% 		plot(plot_SNc_values(:,i_plot))
% 		xlim([1500,9000])
% 		% xlim([1,18500])
% 		% ylim([0.15,.35])
% 		ylim([0.5,.7])
% 		title([num2str(i_plot)])
% 	end

% 	plotnum = 1;
% 	figure
% 	for i_plot = 51:100
% 		subplot(10, 5, plotnum)
% 		% plot(plot_SNc_times(:,i_plot), plot_SNc_values(:,i_plot))
% 		plot(plot_SNc_values(:,i_plot))
% 		% xlim([1,18500])
% 		xlim([1500,9000])
% 		ylim([0.5,.7])
% 		plotnum = plotnum + 1;
% 		title([num2str(i_plot)])
% 	end
% 	plotnum = 1;
% 	figure
% 	for i_plot = 100:num_trials_plus_1-1
% 		subplot(10, 5, plotnum)
% 		% plot(plot_SNc_times(:,i_plot), plot_SNc_values(:,i_plot))
% 		plot(plot_SNc_values(:,i_plot))
% 		xlim([1500,9000])
% 		% xlim([1,18500])
% 		ylim([0.5,.7])
% 		plotnum = plotnum + 1;
% 		title([num2str(i_plot)])
% 	end












%---------PLOT DLS PRECUE----------
% plot_precue_DLS_values = DLS_pre_cue_values_by_trial';
	% 
	% % Generate a plot for each trial:
	% figure
	% for i_plot = 1:50
	% 	subplot(10, 5, i_plot)
	% 	plot(plot_precue_DLS_values(:,i_plot))
	% 	xlim([0,1500])
	% end
	% 
	% plotnum = 1;
	% figure
	% for i_plot = 51:100
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_precue_DLS_values(:,i_plot))
	% 	xlim([0,1500])
	% 	plotnum = plotnum + 1;
	% end
	% plotnum = 1;
	% figure
	% for i_plot = 100:num_trials_plus_1
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_precue_DLS_values(:,i_plot))
	% 	xlim([0,1500])
	% 	plotnum = plotnum + 1;
	% end

%---------PLOT DLS POSTCUE----------
% plot_postcue_DLS_values = DLS_post_cue_values_by_trial';

% 	% % Generate a plot for each trial:
	% figure
	% for i_plot = 1:50
	% 	subplot(10, 5, i_plot)
	% 	plot(plot_postcue_DLS_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	title([num2str(i_plot)])
	% end

	% plotnum = 1;
	% figure
	% for i_plot = 51:100
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_postcue_DLS_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	plotnum = plotnum + 1;
	% 	title([num2str(i_plot)])
	% end
	% plotnum = 1;
	% figure
	% for i_plot = 100:num_trials_plus_1
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_postcue_DLS_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	plotnum = plotnum + 1;
	% 	title([num2str(i_plot)])
	% end



%---------PLOT SNc PRECUE----------
% plot_precue_SNc_values = SNc_pre_cue_values_by_trial';
	% 
	% % Generate a plot for each trial:
	% figure
	% for i_plot = 1:50
	% 	subplot(10, 5, i_plot)
	% 	plot(plot_precue_SNc_values(:,i_plot))
	% 	xlim([0,1500])
	% end
	% 
	% plotnum = 1;
	% figure
	% for i_plot = 51:100
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_precue_SNc_values(:,i_plot))
	% 	xlim([0,1500])
	% 	plotnum = plotnum + 1;
	% end
	% plotnum = 1;
	% figure
	% for i_plot = 100:num_trials_plus_1
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_precue_SNc_values(:,i_plot))
	% 	xlim([0,1500])
	% 	plotnum = plotnum + 1;
	% end

%---------PLOT SNc POSTCUE----------
% plot_postcue_SNc_values = SNc_post_cue_values_by_trial';

% 	% % Generate a plot for each trial:
	% figure
	% for i_plot = 1:50
	% 	subplot(10, 5, i_plot)
	% 	plot(plot_postcue_SNc_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	title([num2str(i_plot)])
	% end

	% plotnum = 1;
	% figure
	% for i_plot = 51:100
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_postcue_SNc_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	plotnum = plotnum + 1;
	% 	title([num2str(i_plot)])
	% end
	% plotnum = 1;
	% figure
	% for i_plot = 100:num_trials_plus_1
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_postcue_SNc_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	plotnum = plotnum + 1;
	% 	title([num2str(i_plot)])
	% end





