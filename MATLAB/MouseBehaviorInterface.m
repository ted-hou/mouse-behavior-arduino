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
			% Find arduino port
			arduinoPortName = MouseBehaviorInterface.QueryPort();
			
			% Splash
			if ~strcmp(arduinoPortName, '/offline')
				obj.CreateDialog_Splash()
			end
			
			% Establish arduino connection
			obj.Arduino = ArduinoConnection(arduinoPortName, obj);

			% If offline and no file selected quit
			if strcmp(arduinoPortName, '/offline') && isempty(obj.Arduino.ExperimentFileName)
				return
			end

			% Creata Experiment Control window with all the knobs and buttons you need to set up an experiment.
			obj.CreateDialog_ExperimentControl()
			
			% Create Monitor window with all the trial results and plots and stuff so the Grad Student is ON TOP OF THE SITUATION AT ALL TIMES.
			obj.CreateDialog_Monitor()

			% Create Task Scheduler
			obj.CreateDialog_TaskScheduler()

			% Kill splash
			if ~strcmp(arduinoPortName, '/offline')
				obj.CloseDialog_Splash()
			end

			% Establish camera connection
			% if ~strcmp(arduinoPortName, '/offline')
			% 	numCameras = CameraConnection.GetAvailableCameras;
			% 	if numCameras > 0
			% 		obj.Arduino.Camera = CameraConnection(...
			% 			'CameraID', [],...
			% 			'Format', '',...
			% 			'FrameRate', [],...
			% 			'FileFormat', 'MPEG-4',...
			% 			'FrameGrabInterval', 1,...
			% 			'TimestampInterval', 10);
			% 	end
			% end
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
			if isempty(obj.Arduino.SerialConnection)
				port = 'OFFLINE';
			else
				port = obj.Arduino.SerialConnection.Port;
			end
			dlg = dialog(...
				'Name', sprintf('Experiment Control (%s)', port),...
				'WindowStyle', 'normal',...
				'Resize', 'on',...
				'Visible', 'off'... % Hide until all controls created
				);
			% Store the dialog handle
			obj.Rsc.ExperimentControl = dlg;
			
			% Close serial port when you close the window
			dlg.CloseRequestFcn = @obj.ArduinoClose;
			
			% Create a uitable for parameters
			table_params = uitable(...
				'Parent', dlg,...
				'Data', obj.Arduino.ParamValues',...
				'RowName', obj.Arduino.ParamNames,...
				'ColumnName', {'Value'},...
				'ColumnFormat', {'long'},...
				'ColumnEditable', [true],...
				'CellEditCallback', @obj.OnParamChangedViaGUI...
				);
			dlg.UserData.Ctrl.Table_Params = table_params;
			
			% Add listener for parameter change via non-GUI methods, in which case we'll update table_params
			if ~isfield(obj.Arduino.Listeners, 'ParamChanged') || ~isvalid(obj.Arduino.Listeners.ParamChanged)
				obj.Arduino.Listeners.ParamChanged = addlistener(obj.Arduino, 'ParamValues', 'PostSet', @obj.OnParamChanged);
			end

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
				'Callback', @obj.ArduinoStart...
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
				'Callback', @obj.ArduinoStop...
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
				'Callback', @obj.ArduinoReset...
				);
			
			% Resize dialog so it fits all controls
			dlg.Position(1:2) = [10, 50];
			dlg.Position(3) = table_params.Position(3) + buttonWidth + 4*ctrlSpacing;
			dlg.Position(4) = table_params.Position(4) + 3*ctrlSpacing;
			
			% Menus
			menu_file = uimenu(dlg, 'Label', '&File');
			uimenu(menu_file, 'Label', 'Save Experiment ...', 'Callback', @obj.ArduinoSaveExperiment, 'Accelerator', 's');
			uimenu(menu_file, 'Label', 'Save Experiment As ...', 'Callback', @obj.ArduinoSaveAsExperiment);
			uimenu(menu_file, 'Label', 'Load Experiment ...', 'Callback', @obj.ArduinoLoadExperiment, 'Accelerator', 'l');
			uimenu(menu_file, 'Label', 'Save Parameters ...', 'Callback', @obj.ArduinoSaveParameters, 'Separator', 'on');
			uimenu(menu_file, 'Label', 'Load Parameters ...', 'Callback', @obj.ArduinoLoadParameters);
			uimenu(menu_file, 'Label', 'Quit', 'Callback', @obj.ArduinoClose, 'Separator', 'on');
			
			menu_arduino = uimenu(dlg, 'Label', '&Arduino');
			uimenu(menu_arduino, 'Label', 'Start', 'Callback', @obj.ArduinoStart);
			uimenu(menu_arduino, 'Label', 'Stop', 'Callback', @obj.ArduinoStop, 'Accelerator', 'q');
			uimenu(menu_arduino, 'Label', 'Reset', 'Callback', @obj.ArduinoReset, 'Separator', 'on');
			uimenu(menu_arduino, 'Label', 'Reconnect', 'Callback', @obj.ArduinoReconnect);
			
			menu_window = uimenu(dlg, 'Label', '&Window');
			uimenu(menu_window, 'Label', 'Experiment Control', 'Callback', @(~, ~) @obj.CreateDialog_ExperimentControl);
			uimenu(menu_window, 'Label', 'Monitor', 'Callback', @(~, ~) obj.CreateDialog_Monitor);
			uimenu(menu_window, 'Label', 'Camera', 'Callback', @(~, ~) obj.CreateDialog_CameraControl);
			uimenu(menu_window, 'Label', 'Task Scheduler', 'Callback', @(~, ~) obj.CreateDialog_TaskScheduler);
			
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
			if isempty(obj.Arduino.SerialConnection)
				port = 'OFFLINE';
			else
				port = obj.Arduino.SerialConnection.Port;
			end
			dlg = dialog(...
				'Name', sprintf('Monitor (%s)', port),...
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
			
			% Text: Result of last trial
			lastTrialResultText = uicontrol(...
				'Parent', leftPanel,...
				'Style', 'text',...
				'String', 'Last trial: ',...
				'TooltipString', 'Result of previous trial.',...
				'HorizontalAlignment', 'left',...
				'Units', 'pixels',...
				'FontSize', 13 ...
				);
			dlg.UserData.Ctrl.LastTrialResultText = lastTrialResultText;

			% Text: Current state
			currentStateText = uicontrol(...
				'Parent', leftPanel,...
				'Style', 'text',...
				'String', 'Current state: ',...
				'HorizontalAlignment', 'left',...
				'Units', 'pixels',...
				'FontSize', 13 ...
			);
			dlg.UserData.Ctrl.CurrentStateText = currentStateText;
			
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
			
			if isempty(obj.Arduino.SerialConnection)
				figName = 'Raster Plot';
			else
				figName = sprintf('Raster Plot (%s)', obj.Arduino.SerialConnection.Port);
			end
			edit_figureName_raster = uicontrol(...
				'Parent', tab_raster,...
				'Style', 'edit',...
				'String', figName,...
				'HorizontalAlignment', 'left'...
				);
			dlg.UserData.Ctrl.Edit_FigureName_Raster = edit_figureName_raster;
			
			tabgrp_plot_raster = uitabgroup(...
				'Parent', tab_raster,...
				'Units', 'pixels'...
				);
			dlg.UserData.Ctrl.TabGrp_Plot_Raster = tabgrp_plot_raster;
			
			tab_params_raster = uitab(...
				'Parent', tabgrp_plot_raster,...
				'Title', 'Add Parameters',...
				'Units', 'pixels'...
				);
			dlg.UserData.Ctrl.Tab_Params_Raster = tab_params_raster;
			
			tab_events_raster = uitab(...
				'Parent', tabgrp_plot_raster,...
				'Title', 'Add Events',...
				'Units', 'pixels'...
				);
			dlg.UserData.Ctrl.Tab_Events_Raster = tab_events_raster;
			
			paramNames = [obj.Arduino.ParamNames'; repmat({'Enter Custom Value'}, 4, 1)];
			numParams = length(paramNames);
			table_params_raster = uitable(...
				'Parent', tab_params_raster,...
				'Data', [paramNames, repmat({false}, [numParams, 1]), repmat({'black'}, [numParams, 1]), repmat({'-'}, [numParams, 1])],...
				'RowName', {},...
				'ColumnName', {'Parameter', 'Plot', 'Color', 'Style'},...
				'ColumnFormat', {'char', 'logical', {'black', 'red', 'blue', 'green', 'yellow', 'magenta', 'cyan'}, {'-', '--', ':', '-.'}},...
				'ColumnEditable', [true, true, true, true]...
				);
			dlg.UserData.Ctrl.Table_Params_Raster = table_params_raster;
			
			eventNames = obj.Arduino.EventMarkerNames';
			numEvents = length(eventNames);
			table_events_raster = uitable(...
				'Parent', tab_events_raster,...
				'Data', [eventNames, repmat({false}, [numEvents, 1]), repmat({'black'}, [numEvents, 1]), repmat({10}, [numEvents, 1])],...
				'RowName', {},...
				'ColumnName', {'Event', 'Plot', 'Color', 'Size'},...
				'ColumnFormat', {'char', 'logical', {'black', 'red', 'blue', 'green', 'yellow', 'magenta', 'cyan'}, 'numeric'},...
				'ColumnEditable', [false, true, true, true]...
				);
			dlg.UserData.Ctrl.Table_Events_Raster = table_events_raster;
			
			tab_params_raster.SizeChangedFcn = @(~, ~) MouseBehaviorInterface.OnPlotOptionsTabResized(table_params_raster);
			tab_events_raster.SizeChangedFcn = @(~, ~) MouseBehaviorInterface.OnPlotOptionsTabResized(table_events_raster);
			
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
			
			if isempty(obj.Arduino.SerialConnection)
				figName = 'Histogram';
			else
				figName = sprintf('Histogram (%s)', obj.Arduino.SerialConnection.Port);
			end
			edit_figureName_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'edit',...
				'String', figName,...
				'HorizontalAlignment', 'left'...
				);
			dlg.UserData.Ctrl.Edit_FigureName_Hist = edit_figureName_hist;
			text_numBins_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'text',...
				'String', 'Number of Bins',...
				'HorizontalAlignment', 'left'...
				);
			dlg.UserData.Ctrl.Text_NumBins_Hist = text_numBins_hist;
			edit_numBins_hist = uicontrol(...
				'Parent', tab_hist,...
				'Style', 'edit',...
				'String', num2str(10),...
				'HorizontalAlignment', 'left'...
				);
			dlg.UserData.Ctrl.Edit_NumBins_Hist = edit_numBins_hist;
			
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
			if ~isfield(obj.Arduino.Listeners, 'TrialRegistered') || ~isvalid(obj.Arduino.Listeners.TrialRegistered)
				obj.Arduino.Listeners.TrialRegistered = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @obj.OnTrialRegistered);
			end

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
			uimenu(menu_window, 'Label', 'Camera', 'Callback', @(~, ~) obj.CreateDialog_CameraControl);
			uimenu(menu_window, 'Label', 'Task Scheduler', 'Callback', @(~, ~) obj.CreateDialog_TaskScheduler);
			
			% Stretch barchart When dialog window is resized
			dlg.SizeChangedFcn = @MouseBehaviorInterface.OnMonitorDialogResized;
			
			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end

		function CreateDialog_CameraControl(obj)
			% If object already exists, show window
			if isvalid(obj.Arduino.Camera)
				obj.Arduino.Camera.CreateDialog_CameraControl();
			end
		end

		function CreateDialog_Splash(obj)
			% Load image
			[fncpath, ~, ~] = fileparts(which('MouseBehaviorInterface'));
			img = imread([fncpath, '\logo.png']);
			
			% Create java window object
			splashImage = im2java(img);
			win = javax.swing.JWindow;
			obj.Rsc.Splash = win;
			icon = javax.swing.ImageIcon(splashImage);
			label = javax.swing.JLabel(icon);
			win.getContentPane.add(label);
			win.setAlwaysOnTop(true);
			win.pack;
			
			% Set the splash image to the center of the screen
			screenSize = win.getToolkit.getScreenSize;
			screenHeight = screenSize.height;
			screenWidth = screenSize.width;
			% Get the actual splashImage size
			imgHeight = icon.getIconHeight;
			imgWidth = icon.getIconWidth;
			win.setLocation((screenWidth-imgWidth)/2,(screenHeight-imgHeight)/2);
			
			% Show the splash screen
			win.show
			
			% Hide in 10 seconds
			t = timer;
			obj.Rsc.SplashTimer = t;
			t.StartDelay = 10;
			t.TimerFcn = @(~, ~) win.dispose;
			start(t)
		end
		
		function CloseDialog_Splash(obj)
			stop(obj.Rsc.SplashTimer);
			obj.Rsc.Splash.dispose;
		end

		%----------------------------------------------------
		% 		Task scheduler
		%----------------------------------------------------
		function CreateDialog_TaskScheduler(obj)
			% If object already exists, show window
			if isfield(obj.Rsc, 'TaskScheduler')
				if isvalid(obj.Rsc.TaskScheduler)
					figure(obj.Rsc.TaskScheduler)
					return
				end
			end

			if ~isfield(obj.UserData, 'TaskSchedulerEnabled')
				obj.UserData.TaskSchedulerEnabled = false;
			end

			% Size and position of controls
			numButtons = 4;
			ctrlSpacingX = 0.05;
			ctrlSpacingY = 0.025;
			buttonWidth = (1 - (numButtons + 1)*ctrlSpacingX)/numButtons;
			buttonHeight = 0.075;
			tableWidth = 1 - 2*ctrlSpacingX;
			tableHeight = 1 - buttonHeight - 3*ctrlSpacingY;

			% Create the dialog
			if isempty(obj.Arduino.SerialConnection)
				port = 'OFFLINE';
			else
				port = obj.Arduino.SerialConnection.Port;
			end
			dlg = dialog(...
				'Name', sprintf('Task Scheduler (%s)', port),...
				'WindowStyle', 'normal',...
				'Resize', 'on',...
				'Units', 'pixels',...
				'Position', [10 550 430 280],...
				'Visible', 'off'... % Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.TaskScheduler = dlg;

			% Create a uitable for creating tasks
			if isfield(obj.UserData, 'TaskSchedule')
				data = obj.UserData.TaskSchedule;
			else
				data = repmat({'', 'NONE', []}, [12, 1]);
			end
			table_tasks = uitable(...
				'Parent', dlg,...
				'ColumnName', {'Trials', 'Action', 'Value'},...
				'ColumnWidth', {'auto', 200, 'auto'},...
				'ColumnFormat', {'char', ['NONE', obj.Arduino.ParamNames, 'STOP'], 'long'},...
				'Data', data,...
				'ColumnEditable', true,...
				'Units', 'normalized',...
				'Position', [ctrlSpacingX, buttonHeight + 2*ctrlSpacingY, tableWidth, tableHeight] ...
			);
			dlg.UserData.Ctrl.Table_Tasks = table_tasks;

			% Apply button
			button_apply = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Units', 'normalized',...
				'Position', [ctrlSpacingX, ctrlSpacingY, buttonWidth, buttonHeight],...
				'String', 'Apply',...
				'TooltipString', 'Apply these settings.',...
				'Callback', @obj.TaskSchedulerApply ...
			);
			hPrev = button_apply;
			dlg.UserData.Ctrl.Button_Apply = hPrev;

			% Enable/disable button
			if obj.UserData.TaskSchedulerEnabled
				buttonString = 'Disable';
			else
				buttonString = 'Enable';
			end
			button_enable = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Units', 'normalized',...
				'Position', hPrev.Position,...
				'String', buttonString,...
				'TooltipString', 'Enable task scheduling.',...
				'Callback', @obj.TaskSchedulerEnable ...
			);
			hPrev = button_enable;
			dlg.UserData.Ctrl.Button_Enable = hPrev;
			hPrev.Position(1) = hPrev.Position(1) + ctrlSpacingX + buttonWidth;

			% Revert button
			button_revert = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Units', 'normalized',...
				'Position', hPrev.Position,...
				'String', 'Revert',...
				'TooltipString', 'Revert to previous setting.',...
				'Callback', @obj.TaskSchedulerRevert ...
			);
			hPrev = button_revert;
			dlg.UserData.Ctrl.Button_Revert = hPrev;
			hPrev.Position(1) = hPrev.Position(1) + ctrlSpacingX + buttonWidth;

			% Clear button
			button_clear = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Units', 'normalized',...
				'Position', hPrev.Position,...
				'String', 'Clear',...
				'TooltipString', 'Clear all settings.',...
				'Callback', @obj.TaskSchedulerClear ...
			);
			hPrev = button_clear;
			dlg.UserData.Ctrl.Button_Clear = hPrev;
			hPrev.Position(1) = hPrev.Position(1) + ctrlSpacingX + buttonWidth;

			% Menus
			menu_window = uimenu(dlg, 'Label', '&Window');
			uimenu(menu_window, 'Label', 'Experiment Control', 'Callback', @(~, ~) @obj.CreateDialog_ExperimentControl);
			uimenu(menu_window, 'Label', 'Monitor', 'Callback', @(~, ~) obj.CreateDialog_Monitor);
			uimenu(menu_window, 'Label', 'Task Scheduler', 'Callback', @(~, ~) obj.CreateDialog_TaskScheduler);

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end

		function TaskSchedulerApply(obj, ~, ~)		
			obj.UserData.TaskSchedule = obj.Rsc.TaskScheduler.UserData.Ctrl.Table_Tasks.Data;
			if ~isfield(obj.UserData, 'TaskSchedulerEnabled') || ~obj.UserData.TaskSchedulerEnabled
				selection = questdlg(...
					'Enable task scheduler?',...
					'Enable',...
					'Enable','No','No'...
					);
				if strcmp(selection, 'Enable')
					obj.TaskSchedulerEnable(obj.Rsc.TaskScheduler.UserData.Ctrl.Button_Enable, [])
				end
			end				
		end

		function TaskSchedulerEnable(obj, hButton, ~)
			% Default to disabled
			if ~isfield(obj.UserData, 'TaskSchedulerEnabled')
				obj.UserData.TaskSchedulerEnabled = false;
			end

			% Toggle
			obj.UserData.TaskSchedulerEnabled = ~obj.UserData.TaskSchedulerEnabled;

			% Update button
			if obj.UserData.TaskSchedulerEnabled
				hButton.String = 'Disable';
			else
				hButton.String = 'Enable';
			end
		end

		function TaskSchedulerRevert(obj, ~, ~)
			if isfield(obj.UserData, 'TaskSchedule') && ~isempty(obj.UserData.TaskSchedule)
				obj.Rsc.TaskScheduler.UserData.Ctrl.Table_Tasks.Data = obj.UserData.TaskSchedule;
			else
				obj.TaskSchedulerClear();
			end
		end

		function TaskSchedulerClear(obj, ~, ~)
			if isfield(obj.Rsc, 'TaskScheduler')
				obj.Rsc.TaskScheduler.UserData.Ctrl.Table_Tasks.Data = repmat({'', 'NONE', []}, [size(obj.Rsc.TaskScheduler.UserData.Ctrl.Table_Tasks.Data, 1), 1]);
			end
		end

		function TaskSchedulerExecute(obj)
			if ~isfield(obj.UserData, 'TaskSchedulerEnabled') || ~obj.UserData.TaskSchedulerEnabled
				return
			end

			% How many trials have been completed so far
			iTrial = obj.Arduino.TrialsCompleted;

			% Parse the list
			tasks = obj.UserData.TaskSchedule;
			isItTimeYet = cellfun(@(str) obj.TaskSchedulerIsItTimeYet(str, iTrial), tasks(:, 1));

			if ~isempty(find(isItTimeYet))
				for iTask = transpose(find(isItTimeYet))
					task = tasks{iTask, 2};
					if strcmpi(task, 'STOP')
						obj.ArduinoStop();
						break
					end
					if strcmpi(task, 'NONE')
						continue
					end
					oldValue = obj.GetParam(task);
					newValue = tasks{iTask, 3};
					if ~isempty(oldValue) && ~isempty(newValue)
						obj.SetParam(task, newValue)
					end
				end
			end
		end

		function isItTimeYet = TaskSchedulerIsItTimeYet(obj, str, iTrial)
			isItTimeYet = false;
			if isempty(str)
				return
			end

			try
				if contains(str, 'end', 'IgnoreCase', true)
					parts = strsplit(str, ':');
					if ~strcmpi(parts{end}, 'end') || nnz(cellfun(@(x) isempty(x), parts)) > 0
						error('')
					end
					switch length(parts)
						case 2
							isItTimeYet = iTrial >= str2num(parts{1});
						case 3
							isItTimeYet = iTrial >= str2num(parts{1}) && rem(iTrial - str2num(parts{1}), str2num(parts{2})) == 0;
					end
				else
					isItTimeYet = ismember(iTrial, eval(str));
				end
			catch
				warning(['Failed to evaluate task scheduler parameter (', str, ')'])
			end
		end
		
		function OnTrialRegistered(obj, ~, ~)
			% Executed when a new trial is completed
			% Autosave if a savepath is defined
			if (~isempty(obj.Arduino.ExperimentFileName) && obj.Arduino.AutosaveEnabled)
				obj.ArduinoSaveExperiment();
			end

			% Task scheduling
			obj.TaskSchedulerExecute();

			% Updated monitor window
			if isvalid(obj.Rsc.Monitor)
				% Count how many trials have been completed
				iTrial = obj.Arduino.TrialsCompleted;
				
				% Update the "Trials Completed" counter.
				t = obj.Rsc.Monitor.UserData.Ctrl.TrialCountText;
				t.String = sprintf('Trials completed: %d', iTrial);
				
				% Show result of last trial
				if (iTrial > 0)
					t = obj.Rsc.Monitor.UserData.Ctrl.LastTrialResultText;
					t.String = sprintf('Last trial: %s', obj.Arduino.Trials(iTrial).CodeName);
				end

				% Update Stacked Bar Plot (Session summary)
				ax = obj.Rsc.Monitor.UserData.Ctrl.Ax;
				if (iTrial > 0)
					resultCodes = reshape([obj.Arduino.Trials.Code], [], 1);
					resultCodeNames = obj.Arduino.ResultCodeNames;
					allResultCodes = 1:(length(resultCodeNames) + 1);
					resultCodeCounts = histcounts(resultCodes, allResultCodes);

					MouseBehaviorInterface.StackedBar(ax, resultCodeCounts, resultCodeNames);
				else
					cla(ax)
				end
			end
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
			paramPlotOptions 	= ctrl.Table_Params_Raster.Data;
			eventPlotOptions	= ctrl.Table_Events_Raster.Data;
			
			obj.Raster(eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName, paramPlotOptions, eventPlotOptions)
		end
		function Raster(obj, eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName, paramPlotOptions, eventPlotOptions)
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
			ax.UserData.EventPlotOptions 	= eventPlotOptions;
			
			% Plot it for the first time
			obj.Raster_Execute(figId);
			
			% Plot again everytime an event of interest occurs
			if ~isfield(ax.UserData, 'Listener') || ~isvalid(ax.UserData.Listener)
				ax.UserData.Listener = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @(~, ~) obj.Raster_Execute(figId));
			end
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
			eventPlotOptions	= ax.UserData.EventPlotOptions;
			
			% If events did not occur at all, do not plot
			if (isempty(data))
				return
			end
			
			% Plot events
			hold(ax, 'on')
			obj.Raster_Execute_Events(ax, data, eventCodeTrialStart, eventCodeOfInterest, eventCodeZero, eventPlotOptions);
			
			% Plot parameters
			obj.Raster_Execute_Params(ax, paramPlotOptions);
			hold(ax, 'off')
			
			% Annotations
			lgd = legend(ax, 'Location', 'northoutside');
			lgd.Interpreter = 'none';
			lgd.Orientation = 'horizontal';
			
			ax.XLimMode 		= 'auto';
			% ax.XLim 			= [max([-5000, ax.XLim(1) - 100]), ax.XLim(2) + 100]/1000;
			ax.YLim 			= [0, obj.Arduino.TrialsCompleted + 1];
			ax.YDir				= 'reverse';
			ax.XLabel.String 	= 'Time (s)';
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
			ax.UserData.EventPlotOptions 	= eventPlotOptions;
		end
		function Raster_Execute_Events(obj, ax, data, eventCodeTrialStart, eventCodeOfInterest, eventCodeZero, eventPlotOptions)
			% Plot primary event of interest
			obj.Raster_Execute_Single(ax, data, eventCodeTrialStart, eventCodeOfInterest, eventCodeZero, 'cyan', 10)

			% Filter out events the Grad Student does not want to plot
			eventsToPlot = find([eventPlotOptions{:, 2}]);

			if ~isempty(eventsToPlot)
				for iEvent = eventsToPlot
					if iEvent == eventCodeOfInterest
						continue
					end
					obj.Raster_Execute_Single(ax, data, eventCodeTrialStart, iEvent, eventCodeZero, eventPlotOptions{iEvent, 3}, eventPlotOptions{iEvent, 4})
				end
			end
		end
		function Raster_Execute_Single(obj, ax, data, eventCodeTrialStart, eventCodeOfInterest, eventCodeZero, markerColor, markerSize)
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
			if (sum(ism) == 0)
				return
			end
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
			
			if ischar(markerColor)
				switch markerColor
					case 'black'
						markerColor = [.1, .1, .1];
					case 'red'
						markerColor = [.9, .1, .1];
					case 'blue'
						markerColor = [.1, .1, .9];
					case 'green'
						markerColor = [.1, .9, .1];
					case 'cyan'
						markerColor = [0, .5, .5];
				end
			end
			
			plot(ax, eventTimesRelative/1000, trialsOfInterest, '.',...
				'MarkerSize', markerSize,...
				'MarkerEdgeColor', markerColor,...
				'MarkerFaceColor', markerColor,...
				'LineWidth', 1.5,...
				'DisplayName', obj.Arduino.EventMarkerNames{eventCodeOfInterest}...
				)
		end
		function Raster_Execute_Params(obj, ax, paramPlotOptions)
			% Plot parameters
			% Filter out parameters the Grad Student does not want to plot
			paramsToPlot = find([paramPlotOptions{:, 2}]);
			
			if ~isempty(paramsToPlot)
				params = ctranspose(reshape([obj.Arduino.Trials.Parameters], [], size(obj.Arduino.Trials, 2)));
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
					plot(ax, paramValues/1000, 1:length(obj.Arduino.Trials),...
						'DisplayName', num2str(paramPlotOptions{iParam, 1}),...
						'Color', paramPlotOptions{iParam, 3},...
						'LineStyle', paramPlotOptions{iParam, 4},...
						'LineWidth', 1.2 ...
						);
				end
			end
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
			numBins             = str2num(ctrl.Edit_NumBins_Hist.String);
			
			obj.Hist(eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName, numBins)
		end
		function Hist(obj, eventCodeTrialStart, eventCodeZero, eventCodeOfInterest, figName, numBins)
			% First column in data is eventCode, second column is timestamp (since trial start)
			if nargin < 5
				figName = '';
			end
			if nargin < 6
				numBins = 10;
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
			obj.Hist_Execute(figId, numBins);
			
			% Plot again every time an event of interest occurs
			if ~isfield(ax.UserData, 'Listener') || ~isvalid(ax.UserData.Listener)
				ax.UserData.Listener = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @(~, ~) obj.Hist_Execute(figId, numBins));
			end
			f.CloseRequestFcn = {@MouseBehaviorInterface.OnLooseFigureClosed, ax.UserData.Listener};
		end
		function Hist_Execute(obj, figId, numBins)
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
			if (sum(ism) == 0)
				return
			end
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
			histogram(ax, eventTimesOfInterest/1000, numBins, 'DisplayName', obj.Arduino.EventMarkerNames{eventCodeOfInterest})
			lgd = legend(ax, 'Location', 'northoutside');
			lgd.Interpreter 	= 'none';
			lgd.Orientation 	= 'horizontal';
			ax.XLabel.String 	= 'Time (s)';
			ax.YLabel.String 	= 'Occurance';
			title(ax, figName)
			
			% Store plot options cause for some reason it's lost unless we do this.
			ax.UserData.EventCodeTrialStart = eventCodeTrialStart;
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.FigName 			= figName;
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
				ctrl.Table_Params_Raster.Data,...
				ctrl.Table_Events_Raster.Data,...
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
				ctrl.Table_Params_Raster.Data = p.plotSettings{1};
				ctrl.Table_Events_Raster.Data = p.plotSettings{2};
				ctrl.Popup_EventTrialStart_Raster.Value = p.plotSettings{3};
				ctrl.Popup_EventZero_Raster.Value = p.plotSettings{4};
				ctrl.Popup_EventOfInterest_Raster.Value = p.plotSettings{5};
				ctrl.Popup_EventTrialStart_Hist.Value = p.plotSettings{6};
				ctrl.Popup_EventZero_Hist.Value = p.plotSettings{7};
				ctrl.Popup_EventOfInterest_Hist.Value = p.plotSettings{8};
			end
		end
		
		% Arduino connection
		function OnParamChanged(obj, ~, ~)
			obj.Rsc.ExperimentControl.UserData.Ctrl.Table_Params.Data = obj.Arduino.ParamValues';
		end
		
		function OnParamChangedViaGUI(obj, ~, evnt)
			% evnt (event data contains infomation on which elements were changed to what)
			changedParam = evnt.Indices(1);
			newValue = evnt.NewData;
			
			% Add new parameter to update queue
			obj.Arduino.UpdateParams_AddToQueue(changedParam, newValue)
			% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
			obj.Arduino.UpdateParams_Execute()
		end

		function varargout = GetParam(obj, index)
			p = inputParser;
			addRequired(p, 'Index', @(x) isnumeric(x) || ischar(x));
			parse(p, index);
			index = p.Results.Index;

			if ischar(index)
				index = find(strcmpi(index, obj.Arduino.ParamNames));
			end

			if isempty(index)
				varargout = {[]};
			else
				index = index(1);
				varargout = {obj.Arduino.ParamValues(index)};
			end
		end

		function SetParam(obj, index, value, varargin)
			p = inputParser;
			addRequired(p, 'Index', @(x) isnumeric(x) || ischar(x));
			addRequired(p, 'Value', @isnumeric);
			parse(p, index, value);
			index = p.Results.Index;
			value = p.Results.Value;

			if ischar(index)
				index = find(strcmpi(index, obj.Arduino.ParamNames));
			end

			if ~isempty(index)
				index = index(1);
				obj.Arduino.UpdateParams_AddToQueue(index, value);
				obj.Arduino.UpdateParams_Execute();
			end
		end
		
		%----------------------------------------------------
		%		Commmunicating with Arduino
		%----------------------------------------------------
		function ArduinoStart(obj, ~, ~)
			if ((~obj.Arduino.AutosaveEnabled) || isempty(obj.Arduino.ExperimentFileName))
				selection = questdlg(...
					'Autosave is disabled. Start experiment anyway?',...
					'Autosave',...
					'Save', 'Start Anyway', 'Cancel' ,'Save'...
				);
				switch selection
					case 'Save'
						obj.ArduinoSaveAsExperiment()
					case 'Start Anyway'
						warning('Autosave not enabled. Starting experiment anyway.')
					otherwise
						return
				end
			end
			obj.CreateVisualStim()
			obj.Arduino.Start()
		end

		function ArduinoStop(obj, ~, ~)
			obj.Arduino.Stop()
			obj.DeleteVisualStim()
		end

		function ArduinoReset(obj, ~, ~)
			obj.Arduino.Reset()
			delete(obj.Rsc.Monitor)
			delete(obj.Rsc.ExperimentControl)
			obj.CreateDialog_ExperimentControl();
			obj.CreateDialog_Monitor();
		end

		function ArduinoClose(obj, ~, ~)
			selection = questdlg(...
				'Close all windows and terminate connection with Arduino?',...
				'Close Window',...
				'Yes','No','Yes'...
			);
			switch selection
				case 'Yes'
					obj.Arduino.Close()
					delete(obj.Rsc.Monitor)
					delete(obj.Rsc.ExperimentControl)
					if isfield(obj.Rsc, 'TaskScheduler')
						delete(obj.Rsc.TaskScheduler)
					end
					fprintf('Arduino connection closed.\n')
				case 'No'
					return
			end
		end

		function ArduinoReconnect(obj, ~, ~)
			obj.Arduino.Reconnect()
		end

		function ArduinoSaveParameters(obj, ~, ~)
			file = obj.Arduino.SaveParameters();
			if ~isempty(file)
				if isfield(obj.UserData, 'TaskSchedule')
					taskSchedule = obj.UserData.TaskSchedule;
					save(file, 'taskSchedule', '-append')
				end
			end
		end

		function ArduinoLoadParameters(obj, ~, ~)
			file = obj.Arduino.LoadParameters();
			if ~isempty(file)
				p = load(file);
				if isfield(p, 'taskSchedule')
					obj.UserData.TaskSchedule = p.taskSchedule;
					if isfield(obj.Rsc, 'TaskScheduler') && isvalid(obj.Rsc.TaskScheduler)
						obj.Rsc.TaskScheduler.UserData.Ctrl.Table_Tasks.Data = p.taskSchedule;
					end
				end
			end
		end

		function ArduinoSaveExperiment(obj, ~, ~)
			if isempty(obj.Arduino.ExperimentFileName)
				obj.ArduinoSaveAsExperiment()
			else
				obj.Arduino.SaveExperiment()
			end
		end

		function ArduinoSaveAsExperiment(obj, ~, ~)
			obj.Arduino.SaveAsExperiment()
		end

		function ArduinoLoadExperiment(obj, ~, ~)
			obj.Arduino.LoadExperiment()
		end

		%----------------------------------------------------
		%		Visual stimulation for Julia's task
		%----------------------------------------------------
		function CreateVisualStim(obj)
			% make black background
			opengl hardwarebasic % Big performance improvement, might not be necessary on a computer w/ decent GPU

			hFigure = figure();
			hAxes = axes(hFigure);
			hold(hAxes, 'on')

			hFigure.Color = 'k';
			set(hFigure, 'MenuBar', 'none')
			set(hFigure, 'NumberTitle', 'off')
			hFigure.Units = 'Pixels';
			hFigure.Position = [1920, 30, 1920, 1080]; %if you have a different resolution, change

			undecorateFig(hFigure);	% Stuff from interweb, makes the window borderless

			hAxes.Units = 'Normalized';
			hAxes.Position = [0, 0, 1, 1];

			axis equal

			hAxes.Visible = 'off';

			xlim(hAxes, 'manual')
			ylim(hAxes, 'manual')
			xlim(hAxes, [-1.2, 1.2]);
			ylim(hAxes, [-1.2, 1.2]);

			obj.Rsc.VisualStimFigure = hFigure;
			obj.Rsc.VisualStimAxes = hAxes;

			if ~isfield(obj.Rsc, 'OmegaToITITimer')
				obj.Rsc.OmegaToITITimer = timer;
				obj.Rsc.OmegaToITITimer.TimerFcn = {@(~, ~) obj.Arduino.SendMessage('E')};
			end

			if ~isfield(obj.Rsc, 'FlashingScreenTimer')
				obj.Rsc.FlashingScreenTimer = timer;
				obj.Rsc.FlashingScreenTimer.Execution = 'fixedRate';
				obj.Rsc.FlashingScreenTimer.Period = .167;
				obj.Rsc.FlashingScreenTimer.TasksToExecute = 6;
				obj.Rsc.FlashingScreenTimer.TimerFcn = @obj.FlashingScreen;
			end

			% OnStateChanged Callback
			obj.Arduino.Listeners.StateChanged_VisualStim = addlistener(obj.Arduino, 'StateChanged', @obj.OnStateChanged_VisualStim);

			% OnTrialRegistered Callback
			obj.Arduino.Listeners.TrialRegistered_VisualStim = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @obj.OnTrialRegistered_VisualStim);
		end
		
		function DeleteVisualStim(obj, ~, ~)
			timers = {'OmegaToITITimer', 'BarRefreshTimer', 'BarStatTimer', 'DotsRefreshTimer', 'CueRefreshTimer', 'AbortToStimOffTimer', 'FlashingScreenTimer'};
			for iTimer = 1:length(timers)
				if isfield(obj.Rsc, timers{iTimer})
					if isvalid(obj.Rsc.(timers{iTimer}))
						stop(obj.Rsc.(timers{iTimer}));
						delete(obj.Rsc.(timers{iTimer}));
					end
				end			
			end
			if isfield(obj.Rsc, 'VisualStimFigure')
				if isvalid(obj.Rsc.VisualStimFigure)
					delete(obj.Rsc.VisualStimFigure)
				end
			end
			if isfield(obj.Arduino.Listeners, 'StateChanged_VisualStim')
				if isvalid(obj.Arduino.Listeners.StateChanged_VisualStim)
					delete(obj.Arduino.Listeners.StateChanged_VisualStim)
				end
			end
			if isfield(obj.Arduino.Listeners, 'TrialRegistered_VisualStim')
				if isvalid(obj.Arduino.Listeners.TrialRegistered_VisualStim)
					delete(obj.Arduino.Listeners.TrialRegistered_VisualStim)
				end
			end
		end

		function OnStateChanged_VisualStim(obj, ~, ~)
			switch upper(obj.Arduino.StateNames{obj.Arduino.State})
				% Create bar, create dots
				case 'BAR_STAT'
					% Read Arduino parameters
					speed 				= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'BAR_SPEED'));
					spatialFrequency 	= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'SPATIAL_FREQUENCY'));
					windowDuration  	= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'WINDOW_DURATION'))/1000;                

					% Generate list of bar angles for proactive trials
					thetas				= [360:-obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'SPATIAL_FREQUENCY')):0];
					thetas 				= flip(thetas);

					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 0
						if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'CUE_LOCATIONS')) == 0
							endTheta 	= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'END_THETA'));
						elseif obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'CUE_LOCATIONS')) == 1
							endThetas 	= [0:90:270]; % Training Day 1/2/3
							endTheta 	= endThetas(randi(length(endThetas))); % Training Day 6-inf
						elseif obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'CUE_LOCATIONS')) == 2
							endThetas = [0:45:315]; % Training Day 4/5
							endTheta 	= endThetas(randi(length(endThetas))); 
						else
							endTheta = randi(360); % Training Day 6-inf
						end
					else
                    	endTheta = randi(360);
                    end

                    mu = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'MU')); % in seconds
                    sig = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'SIGMA')); % in seconds
                    minTrialLength = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'MIN_TRIAL_LENGTH')); % in seconds

					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'TIMING')) == 1 % is timing trial
						pd = makedist('Normal', 'mu', mu, 'sigma', sig); % Normal distribution
						trunk = truncate(pd, minTrialLength, ((360/spatialFrequency/speed))); % min set by param in sec, max 22.5 for 4/4 freq/speed
						trialLength(i) = random(trunk); % seconds
                    else % is not timing trial
                    	trialLength = exprnd(mu) + minTrialLength; % Exponential decay
                    end

                    turnTheta = trialLength * speed;
                    thetaIndex0 = length(thetas) - round(turnTheta - 1);
                    thetaIndex0 = max(thetaIndex0, 1);
                    if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 0
                   		thetaIndex0 = min(thetaIndex0, (length(thetas) - round(windowDuration * speed)));
                   	end
                    theta0 = thetas(thetaIndex0);

                    theta0 = theta0 + endTheta;
                    thetas = thetas + endTheta;

					% Create objects
					obj.Rsc.Dots    	= obj.MovingDots('Ax', obj.Rsc.VisualStimAxes);
					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'TRIANGLE_CUE')) == 1
						obj.Rsc.Cue 	= obj.TriangleCue(thetas(end), 'Ax', obj.Rsc.VisualStimAxes);
					elseif obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'TRIANGLE_CUE')) == 0
						obj.Rsc.Cue 	= obj.BarCue(thetas(end), 'Ax', obj.Rsc.VisualStimAxes);
					end
					obj.Rsc.Bar     	= obj.RotatingBar(theta0, 'Ax', obj.Rsc.VisualStimAxes);
					obj.Rsc.Bar2     	= obj.StationaryBar(theta0, 'Ax', obj.Rsc.VisualStimAxes);

					% Show or hide dots
					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'DOTS')) == 0
						set(obj.Rsc.Dots, 'Visible', 'off');
					else
						set(obj.Rsc.Dots, 'Visible', 'on');
					end

					% Hide visual cue during reactive trials
					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 0
						set(obj.Rsc.Cue, 'Visible', 'on');
					else
						set(obj.Rsc.Cue, 'Visible', 'off');
					end

					% Hide bar until turning point for training the reactive task
					if (obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 1) && (obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'FADE_BAR')) == 1)
						set(obj.Rsc.Bar, 'Visible', 'off');
					end

					obj.Rsc.UserData.FlashingScreenPresented = false;

					obj.UserData.Theta0								= theta0;
					obj.Rsc.Bar.UserData.Thetas 					= thetas;
					obj.Rsc.Bar.UserData.ThetaIndex					= thetaIndex0;
					obj.Rsc.Bar.UserData.Direction 					= 1;
					obj.Rsc.Bar.UserData.Speed						= speed;
					obj.Rsc.Bar.UserData.IsAlphaReached				= false;
					obj.Rsc.Bar.UserData.IsOmegaReached				= false;
					obj.Rsc.Bar.UserData.IsTurningPointReached		= false;
					obj.Rsc.Bar.UserData.IsBarPaused				= false;
					obj.Rsc.Bar.UserData.IsListOfThetasTruncated	= false;

					obj.Rsc.BarRefreshTimer = timer;
					obj.Rsc.BarRefreshTimer.Execution = 'fixedRate';
					obj.Rsc.BarRefreshTimer.Period = 1/speed;
					obj.Rsc.BarRefreshTimer.TimerFcn = {@obj.OnBarRefresh, obj.Rsc.Bar};

					% Bar flashing during bar_stat only
					obj.Rsc.Bar2.UserData.Thetas 					= thetas;
					obj.Rsc.Bar2.UserData.ThetaIndex				= thetaIndex0;
					obj.Rsc.Bar2.UserData.Speed						= speed;
					obj.Rsc.Bar2.FaceColor 							= [1 1 1];

					obj.Rsc.BarStatTimer = timer;
					obj.Rsc.BarStatTimer. Execution = 'fixedRate';
					obj.Rsc.BarStatTimer.Period = 1/speed;
					obj.Rsc.BarStatTimer.TimerFcn = {@obj.OnBarStatRefresh, obj.Rsc.Bar2};
					start(obj.Rsc.BarStatTimer);

					obj.Rsc.DotsRefreshTimer = timer;
					obj.Rsc.DotsRefreshTimer.Execution = 'fixedRate';
					obj.Rsc.DotsRefreshTimer.Period = round(1000/60)/1000;
					obj.Rsc.DotsRefreshTimer.TimerFcn = {@obj.OnDotsRefresh, obj.Rsc.Dots};
					start(obj.Rsc.DotsRefreshTimer);

					obj.Rsc.CueRefreshTimer = timer;
					obj.Rsc.CueRefreshTimer.Execution = 'fixedRate';
					obj.Rsc.CueRefreshTimer.Period = 1;
					obj.Rsc.CueRefreshTimer.TimerFcn = {@obj.OnCueRefresh, obj.Rsc.Cue};
					start(obj.Rsc.CueRefreshTimer);
                    
				% Bar starts moving
				case 'BAR_MOVE'
					stop(obj.Rsc.BarStatTimer);
					delete(obj.Rsc.BarStatTimer);
					start(obj.Rsc.BarRefreshTimer);
					delete(obj.Rsc.Bar2);

				case 'ABORT_BAR_STAT'
					start(obj.Rsc.BarRefreshTimer);
					objects = {'Bar', 'Bar2', 'Dots', 'Cue'};
					for iObject = 1:length(objects)
						if isfield(obj.Rsc, objects{iObject})
							if isvalid(obj.Rsc.(objects{iObject}))
								set(obj.Rsc.(objects{iObject}), 'Visible', 'off');
							end
						end
					end
					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'EARLY_MOVE_PUNISHMENT')) == 1
						if strcmpi(obj.Rsc.FlashingScreenTimer.Running, 'off') && ~obj.Rsc.UserData.FlashingScreenPresented
							obj.Rsc.FlashingScreenTimer.StartDelay = 0;
							start(obj.Rsc.FlashingScreenTimer);
							obj.Rsc.UserData.FlashingScreenPresented = true;
						end	
					end

				% Early lick: hide visual stim
				case 'ABORT_EARLY'
					objects = {'Bar', 'Bar2', 'Dots', 'Cue'};
					for iObject = 1:length(objects)
						if isfield(obj.Rsc, objects{iObject})
							if isvalid(obj.Rsc.(objects{iObject}))
								set(obj.Rsc.(objects{iObject}), 'Visible', 'off');
							end
						end
					end
					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'EARLY_MOVE_PUNISHMENT')) == 1
						if strcmpi(obj.Rsc.FlashingScreenTimer.Running, 'off') && ~obj.Rsc.UserData.FlashingScreenPresented
							obj.Rsc.FlashingScreenTimer.StartDelay = 0;
							start(obj.Rsc.FlashingScreenTimer);
							obj.Rsc.UserData.FlashingScreenPresented = true;
						end			
					end			

				% Wait some time and tell Arduino to go to ITI
				case 'REWARD'
					omegaToITIDuration = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'OMEGA_TO_ITI_DURATION'))/1000;
					obj.Rsc.OmegaToITITimer.StartDelay = omegaToITIDuration;
					start(obj.Rsc.OmegaToITITimer);
					if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'OPERANT_TURN')) == 1
						obj.Rsc.Bar.UserData.IsListOfThetasTruncated = true;
						obj.Rsc.Bar.UserData.Thetas = obj.Rsc.Bar.UserData.Thetas(1:obj.Rsc.Bar.UserData.ThetaIndex);
					end

				% Punishment, wait some time then go to ITI
				case 'ABORT'
					obj.Rsc.AbortToStimOffTimer = timer;
					obj.Rsc.AbortToStimOffTimer.TimerFcn = {@obj.AbortToStimOff, false};
					obj.Rsc.AbortToStimOffTimer.StartDelay = 0;
					start(obj.Rsc.AbortToStimOffTimer);
					if (isfield(obj.Rsc, 'OmegaToITITimer') && isvalid(obj.Rsc.OmegaToITITimer))
						omegaToITIDuration = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'OMEGA_TO_ITI_DURATION'))/1000;
						obj.Rsc.OmegaToITITimer.StartDelay = omegaToITIDuration;
						start(obj.Rsc.OmegaToITITimer);
					end

				% Punishment, wait some time then go to ITI
				case 'POST_WINDOW'
					obj.Rsc.AbortToStimOffTimer = timer;
					obj.Rsc.AbortToStimOffTimer.TimerFcn = {@obj.AbortToStimOff, true};
					obj.Rsc.AbortToStimOffTimer.StartDelay = 3; % stim continues for 2 sec before flashing screen
					start(obj.Rsc.AbortToStimOffTimer);
					if (isfield(obj.Rsc, 'OmegaToITITimer') && isvalid(obj.Rsc.OmegaToITITimer))
						omegaToITIDuration = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'OMEGA_TO_ITI_DURATION'))/1000;
						obj.Rsc.OmegaToITITimer.StartDelay = omegaToITIDuration;
						start(obj.Rsc.OmegaToITITimer);
					end

				case 'INTERTRIAL'
					obj.Rsc.VisualStimFigure.Color = [0 0 0];
					timers = {'BarRefreshTimer', 'BarStatTimer', 'DotsRefreshTimer', 'CueRefreshTimer'};
					for iTimer = 1:length(timers)
						if isfield(obj.Rsc, timers{iTimer})
							if isvalid(obj.Rsc.(timers{iTimer}))
								stop(obj.Rsc.(timers{iTimer}));
								delete(obj.Rsc.(timers{iTimer}));
							end
						end			
					end
					objects = {'Bar', 'Bar2', 'Dots', 'Cue'};
					for iObject = 1:length(objects)
						if isfield(obj.Rsc, objects{iObject})
							if isvalid(obj.Rsc.(objects{iObject}))
								delete(obj.Rsc.(objects{iObject}));
							end
						end
					end
			end

			% Updated monitor window
			if isvalid(obj.Rsc.Monitor)
				% Show result of last trial
				t = obj.Rsc.Monitor.UserData.Ctrl.CurrentStateText;
				t.String = sprintf('Current state: \n%s', obj.Arduino.StateNames{obj.Arduino.State});
			end
		end

		function OnTrialRegistered_VisualStim(obj, ~, ~)
			% Register theta0 when trial completed
			obj.Arduino.Trials(end).Theta0 = obj.UserData.Theta0;		
		end

		function OnBarRefresh(obj, t, ~, hBar)
			try
				nextThetaIndex = obj.Rsc.Bar.UserData.ThetaIndex + hBar.UserData.Direction;

				% Read parameters from Arduino
				speed 				= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'BAR_SPEED'));
				spatialFrequency 	= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'SPATIAL_FREQUENCY'));
				windowDuration  	= obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'WINDOW_DURATION'))/1000;

				if nextThetaIndex > 0
					% Alpha
					if (~hBar.UserData.IsAlphaReached && nextThetaIndex <= length(obj.Rsc.Bar.UserData.Thetas) && hBar.UserData.Direction > 0 && abs(obj.Rsc.Bar.UserData.Thetas(end) - obj.Rsc.Bar.UserData.Thetas(nextThetaIndex)) < windowDuration*speed*spatialFrequency)
						obj.Arduino.SendMessage('A');
						hBar.UserData.IsAlphaReached = true;
					end
					% Turning point
					if (~hBar.UserData.IsTurningPointReached && hBar.UserData.Direction > 0 && nextThetaIndex > length(obj.Rsc.Bar.UserData.Thetas)) % turn when reach end of list of thetas
						% If we need to stop but haven't yet
						if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'NUM_HOPS')) > 0 && ~obj.Rsc.Bar.UserData.IsBarPaused && ~obj.Rsc.Bar.UserData.IsListOfThetasTruncated
							% Stop the bar for a few hops, but send Turning point later
							if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 0
								obj.Rsc.Bar.UserData.Thetas = [obj.Rsc.Bar.UserData.Thetas, repmat(obj.Rsc.Bar.UserData.Thetas(end), 1, obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'NUM_HOPS')))];
								obj.Rsc.Bar.UserData.IsBarPaused = true;
							% Stop the bar for a few hops, but send Turning point now
							elseif obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 1
								obj.Rsc.Bar.UserData.Thetas = [obj.Rsc.Bar.UserData.Thetas, repmat(obj.Rsc.Bar.UserData.Thetas(end), 1, obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'NUM_HOPS')))];
								obj.Rsc.Bar.UserData.IsBarPaused = true;
								obj.Arduino.SendMessage('T');
								% For training reactive task, make bar visible at turning point
								if (obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'FADE_BAR')) == 1)
									set(obj.Rsc.Bar, 'Visible', 'on');
								end
							end
						% Reached the end of the list for real this time I promise
						else
							hBar.UserData.Direction = -1;
							hBar.UserData.IsTurningPointReached = true;
							% Proactive, keep bar going same direction
							if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'REACTIVE')) == 0
								% Send turning point, this is end of response window
								obj.Arduino.SendMessage('T');

								% Edit previous entries in list of thetas so the bar doesn't reverse direction visually
								if ~strcmpi(obj.Arduino.StateNames{obj.Arduino.State}, 'REWARD')
									obj.Rsc.Bar.UserData.Thetas = obj.Rsc.Bar.UserData.Thetas(end):spatialFrequency:(obj.Rsc.Bar.UserData.Thetas(end) + spatialFrequency*(length(obj.Rsc.Bar.UserData.Thetas) - 1));
									obj.Rsc.Bar.UserData.Thetas = flip(obj.Rsc.Bar.UserData.Thetas);
								end
							% Reactive send turning point
							elseif obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'NUM_HOPS')) == 0
								obj.Arduino.SendMessage('T');
							end
						end
						nextThetaIndex = obj.Rsc.Bar.UserData.ThetaIndex + hBar.UserData.Direction;
					end
					% Omega
					if (~hBar.UserData.IsOmegaReached && nextThetaIndex <= length(obj.Rsc.Bar.UserData.Thetas) && hBar.UserData.Direction < 0 && abs(obj.Rsc.Bar.UserData.Thetas(end) - obj.Rsc.Bar.UserData.Thetas(nextThetaIndex)) > windowDuration*speed*spatialFrequency)
						obj.Arduino.SendMessage('W');
						hBar.UserData.IsOmegaReached = true;
					end
					nextTheta = obj.Rsc.Bar.UserData.Thetas(nextThetaIndex);
				% If OmegaToITI interval is too long and bar in going in reverse, the list of thetas might not be long enough (nextThetaIndex <= 0)
				else
					if (~hBar.UserData.IsOmegaReached)
						obj.Arduino.SendMessage('W');
						hBar.UserData.IsOmegaReached = true;
					end
					nextTheta = obj.Rsc.Bar.UserData.Thetas(1) + mode(diff(obj.Rsc.Bar.UserData.Thetas))*(nextThetaIndex - 1);
				end

				obj.Rsc.Bar.UserData.ThetaIndex = nextThetaIndex;
				obj.RotatingBar(nextTheta, 'Bar', hBar);
			catch ME
				nextThetaIndex
				assignin('base', 'thetas', obj.Rsc.Bar.UserData.Thetas)
				assignin('base', 'ME', ME) 
				warning('Bar refresh error. Aborting current trial.')
				if (~hBar.UserData.IsAlphaReached)
					obj.Arduino.SendMessage('A');
					hBar.UserData.IsAlphaReached = true;
				end
				if (~hBar.UserData.IsTurningPointReached)
					obj.Arduino.SendMessage('T');
					hBar.UserData.IsTurningPointReached = true;
				end
				if (~hBar.UserData.IsOmegaReached)
					obj.Arduino.SendMessage('W');
					hBar.UserData.IsOmegaReached = true;
				end				
			end
		end

		function OnBarStatRefresh(obj, t, ~, hBar)
			% Read parameters from Arduino
			speed = obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'BAR_SPEED'));

			if obj.Rsc.Bar2.FaceColor(1) == 1
				obj.Rsc.Bar2.FaceColor = [0 0 0];
			else
				obj.Rsc.Bar2.FaceColor = [1 1 1];
			end
		end

		function OnDotsRefresh(obj, t, ~, hDots)
			obj.MovingDots('Dots', hDots, 'Time', t.TasksExecuted*t.Period, 'RefreshRate', t.Period);
		end

		function OnCueRefresh(obj, t, ~, hCue)
			% This makes the cue just a solid image instead of flashing
			obj.Rsc.Cue.FaceColor = [1 1 1];

			% if obj.Rsc.Cue.FaceColor(1) == 1
			% 	obj.Rsc.Cue.FaceColor = [0 0 0];
			% else
			% 	obj.Rsc.Cue.FaceColor = [1 1 1];
			% end
		end

		function AbortToStimOff(obj, ~, ~, noMovePun)
			if obj.Arduino.ParamValues(ismember(obj.Arduino.ParamNames, 'NO_MOVE_PUNISHMENT')) == 1 && noMovePun
				objects = {'Bar', 'Bar2', 'Dots', 'Cue'};
				for iObject = 1:length(objects)
					if isfield(obj.Rsc, objects{iObject})
						if isvalid(obj.Rsc.(objects{iObject}))
							set(obj.Rsc.(objects{iObject}), 'Visible', 'off');
						end
					end
				end				
				if strcmpi(obj.Rsc.FlashingScreenTimer.Running, 'off') && ~obj.Rsc.UserData.FlashingScreenPresented
					start(obj.Rsc.FlashingScreenTimer);
				end
			end
		end

		function FlashingScreen(obj, ~, ~)
			if mod(obj.Rsc.FlashingScreenTimer.TasksExecuted, 2) == 1
				obj.Rsc.VisualStimFigure.Color = [0.7 0.7 0.7];
			else
				obj.Rsc.VisualStimFigure.Color = [0 0 0];	
			end
		end
	end
	
	%----------------------------------------------------
	%		Static methods
	%----------------------------------------------------
	methods (Static)
		function arduinoPortName = QueryPort()
			
			serialInfo = instrhwinfo('serial');
			
			if isempty(serialInfo.AvailableSerialPorts)
				serialPorts = {'Nothing connected'};
			else
				serialPorts = serialInfo.AvailableSerialPorts;
			end
			
			[selection, online] = listdlg(...
				'ListString', serialPorts,...
				'SelectionMode', 'single',...
				'ListSize', [100, 75],...
				'PromptString', 'Select COM port',...
				'CancelString', 'Offline'...
				);
			
			if isempty(serialInfo.AvailableSerialPorts)
				arduinoPortName = '/offline';
				return
			end
			
			if online
				arduinoPortName = serialInfo.AvailableSerialPorts{selection};
			else
				arduinoPortName = '/offline';
			end
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
			lastTrialResultText = dlg.UserData.Ctrl.LastTrialResultText;
			currentStateText = dlg.UserData.Ctrl.CurrentStateText;
			
			text_eventTrialStart_raster = dlg.UserData.Ctrl.Text_EventTrialStart_Raster;
			popup_eventTrialStart_raster = dlg.UserData.Ctrl.Popup_EventTrialStart_Raster;
			text_eventZero_raster = dlg.UserData.Ctrl.Text_EventZero_Raster;
			popup_eventZero_raster = dlg.UserData.Ctrl.Popup_EventZero_Raster;
			text_eventOfInterest_raster = dlg.UserData.Ctrl.Text_EventOfInterest_Raster;
			popup_eventOfInterest_raster = dlg.UserData.Ctrl.Popup_EventOfInterest_Raster;
			text_figureName_raster = dlg.UserData.Ctrl.Text_FigureName_Raster;
			edit_figureName_raster = dlg.UserData.Ctrl.Edit_FigureName_Raster;
			tabgrp_plot_raster = dlg.UserData.Ctrl.TabGrp_Plot_Raster;
			button_plot_raster = dlg.UserData.Ctrl.Button_Plot_Raster;
			
			text_eventTrialStart_hist = dlg.UserData.Ctrl.Text_EventTrialStart_Hist;
			popup_eventTrialStart_hist = dlg.UserData.Ctrl.Popup_EventTrialStart_Hist;
			text_eventZero_hist = dlg.UserData.Ctrl.Text_EventZero_Hist;
			popup_eventZero_hist = dlg.UserData.Ctrl.Popup_EventZero_Hist;
			text_eventOfInterest_hist = dlg.UserData.Ctrl.Text_EventOfInterest_Hist;
			popup_eventOfInterest_hist = dlg.UserData.Ctrl.Popup_EventOfInterest_Hist;
			text_figureName_hist = dlg.UserData.Ctrl.Text_FigureName_Hist;
			text_numBins_hist = dlg.UserData.Ctrl.Text_NumBins_Hist;
			edit_numBins_hist = dlg.UserData.Ctrl.Edit_NumBins_Hist;
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
			
			lastTrialResultText.Position = trialCountText.Position;
			lastTrialResultText.Position(2) = trialCountText.Position(2) - 2.4*u.TextHeight;
			lastTrialResultText.Position(4) = 2.4*trialCountText.Position(4);
			
			currentStateText.Position = lastTrialResultText.Position;
			currentStateText.Position(2) = lastTrialResultText.Position(2) - u.TextHeight;
			currentStateText.Position(4) = lastTrialResultText.Position(4);

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
			
			tabgrp_plot_raster.Position = popup_eventTrialStart_raster.Position;
			tabgrp_plot_raster.Position(2:4) = [...
				u.PanelMargin,...
				max([1, 2*plotOptionWidth + u.PanelMargin]),...
				max([1, popup_eventTrialStart_raster.Position(2) - 2*u.PanelMargin]),...
				];
			
			text_figureName_raster.Position = popup_eventOfInterest_raster.Position;
			text_figureName_raster.Position(2) = popup_eventOfInterest_raster.Position(2) - u.PanelMargin - text_figureName_raster.Position(4);
			
			edit_figureName_raster.Position = text_figureName_raster.Position;
			edit_figureName_raster.Position(2) =...
				text_figureName_raster.Position(2) - text_figureName_raster.Position(4);
			
			button_plot_raster.Position = edit_figureName_raster.Position;
			button_plot_raster.Position([2, 4]) = [...
				tabgrp_plot_raster.Position(2),...
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
			text_numBins_hist.Position = text_figureName_hist.Position;
			text_numBins_hist.Position(1) = text_figureName_hist.Position(1) - text_figureName_hist.Position(3) - u.PanelMargin;
			edit_numBins_hist.Position = edit_figureName_raster.Position;
			edit_numBins_hist.Position(1) = edit_figureName_raster.Position(1) - edit_figureName_raster.Position(3) - u.PanelMargin;
			button_plot_hist.Position = button_plot_raster.Position;
		end
		
		function OnPlotOptionsTabResized(table)
			tab = gcbo;
			table.Position = tab.Position;
			table.ColumnWidth = num2cell((table.Position(3) - 17)*[0.5, 0.5/3, 0.5/3, 0.5/3]);
		end
		
		%----------------------------------------------------
		%		Loose figure closed callback
		%----------------------------------------------------
		% Stop updating figure when we close it
		function OnLooseFigureClosed(src, ~, lh)
			delete(lh)
			delete(src)
		end
		
		%----------------------------------------------------
		%		Plot - Stacked Bar
		%----------------------------------------------------
		function bars = StackedBar(ax, data, names, colors)
			% Default params
			if nargin < 4
				colors = {[.2, .8, .2], [0 .75 0], [0 .7 0], [0 .65 0], [0.5 0.5 0.5], [1 .2 .2], [.9 .2 .2], [.8 .2 .2]};
				%colors = {[.2, .8, .2], [1 .2 .2], [.9 .2 .2], [.8 .2 .2], [.7 .2 .2]};
			end
			
			% Create a stacked horizontal bar plot
			data = reshape(data, 1, []);
			bars = barh(ax, [data; nan(size(data))], 'stack');
			
			% Remove whitespace and axis ticks
			ax.XLim = [0, sum(data)];
			ax.YLim = [1 - 0.5*bars(1).BarWidth, 1 + 0.5*bars(1).BarWidth];
			ax.XTickLabel = [];
			ax.YTickLabel = [];
			ax.XTick = [];
			ax.YTick = [];
			
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

		function varargout = RotatingBar(theta, varargin)
			p = inputParser;
			addRequired(p, 'Theta', @isnumeric);
			addParameter(p, 'Ax', []);
			addParameter(p, 'Bar', []);
			addParameter(p, 'Width', 1, @isnumeric);
			addParameter(p, 'Height', 0.03, @isnumeric);
			parse(p, theta, varargin{:});
			theta 	= p.Results.Theta;
			hAxes	= p.Results.Ax;
			hBar 	= p.Results.Bar;
			w 		= p.Results.Width;
			h 		= p.Results.Height;
			
			theta = theta/180*pi;
			
			X = [0 + h*sin(theta), cos(theta) + h*sin(theta), cos(theta) - h*sin(theta), 0 - h*sin(theta), 0 + h*sin(theta)];
			Y = [0 - h*cos(theta), sin(theta) - h*cos(theta), sin(theta) + h*cos(theta), 0 + h*cos(theta), 0 - h*cos(theta)];
			
			if isempty(hBar)
				hBar = fill(hAxes, X, Y, 'w');
			else
				hBar.Vertices = [X', Y'];
			end
			
			varargout = {hBar};
		end
		
		function varargout = MovingDots(varargin)
			p = inputParser;
			addParameter(p, 'Ax', []);
			addParameter(p, 'Dots', []);
			addParameter(p, 'NumDots', 100, @isnumeric);
			addParameter(p, 'Radius', 1, @isnumeric);
			addParameter(p, 'DotSize', 12, @isnumeric);
			addParameter(p, 'DotAlpha', 0.5, @isnumeric);
			addParameter(p, 'AverageLifeTime', 10, @isnumeric);
			addParameter(p, 'Time', 0, @isnumeric);
			addParameter(p, 'RefreshRate', 1/60, @isnumeric);
			parse(p, varargin{:});
			hDots			= p.Results.Dots;
			hAxes			= p.Results.Ax;
			numDots			= p.Results.NumDots;
			radius 			= p.Results.Radius;
			dotSize			= p.Results.DotSize;
			dotAlpha		= p.Results.DotAlpha;
			averageLifeTime = p.Results.AverageLifeTime;
			time			= p.Results.Time;
			refreshRate		= p.Results.RefreshRate;
			
			if isempty(hDots)
				randRadius = rand(1, numDots) + rand(1, numDots);
				randRadius(randRadius > 1) = 2 - randRadius(randRadius > 1);
				randRadius = radius*randRadius;
				randTheta = 2*pi*rand(1, numDots);
				hDots = plot(hAxes, randRadius.*cos(randTheta), randRadius.*sin(randTheta), 'wo', 'MarkerFaceColor', dotAlpha*[1, 1, 1], 'MarkerEdgeColor', dotAlpha*[1, 1, 1], 'MarkerSize', dotSize);
				hDots.UserData.Speed 	= randn(1, numDots)*0.1;
				hDots.UserData.Dir 		= rand(1, numDots)*pi;
				hDots.UserData.DOB 		= zeros(1, numDots);
				hDots.UserData.Life 	= max(averageLifeTime*0.1, min(exprnd(averageLifeTime, [1, numDots]), averageLifeTime*10)); % in seconds
			else
				xData = hDots.XData + refreshRate*hDots.UserData.Speed.*cos(hDots.UserData.Dir);
				yData = hDots.YData + refreshRate*hDots.UserData.Speed.*sin(hDots.UserData.Dir);
				
				undead = hDots.UserData.DOB + hDots.UserData.Life < time | sqrt(xData.^2 + yData.^2) >= radius;
				hDots.XData(~undead) 			= xData(~undead);
				hDots.YData(~undead) 			= yData(~undead);
				randRadius = rand(1, nnz(undead)) + rand(1, nnz(undead));
				randRadius(randRadius > 1) = 2 - randRadius(randRadius > 1);
				randRadius = radius*randRadius;
				randTheta = 2*pi*rand(1, nnz(undead));
				hDots.XData(undead) 			= randRadius.*cos(randTheta);
				hDots.YData(undead) 			= randRadius.*sin(randTheta);
				hDots.UserData.Speed(undead) 	= randn(1, nnz(undead))*0.1;
				hDots.UserData.Dir(undead) 		= rand(1, nnz(undead))*pi;
				hDots.UserData.DOB(undead) 		= time;
				hDots.UserData.Life(undead) 	= max(averageLifeTime*0.1, min(exprnd(averageLifeTime, [1, nnz(undead)]), averageLifeTime*10)); % in seconds
			end

			varargout = {hDots};
		end

		function varargout = TriangleCue(theta, varargin)
			p = inputParser;
			addParameter(p, 'Ax', []);
			addParameter(p, 'Cue', []);
			parse(p, varargin{:});
			hCue 	= p.Results.Cue;
			hAxes 	= p.Results.Ax;

			theta = theta/180*pi; % theta in radians
			l = .2; % length of side of triangle cue
			alphie = pi/6; % alpha (half angle of vertex) 

			xs = [cos(theta), (cos(theta) + (l * cos(theta - alphie))), cos(theta) + (l * cos(theta + alphie))];
			ys = [sin(theta), (sin(theta) + (l * sin(theta - alphie))), sin(theta) + (l * sin(theta + alphie))];

			if isempty(hCue)
				hCue = patch(hAxes, xs, ys, 'w');
			end 

			varargout = {hCue};
		end

		function varargout = BarCue(theta, varargin)
			p = inputParser;
			addParameter(p, 'Ax', []);
			addParameter(p, 'Cue', []);
			addParameter(p, 'Width', 1, @isnumeric);
			addParameter(p, 'Height', 0.03, @isnumeric);
			parse(p, varargin{:});
			hCue 	= p.Results.Cue;
			hAxes 	= p.Results.Ax;
			w 		= p.Results.Width;
			h 		= p.Results.Height;

			theta = theta/180*pi; % theta in radians


			X = [0 + h*sin(theta), cos(theta) + h*sin(theta), cos(theta) - h*sin(theta), 0 - h*sin(theta), 0 + h*sin(theta)];
			Y = [0 - h*cos(theta), sin(theta) - h*cos(theta), sin(theta) + h*cos(theta), 0 + h*cos(theta), 0 - h*cos(theta)];

			if isempty(hCue)
				hCue = fill(hAxes, X, Y, 'w');
			else
				hCue.Vertices = [X', Y'];
			end

			varargout = {hCue};
		end

		function varargout = StationaryBar(theta, varargin)
			p = inputParser;
			addRequired(p, 'Theta', @isnumeric);
			addParameter(p, 'Ax', []);
			addParameter(p, 'Bar', []);
			addParameter(p, 'Width', 1, @isnumeric);
			addParameter(p, 'Height', 0.03, @isnumeric);
			parse(p, theta, varargin{:});
			hAxes		= p.Results.Ax;
			hBar 		= p.Results.Bar;
			w 			= p.Results.Width;
			h 			= p.Results.Height;
			
			theta = theta/180*pi;
			
			X = [0 + h*sin(theta), cos(theta) + h*sin(theta), cos(theta) - h*sin(theta), 0 - h*sin(theta), 0 + h*sin(theta)];
			Y = [0 - h*cos(theta), sin(theta) - h*cos(theta), sin(theta) + h*cos(theta), 0 + h*cos(theta), 0 - h*cos(theta)];
			

			if isempty(hBar)
				hBar = fill(hAxes, X, Y, 'w');
			else
				hBar.Vertices = [X', Y'];
			end
			
			varargout = {hBar};
		end
	end
end