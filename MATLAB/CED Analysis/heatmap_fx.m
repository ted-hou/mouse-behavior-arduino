function [h_heatmap, heat_by_trial, mins, means] = heatmap_fx(analog_data_by_trial, lick_times_by_trial, plot_raster, window_smooth)
% Heatmap version 1: normalizes the heat within each trial and then plots with raster
% 
% Created 		4/21/17 - ahamilos
% Last Modfied 	4/25/17 - ahamilos
% 
% New Version Updates:
% 	4/25/17: finished debugging. See notes in Lab Notebook (3/21/17 Marble Cover)
% 
% Method:
% 	Input dF/F corrected data
% 	Smooth each trial
% 	Subtract out min from each smoothed trial (i.e., local correction specific to each trial)
% 	Normalize to max in each trial (i.e., local to the trial)


% % debug defaults - when running as script
% analog_data_by_trial = SNc_values_by_trial;
% lick_times_by_trial = lick_times_by_trial;
% plot_raster = true;
switch nargin
    case 4
    	disp('got it');
    case 3
        window_smooth = 100;
    case 2
        plot_raster = true;
        window_smooth = 100;
    otherwise
        lick_times_by_trial = [];
        plot_raster = false;
        window_smooth = 100;
end

num_trials = size(analog_data_by_trial(:, 1:18500), 1);
num_times = size(analog_data_by_trial(:, 1:18500), 2);
smooth_data = NaN(num_trials, num_times);

% First, smooth all the data for each trial:
for i_trial = 1:num_trials
	smooth_data(i_trial, :) = smooth(analog_data_by_trial(i_trial, 1:18500), window_smooth, 'moving');
end

% % Smoothing causes a weird edge effect way out on the outside of the data... let's clip the data much earlier (18000)
smooth_data = smooth_data(:, 1:18000);
% Let's also clip the first 5 # data points and turn them to NaN:
for i_trial = 1:num_trials
	first_num_position = min(find(smooth_data(i_trial, :) > -10000));
	smooth_data(i_trial, first_num_position:first_num_position+9) = NaN; 
end


mins = [];
means = [];
% Subtract away the minimum in each trial:
smooth_floor = NaN(num_trials, 18000);
for i_trial = 1:num_trials
	smooth_floor(i_trial, :) = smooth_data(i_trial,:) - (nanmin(smooth_data(i_trial,:)));
	% mins(end+1) = [(min(smooth_data(i_trial,:)))];
	% means(end+1) = [(nanmean(smooth_data(i_trial,:)))];
end



% Normalize to max:
smooth_norm = NaN(num_trials, 18000);
for i_trial = 1:num_trials
	smooth_norm(i_trial, :) = smooth_floor(i_trial,:) ./ (max(smooth_floor(i_trial,:)));
end



% convert lick times == 0 to NaN in each trial:
lick_times_NaN = lick_times_by_trial;
lick_times_NaN(lick_times_by_trial == 0) = NaN;

% Try snipping off the last column because it's all zeros...
smooth_trim = smooth_norm;	%([1:76,78:end], 1:18499);

% Get the average plot (exclude early because artificially high rel to rest of plot due to fewer data points)
ave_data = mean(smooth_trim, 1);
% ave_data = ave_data(1000:end);	% note: cue on now at 500
ave_data(1:1000) = NaN;
floor_ave_data = ave_data - min(ave_data);
norm_ave_data = floor_ave_data ./ max(floor_ave_data);


% plot heatmap for normalized, smoothed data:
figure,
pos1 = [0.12 0.2 .8 .75];
subplot('Position', pos1)
h_heatmap = imagesc(smooth_trim)
hold on
plot([1500,1500], [0,141], 'r-', 'Linewidth', 3)
plot([2000,2000], [0,141], 'r-', 'Linewidth', 3)
plot([4833,4833], [0,141], 'r-', 'Linewidth', 3)
plot([6500,6500], [0,141], 'r-', 'Linewidth', 3)
ax1 = gca;
ax1.XTick = [0, 1000, 1500, 2000, 3000, 4000, 4833, 5500, 6500, 7500, 8500, 9500, 10500, 11500, 12500, 13500, 14500, 15500, 16500, 17500];
cue = '0'; %sprintf('0: Cue On');
abort = '500'; % sprintf('500: Abort Window');
reward = '3333'; %sprintf('3333: Reward Window');
target = '5000'; %sprintf('5000: Target');
ITI = '7000'; %sprintf('7000: ITI');
ax1.XTickLabel = {'-1500', '-500', cue, abort, '1500', '2500', reward, '4000', target, '6000', ITI, '8000', '9000','10000','11000','12000','13000','14000','15000','16000'};
ylabel('Trial #')

pos2 = [0.12 0.1 0.8 0.05];
subplot('Position', pos2)
h_ave = imagesc(norm_ave_data)
hold on
plot([1500,1500], [0,141], 'r-', 'Linewidth', 3)
plot([2000,2000], [0,141], 'r-', 'Linewidth', 3)
plot([4833,4833], [0,141], 'r-', 'Linewidth', 3)
plot([6500,6500], [0,141], 'r-', 'Linewidth', 3)
ax2 = gca;
ax2.XTick = [0, 1000, 1500, 2000, 3000, 4000, 4833, 5500, 6500, 7500, 8500, 9500, 10500, 11500, 12500, 13500, 14500, 15500, 16500, 17500];
cue = '0'; %sprintf('0: Cue On');
abort = '500'; % sprintf('500: Abort Window');
reward = '3333'; %sprintf('3333: Reward Window');
target = '5000'; %sprintf('5000: Target');
ITI = '7000'; %sprintf('7000: ITI');
ax2.XTickLabel = {'-1500', '-500', cue, abort, '1500', '2500', reward, '4000', target, '6000', ITI, '8000', '9000','10000','11000','12000','13000','14000','15000','16000'};
ax2.YTick = [1];
ax2.YTickLabel = ['Average'];
xlabel('Time Relative to Cue (ms)')

heat_by_trial = smooth_trim;


% overlay the raster
if plot_raster
	hold on
    % plot over trial-by-trial heatmap
    for i_trial = 1:num_trials
        plot(ax1, lick_times_NaN(i_trial, :)*1000, i_trial(ones(size(lick_times_NaN, 2))), '.',...
                    'MarkerSize', 10,...
                    'MarkerEdgeColor', 'black',...
                    'MarkerFaceColor', 'black',...
                    'LineWidth', 1.5)
    end
    % % plot over ave heatmap - note this isn't v helpful...
    % licks_1_x_n = reshape(lick_times_NaN, [1, numel(lick_times_NaN)]);
    % hold on
    % plot(ax2, licks_1_x_n*1000, ones(numel(licks_1_x_n)), '.',...
    % 	            'MarkerSize', 10,...
    %                 'MarkerEdgeColor', 'black',...
    %                 'MarkerFaceColor', 'black',...
    %                 'LineWidth', 1.5)

end