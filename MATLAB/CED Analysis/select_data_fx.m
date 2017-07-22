% function [] = select_data_fx(analog_times, analog_values, filename)
% 
% Created 			4-24-17 - ahamilos
% Last Modified 	4-24-17 - ahamilos
% 
% Takes raw analog data from CED
% 	1. divide all data into trials by cue on
% 	2. plot by trials as heatmap + allow you to select trials to ignore (due to change in BG in the middle of the trial)
% 	3. concatenate all the continuous remaining data and fit it with exp or 2x exp
% 	4. correct each timepoint with its respective correction fx
% 	5. replot the heatmap to validate
% 
%% Debug defaults
% analog_data = Day1_A1_DLS;
filename = 'Day1_A1';
% DLS_struct = eval([filename, '_DLS']);
% analog_values = DLS_struct.values;
% analog_times = DLS_struct.times;

DLS_struct = eval([filename, '_SNc']);
analog_values = DLS_struct.values;
analog_times = DLS_struct.times;

% %% Open file:
% response = inputdlg('Enter CED filename (don''t include *_lick, etc)');
% filename = response{1};
%-----------------------------------------------------------------------------------------
%% Extract DIGITAL variables from file

% Extract the lamp_off structure and timepoints
lamp_off_struct = eval([filename, '_Lamp_OFF']);
trial_start_times = lamp_off_struct.times;

% Extract the cue_on structure and timepoints
cue_on_struct = eval([filename, '_Start_Cu']);
cue_on_times = cue_on_struct.times;

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)

% Number of trials:
num_trials_plus_1 = length(trial_start_times);
num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)

%------------------------------------------------------------------------------------------
%% 1. Divide all data into trials by cue on:
[times_by_trial, values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(analog_times, analog_values, trial_start_times, cue_on_times);

%% 2. Plot as heatmap...
[h_heatmap, heat_by_trial] = heatmap_3_fx(values_by_trial, [], false);

% Allow user to select trials they want to ignore from consideration:

button = questdlg('Did the light intensity change during the experiment?','Hey!','Yes','No','Yes');
answer = strcmp(button, 'Yes');

if answer ~= 1
	close(h_heatmap);
end

%% If light level was changed, allow user to select timepoint to split data on:
split_times = [];
split_trials = []; 
num = 1;
keep_checking = answer;

while keep_checking == 1
	title('Select trials to split data by clicking (choose in order small->large)');
	[split_times(num), split_trials(num)] = ginput(1);
	
	button2 = questdlg(strcat('You selected trial #', num2str(split_trials(num))) ,'Hey!','Continue','Redo', 'Select More Trials', 'Continue');
	if strcmp(button2, 'Select More Trials');
		disp('checking again')
		num = num + 1;
		keep_checking = 1;	
	elseif strcmp(button2, 'Continue');
		disp('don''t check again')
		keep_checking = false;
		break
	elseif strcmp(button2, 'Redo');
		disp('Pick again...')
		num = num;
		keep_checking = 1;
    end
end

% Take the floor of the trial # so it is a whole #:
split_trials = floor(split_trials);


% Now get the timepoints for the splits from the times_by_trial array:
position_1st_timestamp = min(find(times_by_trial(1,:)>-10000))
start_time = times_by_trial(1,position_1st_timestamp);
end_time = times_by_trial(end,end-1);
times_to_break = []; % this is a nx2 array. col1 = end of prev split, col2 = begin next split

for i_splits = 1:length(split_trials)
	% find the first timestamp in the trial
	position_1st_timestamp = min(find(times_by_trial(split_trials(i_splits),:)>-10000))
	times_to_break(i_splits,1) = times_by_trial(split_trials(i_splits), position_1st_timestamp);
	times_to_break(i_splits,2) = times_by_trial(split_trials(i_splits), end-1);
end


% make a cell array to hold all the split things:
	splitting_times_final = []; % a nx2 array, col 1 = start, col2 = end
	split_time_begin = start_time;
	splitting_times_final(1,1) = split_time_begin;
	belly = {}; 	% belly will hold all these split up 1xn arrays
	for i_split = 1:length(split_trials)
		split_time_end = times_to_break(i_split, 1);
		splitting_times_final(i_split, 2) = split_time_end;
		%find values position where the split times are:
		val_pos_1 = min(find(analog_times <= split_time_begin + 0.001 & analog_times >= split_time_begin - 0.001));
		val_pos_2 = min(find(analog_times <= split_time_end + 0.001 & analog_times >= split_time_end - 0.001));

		belly{i_split} = analog_values(val_pos_1:val_pos_2);

		split_time_begin = times_to_break(i_split, 2); % for next trial
		splitting_times_final(i_split+1, 1) = split_time_begin;
	end
	% Now do the final split:
	split_time_end = end_time;
	splitting_times_final(end, 2) = split_time_end;
	%find values position where the split times are:
	val_pos_1 = min(find(analog_times <= split_time_begin + 0.001 & analog_times >= split_time_begin - 0.001));
	val_pos_2 = min(find(analog_times <= split_time_end + 0.001 & analog_times >= split_time_end - 0.001));
	belly{end+1} = analog_values(val_pos_1:val_pos_2);


%% Now fit each belly with exp:
	fitobject = {}; % saves each fit
	gof = {};		% saves goodness of fit stats for each fit
	output = {};	% saves output for each fit
	coefficient_array = []; % saves the coeffs as rows = fit, col = a,b
	split_time_begin = start_time;
	for i_fit = 1:length(belly)
		% Make x and y and then transpose:
		x = (1:length(belly{i_fit}));
		% split_time_begin = splitting_times_final(i_fit, 1);
		% split_time_end = splitting_times_final(i_fit, 2);
		% %find values position where the split times are:
		% val_pos_1 = min(find(analog_times <= split_time_begin + 0.001 & analog_times >= split_time_begin - 0.001));
		% val_pos_2 = min(find(analog_times <= split_time_end + 0.001 & analog_times >= split_time_end - 0.001));
		% x = analog_times(val_pos_1:val_pos_2);
		x = x';
		y = belly{i_fit};
		[fitobject{i_fit},gof{i_fit},output{i_fit}] = fit(x,y,'exp2');
		figure, hold on, plot(belly{i_fit}), plot(fitobject{i_fit});
        % h_plot = plot(fitobject{i_fit});
		coefficient_array(i_fit, :) = coeffvalues(fitobject{i_fit});
	end



%% Now, use the coefficients to get a correction function for each fit
	correction_functions = {}; % each cell has a 1xn array of multipliers based on the exp fit
	for i_fit = 1:(length(belly))
		a = coefficient_array(i_fit, 1);
		b = coefficient_array(i_fit, 2);
		for i_timestamp = 1:length(belly{i_fit})+18501
			correction_functions{i_fit}(i_timestamp) = a*exp(b*i_timestamp);  % note if a = 0, then this will end up reading as NaN - basically if the end of the light function is not exp, this will give a meaningless exp fit
		end
	end



% Now correct each datapoint:
	df_f_values = NaN(size(values_by_trial));
	start_trial = 1;
	for i_fit = 1:length(belly)-1
		end_trial = split_trials(i_fit);
		expcount = 1;

		for i_trial = start_trial:end_trial
			for i_col = 1:size(values_by_trial,2)
				% for each timestamp, check if not NaN. Remember to increment the exp counter
				if values_by_trial(i_trial, i_col) > -10000
					df_f_values(i_trial, i_col) = values_by_trial(i_trial, i_col) ./ correction_functions{i_fit}(expcount);
					expcount = expcount + 1;
				end
			end
		end

		start_trial = end_trial + 1
	end
	% now do the final fit:
	end_trial = size(values_by_trial,1);
	expcount = 1;
	for i_trial = start_trial:end_trial
		for i_col = 1:size(values_by_trial,2)
			% for each timestamp, check if not NaN. Remember to increment the exp counter
			if values_by_trial(i_trial, i_col) > -10000
				df_f_values(i_trial, i_col) = values_by_trial(i_trial, i_col) ./ correction_functions{i_fit}(expcount);
				expcount = expcount + 1;
			end
		end
	end



















% %% 3. Concatenate all the remaining data into one line:
% 	concat_belly = {};	% each cell of concat_belly has a 1xn array of values
% 	concat_belly_no_nan = {};
% 	for i_bellies = 1:length(belly)
% 		% v_times = times_by_trial';
% 		% times_1xn = v_times(:)';
% 		v_values = belly{i_bellies}';
% 		concat_belly{i_bellies} = v_values(:)';
% 	% Remove NaNs from the concat data (because fit fxs don't like NaN):
% 		concat_belly_no_nan{i_bellies} = rmmissing(concat_belly{i_bellies});
% 	end



% % Now fit each concat_belly with exp:
% 	fitobject = {}; % saves each fit
% 	gof = {};		% saves goodness of fit stats for each fit
% 	output = {};	% saves output for each fit
% 	coefficient_array = []; % saves the coeffs as rows = fit, col = a,b
%     figure, hold on
% 	for i_fit = 1:length(concat_belly_no_nan)
% 		% Make x and y and then transpose:
% 		x = (1:length(concat_belly_no_nan{i_fit}));
% 		x = x';
% 		y = concat_belly_no_nan{i_fit};
% 		y = y';
% 		% Eliminate NaNs then clip:
% 		[fitobject{i_fit},gof{i_fit},output{i_fit}] = fit(x,y,'exp2');
%         h_plot = plot(fitobject{i_fit});
% 		coefficient_array(i_fit, :) = coeffvalues(fitobject{i_fit});
% 	end




























% % Discard the ambiguous data by turning to NaN all values in the split trials:
% data_w_o_split_trials = values_by_trial;
% for i_splits = split_trials
% 	data_w_o_split_trials(i_splits, :) = NaN;
% end

% % Check heatmap...
% [h_heatmap, heat_by_trial_split] = heatmap_3_fx(data_w_o_split_trials, [], false);
% button3 = questdlg('Are you happy with the ignored trials?','Hey!','Yes','No','Yes');
% answer3 = strcmp(button, 'Yes');

% % If everything looks good, continue...
% if answer3 == 1
% 	% make a cell array to hold all the split things:
% 	split_num_1 = 1;
% 	belly = {}; 	% belly will hold all these split up arrays
% 	for i_split = 1:length(split_trials)
% 		split_num_2 = split_trials(i_split) - 1;
% 		belly{i_split} = data_w_o_split_trials(split_num_1:split_num_2, :);
% 		split_num_1 = split_trials(i_split) + 1;
% 	end
% 	% Now do the final split:
% 	belly{end+1} = data_w_o_split_trials(split_num_1:end, :);



% %% 3. Concatenate all the remaining data into one line:
% 	concat_belly = {};	% each cell of concat_belly has a 1xn array of values
% 	concat_belly_no_nan = {};
% 	for i_bellies = 1:length(belly)
% 		% v_times = times_by_trial';
% 		% times_1xn = v_times(:)';
% 		v_values = belly{i_bellies}';
% 		concat_belly{i_bellies} = v_values(:)';
% 	% Remove NaNs from the concat data (because fit fxs don't like NaN):
% 		concat_belly_no_nan{i_bellies} = rmmissing(concat_belly{i_bellies});
% 	end



% % Now fit each concat_belly with exp:
% 	fitobject = {}; % saves each fit
% 	gof = {};		% saves goodness of fit stats for each fit
% 	output = {};	% saves output for each fit
% 	coefficient_array = []; % saves the coeffs as rows = fit, col = a,b
%     figure, hold on
% 	for i_fit = 1:length(concat_belly_no_nan)
% 		% Make x and y and then transpose:
% 		x = (1:length(concat_belly_no_nan{i_fit}));
% 		x = x';
% 		y = concat_belly_no_nan{i_fit};
% 		y = y';
% 		% Eliminate NaNs then clip:
% 		[fitobject{i_fit},gof{i_fit},output{i_fit}] = fit(x,y,'exp2');
%         h_plot = plot(fitobject{i_fit});
% 		coefficient_array(i_fit, :) = coeffvalues(fitobject{i_fit});
% 	end


% 	%% the exp fits work well! Now, use the coefficients piecewise to get the correction function
% 	correction_array = NaN(size(values_by_trial));
% 	corr_x_pos = 1;
% 	corr_y_pos = 1;
% 	trial_1_for_next_fit = 1; % start with first trial
% 	position_counter = 1; % keeps track of where you are in the exponential fit
% 	% the correction function will have a value at each trial timepoint corresponding to the exponential curve evaluated at that timepoint
% 	for i_fit = 1:(length(split_trials))
% 		a = coefficient_array(i_fit, 1);
% 		b = coefficient_array(i_fit, 2);
% 		for i_trial = trial_1_for_next_fit:split_trials(i_fit) % for each trial in the batch of data being corrected
% 			for i_time = 1:size(values_by_trial,2)
% 				correction_array(i_trial, i_time) = a*exp(b*position_counter);  % note if a = 0, then this will end up reading as NaN - basically if the end of the light function is not exp, this will give a meaningless exp fit
% 			end
% 		end
% 		trial_1_for_next_fit = split_trials(i_fit)+1;
% 	end
% 	% do the last split here:






% 	i_repeat = true;
% 	position_counter = 1;
% 	for i_fit = 1:number_of_fits
% 		%will go until counter reaches split_times(i_fit)
% 		a = coefficient_array(i_fit, 1);
% 		b = coefficient_array(i_fit, 2);
% 	    i_repeat = true;
% 		while i_repeat == true
% 			% keep adding values until reach breakpoint, then switch to the other fit functions by breaking out of the loop
% 			if position_counter <= split_times(i_fit)
% 				% do stuff
% 				% use coeff of the current fit to generate a datapoint:
% 				correction_array(position_counter) = a*exp(b*position_counter);  % note if a = 0, then this will end up reading as NaN - basically if the end of the light function is not exp, this will give a meaningless exp fit
% 				position_counter = position_counter + 1;
% 			else
% 				i_repeat = false;
% 			end
% 		end
% 	end


% end