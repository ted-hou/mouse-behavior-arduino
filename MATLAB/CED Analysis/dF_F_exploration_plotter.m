%% dF/F exploration plotter
% 
% 1. Exp fit
% 2. gFit fit
% 3. Nao Baseline
% 4. Soares method interp 1
% 5. Soares method interp 2 is the same as Nao Baseline
gfit_win = 18500; % the length of one trial
% ------------------------------


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


% Extract the Lick structure and timepoints
lick_struct = eval([filename, '_Lick']);
lick_times = lick_struct.times;


% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)



%% ------------------------------------DLS---------------------------------------------------
DLS_struct = eval([filename, '_DLS']);
DLS_values = DLS_struct.values;
DLS_times = DLS_struct.times;
%%------------------------------------SNc---------------------------------------------------
SNc_struct = eval([filename, '_SNc']);
SNc_values = SNc_struct.values;
SNc_times = SNc_struct.times;



%% Exp fit==============================================================================================
	DLS_values = DLS_values;

	h_plot = figure; 
	plot(DLS_values');

	number_of_fits = 1;
	coefficient_array = NaN(number_of_fits, 2); 	% format: col1 = a, col2 = b; each row corresponds to the different breakpoints
	figure
	x = 1:length(DLS_values(7000:end-7000));
	x = x';
	y = DLS_values(7000:end-7000); %%%%% Note: I'm ommitting things close to the edge for a better fit

	% Eliminate NaNs then clip:
	x = find(y > -10000); % this eliminates NaN positions
	y = y(1:length(x));
	[fitobject{1},gof{1},output{1}] = fit(x,y,'exp1');
	h_plot = plot(fitobject{1});
	coefficient_array(1, :) = coeffvalues(fitobject{1});
	hold on



	%% the exp fits work well! Now, use the coefficients piecewise to get the correction function
	correction_function = NaN(1, length(DLS_values));
	a = coefficient_array(1, 1);
	b = coefficient_array(1, 2);

	positions = 1:length(DLS_values);
	correction_function(positions) = a*exp(b*positions);



	figure,
	title('Correction Function - not normalized')
	plot(correction_function)


	for i_times = 1:length(DLS_values)
		corrected_DLS_values(i_times) = (DLS_values(i_times) - correction_function(i_times)) * 1/correction_function(i_times);
	end

	figure,
	subplot(2,1,1)
	title('DLS_values: No correction')
	plot(DLS_values)
	hold on
	plot(correction_function, 'linewidth', 3)

	subplot(2,1,2)
	title('DLS_values: Corrected')
	plot(corrected_DLS_values)
	    
	    


%% gFit dF/F (much smaller window though)=====================================================================================
	% 	Global Fitting Procedure (5/25/17) -- Uses smooth() to fit raw photometry traces and calculates dF/F based on this global fit

	% start by plotting what the curve looks like for the size of your window	    
	figure,
	subplot(1,3,1)
	plot(DLS_values(1:gfit_win))
	title(['gFit window times 1:',num2str(gfit_win)])
	xlabel('time in session (ms)')
	ylabel('Raw F')
	xlim([1, gfit_win])
	subplot(1,3,2)
	plot([100000:(gfit_win+100000)], DLS_values(100000:(gfit_win+100000)))
	title(['gFit window times 100000:',num2str(100000+gfit_win)])
	xlabel('time in session (ms)')
	ylabel('Raw F')
	xlim([100000, (gfit_win+100000)])
	subplot(1,3,3)
	plot([1000000:(gfit_win+1000000)],DLS_values(1000000:(gfit_win+1000000)))
	title(['gFit window times 1million:',num2str(1000000+gfit_win)])
	xlabel('time in session (ms)')
	ylabel('Raw F')
	xlim([1000000, (1000000+gfit_win)])


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
	disp(['gfitting with ', num2str(gfit_win/1000), 'sec window, moving']);
	% Fsmooth_SNc = smooth(Frs_SNc, 500000, 'gauss');
	% Fsmooth_DLS = smooth(Frs_DLS, 500000, 'gauss');
	Fsmooth_SNc = smooth(Frs_SNc, gfit_win, 'moving');
	Fsmooth_DLS = smooth(Frs_DLS, gfit_win, 'moving');
	disp('gfitting complete');

	% 4. Now at each point, do the dF/F calculation: [Frs(point) - Fsmooth(point)]/Fsmooth(point)
	gfit_SNc = (Frs_SNc - Fsmooth_SNc)./Fsmooth_SNc;
	gfit_DLS = (Frs_DLS - Fsmooth_DLS)./Fsmooth_DLS;


	figure
	subplot(2,1,1)
	plot(DLS_values)
	hold on
	plot(Fsmooth_DLS, 'linewidth', 3)
	xlabel('time in session (ms)')
	ylabel('Raw F')
	title(['DLS gFit with ', num2str(gfit_win/1000), 'sec window'])
	subplot(2,1,2)
	plot(SNc_values)
	hold on
	plot(Fsmooth_SNc, 'linewidth', 3)
	xlabel('time in session (ms)')
	ylabel('Raw F')
	title(['SNc gFit with ', num2str(gfit_win/1000), 'sec window'])

	figure
	subplot(2,1,1)
	plot(gfit_DLS)
	xlabel('time in session (ms)')
	ylabel('dF/F')
	title(['DLS dF/F using gFit with ', num2str(gfit_win/1000), 'sec window'])
	subplot(2,1,2)
	plot(gfit_SNc)
	xlabel('time in session (ms)')
	ylabel('dF/F')
	title(['SNc dF/F using gFit with ', num2str(gfit_win/1000), 'sec window'])




%% 3. Nao Baseline (last 1 sec in the ITI preceeding lights off)










