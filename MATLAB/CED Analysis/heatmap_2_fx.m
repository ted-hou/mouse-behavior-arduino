function [h_heatmap, heat_by_trial] = heatmap_2_fx(analog_data_by_trial, lick_times_by_trial, plot_raster)
% Heatmap version 2: normalizes the heat across all trials and then plots with raster
% Method:
% 	Input dF/F corrected data
% 	Smooth each trial
% 	Subtract out min (global correction)
% 	Normalize to max (global correction)


% defaults
% analog_data_by_trial = SNc_values_by_trial;
% lick_times_by_trial = lick_times_by_trial;
% plot_raster = true;


num_trials = size(analog_data_by_trial, 1);
num_times = size(analog_data_by_trial, 2);
smooth_data = NaN(num_trials, num_times);

% First, smooth all the data for each trial:
for i_trial = 1:num_trials
	smooth_data(i_trial, :) = smooth(analog_data_by_trial(i_trial, :), 50, 'gauss');
end

% Subtract away the minimum globally:
% (note: test data has bg change in the middle, so do diff from 1-77, 78-end. Ignore 77 bc intensity changed in the middle of it)
smooth_floor_1 = smooth_data(1:76, :) - (min(min(smooth_data(1:76, :))));
smooth_floor_2 = NaN(1, num_times);
smooth_floor_2(1, 1:7000) = smooth_data(77, 1:7000) - (min(min(smooth_data(77, 1:7000))));
smooth_floor_3 = smooth_data(78:end, :) - (min(min(smooth_data(78:end, :))));
smooth_floor = vertcat(smooth_floor_1, smooth_floor_2, smooth_floor_3);

% Normalize to max globally:
smooth_norm = smooth_floor ./ (max(max(smooth_floor)));

heat_by_trial = smooth_norm;


% convert lick times == 0 to NaN in each trial:
lick_times_NaN = lick_times_by_trial;
lick_times_NaN(lick_times_by_trial == 0) = NaN;

% plot heatmap for normalized, smoothed data:
figure,
h_heatmap = imagesc(smooth_norm)

% overlay the raster
if plot_raster
	hold on
	plot(gca, lick_times_NaN*1000, [1:num_trials], '.',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', 'black',...
				'MarkerFaceColor', 'black',...
				'LineWidth', 1.5)
	xlabel('Time (ms)')
	ylabel('Trial #')
	zlabel('dF/F')
	title('Globally-normalized Heatmap')
end