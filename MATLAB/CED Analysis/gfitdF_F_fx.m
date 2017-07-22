function [gfit_SNc, gfit_DLS] = gfitdF_F_fx(SNc_values, DLS_values)
% 
% 	Global Fitting Procedure (5/25/17) -- Uses smooth() to fit raw photometry traces and calculates dF/F based on this global fit
% 
% 	Created: 		ahamilos	6/1/17
% 	Last Modified:	ahamilos	6/1/17
% 
% --------------------------------------------------------------------------------------------

% 1. Smooth the whole day timeseries (window is 10 seconds)
disp('killing noise with 1,000 ms window, moving');
Fraw_SNc = smooth(SNc_values, 1000, 'moving');
Fraw_DLS = smooth(DLS_values, 1000, 'moving');
% Fraw_SNc = smooth(SNc_values, 1000, 'gauss');
% Fraw_DLS = smooth(DLS_values, 1000, 'gauss');
disp('noise killing complete');

% 2. Subtract the smoothed curve from the raw trace 			(Fraw)
Fraw_SNc = SNc_values - Fraw_SNc;
Fraw_DLS = DLS_values - Fraw_DLS;

% 2b. Eliminate all noise > 15 STD above the whole trace 		(Frs = Fraw-singularities)
	% find points > 15 STD above/below trace and turn to average of surrounding points
ignore_pos_SNc = find(Fraw_SNc > 15*std(Fraw_SNc));
% disp(['Ignored points SNc: ', num2str(ignore_pos_SNc)]);
Frs_SNc = SNc_values;
for ig = ignore_pos_SNc
	Frs_SNc(ig) = mean([Frs_SNc(ig-1), Frs_SNc(ig+1)],2);
end

ignore_pos_DLS = find(Fraw_DLS > 15*std(Fraw_DLS));
% disp(['Ignored points DLS: ', num2str(ignore_pos_DLS)]);
Frs_DLS = DLS_values;
for ig = ignore_pos_DLS
	Frs_DLS(ig) = mean([Frs_DLS(ig-1), Frs_DLS(ig+1)],2);
end

% 3. Repeat step 1 without the noise points (this way smoothing not contaminated with artifacts)
%																(Fsmooth)
disp('gfitting with 200,000 ms window, moving');
% Fsmooth_SNc = smooth(Frs_SNc, 500000, 'gauss');
% Fsmooth_DLS = smooth(Frs_DLS, 500000, 'gauss');
Fsmooth_SNc = smooth(Frs_SNc, 200000, 'moving');
Fsmooth_DLS = smooth(Frs_DLS, 200000, 'moving');
disp('gfitting complete');

% 4. Now at each point, do the dF/F calculation: [Frs(point) - Fsmooth(point)]/Fsmooth(point)
gfit_SNc = (Frs_SNc - Fsmooth_SNc)./Fsmooth_SNc;
gfit_DLS = (Frs_DLS - Fsmooth_DLS)./Fsmooth_DLS;

% % 5. Now put data into values by trial:
% [SNc_times_by_trial_gfit, SNc_values_by_trial_gfit] = put_data_into_trials_aligned_to_cue_on_fx(SNc_times,...
% 																					 gfit_SNc,...
% 																					 trial_start_times,...
% 																					 cue_on_times);
% [DLS_times_by_trial_gfit, DLS_values_by_trial_gfit] = put_data_into_trials_aligned_to_cue_on_fx(DLS_times,...
% 																					 gfit_DLS,...
% 																					 trial_start_times,...
% 																					 cue_on_times);
% 












