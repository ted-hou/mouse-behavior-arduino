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
		function obj = ExcluderInterface()
			
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
			% dlg.CloseRequestFcn = {@MouseBehaviorInterface.ArduinoClose, obj};

			% Create a uitable for parameters
			table_params = uitable(...
				'Parent', dlg,...
				'Data', obj.Excluder.ParamValues',...
				'RowName', obj.Excluder.ParamNames,...
				'ColumnName', {'Value'},...
				'ColumnFormat', {'long'},...
				'ColumnEditable', [true],...
				'CellEditCallback', {@exclude_trials_type.OnParamChangedViaGUI, obj.Excluder}...
			);
			dlg.UserData.Ctrl.Table_Params = table_params;

			% Add listener for parameter change via non-GUI methods, in which case we'll update table_params
			obj.Excluder.Listeners.ParamChanged = addlistener(obj.Excluder, 'ParamValues', 'PostSet', @obj.OnParamChanged);

			% Set width and height
			table_params.Position(3:4) = table_params.Extent(3:4);


			% Reset button - restore no exclusions
			ctrlPosBase = button_stop.Position;
			ctrlPos = [...
				ctrlPosBase(1),...
				ctrlPosBase(2) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_reset = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Reset',...
				'TooltipString', 'Restore Original Trial File.',...
				'Callback', {@exclude_trials_type.ArduinoReset, obj.Excluder}...
			);

			% Resize dialog so it fits all controls
			dlg.Position(1:2) = [10, 50];
			dlg.Position(3) = table_params.Position(3) + buttonWidth + 4*ctrlSpacing;
			dlg.Position(4) = table_params.Position(4) + 3*ctrlSpacing;

			% Menus
			menu_file = uimenu(dlg, 'Label', '&File');
			uimenu(menu_file, 'Label', 'Save Parameters ...', 'Callback', {@exclude_trials_type.ArduinoSaveParameters, obj.Excluder}, 'Separator', 'on');
			uimenu(menu_file, 'Label', 'Load Parameters ...', 'Callback', {@exclude_trials_type.ArduinoLoadParameters, obj.Excluder, table_params});
			uimenu(menu_file, 'Label', 'Quit', 'Callback', {@exclude_trials_type.ArduinoClose, obj}, 'Separator', 'on');

			
			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end
	end

	

	%----------------------------------------------------
	%		Static methods
	%----------------------------------------------------
	methods (Static)
		
		function OnParamChangedViaGUI(~, evnt, Excluder)
			% evnt (event data contains infomation on which elements were changed to what)
			changedParam = evnt.Indices(1);
			newValue = evnt.NewData;
		end
		

		function ArduinoReset(~, ~, Excluder)
			arduino.Reset()
			fprintf('Reset.\n')
		end

		function ArduinoClose(~, ~, obj)
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
		
		function ArduinoSaveParameters(~, ~, Excluder)
			Excluder.SaveParameters()
		end
		function ArduinoLoadParameters(~, ~, Excluder, table_params)
			if nargin < 4
				table_params = [];
			end
			Excluder.LoadParameters(table_params, '')
		end
	end
end






