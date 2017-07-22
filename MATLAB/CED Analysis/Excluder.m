classdef Excluder < handle
	properties
		TrialNames = {}
		numtrials = [];
	end

	properties (SetObservable, AbortSet)
		TrialValues = {}
		DLS_data = []
		SNc_data = []
		DLS_original = []
		SNc_original = []
		Excluded_Trials = [];
		lick_times_by_trial_original = [];
		lick_times_by_trial_excluded = [];
	end

	properties (Transient)	% These properties will be discarded when saving to file
		Listeners
	end

	events
		% StateChanged
	end

	methods
		function obj = Excluder(DLS_original,SNc_original, lick_times_by_trial_original)
			obj.TrialNames{1} = 'Excluded Trials:';
			obj.TrialValues{1} = 'none';
			obj.DLS_original = DLS_original;
			obj.SNc_original = SNc_original;
			obj.DLS_data = DLS_original;
			obj.SNc_data = SNc_original;
			obj.lick_times_by_trial_original = lick_times_by_trial_original;
			obj.lick_times_by_trial_excluded = lick_times_by_trial_original;
			obj.numtrials = size(obj.DLS_original, 1);
		end


		% Save parameters to parameter file
		function SaveTrialNumbers(obj)
			% Fetch trials from object
			parameterNames = obj.TrialNames; 		% store parameter names
			parameterValues = obj.TrialValues; 		% store parameter values

			% Prompt user to select save path
			[filename, filepath] = uiputfile(['parameters_', datestr(now, 'yyyymmdd'), '.mat'], 'Save current parameters to file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			% Save to file
			save([filepath, filename], 'parameterNames', 'parameterValues');
		end

		% Load parameters from parameter/experiment file
		function LoadTrialNumbers(obj, table_trials, errorMessage)
			if nargin < 3
				errorMessage = '';
			end
			if nargin < 2
				table_trials = [];
			end
			% Display errorMessage prompt if called for
			if ~isempty(errorMessage)
				selection = questdlg(...
					errorMessage,...
					'Error',...
					'Yes','No','Yes'...
				);
				% Exit if the Grad Student says 'No'
				if strcmp(selection, 'No')
					return
				end
			end

			[filename, filepath] = uigetfile('*.mat', 'Load parameters from file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			% Load file
			p = load([filepath, filename]);
			% If loaded file does not contain parameters
			if ~(isfield(p, 'parameterNames') && isfield(p, 'parameterValues'))
				% Ask the Grad Student if he wants to selcet another file instead
				obj.LoadTrialNumbers(table_trials, 'The file you selected was not loaded because it does not contain experiment parameters. Select another file instead?')
			else
				% If loaded parameterNames contains a different number of parameters from arduino object
				if (length(p.parameterNames) ~= length(obj.TrialNames))
					obj.LoadTrialNumbers(table_trials, 'The file you selected was not loaded because parameter names do not match the ones used by Arduino. Select another file instead?')	
				else
					paramHasSameName = cellfun(@strcmp, p.parameterNames, obj.TrialNames);
					% If loaded parameterNames names are different from arduino object
					if (sum(paramHasSameName) ~= length(paramHasSameName))			
						obj.LoadTrialNumbers(table_trials, 'The file you selected was not loaded because the number of parameters does not match the ones used by Arduino. Select another file instead?')
					else
						obj.TrialNames = p.parameterNames
						obj.TrialValues = p.parameterValues
						% If all checks pass, upload to Arduino
						% Add all parameters to update queue
						% for iTrial = 1:length(p.parameterNames)
						% 	obj.UpdateTrials_AddToQueue(iTrial, p.parameterValues(iTrial))
						% end
						% % Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
						% obj.UpdateTrials_Execute()
						set(table_trials, 'Data', obj.TrialValues);
						obj.SetTrial(1, p.parameterValues{1})
					end
				end
			end
		end


		

		% Update a single parameter by index
		function SetTrial(obj, paramId, value)
			% % Update parameter value in MATLAB
			obj.TrialValues{paramId} = value;
			% Parse the userinput to determine which trials to omit:
				% Reset the exlcuded trials array
			obj.Excluded_Trials = [];
			% previous_case = 0;
			ichar = 1;
			while ichar <= length(value)
				disp(['the class of ichar is: ', class(value(ichar)), ' and the value is: ', value(ichar)])
				if strcmp(value(ichar),' ')
					disp(['Space detected: you entered: ', value(ichar)])
					% pass
					ichar = ichar + 1;
				elseif ismember(value(ichar), '0123456789')
					disp(['Single trial #. you entered: ', value(ichar)])
					jchar = ichar;
					next_number = '';
					while jchar <= length(value) && ismember(value(jchar), '0123456789')% get the single numbers eg 495
						next_number(end+1) = value(jchar);
						jchar = jchar + 1;
					end
					next_number = str2double(next_number);
					if next_number <= obj.numtrials % otherwise ignore bc is not in range
						obj.Excluded_Trials(end + 1) = next_number;
					end
					ichar = jchar;
				elseif strcmp(value(ichar),'-')
					disp(['Range detected. you entered: ', value(ichar)])
					% this means we have a range situation:
					while ichar <= length(value) && ~ismember(value(ichar), '0123456789')
						ichar = ichar + 1;
					end
					jchar = ichar;
					next_number = '';
					while jchar <= length(value) && ismember(value(jchar), '0123456789')% get the single numbers eg 495
						next_number(end+1) = value(jchar);
						jchar = jchar + 1;
					end
					next_number = str2double(next_number);
					if next_number <= obj.numtrials
						trials_to_append = (obj.Excluded_Trials(end)+1:next_number);
						obj.Excluded_Trials = horzcat(obj.Excluded_Trials,trials_to_append);	
					else
						trials_to_append = (obj.Excluded_Trials(end)+1:obj.numtrials);
						obj.Excluded_Trials = horzcat(obj.Excluded_Trials,trials_to_append);	
					end
					ichar = ichar;
				else
					disp(['parse error: only use numbers, spaces and dashes. you entered: ', value(ichar)])
					ichar = ichar + 1;
				end
			end
	        DLS_excluded = obj.DLS_original;
	        SNc_excluded = obj.SNc_original;
	        licks_excluded = obj.lick_times_by_trial_original;

	        DLS_excluded(obj.Excluded_Trials, :) = NaN;
	        SNc_excluded(obj.Excluded_Trials, :) = NaN;
	        licks_excluded(obj.Excluded_Trials, :) = NaN;

	        obj.DLS_data = DLS_excluded;
	        obj.SNc_data = SNc_excluded;
	        obj.lick_times_by_trial_excluded = licks_excluded;
        end


		function Reset(obj)
			obj.TrialValues = {'reset'}
		end

	end

end
