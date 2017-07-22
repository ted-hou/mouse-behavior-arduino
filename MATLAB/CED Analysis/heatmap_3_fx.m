function [h_heatmap, heat_by_trial] = heatmap_3_fx(analog_data_by_trial, lick_times_by_trial, plot_raster)
% Heatmap version 2: normalizes the heat across all trials. This one is for selecting breakpoints in photometry data
%   For use with select_data_fx.m
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
% this replaces the old smooth fx which no longer allows gaussian smoothing. use filter(50, 1, data)
for i_trial = 1:num_trials
	smooth_data(i_trial, :) = smooth(analog_data_by_trial(i_trial, :), 50, 'moving');
end

% Subtract away the minimum globally:
% (note: test data has bg change in the middle, so do diff from 1-77, 78-end. Ignore 77 bc intensity changed in the middle of it)



smooth_floor = smooth_data - (min(min(smooth_data)));

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