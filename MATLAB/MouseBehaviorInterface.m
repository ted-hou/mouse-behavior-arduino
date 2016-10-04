%% MouseBehaviorInterface: construct graphical user interface to interact with arduino
classdef MouseBehaviorInterface < handle
	properties
		Arduino
		UserData
	end
	properties (Transient)
		Rsc
	end

	%----------------------------------------------------
	%		Methods
	%----------------------------------------------------
	methods
		function obj = MouseBehaviorInterface()
			% Establish arduino connection
			obj.Arduino = ArduinoConnection();

			% Creata Experiment Control window with all the knobs and buttons you need to set up an experiment. 
			obj.CreateDialog_ExperimentControl()

			% Create Monitor window with all thr trial results and plots and stuff so the Grad Student is ON TOP OF THE SITUATION AT ALL TIMES.
			obj.CreateDialog_Monitor()
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
				'Name', 'Experiment Control',...
				'WindowStyle', 'normal',...
				'Resize', 'on',...
				'Visible', 'off'... % Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.ExperimentControl = dlg;

			% Close serial port when you close the window
			dlg.CloseRequestFcn = {@MouseBehaviorInterface.ArduinoClose, obj.Arduino};

			% Create a uitable for parameters
			table_params = uitable(...
				'Parent', dlg,...
				'Data', obj.Arduino.ParamValues',...
				'RowName', obj.Arduino.ParamNames,...
				'ColumnName', {'Value'},...
				'ColumnFormat', {'long'},...
				'ColumnEditable', [true],...
				'CellEditCallback', {@MouseBehaviorInterface.OnParamChangedViaGUI, obj.Arduino}...
			);
			dlg.UserData.Ctrl.Table_Params = table_params;

			% Add listener for parameter change via non-GUI methods, in which case we'll update table_params
			obj.Arduino.Listeners.ParamChanged = addlistener(obj.Arduino, 'ParamValues', 'PostSet', @obj.OnParamChanged);

			% Set width and height
			table_params.Position(3:4) = table_params.Extent(3:4);

			% Start button - start experiment from IDLE
			ctrlPosBase = table_params.Position;
			ctrlPos = [...
				ctrlPosBase(1) + ctrlPosBase(3) + ctrlSpacing,...
				ctrlPosBase(2) + ctrlPosBase(4) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_start = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Start',...
				'TooltipString', 'Tell Arduino to start the experiment. Breaks out of IDLE state.',...
				'Callback', {@MouseBehaviorInterface.ArduinoStart, obj.Arduino}...
			);

			% Stop button - abort current trial and return to IDLE
			ctrlPosBase = button_start.Position;
			ctrlPos = [...
				ctrlPosBase(1),...
				ctrlPosBase(2) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_stop = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Stop',...
				'TooltipString', 'Puts Arduino into IDLE state. Resume using the "Start" button.',...
				'Callback', {@MouseBehaviorInterface.ArduinoStop, obj.Arduino}...
			);

			% Reset button - software reset for arduino
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
				'TooltipString', 'Reset Arduino (parameters will not be changed).',...
				'Callback', {@MouseBehaviorInterface.ArduinoReset, obj.Arduino}...
			);

			% Resize dialog so it fits all controls
			dlg.Position(1:2) = [10, 50];
			dlg.Position(3) = table_params.Position(3) + buttonWidth + 4*ctrlSpacing;
			dlg.Position(4) = table_params.Position(4) + 3*ctrlSpacing;

			% Menus
			menu_file = uimenu(dlg, 'Label', '&File');
			uimenu(menu_file, 'Label', 'Save Experiment ...', 'Callback', {@MouseBehaviorInterface.ArduinoSaveExperiment, obj.Arduino}, 'Accelerator', 's');
			uimenu(menu_file, 'Label', 'Save Experiment As ...', 'Callback', {@MouseBehaviorInterface.ArduinoSaveAsExperiment, obj.Arduino});
			uimenu(menu_file, 'Label', 'Load Experiment ...', 'Callback', {@MouseBehaviorInterface.ArduinoLoadExperiment, obj.Arduino}, 'Accelerator', 'l');
			uimenu(menu_file, 'Label', 'Save Parameters ...', 'Callback', {@MouseBehaviorInterface.ArduinoSaveParameters, obj.Arduino}, 'Separator', 'on');
			uimenu(menu_file, 'Label', 'Load Parameters ...', 'Callback', {@MouseBehaviorInterface.ArduinoLoadParameters, obj.Arduino, table_params});
			uimenu(menu_file, 'Label', 'Quit', 'Callback', {@MouseBehaviorInterface.ArduinoClose, obj.Arduino}, 'Separator', 'on');

			menu_arduino = uimenu(dlg, 'Label', '&Arduino');
			uimenu(menu_arduino, 'Label', 'Start', 'Callback', {@MouseBehaviorInterface.ArduinoStart, obj.Arduino});
			uimenu(menu_arduino, 'Label', 'Stop', 'Callback', {@MouseBehaviorInterface.ArduinoStop, obj.Arduino}, 'Accelerator', 'q');
			uimenu(menu_arduino, 'Label', 'Reset', 'Callback', {@MouseBehaviorInterface.ArduinoReset, obj.Arduino}, 'Separator', 'on');
			uimenu(menu_arduino, 'Label', 'Reconnect', 'Callback', {@MouseBehaviorInterface.ArduinoReconnect, obj.Arduino});

			menu_window = uimenu(dlg, 'Label', '&Window');
			uimenu(menu_window, 'Label', 'Experiment Control', 'Callback', @(~, ~) @obj.CreateDialog_ExperimentControl);
			uimenu(menu_window, 'Label', 'Monitor', 'Callback', @(~, ~) obj.CreateDialog_Monitor);

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end

		function CreateDialog_Monitor(obj)
			% If object already exists, show window
			if isfield(obj.Rsc, 'Monitor')
				if isvalid(obj.Rsc.Monitor)
					figure(obj.Rsc.Monitor)
					return
				end
			end
			dlgWidth = 800;
			dlgHeight = 400;

			% Create the dialog
			dlg = dialog(...
				'Name', 'Monitor',...
				'WindowStyle', 'normal',...
				'Position', [350, 50, dlgWidth, dlgHeight],...
				'Units', 'pixels',...
				'Resize', 'on',...
				'Visible', 'off'... % Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.Monitor = dlg;

			% Size and position of controls
			dlg.UserData.DlgMargin = 20;
			dlg.UserData.LeftPanelWidthRatio = 0.3;
			dlg.UserData.PanelSpacing = 20;
			dlg.UserData.PanelMargin = 20;
			dlg.UserData.PanelMarginTop = 20;
			dlg.UserData.BarHeight = 75;
			dlg.UserData.TextHeight = 30;

			u = dlg.UserData;

			% % Close serial port when you close the window
			dlg.CloseRequestFcn = @(~, ~) (delete(gcbo));

			%----------------------------------------------------
			%		Left panel
			%----------------------------------------------------
			leftPanel = uipanel(...
				'Parent', dlg,...
				'Title', 'Experiment Summary',...
				'Units', 'pixels'...
			);
			dlg.UserData.Ctrl.LeftPanel = leftPanel;

			% Text: Number of trials completed
			trialCountText = uicontrol(...
				'Parent', leftPanel,...
				'Style', 'text',...
				'String', 'Trials completed: 0',...
				'TooltipString', 'Number of trials completed in this session.',...
				'HorizontalAlignment', 'left',...
				'Units', 'pixels',...
				'FontSize', 13 ...
			);
			dlg.UserData.Ctrl.TrialCountText = trialCountText;

			%----------------------------------------------------
			%		Right panel
			%----------------------------------------------------
			rightPanel = uitabgroup(...
				'Parent', dlg,...
				'Units', 'pixels'...
			);
			dlg.UserData.Ctrl.RightPanel = rightPanel;

			%----------------------------------------------------
			%		Raster Tab
			%----------------------------------------------------
			tab_raster = uitab(...
				'Parent', rightPanel,...
				'Title', 'Raster Plot'...
			);
			dlg.UserData.Ctrl.Tab_Raster = tab_raster;

			text_eventTrialStart_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'text',...
				'String', 'Trial Start Event',...
				'HorizontalAlignment', 'left'...				
			);
			dlg.UserData.Ctrl.Text_EventTrialStart_Raster = text_eventTrialStart_raster;

			popup_eventTrialStart_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventTrialStart_Raster = popup_eventTrialStart_raster;

			text_eventZero_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'text',...
				'String', 'Reference Event',...
				'HorizontalAlignment', 'left'...				
			);
			dlg.UserData.Ctrl.Text_EventZero_Raster = text_eventZero_raster;

			popup_eventZero_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventZero_Raster = popup_eventZero_raster;

			text_eventOfInterest_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'text',...
				'String', 'Event Of Interest',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_EventOfInterest_Raster = text_eventOfInterest_raster;

			popup_eventOfInterest_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventOfInterest_Raster = popup_eventOfInterest_raster;

			text_figureName_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'text',...
				'String', 'Figure Name',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_FigureName_Raster = text_figureName_raster;

			edit_figureName_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'edit',...
				'String', 'Raster Plot',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Edit_FigureName_Raster = edit_figureName_raster;

			text_paramsToPlot_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'text',...
				'String', 'Show parameters in plot:',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_ParamsToPlot_Raster = text_paramsToPlot_raster;

			paramNames = [obj.Arduino.ParamNames'; repmat({'Enter Custom Value'}, 4, 1)];
			numParams = length(paramNames);
			table_paramsToPlot_raster = uitable(...
				'Parent', tab_raster,...
				'Data', [paramNames, repmat({false}, [numParams, 1]), repmat({'black'}, [numParams, 1]), repmat({'-'}, [numParams, 1])],...
				'RowName', {},...
				'ColumnName', {'Parameter', 'Plot', 'Color', 'Style'},...
				'ColumnFormat', {'char', 'logical', {'black', 'red', 'blue', 'green'}, {'-', '--', ':', '-.'}},...
				'ColumnEditable', [true, true, true, true]...
			);
			dlg.UserData.Ctrl.Table_ParamsToPlot_Raster = table_paramsToPlot_raster;

			button_plot_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'pushbutton',...
				'String', 'Plot',...
				'Callback', @obj.Raster_GUI...
			);
			dlg.UserData.Ctrl.Button_Plot_Raster = button_plot_raster;

			%----------------------------------------------------
			%		Hist Tab
			%----------------------------------------------------
			tab_hist = uitab(...
				'Parent', rightPanel,...
				'Title', 'Histogram'...
			);
			dlg.UserData.Ctrl.Tab_Hist = tab_hist;

			text_eventTrialStart_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'text',...
				'String', 'Trial Start Event',...
				'HorizontalAlignment', 'left'...				
			);
			dlg.UserData.Ctrl.Text_EventTrialStart_Hist = text_eventTrialStart_hist;

			popup_eventTrialStart_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventTrialStart_Hist = popup_eventTrialStart_hist;

			text_eventZero_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'text',...
				'String', 'Reference Event',...
				'HorizontalAlignment', 'left'...				
			);
			dlg.UserData.Ctrl.Text_EventZero_Hist = text_eventZero_hist;

			popup_eventZero_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventZero_Hist = popup_eventZero_hist;

			text_eventOfInterest_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'text',...
				'String', 'Event Of Interest',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_EventOfInterest_Hist = text_eventOfInterest_hist;

			popup_eventOfInterest_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventOfInterest_Hist = popup_eventOfInterest_hist;

			text_figureName_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'text',...
				'String', 'Figure Name',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_FigureName_Hist = text_figureName_hist;

			edit_figureName_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'edit',...
				'String', 'Histogram',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Edit_FigureName_Hist = edit_figureName_hist;

			button_plot_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'pushbutton',...
				'String', 'Plot',...
				'Callback', @obj.Hist_GUI...
			);
			dlg.UserData.Ctrl.Button_Plot_Hist = button_plot_hist;

			%----------------------------------------------------
			% 		Stacked bar chart for trial results
			%----------------------------------------------------
			ax = axes(...
				'Parent', dlg,...
				'Units', 'pixels',...
				'XTickLabel', [],...
				'YTickLabel', [],...
				'XTick', [],...
				'YTick', [],...
				'Box', 'on'...
			);
			obj.Rsc.Monitor.UserData.Ctrl.Ax = ax;

			% Update session summary everytime a new trial's results are registered by Arduino
			obj.Arduino.Listeners.TrialRegistered = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @obj.OnTrialRegistered);


			%----------------------------------------------------
			% 		Menus
			%----------------------------------------------------
			menu_file = uimenu(dlg, 'Label', '&File');
			uimenu(menu_file, 'Label', '&Save Plot Settings ...', 'Callback', @(~, ~) obj.SavePlotSettings, 'Accelerator', 's');
			uimenu(menu_file, 'Label', '&Load Plot Settings ...', 'Callback', @(~, ~) obj.LoadPlotSettings, 'Accelerator', 'l');
			menu_plot = uimenu(menu_file, 'Label', '&Plot Update', 'Separator', 'on');
			menu_plot.UserData.Menu_Enable = uimenu(menu_plot, 'Label', '&Enabled', 'Callback', @(~, ~) obj.EnablePlotUpdate(menu_plot));
			menu_plot.UserData.Menu_Disable = uimenu(menu_plot, 'Label', '&Disabled', 'Callback', @(~, ~) obj.DisablePlotUpdate(menu_plot));

			if isfield(obj.UserData, 'UpdatePlot')
				if obj.UserData.UpdatePlot
					menu_plot.UserData.Menu_Enable.Checked = 'on';
					menu_plot.UserData.Menu_Disable.Checked = 'off';
				else
					menu_plot.UserData.Menu_Enable.Checked = 'off';
					menu_plot.UserData.Menu_Disable.Checked = 'on';
				end
			else
				menu_plot.UserData.Menu_Enable.Checked = 'on';
				menu_plot.UserData.Menu_Disable.Checked = 'off';
				obj.UserData.UpdatePlot = true;
			end

			menu_window = uimenu(dlg, 'Label', '&Window');
			uimenu(menu_window, 'Label', 'Experiment Control', 'Callback', @(~, ~) @obj.CreateDialog_ExperimentControl);
			uimenu(menu_window, 'Label', 'Monitor', 'Callback', @(~, ~) obj.CreateDialog_Monitor);

			% Stretch barchart When dialog window is resized
			dlg.SizeChangedFcn = @MouseBehaviorInterface.OnMonitorDialogResized; 

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end


		function OnTrialRegistered(obj, ~, ~)
		% Executed when a new trial is completed
			% Autosave if a savepath is defined
			if (~isempty(obj.Arduino.ExperimentFileName) && obj.Arduino.AutosaveEnabled)
				MouseBehaviorInterface.ArduinoSaveExperiment([], [], obj.Arduino);
			end

			if isvalid(obj.Rsc.Monitor)
				% Count how many trials have been completed
				iTrial = obj.Arduino.TrialsCompleted;

				% Update the "Trials Completed" counter.
				t = obj.Rsc.Monitor.UserData.Ctrl.TrialCountText;
				t.String = sprintf('Trials completed: %d', iTrial);

				% When a new trial is completed
				ax = obj.Rsc.Monitor.UserData.Ctrl.Ax;
				% Get a list of currently recorded result codes
				resultCodes = reshape([obj.Arduino.Trials.Code], [], 1);
				resultCodeNames = obj.Arduino.ResultCodeNames;
				allResultCodes = 1:(length(resultCodeNames) + 1);
				resultCodeCounts = histcounts(resultCodes, allResultCodes);

				MouseBehaviorInterface.StackedBar(ax, resultCodeCounts, resultCodeNames);
			end
		
			drawnow
		end

		%----------------------------------------------------
		%		Plot - Raster plot events for each trial
		%----------------------------------------------------
		function Raster_GUI(obj, ~, ~)
			ctrl = obj.Rsc.Monitor.UserData.Ctrl;

			eventCodeTrialStart = ctrl.Popup_EventTrialStart_Raster.Value;
			eventCodeZero 		= ctrl.Popup_EventZero_Raster.Value;
			eventCodeOfInterest = ctrl.Popup_EventOfInterest_Raster.Value;
			figName 			= ctrl.Edit_FigureName_Raster.String;
			paramPlotOptions 	= ctrl.Table_ParamsToPlot_Raster.Data;

			obj.Raster(eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName, paramPlotOptions)
		end
		function Raster(obj, eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName, paramPlotOptions)
			% First column in data is eventCode, second column is timestamp (since trial start)
			if nargin < 5
				figName = '';
			end
			if nargin < 6
				paramPlotOptions = struct([]);
			end

			% Create axes object
			f = figure('Name', figName, 'NumberTitle', 'off');

			% Store the axes object
			if ~isfield(obj.Rsc, 'LooseFigures')
				figId = 1;
			else
				figId = length(obj.Rsc.LooseFigures) + 1;
			end
			obj.Rsc.LooseFigures(figId).Ax = gca;
			ax = obj.Rsc.LooseFigures(figId).Ax;

			% Store plot settings into axes object
			ax.UserData.EventCodeTrialStart = eventCodeTrialStart;
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.FigName				= figName;
			ax.UserData.ParamPlotOptions 	= paramPlotOptions;

			% Plot it for the first time
			obj.Raster_Execute(figId);

			% Plot again everytime an event of interest occurs
			ax.UserData.Listener = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @(~, ~) obj.Raster_Execute(figId));
			f.CloseRequestFcn = {@MouseBehaviorInterface.OnLooseFigureClosed, ax.UserData.Listener};
		end
		function Raster_Execute(obj, figId)
			% Do not plot if the Grad Student decides we should stop plotting stuff.
			if isfield(obj.UserData, 'UpdatePlot') && (~obj.UserData.UpdatePlot)
				return
			end

			data 				= obj.Arduino.EventMarkers;
			ax 					= obj.Rsc.LooseFigures(figId).Ax;

			eventCodeTrialStart = ax.UserData.EventCodeTrialStart;
			eventCodeOfInterest = ax.UserData.EventCodeOfInterest;
			eventCodeZero 		= ax.UserData.EventCodeZero;
			figName 			= ax.UserData.FigName;
			paramPlotOptions	= ax.UserData.ParamPlotOptions;

			% If events did not occur at all, do not plot
			if (isempty(data))
				return
			end

			% Separate eventsOfInterest into trials, divided by eventsZero
			eventsTrialStart	= find(data(:, 1) == eventCodeTrialStart);
			eventsZero 			= find(data(:, 1) == eventCodeZero);
			eventsOfInterest 	= find(data(:, 1) == eventCodeOfInterest);

			% If events did not occur at all, do not plot
			if (isempty(eventsTrialStart) || isempty(eventsZero) || isempty(eventsOfInterest))
				return
			end

			if eventsOfInterest(end) > eventsTrialStart(end) || eventsZero(end) > eventsTrialStart(end)
				edges = [eventsTrialStart; max([eventsZero(end), eventsOfInterest(end)]) + 1];
			else
				edges = [eventsTrialStart; eventsTrialStart(end) + 1];
			end

			% Filter out 'orphan' eventsOfInterest that do not have an eventZero in the same trial 
			[~, ~, trialsOfInterest] = histcounts(eventsOfInterest, edges);
			[~, ~, trialsZero] = histcounts(eventsZero, edges);

			ism = ismember(trialsOfInterest, trialsZero);
			trialsOfInterest = trialsOfInterest(ism);
			eventsOfInterest = eventsOfInterest(ism);

			% Events of interest timestamps
			eventTimesOfInterest = data(eventsOfInterest, 2); 

			% Reference events timestamps
			if trialsOfInterest(end) > trialsZero(end)
				edges = [trialsZero; trialsOfInterest(end) + 1];
			else
				edges = [trialsZero; trialsZero(end) + 1];
			end
			[~, ~, bins] = histcounts(trialsOfInterest, edges);
			eventTimesZero = data(eventsZero(bins), 2);

			% Plot histogram of selected event times
			eventTimesRelative = eventTimesOfInterest - eventTimesZero;
			plot(ax, eventTimesRelative, trialsOfInterest, '.k',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', [0 .5 .5],...
				'MarkerFaceColor', [0 .7 .7],...
				'LineWidth', 1.5,...
				'DisplayName', obj.Arduino.EventMarkerNames{eventCodeOfInterest}...
			)

			% Plot parameters
			% Filter out parameters the Grad Student does not want to plot
			paramsToPlot = find([paramPlotOptions{:, 2}]);

			if ~isempty(paramsToPlot)
				params = ctranspose(reshape([obj.Arduino.Trials.Parameters], [], size(obj.Arduino.Trials, 2)));			
				hold(ax, 'on')
				for iParam = paramsToPlot
					% Arduino parameter
					if iParam <= length(obj.Arduino.ParamNames)
						paramValues = params(:, iParam);
					% Plot custom parameter unless the Grad Student changes its default name to a number
					elseif ~isempty(str2num(paramPlotOptions{iParam, 1}))
						paramValues = repmat(str2num(paramPlotOptions{iParam, 1}), size(params, 1), 1);
					else
						continue
					end
					plot(ax, paramValues, 1:length(obj.Arduino.Trials),...
						'DisplayName', num2str(paramPlotOptions{iParam, 1}),...
						'Color', paramPlotOptions{iParam, 3},...
						'LineStyle', paramPlotOptions{iParam, 4},...
						'LineWidth', 1.2 ...
					);
				end
				hold(ax, 'off')
			end
			lgd = legend(ax, 'Location', 'northoutside');
			lgd.Interpreter = 'none';
			lgd.Orientation = 'horizontal';

			ax.XLim 			= [min(eventTimesRelative) - 100, max(eventTimesRelative) + 100];
			ax.YLim 			= [max([0, min(trialsOfInterest) - 1]), obj.Arduino.TrialsCompleted + 1];
			ax.YDir				= 'reverse';
			ax.XLabel.String 	= 'Time (ms)';
			ax.YLabel.String 	= 'Trial';

			% Set ytick labels
			tickInterval 	= max([1, round(ceil(obj.Arduino.TrialsCompleted/10)/5)*5]);
			ticks 			= tickInterval:tickInterval:obj.Arduino.TrialsCompleted;
			if (tickInterval > 1)
				ticks = [1, ticks];
			end
			if (obj.Arduino.TrialsCompleted) > ticks(end)
				ticks = [ticks, obj.Arduino.TrialsCompleted];
			end
			ax.YTick 		= ticks;
			ax.YTickLabel 	= ticks;

			title(ax, figName)

			% Store plot options cause for some reason it's lost unless we do this.
			ax.UserData.EventCodeTrialStart = eventCodeTrialStart;
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.FigName 			= figName;
			ax.UserData.ParamPlotOptions 	= paramPlotOptions;
		end

		%----------------------------------------------------
		%		Plot - Histogram of first licks/press duration
		%----------------------------------------------------
		function Hist_GUI(obj, ~, ~)
			ctrl = obj.Rsc.Monitor.UserData.Ctrl;

			eventCodeTrialStart = ctrl.Popup_EventTrialStart_Hist.Value;
			eventCodeZero 		= ctrl.Popup_EventZero_Hist.Value;
			eventCodeOfInterest = ctrl.Popup_EventOfInterest_Hist.Value;
			figName 			= ctrl.Edit_FigureName_Hist.String;

			obj.Hist(eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName)
		end
		function Hist(obj, eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName)
			% First column in data is eventCode, second column is timestamp (since trial start)
			if nargin < 5
				figName = '';
			end

			% Create axes object
			f = figure('Name', figName, 'NumberTitle', 'off');

			% Store the axes object
			if ~isfield(obj.Rsc, 'LooseFigures')
				figId = 1;
			else
				figId = length(obj.Rsc.LooseFigures) + 1;
			end
			obj.Rsc.LooseFigures(figId).Ax = gca;
			ax = obj.Rsc.LooseFigures(figId).Ax;

			% Store plot settings into axes object
			ax.UserData.EventCodeTrialStart = eventCodeTrialStart;
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.FigName				= figName;

			% Plot it for the first time
			obj.Hist_Execute(figId);

			% Plot again everytime an event of interest occurs
			ax.UserData.Listener = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @(~, ~) obj.Hist_Execute(figId));
			f.CloseRequestFcn = {@MouseBehaviorInterface.OnLooseFigureClosed, ax.UserData.Listener};
		end
		function Hist_Execute(obj, figId)
			% Do not plot if the Grad Student decides we should stop plotting stuff.
			if isfield(obj.UserData, 'UpdatePlot') && (~obj.UserData.UpdatePlot)
				return
			end

			data 				= obj.Arduino.EventMarkers;
			ax 					= obj.Rsc.LooseFigures(figId).Ax;

			eventCodeTrialStart = ax.UserData.EventCodeTrialStart;
			eventCodeOfInterest = ax.UserData.EventCodeOfInterest;
			eventCodeZero 		= ax.UserData.EventCodeZero;
			figName 			= ax.UserData.FigName;

			% If events did not occur at all, do not plot
			if (isempty(data))
				return
			end

			% Separate eventsOfInterest into trials, divided by eventsZero
			eventsTrialStart	= find(data(:, 1) == eventCodeTrialStart);
			eventsZero 			= find(data(:, 1) == eventCodeZero);
			eventsOfInterest 	= find(data(:, 1) == eventCodeOfInterest);

			% If events did not occur at all, do not plot
			if (isempty(eventsTrialStart) || isempty(eventsZero) || isempty(eventsOfInterest))
				return
			end

			if eventsOfInterest(end) > eventsTrialStart(end) || eventsZero(end) > eventsTrialStart(end)
				edges = [eventsTrialStart; max([eventsZero(end), eventsOfInterest(end)]) + 1];
			else
				edges = [eventsTrialStart; eventsTrialStart(end) + 1];
			end

			% Filter out 'orphan' eventsOfInterest that do not have an eventZero in the same trial 
			[~, ~, trialsOfInterest] = histcounts(eventsOfInterest, edges);
			[~, ~, trialsZero] = histcounts(eventsZero, edges);

			ism = ismember(trialsOfInterest, trialsZero);
			trialsOfInterest = trialsOfInterest(ism);
			eventsOfInterest = eventsOfInterest(ism);

			% Get timestamps for events of interests and zero events
			[C, ia, ~] 			= unique(trialsOfInterest);

			eventsZero  		= eventsZero(C);
			eventsOfInterest 	= eventsOfInterest(ia);

			eventTimesOfInterest 	= data(eventsOfInterest, 2);
			eventTimesZero 			= data(eventsZero, 2);
			
			% Substract two sets of timestamps to get relative times 
			eventTimesOfInterest 	= eventTimesOfInterest - eventTimesZero;

			% Plot histogram of selected event times
			hist(ax, eventTimesOfInterest)
			eventTimesOfInterest

			ax.XLabel.String 	= 'Time (ms)';
			ax.YLabel.String 	= 'Occurance';
			title(ax, figName)

			% Store plot options cause for some reason it's lost unless we do this.
			ax.UserData.EventCodeTrialStart = eventCodeTrialStart;
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.FigName 			= figName;
		end

		function OnParamChanged(obj, ~, ~)
			obj.Rsc.ExperimentControl.UserData.Ctrl.Table_Params.Data = obj.Arduino.ParamValues';
		end

		function EnablePlotUpdate(obj, menu_plot)
			menu_plot.UserData.Menu_Enable.Checked = 'on';
			menu_plot.UserData.Menu_Disable.Checked = 'off';

			obj.UserData.UpdatePlot = true;
		end

		function DisablePlotUpdate(obj, menu_plot)
			menu_plot.UserData.Menu_Enable.Checked = 'off';
			menu_plot.UserData.Menu_Disable.Checked = 'on';

			obj.UserData.UpdatePlot = false;
		end

		function SavePlotSettings(obj)
			[filename, filepath] = uiputfile('plot_parameters.mat', 'Save plot settings to file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end

			ctrl = obj.Rsc.Monitor.UserData.Ctrl;

			plotSettings = {...
				ctrl.Table_ParamsToPlot_Raster.Data,...
				ctrl.Popup_EventTrialStart_Raster.Value,...
				ctrl.Popup_EventZero_Raster.Value,...
				ctrl.Popup_EventOfInterest_Raster.Value,...
				ctrl.Popup_EventTrialStart_Hist.Value,...
				ctrl.Popup_EventZero_Hist.Value,...
				ctrl.Popup_EventOfInterest_Hist.Value...
			};

			save([filepath, filename], 'plotSettings')
		end

		function LoadPlotSettings(obj, errorMessage)
			if nargin < 2
				errorMessage = '';
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

			[filename, filepath] = uigetfile('*.mat', 'Load plot settings from file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			% Load file
			p = load([filepath, filename]);
			% If loaded file does not contain parameters
			if ~isfield(p, 'plotSettings')
				% Ask the Grad Student if he wants to select another file instead
				obj.LoadPlotSettings('The file you selected was not loaded because it does not contain plot settings. Select another file instead?')
			else
				% If all checks are good then do the deed
				ctrl = obj.Rsc.Monitor.UserData.Ctrl;
				ctrl.Table_ParamsToPlot_Raster.Data = p.plotSettings{1};
				ctrl.Popup_EventTrialStart_Raster.Value = p.plotSettings{2};
				ctrl.Popup_EventZero_Raster.Value = p.plotSettings{3};
				ctrl.Popup_EventOfInterest_Raster.Value = p.plotSettings{4};
				ctrl.Popup_EventTrialStart_Hist.Value = p.plotSettings{5};
				ctrl.Popup_EventZero_Hist.Value = p.plotSettings{6};
				ctrl.Popup_EventOfInterest_Hist.Value = p.plotSettings{7};
			end
		end
	end

	%----------------------------------------------------
	%		Static methods
	%----------------------------------------------------
	methods (Static)
		%----------------------------------------------------
		%		Commmunicating with Arduino
		%----------------------------------------------------
		function OnParamChangedViaGUI(~, evnt, arduino)
			% evnt (event data contains infomation on which elements were changed to what)
			changedParam = evnt.Indices(1);
			newValue = evnt.NewData;
			
			% Add new parameter to update queue
			arduino.UpdateParams_AddToQueue(changedParam, newValue)
			% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
			arduino.UpdateParams_Execute()
		end
		function ArduinoStart(~, ~, arduino)
			if ((~arduino.AutosaveEnabled) || isempty(arduino.ExperimentFileName))
				selection = questdlg(...
					'Autosave is disabled. Start experiment anyway?',...
					'Autosave',...
					'Save', 'Start Anyway', 'Cancel' ,'Save'...
				);
				switch selection
					case 'Save'
						arduino.SaveAsExperiment()
					case 'Start Anyway'
						warning('Autosave not enabled. Starting experiment anyway.')
					otherwise
						return
				end 
			end
			arduino.Start()
			fprintf('Started.\n')			
		end
		function ArduinoStop(~, ~, arduino)
			arduino.Stop()
			fprintf('Stopped.\n')
		end
		function ArduinoReset(~, ~, arduino)
			arduino.Reset()
			fprintf('Reset.\n')
		end
		function ArduinoClose(~, ~, arduino)
			selection = questdlg(...
				'Close all windows and terminate connection with Arduino?',...
				'Close Window',...
				'Yes','No','Yes'...
			);
			switch selection
				case 'Yes'
					arduino.Close()
					delete(gcf)
					close all
					fprintf('Connection closed.\n')
				case 'No'
					return
			end
		end
		function ArduinoReconnect(~, ~, arduino)
			arduino.Reconnect()
		end
		function ArduinoSaveParameters(~, ~, arduino)
			arduino.SaveParameters()
		end
		function ArduinoLoadParameters(~, ~, arduino, table_params)
			if nargin < 4
				table_params = [];
			end
			arduino.LoadParameters(table_params, '')
		end
		function ArduinoSaveExperiment(~, ~, arduino)
			if isempty(arduino.ExperimentFileName)
				arduino.SaveAsExperiment()
			else
				arduino.SaveExperiment()
			end
		end
		function ArduinoSaveAsExperiment(~, ~, arduino)
			arduino.SaveAsExperiment()
		end
		function ArduinoLoadExperiment(~, ~, arduino)
			arduino.LoadExperiment()
		end

		%----------------------------------------------------
		%		Dialog Resize callbacks
		%----------------------------------------------------
		function OnMonitorDialogResized(~, ~)
			% Retrieve dialog object and axes to resize
			dlg = gcbo;
			ax = dlg.UserData.Ctrl.Ax;
			leftPanel = dlg.UserData.Ctrl.LeftPanel;
			rightPanel = dlg.UserData.Ctrl.RightPanel;
			trialCountText = dlg.UserData.Ctrl.TrialCountText;

			text_eventTrialStart_raster = dlg.UserData.Ctrl.Text_EventTrialStart_Raster;
			popup_eventTrialStart_raster = dlg.UserData.Ctrl.Popup_EventTrialStart_Raster;
			text_eventZero_raster = dlg.UserData.Ctrl.Text_EventZero_Raster;
			popup_eventZero_raster = dlg.UserData.Ctrl.Popup_EventZero_Raster;
			text_eventOfInterest_raster = dlg.UserData.Ctrl.Text_EventOfInterest_Raster;
			popup_eventOfInterest_raster = dlg.UserData.Ctrl.Popup_EventOfInterest_Raster;
			text_figureName_raster = dlg.UserData.Ctrl.Text_FigureName_Raster;
			edit_figureName_raster = dlg.UserData.Ctrl.Edit_FigureName_Raster;
			text_paramsToPlot_raster = dlg.UserData.Ctrl.Text_ParamsToPlot_Raster;
			table_paramsToPlot_raster = dlg.UserData.Ctrl.Table_ParamsToPlot_Raster;
			button_plot_raster = dlg.UserData.Ctrl.Button_Plot_Raster;

			text_eventTrialStart_hist = dlg.UserData.Ctrl.Text_EventTrialStart_Hist;
			popup_eventTrialStart_hist = dlg.UserData.Ctrl.Popup_EventTrialStart_Hist;
			text_eventZero_hist = dlg.UserData.Ctrl.Text_EventZero_Hist;
			popup_eventZero_hist = dlg.UserData.Ctrl.Popup_EventZero_Hist;
			text_eventOfInterest_hist = dlg.UserData.Ctrl.Text_EventOfInterest_Hist;
			popup_eventOfInterest_hist = dlg.UserData.Ctrl.Popup_EventOfInterest_Hist;
			text_figureName_hist = dlg.UserData.Ctrl.Text_FigureName_Hist;
			edit_figureName_hist = dlg.UserData.Ctrl.Edit_FigureName_Hist;
			button_plot_hist = dlg.UserData.Ctrl.Button_Plot_Hist;

			u = dlg.UserData;
			
			% Bar plot axes should have constant height.
			ax.Position = [...
				u.DlgMargin,...
				u.DlgMargin,...
				dlg.Position(3) - 2*u.DlgMargin,...
				u.BarHeight...
			];

			% Left and right panels extends in width and height to fill dialog.
			leftPanel.Position = [...
				u.DlgMargin,...
				u.DlgMargin + u.BarHeight + u.PanelSpacing,...
				max([0, u.LeftPanelWidthRatio*(dlg.Position(3) - 2*u.DlgMargin - u.PanelSpacing)]),...
				max([0, dlg.Position(4) - 2*u.DlgMargin - u.PanelSpacing - u.BarHeight])...
			];				
			rightPanel.Position = [...
				u.DlgMargin + leftPanel.Position(3) + u.PanelSpacing,...
				u.DlgMargin + u.BarHeight + u.PanelSpacing,...
				max([1, (1 - u.LeftPanelWidthRatio)*(dlg.Position(3) - 2*u.DlgMargin - u.PanelSpacing)]),...
				leftPanel.Position(4)...
			];

			% Trial count text should stay on top left of leftPanel
			trialCountText.Position = [...
				u.PanelMargin,...
				leftPanel.Position(4) - u.PanelMargin - 1.2*u.TextHeight,...
				max([0, leftPanel.Position(3) - 2*u.PanelMargin]),...
				u.TextHeight...
			];

			% Raster plot tab
			plotOptionWidth = (rightPanel.Position(3) - 4*u.PanelMargin)/3;
			text_eventTrialStart_raster.Position = [...
				u.PanelMargin,...
				rightPanel.Position(4) - u.PanelMargin - u.PanelMarginTop - text_eventTrialStart_raster.Extent(4),...
				plotOptionWidth,...
				text_eventTrialStart_raster.Extent(4)...
			];

			popup_eventTrialStart_raster.Position = text_eventTrialStart_raster.Position;
			popup_eventTrialStart_raster.Position(2) =...
				text_eventTrialStart_raster.Position(2) - text_eventTrialStart_raster.Position(4);

			text_eventZero_raster.Position = text_eventTrialStart_raster.Position;
			text_eventZero_raster.Position(1) =...
				text_eventTrialStart_raster.Position(1) + text_eventTrialStart_raster.Position(3) + u.PanelMargin;

			popup_eventZero_raster.Position = text_eventZero_raster.Position;
			popup_eventZero_raster.Position(2) =...
				text_eventZero_raster.Position(2) - text_eventZero_raster.Position(4);

			text_eventOfInterest_raster.Position = text_eventZero_raster.Position;
			text_eventOfInterest_raster.Position(1) =...
				text_eventZero_raster.Position(1) + text_eventZero_raster.Position(3) + u.PanelMargin;

			popup_eventOfInterest_raster.Position = text_eventOfInterest_raster.Position;
			popup_eventOfInterest_raster.Position(2) =...
				text_eventOfInterest_raster.Position(2) - text_eventOfInterest_raster.Position(4);

			text_paramsToPlot_raster.Position = popup_eventTrialStart_raster.Position;
			text_paramsToPlot_raster.Position(2:3) = [...
				popup_eventTrialStart_raster.Position(2) - u.PanelSpacing - popup_eventTrialStart_raster.Position(4),...
				2*plotOptionWidth + u.PanelMargin,...
			];

			table_paramsToPlot_raster.Position = text_paramsToPlot_raster.Position;
			table_paramsToPlot_raster.Position = [...
				text_paramsToPlot_raster.Position(1),...
				u.PanelMargin,...
				max([1, text_paramsToPlot_raster.Position(3)]),...
				max([1, text_paramsToPlot_raster.Position(2) - u.PanelMargin])...
			];
			tableWidth = text_paramsToPlot_raster.Position(3) - 16.5;
			table_paramsToPlot_raster.ColumnWidth = num2cell(tableWidth*[0.5, 0.5/3, 0.5/3, 0.5/3]);

			text_figureName_raster.Position = popup_eventOfInterest_raster.Position;
			text_figureName_raster.Position(2) = text_paramsToPlot_raster.Position(2);

			edit_figureName_raster.Position = text_figureName_raster.Position;
			edit_figureName_raster.Position(2) =...
				text_figureName_raster.Position(2) - text_figureName_raster.Position(4);

			button_plot_raster.Position = edit_figureName_raster.Position;
			button_plot_raster.Position([2, 4]) = [...
				table_paramsToPlot_raster.Position(2),...
				2*text_eventZero_raster.Position(4)...
			];

			% Histogram tab
			text_eventTrialStart_hist.Position = text_eventTrialStart_raster.Position;
			popup_eventTrialStart_hist.Position = popup_eventTrialStart_raster.Position;
			text_eventZero_hist.Position = text_eventZero_raster.Position;
			popup_eventZero_hist.Position = popup_eventZero_raster.Position;
			text_eventOfInterest_hist.Position = text_eventOfInterest_raster.Position;
			popup_eventOfInterest_hist.Position = popup_eventOfInterest_raster.Position;
			text_figureName_hist.Position = text_figureName_raster.Position;
			edit_figureName_hist.Position = edit_figureName_raster.Position;
			button_plot_hist.Position = button_plot_raster.Position;
		end

		%----------------------------------------------------
		%		Loose figure closed callback
		%----------------------------------------------------
		% Stop updating figure when we close it
		function OnLooseFigureClosed(src, evnt, lh)
			delete(lh)
			delete(src)
		end

		%----------------------------------------------------
		%		Plot - Stacked Bar
		%----------------------------------------------------
		function bars = StackedBar(ax, data, names, colors)
			% Default params
			if nargin < 4
				colors = {[.2, .8, .2], [1 .2 .2], [.9 .2 .2], [.8 .2 .2], [.7 .2 .2]};
			end

			% Create a stacked horizontal bar plot
			data = reshape(data, 1, []);
			bars = barh(ax, [data; nan(size(data))], 'stack');
			
			% Remove whitespace and axis ticks
			ax.XLim = [0, sum(data)];
			ax.YLim = [1 - 0.5*bars(1).BarWidth, 1 + 0.5*bars(1).BarWidth];
			ax.XTickLabel = [];
			ax.YTickLabel = [];

			% Add labels and set color
			edges = [0, cumsum(data)];
			
			for iData = 1:length(data)
				percentage = round(data(iData)/sum(data) * 100);
				labelLong = sprintf('%s \n%dx\n(%d%%)', names{iData}, data(iData), percentage);
				labelMed = sprintf('''%d''\n%dx', iData, data(iData));
				labelShort = sprintf('''%d''', iData);
				center = (edges(iData) + edges(iData + 1))/2;

				t = text(ax, center, 1, labelLong,...
					'HorizontalAlignment', 'center',...
					'VerticalAlignment', 'middle',...
					'Interpreter', 'none'...
				);
				bars(iData).UserData.tLong = t;

				% Hide parts of the label if it's wider than the bar
				if (t.Extent(3) > data(iData))
					t.Visible = 'off';
					t = text(ax, center, 1, labelMed,...
						'HorizontalAlignment', 'center',...
						'VerticalAlignment', 'middle',...
						'Interpreter', 'none'...
					);
					bars(iData).UserData.tMed = t;
					if (t.Extent(3) > data(iData))
						t.Visible = 'off';
						t = text(ax, center, 1, labelShort,...
							'HorizontalAlignment', 'center',...
							'VerticalAlignment', 'middle',...
							'Interpreter', 'none'...
						);
						bars(iData).UserData.tShort = t;
						if (t.Extent(3) > data(iData))
							t.Visible = 'off';
						end						
					end
				end

				% Show bar text when clicked
				bars(iData).ButtonDownFcn = @MouseBehaviorInterface.OnStackedBarSingleClick;

				% Set bar color
				if iData <= length(colors)
					thisColor = colors{iData};
					bars(iData).FaceColor = thisColor;
				else
					% If color not defined, fade "R" from .7 to .2
					iOverflow = iData - length(colors);
					totalOverflow = length(data) - length(colors);

					decrement = 0.5/totalOverflow;
					r = 0.7 - decrement*iOverflow;
					bars(iData).FaceColor = [r .2 .2];
				end
			end
		end

		function OnStackedBarSingleClick(h, ~)
			% If text from another bar is force shown, hide it first
			t = findobj(gca, 'Tag', 'ForceShown');
			if ~isempty(t)
				t.Tag = '';
				t.Visible = 'off';
				t.BackgroundColor = 'none';
				t.EdgeColor = 'none';
			end

			% Force show text associated with bar clicked, unless it's already shown, in which case clicking again will hide it
			tLong = h.UserData.tLong;
			if strcmp(tLong.Visible, 'off')
				if ~isempty(t)
					if t == tLong
						return
					end
				end
				tLong.Tag = 'ForceShown';
				tLong.Visible = 'on';
				tLong.BackgroundColor = [1 1 .73];
				tLong.EdgeColor = 'k';
				uistack(tLong, 'top') % Bring to top
			end
		end
	end
end