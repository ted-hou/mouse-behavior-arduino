%% Exclude trials by typing in the trial range to exclude

classdef ExcluderInterface < handle
	properties
		Excluder
		UserData
	end
	properties (Transient)
		Rsc
	end


	%----------------------------------------------------
	%		Methods
	%----------------------------------------------------
	methods
		function obj = ExcluderInterface(DLS_values_by_trial, SNc_values_by_trial, lick_times_by_trial)
			% Load up the original data
			DLS_original = DLS_values_by_trial;
			SNc_original = SNc_values_by_trial;
			lick_times_by_trial_original = lick_times_by_trial;
			% Creat object holding the values_by_trial variables:
			obj.Excluder = Excluder(DLS_original,SNc_original, lick_times_by_trial);
			% Creata Experiment Control window with all the knobs and buttons you need to set up an experiment. 
			obj.CreateDialog_ExperimentControl()

		end

		function CreateDialog_ExperimentControl(obj)
			% If object already exists, show window
			if isfield(obj.Rsc, 'ExperimentControl')
				if isvalid(obj.Rsc.ExperimentControl)
					figure(obj.Rsc.ExperimentControl)
					return
				end
			end

			% Size and position of controls
			buttonWidth = 50; % Width of buttons
			buttonHeight = 20; % Height of 
			ctrlSpacing = 10; % Spacing between ui elements

			% Create the dialog
			dlg = dialog(...
				'Name', sprintf('Exclusion Control'),...
				'WindowStyle', 'normal',...
				'Resize', 'on',...
				'Visible', 'off'... % Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.ExperimentControl = dlg;

			% Close serial port when you close the window
			% dlg.CloseRequestFcn = {@MouseBehaviorInterface.Close, obj};

			% Create a uitable for parameters
			table_trials = uitable(...
				'Parent', dlg,...
				'Data', obj.Excluder.TrialValues',...
				'RowName', obj.Excluder.TrialNames,...
				'ColumnName', {''},...
				'ColumnFormat', {'long'},...
				'ColumnEditable', true,...
				'CellEditCallback', {@ExcluderInterface.OnTrialChangedViaGUI, obj.Excluder}...
			);
			dlg.UserData.Ctrl.Table_Trials = table_trials;
% 
% 			Add listener for parameter change via non-GUI methods, in which case we'll update table_trials
% 			obj.Excluder.Listeners.TrialChanged = addlistener(obj.Excluder, 'PostSet', 'TrialValues', @Excluder.SetTrial);

			% Set width and height
			table_trials.Position(3:4) = table_trials.Extent(3:4);


			% Reset button - restore no exclusions
            ctrlPosBase = table_trials.Position;
			ctrlPos = [...
				ctrlPosBase(1) + ctrlPosBase(3) + ctrlSpacing,...
				ctrlPosBase(2) + ctrlPosBase(4) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_reset = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Reset',...
				'TooltipString', 'Restore Original Trial File.',...
				'Callback', {@ExcluderInterface.Reset, obj.Excluder, table_trials}...
			);

			% Resize dialog so it fits all controls
			dlg.Position(1:2) = [10, 50];
			dlg.Position(3) = table_trials.Position(3) + buttonWidth + 4*ctrlSpacing;
			dlg.Position(4) = table_trials.Position(4) + 3*ctrlSpacing;

			% Menus
			menu_file = uimenu(dlg, 'Label', '&File');
			uimenu(menu_file, 'Label', 'Save TrialNumbers ...', 'Callback', {@ExcluderInterface.ArduinoSaveTrialNumbers, obj.Excluder}, 'Separator', 'on');
			uimenu(menu_file, 'Label', 'Load TrialNumbers ...', 'Callback', {@ExcluderInterface.ArduinoLoadTrialNumbers, obj.Excluder, table_trials});
			uimenu(menu_file, 'Label', 'Quit', 'Callback', {@ExcluderInterface.Close, obj}, 'Separator', 'on');

			
			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
        end

    end

	

	%----------------------------------------------------
	%		Static methods
	%----------------------------------------------------
	methods (Static)
		
		function OnTrialChangedViaGUI(~, evnt, Excluder)
			% evnt (event data contains infomation on which elements were changed to what)
			changedTrial = evnt.Indices(1);
			newValue = evnt.NewData;
			Excluder.SetTrial(changedTrial,newValue)
		end

		

		function Reset(~, ~, Excluder, table_trials)
			Excluder.Reset()
			fprintf('Reset.\n')
			set(table_trials, 'Data', Excluder.TrialValues);
			Excluder.SetTrial(1, Excluder.TrialValues{1})
		end

		function Close(~, ~, obj)
			selection = questdlg(...
				'Close all windows and terminate connection with Arduino?',...
				'Close Window',...
				'Yes','No','Yes'...
			);
			switch selection
				case 'Yes'
					obj.Excluder.Close()
					delete(obj.Rsc.ExperimentControl)
					fprintf('Application closed.\n')
				case 'No'
					return
			end
		end
		
		function ArduinoSaveTrialNumbers(~, ~, Excluder)
			Excluder.SaveTrialNumbers()
		end
		function ArduinoLoadTrialNumbers(~, ~, Excluder, table_trials)
			if nargin < 4
				table_trials = [];
			end
			Excluder.LoadTrialNumbers(table_trials, '')
		end
	end
end






