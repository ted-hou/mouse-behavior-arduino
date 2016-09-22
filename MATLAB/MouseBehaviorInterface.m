%% MouseBehaviorInterface: construct graphical user interface to interact with arduino
classdef MouseBehaviorInterface < handle
	properties
		Arduino
		Rsc
		
	end

	%----------------------------------------------------
	% Methods
	%----------------------------------------------------
	methods
		function obj = MouseBehaviorInterface()
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%		Select Microprocessor in Use
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			selection = questdlg(...
				'Choose the device you are running.',...
				'Choose device',...
				'Arduino','Teensy','Arduino'...
			);
			switch selection
				case 'Arduino'
					port = [];
				case 'Teensy'
					port = inputdlg('Specify COM port:', 'USB Port', 1, {'COM1'});
					port = port{1};
			end

			% Establish arduino connection
			obj.Arduino = ArduinoConnection(port);
		
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%		Initialize FileName and Directory
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			obj.Arduino.InitializeFileName();

			% Creata Experiment Control window with all the knobs and buttons you need to set up an experiment. 
			obj.CreateDialog_ExperimentControl()

			% Create Monitor window with all thr trial results and plots and stuff so the Grad Student is ON TOP OF THE SITUATION AT ALL TIMES.
			obj.CreateDialog_Monitor()


		end














		function CreateDialog_ExperimentControl(obj)
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
				'CellEditCallback', {@MouseBehaviorInterface.OnParamChanged, obj.Arduino}...
			);

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

			% Terminate button - terminate connection w/ arduino and close GUI
			ctrlPosBase = button_reset.Position;
			ctrlPos = [...
				ctrlPosBase(1),...
				ctrlPosBase(2) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_close = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Close',...
				'TooltipString', 'Terminate serial connection with Arduino and close the GUI.',...
				'Callback', {@MouseBehaviorInterface.ArduinoClose, obj.Arduino}...
			);

			% Resize dialog so it fits all controls
			dlg.Position(1:2) = [10, 50];
			dlg.Position(3) = table_params.Position(3) + buttonWidth + 4*ctrlSpacing;
			dlg.Position(4) = table_params.Position(4) + 3*ctrlSpacing;

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end

		function CreateDialog_Monitor(obj)
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
			dlg.UserData.BarHeight = 75;
			dlg.UserData.TextHeight = 30;

			u = dlg.UserData;

			% % Close serial port when you close the window
			% dlg.CloseRequestFcn = {@MouseBehaviorInterface.ArduinoClose, obj.Arduino};

			%----------------------------------------------------
			% Left panel
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
			% Right panel
			%----------------------------------------------------
			rightPanel = uipanel(...
				'Parent', dlg,...
				'Title', 'Plot Options',...
				'Units', 'pixels'...
			);
			dlg.UserData.Ctrl.RightPanel = rightPanel;

			text_eventZero = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Reference Event',...
				'HorizontalAlignment', 'left'...				
			);
			dlg.UserData.Ctrl.Text_EventZero = text_eventZero;

			popup_eventZero = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventZero = popup_eventZero;

			text_eventOfInterest = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Event Of Interest',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_EventOfInterest = text_eventOfInterest;

			popup_eventOfInterest = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventOfInterest = popup_eventOfInterest;

			text_figureName = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Figure Name',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_FigureName = text_figureName;

			edit_figureName = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'edit',...
				'String', 'Raster Plot',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Edit_FigureName = edit_figureName;

			text_paramsToPlot = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Show parameters in plot:',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_ParamsToPlot = text_paramsToPlot;

			numParams = length(obj.Arduino.ParamNames);
			table_paramsToPlot = uitable(...
				'Parent', rightPanel,...
				'Data', [obj.Arduino.ParamNames', repmat({false}, [numParams, 1]), repmat({'black'}, [numParams, 1]), repmat({'-'}, [numParams, 1])],...
				'RowName', {},...
				'ColumnName', {'Parameter', 'Plot', 'Color', 'Style'},...
				'ColumnFormat', {'char', 'logical', {'black', 'red', 'blue', 'green'}, {'-', '--', ':', '-.'}},...
				'ColumnEditable', [false, true, true, true]...
			);
			dlg.UserData.Ctrl.Table_ParamsToPlot = table_paramsToPlot;

			button_plot = uicontrol(...
				'Parent', rightPanel,...
				'Style', 'pushbutton',...
				'String', 'Plot',...
				'Callback', @obj.Raster_GUI...
			);
			dlg.UserData.Ctrl.Button_Plot = button_plot;

			%----------------------------------------------------
			% Stacked bar chart for trial results
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

			% Stretch barchart When dialog window is resized
			dlg.SizeChangedFcn = @MouseBehaviorInterface.OnMonitorDialogResized; 

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end


		function OnTrialRegistered(obj, ~, ~)
		% Executed when a new trial is completed
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
			drawnow

			obj.Arduino.SaveExperiment();	% (overwrites existing file)	
		end

		%----------------------------------------------------
		% Plot - Raster plot events for each trial
		%----------------------------------------------------
		function Raster_GUI(obj, ~, ~)
			dlg = obj.Rsc.Monitor;
			popup_eventZero = dlg.UserData.Ctrl.Popup_EventZero;
			popup_eventOfInterest = dlg.UserData.Ctrl.Popup_EventOfInterest;
			edit_figureName = dlg.UserData.Ctrl.Edit_FigureName;
			table_paramsToPlot = dlg.UserData.Ctrl.Table_ParamsToPlot;
			paramPlotOptions = table_paramsToPlot.Data;

			obj.Raster(popup_eventZero.Value, popup_eventOfInterest.Value, edit_figureName.String, paramPlotOptions)
		end
		function Raster(obj, eventCodeZero, eventCodeOfInterest, figName, paramPlotOptions, nBins)
			% First column in data is eventCode, second column is timestamp (since trial start)
			if nargin < 4
				figName = '';
			end
			if nargin < 5
				paramPlotOptions = struct([]);
			end
			if nargin < 6
				nBins = 10;
			end

			% Create axes object
			f = figure('Name', figName, 'NumberTitle', 'off');
			ax = gca;

			% Store plot settings into axes object
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.NBins 				= nBins;
			ax.UserData.FigName				= figName;
			ax.UserData.ParamPlotOptions 	= paramPlotOptions;

			% Store the axes object
			if ~isfield(obj.Rsc, 'LooseFigures')
				figId = 1;
			else
				figId = length(obj.Rsc.LooseFigures) + 1;
			end
			obj.Rsc.LooseFigures(figId).Ax = ax;

			% Plot it for the first time
			obj.Raster_Execute([], [], figId);

			% Plot again everytime an event of interest occurs
			ax.UserData.Listener = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @(src, evnt) obj.Raster_Execute(src, evnt, figId));
			f.CloseRequestFcn = {@MouseBehaviorInterface.OnLooseFigureClosed, ax.UserData.Listener};
		end
		function Raster_Execute(obj, ~, ~, figId)
			data 				= obj.Arduino.EventMarkers;
			ax 					= obj.Rsc.LooseFigures(figId).Ax;

			eventCodeOfInterest = ax.UserData.EventCodeOfInterest;
			eventCodeZero 		= ax.UserData.EventCodeZero;
			nBins 				= ax.UserData.NBins;
			figName 			= ax.UserData.FigName;
			paramPlotOptions	= ax.UserData.ParamPlotOptions;

			% If events did not occur at all, do not plot
			if (isempty(data))
				return
			end

			% Separate eventsOfInterest into trials, divided by eventsZero
			eventsZero 			= find(data(:, 1) == eventCodeZero);
			eventsOfInterest 	= find(data(:, 1) == eventCodeOfInterest);

			% If events did not occur at all, do not plot
			if (isempty(eventsZero) || isempty(eventsOfInterest))
				return
			end

			if eventsOfInterest(end) > eventsZero(end)
				edges = [eventsZero; eventsOfInterest(end)];
			else
				edges = eventsZero;
			end
			% Get timestamps for events of interests
			[~, ~, trials] = histcounts(eventsOfInterest, edges); % bins tells us which trials events belong to

			eventTimesOfInterest 	= data(eventsOfInterest, 2);

			% Get timestamps for zero events
			eventTimesZero 			= data(eventsZero(trials), 2);
			
			% Substract two sets of timestamps to get relative times 
			eventTimesOfInterest 	= eventTimesOfInterest - eventTimesZero;

			% Plot histogram of selected event times
			plot(ax, eventTimesOfInterest, trials, '.k',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', [0 .5 .5],...
				'MarkerFaceColor', [0 .7 .7],...
				'LineWidth', 1.5,...
				'DisplayName', obj.Arduino.EventMarkerNames{eventCodeOfInterest}...
			)

			% Plot parameters
			% Filter out parameters the Grad Student does not want to plot
			paramsToPlot = find([paramPlotOptions{:,2}]);

			if ~isempty(paramsToPlot)
				params = ctranspose(reshape([obj.Arduino.Trials.Parameters], [], length(obj.Arduino.Trials)));			
				hold(ax, 'on')
				for iParam = paramsToPlot
					paramValues = params(:, iParam);
					plot(ax, paramValues, 1:length(obj.Arduino.Trials),...
						'DisplayName', paramPlotOptions{iParam, 1},...
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

			ax.XLim 			= [min(eventTimesOfInterest) - 100, max(eventTimesOfInterest) + 100];
			ax.YLim 			= [max([0, min(trials) - 1]), obj.Arduino.TrialsCompleted + 1];
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
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.NBins 				= nBins;
			ax.UserData.FigName 			= figName;
			ax.UserData.ParamPlotOptions 	= paramPlotOptions;
		end
	end

	%----------------------------------------------------
	% Staic methods
	%----------------------------------------------------
	methods (Static)
		%----------------------------------------------------
		% Commmunicating with Arduino
		%----------------------------------------------------
		function OnParamChanged(~, evnt, arduino)
			% evnt (event data contains infomation on which elements were changed to what)
			changedParam = evnt.Indices(1);
			newValue = evnt.NewData;
			
			% Add new parameter to update queue
			arduino.UpdateParams_AddToQueue(changedParam, newValue)
			% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
			arduino.UpdateParams_Execute()
		end
		function ArduinoStart(~, ~, arduino)
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

		%----------------------------------------------------
		% Dialog Resize callbacks
		%----------------------------------------------------	
		function OnMonitorDialogResized(~, ~)
			% Retrieve dialog object and axes to resize
			dlg = gcbo;
			ax = dlg.UserData.Ctrl.Ax;
			leftPanel = dlg.UserData.Ctrl.LeftPanel;
			rightPanel = dlg.UserData.Ctrl.RightPanel;
			trialCountText = dlg.UserData.Ctrl.TrialCountText;
			text_eventZero = dlg.UserData.Ctrl.Text_EventZero;
			popup_eventZero = dlg.UserData.Ctrl.Popup_EventZero;
			text_eventOfInterest = dlg.UserData.Ctrl.Text_EventOfInterest;
			popup_eventOfInterest = dlg.UserData.Ctrl.Popup_EventOfInterest;
			text_figureName = dlg.UserData.Ctrl.Text_FigureName;
			edit_figureName = dlg.UserData.Ctrl.Edit_FigureName;
			text_paramsToPlot = dlg.UserData.Ctrl.Text_ParamsToPlot;
			table_paramsToPlot = dlg.UserData.Ctrl.Table_ParamsToPlot;
			button_plot = dlg.UserData.Ctrl.Button_Plot;

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

			% Raster plot options
			plotOptionWidth = (rightPanel.Position(3) - 4*u.PanelMargin)/3;
			text_eventZero.Position = [...
				u.PanelMargin,...
				rightPanel.Position(4) - u.PanelMargin - text_eventZero.Extent(4),...
				plotOptionWidth,...
				text_eventZero.Extent(4)...
			];

			popup_eventZero.Position = [...
				text_eventZero.Position(1),...
				text_eventZero.Position(2) - text_eventZero.Position(4),...
				plotOptionWidth,...
				text_eventZero.Position(4)...
			];

			text_eventOfInterest.Position = [...
				text_eventZero.Position(1) + text_eventZero.Position(3) + u.PanelMargin,...
				text_eventZero.Position(2),...
				plotOptionWidth,...
				text_eventZero.Position(4)...
			];

			popup_eventOfInterest.Position = [...
				text_eventOfInterest.Position(1),...
				text_eventOfInterest.Position(2) - text_eventZero.Position(4),...
				plotOptionWidth,...
				text_eventZero.Position(4)...
			];

			text_figureName.Position = [...
				text_eventOfInterest.Position(1) + text_eventOfInterest.Position(3) + u.PanelMargin,...
				text_eventZero.Position(2),...
				plotOptionWidth,...
				text_eventZero.Position(4)...
			];

			edit_figureName.Position = [...
				text_figureName.Position(1),...
				text_figureName.Position(2) - text_eventZero.Position(4),...
				plotOptionWidth,...
				text_eventZero.Position(4)...
			];

			text_paramsToPlot.Position = [...
				popup_eventZero.Position(1),...
				popup_eventZero.Position(2) - u.PanelSpacing - text_eventZero.Position(4),...
				2*plotOptionWidth + u.PanelMargin,...
				text_eventZero.Position(4)...
			];

			table_paramsToPlot.Position = [...
				popup_eventZero.Position(1),...
				u.PanelMargin,...
				text_paramsToPlot.Position(3),...
				text_paramsToPlot.Position(2) - u.PanelMargin...
			];
			tableWidth = text_paramsToPlot.Position(3) - 16.5;
			table_paramsToPlot.ColumnWidth = num2cell(tableWidth*[0.5, 0.5/3, 0.5/3, 0.5/3]);

			button_plot.Position = [...
				edit_figureName.Position(1),...
				table_paramsToPlot.Position(2) + 0.5*table_paramsToPlot.Position(4) - 0.5*text_eventZero.Position(4),...
				plotOptionWidth,...
				2*text_eventZero.Position(4)...
			];
		end

		%----------------------------------------------------
		% Loose figure closed callback
		%----------------------------------------------------
		% Stop updating figure when we close it
		function OnLooseFigureClosed(src, evnt, lh)
			delete(lh)
			delete(src)
		end

		%----------------------------------------------------
		% Plot - Stacked Bar
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