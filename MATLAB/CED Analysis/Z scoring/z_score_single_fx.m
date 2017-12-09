function [global_Z_scored] = z_score_single_fx(analogdata_by_trial)
% (previously used by_trial_Z_scored as 2nd output...)
% 
%% Z Score Data - Individual Days
% 
% 	Created:  8-18-17  ahamilos
% 	Modified: 12-4-17  ahamilos - from Mactop Assad Lab version of same
% 	name file
% 
% -------------------------------------------------------
% Z score principles:
% 	Z score takes any sample from a data set and determines how many STD above/below mean it is. 
%   The mean is then set to zero and the Z-scored signal floats above/below.
% 
% 	To calculate: need the mean, variance and STD of the sample. 
% 		Z score = (sample_value - mean)/STD
% 
% 	1. Calculate the mean of the entire data set (e.g., day)
% 	2. Calculate the variance of the entire data set (e.g., day)
% 		- this gives sense of how clustered the data is around the mean. (*** DOES IT MATTER IF VARIANCE CHANGES OVER COURSE OF THE DAY?)
% 	 - to get the variance:
% 		a: Subtract the mean from each data point in the data set
% 		b: Square this
% 		c: Get the sum of all squares
% 		d: Divide SOS by (n-1)
% 	3. Standard deviation is the sqrt of variance
% 	4. Calculate the Z-scored data:
% 		- for each timepoint:
% 			Z_timepoint = (value_timepoint - mean)/STD
% 
% 
% -------------------------------------------------------
%  It turns out MATLAB calculates Z scores differently:
% 		Instead of calculating the STD for the whole dataset, it calculates the STD across each timepoint
% 		It's unclear to me if this is the way to go for Z scoring or not. But there seems to be an advantage:
% 			When I Z score the way I wrote above, this brings down the peak of the original data. It really
% 			appears to cripple the dynamics of the signal. 
% 		However, the MATLAB version also really corrupts the original signal. I'm not sure what's going on.
% 
% 
% Something that may help would be to figure out what the purpose of Z Scoring is. How does it help us?
% 	Really, the Z score just tells us how much the signal deviates from the average and how reliably. It's not
% 		a replicate of the signal. However, the way matlab puts it, it should be a replicate of the signal that
%       is centered and scaled. Centered meaning that the mean is zero. Scaled meaning that all the timepoints
% 		will vary around zero proportionally to how much the signal at that point is different from baseline
% 
% 
% It could be that the dummy dataset does not have large enough deviations from the mean...but I don't think that's it...
% 
% 
% Plotting of the individual trials and mean shows that the Z-scored signal should have an up-then-down shape, but neither Z-score method works...
% 
% AH! Ok - the MATLAB default compares mean and std within the column. That of course puts everything in a timepoint v close to zero
%	Instead, should do across the whole trial - this should set the baseline to zero. 
% 		- It seems to me this is what a proper dF/F should do. I would not expect Z scoring to do much other than scale the signals wrt max.
% 		- I'm still not sure if you should instead be comparing each timepoint to the mean and std across all timepoints in the day...
% 		- It seems to me if you do by each trial, you will remove any cool baseline shifts/DC offsets. I think across entire dataset is better...
% 
% 
% OK! My function now works. It does the Zscore using the mean and STD across the entire session to calculate Z-scored timepoints
% 	This gives a slightly different but very close result to the MATLAB result. That's not surprising, because I intentionally chose
% 	trials that would have the same averages (i.e., ave across single trial is v close to ave across all trials in the dataset)
% 
% Next: 
% 	- I'd like to look at real data processed with both Z-scoring techniques and compare it to the original dF/F data
% 
% 	12-4-17: Debugging with real data:
% 		Everything is coming up NaNs - gonna try stepping thru... - fixed (need nansum -- means default matlab zscoring won't work...)
% 
% -----------------------------------------------------------------------------------------------------

%% Calculating global Z score:

n = size(analogdata_by_trial, 1) * size(analogdata_by_trial, 2);

% (global mean)
d_mean = nanmean(nanmean(analogdata_by_trial));

% (value-mean)
d_Z2a = analogdata_by_trial - d_mean;

% (value-mean)^2
d_Z2b = (d_Z2a).^2;

% Sum of squares:
d_sos = nansum(nansum(d_Z2b));

% (global variance)
d_var = d_sos/(n-1);

% global STD:
d_STD = sqrt(d_var);

%% Calculate Z-scored datasets:
global_Z_scored = (analogdata_by_trial - d_mean)./d_STD;



%% Default Z scores:
% disp('Calculating by-trial Z scores (MATLAB default)...')
% by_trial_Z_scored = zscore(analogdata_by_trial,0,2); % 0 for no flag (weighting is standard n-1), 2 for mean and std across each trial


%%
disp('All calculations complete')






%% Debug testing:---------------------------------------------------------------------------------
% disp('generating dummy sets')
% dummy_data_day1 = [5,5,5,5,5,6,7,10,9,9,8,7,6,5,4,3,2,1,-1,-2,-1,1,3,4,5;...
% 			  	   4,4,3,6,6,8,6,8,8,8,8,7,6,7,4,4,1,1,2,2,1,1,2,4,6;...
% 			  	   5,4,4,5,5,8,10,15,10,11,8,7,6,4,2,-2,-5,-3,-1,-2,-1,0,1,2,3];

% dummy_data_day2 = 0.2*[5,5,5,5,5,6,7,10,9,9,8,7,6,5,4,3,2,1,-1,-2,-1,1,3,4,5;...
% 			  	   4,4,3,6,6,8,6,8,8,8,8,7,6,7,4,4,1,1,2,2,1,1,2,4,6;...
% 			  	   5,4,4,5,5,8,10,15,10,11,8,7,6,4,2,-2,-5,-3,-1,-2,-1,0,1,2,3];

% dummy_data_day3 = 1.5*[5,5,5,5,5,6,7,10,9,9,8,7,6,5,4,3,2,1,-1,-2,-1,1,3,4,5;...
% 			  	   4,4,3,6,6,8,6,8,8,8,8,7,6,7,4,4,1,1,2,2,1,1,2,4,6;...
% 			  	   5,4,4,5,5,8,10,15,10,11,8,7,6,4,2,-2,-5,-3,-1,-2,-1,0,1,2,3];



% %% Calculate n for each data set:
% disp('Calculating n, mean, and variance')
% n1 = size(dummy_data_day1, 1) * size(dummy_data_day1, 2);
% n2 = size(dummy_data_day2, 1) * size(dummy_data_day2, 2);
% n3 = size(dummy_data_day3, 1) * size(dummy_data_day3, 2);

% d1_mean = nanmean(nanmean(dummy_data_day1));
% d2_mean = nanmean(nanmean(dummy_data_day2));
% d3_mean = nanmean(nanmean(dummy_data_day3));


% d1_Z2a = dummy_data_day1 - d1_mean;
% d2_Z2a = dummy_data_day2 - d2_mean;
% d3_Z2a = dummy_data_day3 - d3_mean;


% d1_Z2b = (d1_Z2a).^2;
% d2_Z2b = (d2_Z2a).^2;
% d3_Z2b = (d3_Z2a).^2;

% % d1_var = variance(dummy_data_day1);
% % d2_var = variance(dummy_data_day2);
% % d3_var = variance(dummy_data_day3);



% % Sum of squares:

% d1_sos = sum(sum(d1_Z2b));
% d2_sos = sum(sum(d2_Z2b));
% d3_sos = sum(sum(d3_Z2b));




% % Variance:

% d1_var = d1_sos/(n1-1);
% d2_var = d2_sos/(n2-1);
% d3_var = d3_sos/(n3-1);




% %% STD:

% d1_STD = sqrt(d1_var);
% d2_STD = sqrt(d2_var);
% d3_STD = sqrt(d3_var);



% %% Calculate Z-scored datasets:

% d1_Zscore = (dummy_data_day1 - d1_mean)./d1_STD;
% d2_Zscore = (dummy_data_day2 - d2_mean)./d2_STD;
% d3_Zscore = (dummy_data_day3 - d3_mean)./d3_STD;


% %% Default Z scores:
% d1_default_Zscore = zscore(dummy_data_day1,0,2); % 0 for no flag (weighting is standard n-1), 2 for mean and std across each trial
% d2_default_Zscore = zscore(dummy_data_day2,0,2);
% d3_default_Zscore = zscore(dummy_data_day3,0,2);

% %% Compare to MATLAB Z-Scored Data:
% % find(d1_Zscore ~= zscore(dummy_data_day1))
% % find(d2_Zscore ~= zscore(dummy_data_day2))
% find(d3_Zscore ~= zscore(dummy_data_day3))