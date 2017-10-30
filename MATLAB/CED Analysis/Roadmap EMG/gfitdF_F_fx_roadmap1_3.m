function [gfit] = gfitdF_F_fx_roadmap1_3(channel_values)
% 
% 	Global Fitting Procedure (5/25/17) -- Uses smooth() to fit raw photometry traces and calculates dF/F based on this global fit
% 
% 	Created: 		ahamilos	6/1/17
% 	Last Modified:	ahamilos	10/26/17 - handle photom channel one at a
% 	time
% 
% --------------------------------------------------------------------------------------------

% 1. Smooth the whole day timeseries (window is 10 seconds)
disp('killing noise with 1,000 ms window, moving');
Fraw = smooth(channel_values, 1000, 'moving');
% Fraw = smooth(SNc_values, 1000, 'gauss');
disp('noise killing complete');

% 2. Subtract the smoothed curve from the raw trace 			(Fraw)
Fraw = channel_values - Fraw;

% 2b. Eliminate all noise > 15 STD above the whole trace 		(Frs = Fraw-singularities)
	% find points > 15 STD above/below trace and turn to average of surrounding points
ignore_pos = find(Fraw > 15*std(Fraw));
% disp(['Ignored points SNc: ', num2str(ignore_pos)]);
Frs = channel_values;
for ig = ignore_pos
	Frs(ig) = mean([Frs(ig-1), Frs(ig+1)],2);
end


% 3. Repeat step 1 without the noise points (this way smoothing not contaminated with artifacts)
%																(Fsmooth)
disp('gfitting with 200,000 ms window, moving');
% Fsmooth = smooth(Frs, 500000, 'gauss');
Fsmooth = smooth(Frs, 200000, 'moving');
disp('gfitting complete');

% 4. Now at each point, do the dF/F calculation: [Frs(point) - Fsmooth(point)]/Fsmooth(point)
gfit = (Frs - Fsmooth)./Fsmooth;