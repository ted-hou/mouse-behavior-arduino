%% Extract CED Data
%	Created:		4-4-17	ahamilos
%	Last Updated:	4-6-17	ahamilos
%-----------------------------------------------------------------------------------------
%% Open file:
response = inputdlg('Enter CED filename (don''t include *_lick, etc)');
filename = response{1};
%-----------------------------------------------------------------------------------------
%% Extract variables from file

% Extract the lamp_off structure and timepoints
lamp_off_struct = eval([filename, '_Lamp_OFF']);
trial_start_times = lamp_off_struct.times;

% Extract the cue_on structure and timepoints
cue_on_struct = eval([filename, '_Start_Cu']);
cue_on_times = cue_on_struct.times;

% Number of trials:
num_trials = length(trial_start_times);

% %------------------------------------DLS---------------------------------------------------
% % time resolution in 1000Hz rate is 0.001 sec
% % 	thus for each trial start time, take the value: time +/- 0.001 sec

% % Extract the DLS signal structure, timepoints and analog values
% DLS_struct = eval([filename, '_DLS']);
% DLS_values = DLS_struct.values;
% DLS_times = DLS_struct.times;

% % Find the DLS times when trial starting:
% DLS_trial_start_positions = []; % to track which positions should be the split points
% trial_num = 1;

% for i_starttime = 1:length(trial_start_times)
% 	positions = find(DLS_times<trial_start_times(trial_num)+0.001 & DLS_times>trial_start_times(trial_num)-0.001);
%     DLS_trial_start_positions(trial_num) = positions(1);
% 	trial_num = trial_num + 1;
% end

% % Find the DLS times when start cue on:
% DLS_cue_on_positions = []; % to track which positions should be the split points
% trial_num = 1;

% for i_starttime = 1:length(cue_on_times)
% 	positions = find(DLS_times<cue_on_times(trial_num)+0.001 & DLS_times>cue_on_times(trial_num)-0.001);
%     DLS_cue_on_positions(trial_num) = positions(1);
% 	trial_num = trial_num + 1;
% end


% % Trim DLS to remove non-trial data: delete all times before first trial start and after last trial start
% % first_trial_start_time = DLS_trial_start_positions(1);
% % last_trial_start_time = DLS_trial_start_positions(end); % don't include last incomplete trial

% DLS_times_trimmed = DLS_times(DLS_trial_start_positions(1):DLS_trial_start_positions(end)); %doesn't include the last incomplete trial
% DLS_values_trimmed = DLS_values(DLS_trial_start_positions(1):DLS_trial_start_positions(end));


% % Divide DLS into trials 
% %	Easiest way may be to make pre-cue and post-cue arrays so that it's aligned to the start cue

% % For 5 sec interval -> total post-cue length = 1000samples/s * (7 + 10) s = 17000 samples/trial
% % Precue delay: 400-1500 ms = 1.5 sec * 1000samples/s = 1500 samples/precue

% DLS_pre_cue_times_by_trial = NaN(num_trials, 1500);
% DLS_post_cue_times_by_trial = NaN(num_trials, 17001);		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

% DLS_pre_cue_values_by_trial = NaN(num_trials, 1500);
% DLS_post_cue_values_by_trial = NaN(num_trials, 17001);

% time_markers = abs(-1499:-1);
% trimmed_DLS_trial_start_positions = DLS_trial_start_positions - DLS_trial_start_positions(1) + 1;
% trimmed_DLS_cue_on_positions = DLS_cue_on_positions - DLS_trial_start_positions(1) + 1;


% % Do the precue files first:
% DLS_position = 1;

% for i_trial = 0:length(trial_start_times - 2)
% 	pastcue = false;
% 	newtrial = false;
% 	precue_position = 1;
% 	for i_time = 1:18500 % fill the array from the end (1499:1), inverts the time scale...
% 		if find(trimmed_DLS_trial_start_positions == DLS_position)
% 			newtrial = true;
% 			DLS_pre_cue_times_by_trial(i_trial + 1, 1500) = DLS_times_trimmed(DLS_position);
% 			DLS_pre_cue_values_by_trial(i_trial + 1, 1500) = DLS_values_trimmed(DLS_position);
% 			DLS_position = DLS_position + 1;
% 			break
% 		elseif find(trimmed_DLS_cue_on_positions == DLS_position)
% 			pastcue = true;
% 			dontupdate = true;
%             DLS_position = DLS_position + 1;
% 		end

% 		if ~pastcue && ~newtrial
% 			DLS_pre_cue_times_by_trial(i_trial, time_markers(precue_position)) = DLS_times_trimmed(DLS_position);
% 			DLS_pre_cue_values_by_trial(i_trial, time_markers(precue_position)) = DLS_values_trimmed(DLS_position);
% 			DLS_position = DLS_position + 1;
% 			precue_position = precue_position+1;
%         elseif dontupdate
%         % do nothing
%             dontupdate = false;
%         else
% 			DLS_position = DLS_position + 1;
% 		end
% 		if DLS_position > length(DLS_times_trimmed)
% 			break
% 		end
% 	end
% 	if DLS_position > length(DLS_times_trimmed)
% 		break
% 	end
% end

% %for plotting:
% plot_precue_DLS_values = DLS_pre_cue_values_by_trial';
% 	% 
% 	% % Generate a plot for each trial:
% 	% figure
% 	% for i_plot = 1:50
% 	% 	subplot(10, 5, i_plot)
% 	% 	plot(plot_precue_DLS_values(:,i_plot))
% 	% 	xlim([0,1500])
% 	% end
% 	% 
% 	% plotnum = 1;
% 	% figure
% 	% for i_plot = 51:100
% 	% 	subplot(10, 5, plotnum)
% 	% 	plot(plot_precue_DLS_values(:,i_plot))
% 	% 	xlim([0,1500])
% 	% 	plotnum = plotnum + 1;
% 	% end
% 	% plotnum = 1;
% 	% figure
% 	% for i_plot = 100:num_trials
% 	% 	subplot(10, 5, plotnum)
% 	% 	plot(plot_precue_DLS_values(:,i_plot))
% 	% 	xlim([0,1500])
% 	% 	plotnum = plotnum + 1;
% 	% end


% % Now the postcue:
% DLS_position = 1;
% positions_array = [1:17001];
% dontupdate = false;

% for i_trial = 0:length(trial_start_times - 2)
% 	pastcue = false;
% 	newtrial = false;
% 	for i_time = 1:18500 % fill the array from the front
% 		if find(trimmed_DLS_trial_start_positions == DLS_position)
% 			newtrial = true;
% 			DLS_position = DLS_position + 1;
% 			postcue_position = 1;
% 			break
% 		elseif find(trimmed_DLS_cue_on_positions == DLS_position)
%             DLS_post_cue_times_by_trial(i_trial, postcue_position) = DLS_times_trimmed(DLS_position);
% 			DLS_post_cue_values_by_trial(i_trial, postcue_position) = DLS_values_trimmed(DLS_position);
% 			pastcue = true;
% 			dontupdate = true;
%             DLS_position = DLS_position + 1;
%             postcue_position = postcue_position + 1;
% 		end

% 		if pastcue && ~dontupdate
% 			DLS_post_cue_times_by_trial(i_trial, positions_array(postcue_position)) = DLS_times_trimmed(DLS_position);
% 			DLS_post_cue_values_by_trial(i_trial, positions_array(postcue_position)) = DLS_values_trimmed(DLS_position);
% 			DLS_position = DLS_position + 1;
% 			postcue_position = postcue_position+1;
%         elseif dontupdate
%         % do nothing
%             dontupdate = false;
%         else
% 			DLS_position = DLS_position + 1;
% 		end
% 		if DLS_position > length(DLS_times_trimmed)
% 			break
% 		end
% 	end
% 	if DLS_position > length(DLS_times_trimmed)
% 		break
% 	end
% end

% %for plotting:
% plot_postcue_DLS_values = DLS_post_cue_values_by_trial';

% 	% % Generate a plot for each trial:
% 	% figure
% 	% for i_plot = 1:50
% 	% 	subplot(10, 5, i_plot)
% 	% 	plot(plot_postcue_DLS_values(:,i_plot))
% 	% 	xlim([0,17000])
% 	% 	ylim([0.15,.35])
% 	% 	title([num2str(i_plot)])
% 	% end

% 	% plotnum = 1;
% 	% figure
% 	% for i_plot = 51:100
% 	% 	subplot(10, 5, plotnum)
% 	% 	plot(plot_postcue_DLS_values(:,i_plot))
% 	% 	xlim([0,17000])
% 	% 	ylim([0.15,.35])
% 	% 	plotnum = plotnum + 1;
% 	% 	title([num2str(i_plot)])
% 	% end
% 	% plotnum = 1;
% 	% figure
% 	% for i_plot = 100:num_trials
% 	% 	subplot(10, 5, plotnum)
% 	% 	plot(plot_postcue_DLS_values(:,i_plot))
% 	% 	xlim([0,17000])
% 	% 	ylim([0.15,.35])
% 	% 	plotnum = plotnum + 1;
% 	% 	title([num2str(i_plot)])
% 	% end

% %% Combine into one vector:
% DLS_times_by_trial = horzcat(DLS_pre_cue_times_by_trial, DLS_post_cue_times_by_trial);
% DLS_values_by_trial = horzcat(DLS_pre_cue_values_by_trial, DLS_post_cue_values_by_trial);
% % CUE ON marker @ column position 1501!!!

% %%% ISSUE - getting redundant points when doing like this... instead, let's try doing it all at once...



















% %% Note I did SNc in one step but this is probs not as good as dividing into 2 steps
% %------------------------------------SNc---------------------------------------------------
% % time resolution in 1000Hz rate is 0.001 sec
% % 	thus for each trial start time, take the value: time +/- 0.001 sec

% % Extract the SNc signal structure, timepoints and analog values
% SNc_struct = eval([filename, '_SNc']);
% SNc_values = SNc_struct.values;
% SNc_times = SNc_struct.times;

% % Find the SNc times when trial starting:
% SNc_trial_start_positions = []; % to track which positions should be the split points
% trial_num = 1;

% for i_starttime = 1:length(trial_start_times)
% 	positions = find(SNc_times<trial_start_times(trial_num)+0.001 & SNc_times>trial_start_times(trial_num)-0.001);
%     SNc_trial_start_positions(trial_num) = positions(1);
% 	trial_num = trial_num + 1;
% end

% % Find the SNc times when start cue on:
% SNc_cue_on_positions = []; % to track which positions should be the split points
% trial_num = 1;

% for i_starttime = 1:length(cue_on_times)
% 	positions = find(SNc_times<cue_on_times(trial_num)+0.001 & SNc_times>cue_on_times(trial_num)-0.001);
%     SNc_cue_on_positions(trial_num) = positions(1);
% 	trial_num = trial_num + 1;
% end


% % Trim SNc to remove non-trial data: delete all times before first trial start and after last trial start
% SNc_times_trimmed = SNc_times(SNc_trial_start_positions(1):SNc_trial_start_positions(end)); %doesn't include the last incomplete trial
% SNc_values_trimmed = SNc_values(SNc_trial_start_positions(1):SNc_trial_start_positions(end));

% trimmed_SNc_trial_start_positions = SNc_trial_start_positions - SNc_trial_start_positions(1) + 1;
% trimmed_SNc_cue_on_positions = SNc_cue_on_positions - SNc_trial_start_positions(1) + 1;

% % Divide SNc into trials 

% SNc_times_by_trial = NaN(num_trials, 18501);		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint
% SNc_values_by_trial = NaN(num_trials, 18501);






% % We will define trial start time as position #1501
% precue_position_markers = abs(1:1500);
% postcue_position_markers = (1501:18501);
% SNc_position = 1;
% SNc_positions_array = [1:18501];
% dontupdate = false;

% for i_trial = 0:length(trial_start_times - 2)
% 	pastcue = false;
% 	newtrial = false;
% 	for i_time = 1:18500 
% 		if find(trimmed_SNc_trial_start_positions == SNc_position)
% 			newtrial = true;
% 			SNc_times_by_trial(i_trial + 1, 1) = SNc_times_trimmed(SNc_position);
% 			SNc_values_by_trial(i_trial + 1, 1) = SNc_values_trimmed(SNc_position);
% 			SNc_position = SNc_position + 1;
% 			postcue_position = 1;
% 			precue_position = 2;
% 			break
% 		elseif find(trimmed_SNc_cue_on_positions == SNc_position)
%             SNc_times_by_trial(i_trial, postcue_position_markers(postcue_position)) = SNc_times_trimmed(SNc_position);
% 			SNc_values_by_trial(i_trial, postcue_position_markers(postcue_position)) = SNc_values_trimmed(SNc_position);
% 			pastcue = true;
% 			dontupdate = true;
%             SNc_position = SNc_position + 1;
%             postcue_position = postcue_position + 1;
% 		end

% 		if ~pastcue && ~newtrial && ~dontupdate
% 			SNc_times_by_trial(i_trial, precue_position_markers(precue_position)) = SNc_times_trimmed(SNc_position);
% 			SNc_values_by_trial(i_trial, precue_position_markers(precue_position)) = SNc_values_trimmed(SNc_position);
% 			SNc_position = SNc_position + 1;
% 			precue_position = precue_position+1;

% 		elseif pastcue && ~dontupdate && ~newtrial
% 			SNc_times_by_trial(i_trial, postcue_position_markers(postcue_position)) = SNc_times_trimmed(SNc_position);
% 			SNc_values_by_trial(i_trial, postcue_position_markers(postcue_position)) = SNc_values_trimmed(SNc_position);
% 			SNc_position = SNc_position + 1;
% 			postcue_position = postcue_position+1;
		 
%         elseif dontupdate
%         % do nothing
%             dontupdate = false;
%         else
% 			SNc_position = SNc_position + 1;
% 		end
% 		if SNc_position > length(SNc_times_trimmed)
% 			break
% 		end
% 	end
% 	if SNc_position > length(SNc_times_trimmed)
% 		break
% 	end
% end

% %for plotting:
% plot_SNc_values = SNc_values_by_trial';

% 	% % Generate a plot for each trial:
% 	% figure
% 	% for i_plot = 1:50
% 	% 	subplot(10, 5, i_plot)
% 	% 	plot(plot_postcue_DLS_values(:,i_plot))
% 	% 	xlim([0,17000])
% 	% 	ylim([0.15,.35])
% 	% 	title([num2str(i_plot)])
% 	% end

% 	% plotnum = 1;
% 	% figure
% 	% for i_plot = 51:100
% 	% 	subplot(10, 5, plotnum)
% 	% 	plot(plot_postcue_DLS_values(:,i_plot))
% 	% 	xlim([0,17000])
% 	% 	ylim([0.15,.35])
% 	% 	plotnum = plotnum + 1;
% 	% 	title([num2str(i_plot)])
% 	% end
% 	% plotnum = 1;
% 	% figure
% 	% for i_plot = 100:num_trials
% 	% 	subplot(10, 5, plotnum)
% 	% 	plot(plot_postcue_DLS_values(:,i_plot))
% 	% 	xlim([0,17000])
% 	% 	ylim([0.15,.35])
% 	% 	plotnum = plotnum + 1;
% 	% 	title([num2str(i_plot)])
% 	% end






%------------------------------------DLS---------------------------------------------------
% time resolution in 1000Hz rate is 0.001 sec
% 	thus for each trial start time, take the value: time +/- 0.001 sec

% Extract the DLS signal structure, timepoints and analog values
DLS_struct = eval([filename, '_DLS']);
DLS_values = DLS_struct.values;
DLS_times = DLS_struct.times;

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

DLS_pre_cue_times_by_trial = NaN(num_trials-1, 1500);
DLS_post_cue_times_by_trial = NaN(num_trials-1, 17001);		%NOTE: must leave an extra data point on end because of resolution mismatch between analog and digital lines - some trials have one extra datapoint

DLS_pre_cue_values_by_trial = NaN(num_trials-1, 1500);
DLS_post_cue_values_by_trial = NaN(num_trials-1, 17001);


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

%for plotting:
plot_precue_DLS_values = DLS_pre_cue_values_by_trial';
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
	% for i_plot = 100:num_trials
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_precue_DLS_values(:,i_plot))
	% 	xlim([0,1500])
	% 	plotnum = plotnum + 1;
	% end


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

% %for plotting:
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
	% for i_plot = 100:num_trials
	% 	subplot(10, 5, plotnum)
	% 	plot(plot_postcue_DLS_values(:,i_plot))
	% 	xlim([0,17000])
	% 	ylim([0.15,.35])
	% 	plotnum = plotnum + 1;
	% 	title([num2str(i_plot)])
	% end
% 
% %% Combine into one vector:
DLS_times_by_trial = horzcat(DLS_pre_cue_times_by_trial, DLS_post_cue_times_by_trial);
DLS_values_by_trial = horzcat(DLS_pre_cue_values_by_trial, DLS_post_cue_values_by_trial);
% % CUE ON marker @ column position 1501!!!
% 