% Auto-Excluder (for roadmap v1.3)
%  --------------------------------------------------------
% 	Takes input trial numbers and excludes from any analog data
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 

excludedtrials_



% Parse the userinput to determine which trials to omit:
	% Reset the exlcuded trials array
Excluded_Trials = [];
% previous_case = 0;
ichar = 1;
while ichar <= length(excludedtrials_)
	disp(['the class of ichar is: ', class(excludedtrials_(ichar)), ' and the excludedtrials_ is: ', excludedtrials_(ichar)])
	if strcmp(excludedtrials_(ichar),' ')
		disp(['Space detected: you entered: ', excludedtrials_(ichar)])
		% pass
		ichar = ichar + 1;
	elseif ismember(excludedtrials_(ichar), '0123456789')
		disp(['Single trial #. you entered: ', excludedtrials_(ichar)])
		jchar = ichar;
		next_number = '';
		while jchar <= length(excludedtrials_) && ismember(excludedtrials_(jchar), '0123456789')% get the single numbers eg 495
			next_number(end+1) = excludedtrials_(jchar);
			jchar = jchar + 1;
		end
		next_number = str2double(next_number);
		if next_number <= num_trials % otherwise ignore bc is not in range
			Excluded_Trials(end + 1) = next_number;
		end
		ichar = jchar;
	elseif strcmp(excludedtrials_(ichar),'-')
		disp(['Range detected. you entered: ', excludedtrials_(ichar)])
		% this means we have a range situation:
		while ichar <= length(excludedtrials_) && ~ismember(excludedtrials_(ichar), '0123456789')
			ichar = ichar + 1;
		end
		jchar = ichar;
		next_number = '';
		while jchar <= length(excludedtrials_) && ismember(excludedtrials_(jchar), '0123456789')% get the single numbers eg 495
			next_number(end+1) = excludedtrials_(jchar);
			jchar = jchar + 1;
		end
		next_number = str2double(next_number);
		if next_number <= num_trials
			trials_to_append = (Excluded_Trials(end)+1:next_number);
			Excluded_Trials = horzcat(Excluded_Trials,trials_to_append);	
		else
			trials_to_append = (Excluded_Trials(end)+1:num_trials);
			Excluded_Trials = horzcat(Excluded_Trials,trials_to_append);	
		end
		ichar = ichar;
	else
		disp(['parse error: only use numbers, spaces and dashes. you entered: ', excludedtrials_(ichar)])
		ichar = ichar + 1;
	end
end

% Create excluded arrays
DLS_ex_values_by_trial = DLS_values_by_trial;
SNc_ex_values_by_trial = SNc_values_by_trial;
VTA_ex_values_by_trial = VTA_values_by_trial;
DLSred_ex_values_by_trial = DLSred_values_by_trial;
SNcred_ex_values_by_trial = SNcred_values_by_trial;
VTAred_ex_values_by_trial = VTAred_values_by_trial;
X_ex_values_by_trial = X_values_by_trial;
Y_ex_values_by_trial = Y_values_by_trial;
Z_ex_values_by_trial = Z_values_by_trial;
EMG_ex_values_by_trial = EMG_values_by_trial;
lick_ex_times_by_trial = lick_times_by_trial;

DLS_ex_values_by_trial(Excluded_Trials, :) = NaN;
SNc_ex_values_by_trial(Excluded_Trials, :) = NaN;
VTA_ex_values_by_trial(Excluded_Trials, :) = NaN;
DLSred_ex_values_by_trial(Excluded_Trials, :) = NaN;
SNcred_ex_values_by_trial(Excluded_Trials, :) = NaN;
VTAred_ex_values_by_trial(Excluded_Trials, :) = NaN;
X_ex_values_by_trial(Excluded_Trials, :) = NaN;
Y_ex_values_by_trial(Excluded_Trials, :) = NaN;
Z_ex_values_by_trial(Excluded_Trials, :) = NaN;
EMG_ex_values_by_trial(Excluded_Trials, :) = NaN;
lick_ex_times_by_trial(Excluded_Trials, :) = NaN;


