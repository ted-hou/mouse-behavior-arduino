%% MouseBehaviorInterface: construct graphical user interface to interact with arduino
classdef MouseBehaviorInterface < handle	% MBI is subclass to handle, thus will have behaviors of plot/GUI objects
	properties
		Arduino 							    % Messages and data from Arduino stored here
		Rsc 									% Resources - where all the figures and GUI plot handles stored
	end

	%----------------------------------------------------
	% Methods
	%----------------------------------------------------
	methods
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%				Initialize Exp
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function obj = MouseBehaviorInterface(port)		% Initialization method - creates a structure-like data file with all the attributes of the experiment
			% Establish arduino connection
			obj.Arduino = ArduinoConnection(port);			% Connects to arduino via PORT

			% Creata Experiment Control window with all the knobs and buttons you need to set up an experiment. 
			obj.CreateDialog_ExperimentControl()			% Creates the GUI control window for the exp

			% Create Monitor window with all thr trial results and plots and stuff so the Grad Student is ON TOP OF THE SITUATION AT ALL TIMES.
			obj.CreateDialog_Monitor()						% Creates Exp Monitor window
		end

		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%			 Set Up Exp Control GUI
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function CreateDialog_ExperimentControl(obj)	% Initializes the control window
			% Size and position of controls
			buttonWidth = 50; 								% Width of buttons
			buttonHeight = 20; 								% Height of box 
			ctrlSpacing = 10; 								% Spacing between ui elements

			% Create the dialog
			dlg = dialog(...								% Creates a dialog box with the following properties...
				'Name', 'HSOM: Experiment Control',...
				'WindowStyle', 'normal',...
				'Resize', 'on',...
				'Visible', 'off'... 						% Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.ExperimentControl = dlg;				% Store the dialog handle in Resources (Rsc.ExperimentControl)

			% Close serial port when you close the window
			dlg.CloseRequestFcn = {@MouseBehaviorInterface.ArduinoClose, obj.Arduino};	% dlg.CloseRequestFcn is a figure property in Matlab - uses the callback

			% Create a uitable for parameters	
			table_params = uitable(...						% Create UI Table in the dlg box
				'Parent', dlg,...								% Parent = dlg box (means put the table in the dlg box)
				'Data', obj.Arduino.ParamValues',...			% The data in the table will be polled from the exp's ParamValues pulled from Arduino
				'RowName', obj.Arduino.ParamNames,...			% The rows will be named with ParamNames pulled from Arduino
				'ColumnName', {'Value'},...						% The column header will be 'Value'
				'ColumnFormat', {'long'},...					% The column format will be long numbers
				'ColumnEditable', [true],...					% The column values are editable by User
				'CellEditCallback', {@MouseBehaviorInterface.OnParamChanged, obj.Arduino}...	% When user clicks on cell and updates it, uses the Callback fxn *.OnParamChanged
			);

			% Set width and height
			table_params.Position(3:4) = table_params.Extent(3:4);	% Sets the position of the UI table and size in the dlg box
			%														% Position(1) = x_coord from bottom left
			%														% Position(2) = y_coord from bottom left
			%														% Position(3) = width
			%														% Position(4) = height
			%															% Thus, the height and width will be as large as the text is within the table

			% Start button - start experiment from IDLE state
			ctrlPosBase = table_params.Position;					% Positions the start button relative to the table. Here it pulls the position + dimensions of the table
			ctrlPos = [...											% Now the position of the run controllers are defined relative to table
				ctrlPosBase(1) + ctrlPosBase(3) + ctrlSpacing,...		% ctrlPos = [x_button = (x_table+width+spacing), y_button = (y_table+tableheight-buttonheight-spacing), button width, button height]
				ctrlPosBase(2) + ctrlPosBase(4) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_start = uicontrol(...					% Creates the start button:
				'Parent', dlg,...								% Parent = dlg box (means button goes in dlg box)
				'Style', 'pushbutton',...						% Pushbutton
				'Position', ctrlPos,...							% Position as defined above relative to the table
				'String', 'Start',...							% Label = "start"
				'TooltipString', 'Tell Arduino to start the experiment. Breaks out of IDLE state.',...	% Tooltip!
				'Callback', {@MouseBehaviorInterface.ArduinoStart, obj.Arduino}...						% Function callback on button press
			);

			% Stop button - abort current trial and return to IDLE
			ctrlPosBase = button_start.Position;			% Defines stop button position relative to the start button
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
			ctrlPosBase = button_stop.Position;				% Defines reset button position relative to the stop button
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
			ctrlPosBase = button_reset.Position;			% Defines terminate button wrt reset button
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
			dlg.Position(3) = table_params.Position(3) + buttonWidth + 4*ctrlSpacing;
			dlg.Position(4) = table_params.Position(4) + 3*ctrlSpacing;

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end


		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%			Set Up Exp Monitor GUI
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function CreateDialog_Monitor(obj)		% The Exp Monitor contains plots and figures to track Exp progress. It's a modified dlg box
			dlgWidth = 800;							% Define monitor width
			dlgHeight = 400;						% Define monitor height

			% Create the dialog 				% Create the GUI window
			dlg = dialog(...
				'Name', 'Harvard School of Mouse: Monitor',...	% Title bar text
				'WindowStyle', 'normal',...
				'Position', [100, 100, dlgWidth, dlgHeight],...	% Position on the screen wrt lower left corner
				'Units', 'pixels',...								% in pixels
				'Resize', 'on',...								% Can be resized
				'Visible', 'off'... 							% Hide until all controls created
			);

			% Store the dialog handle
			obj.Rsc.Monitor = dlg;				% Stores monitor window handle to Resources (Rsc.Monitor)

			% Size and position of controls
			dlg.UserData.DlgMargin = 20;				% Positions controls with 20 pixel margins
			dlg.UserData.LeftPanelWidthRatio = 0.3;		% Creates a left panel with 30% width of monitor
			dlg.UserData.PanelSpacing = 20;				% Spaces panels by 20 pixels
			dlg.UserData.PanelMargin = 20;				% Creates 20 pixel margin around panels
			dlg.UserData.BarHeight = 75;				% Defines height of progress bar as 75 pixels
			dlg.UserData.TextHeight = 30;				% Defines text height as 30 pixels for anywhere in the monitor

			u = dlg.UserData;					% Stores all the monitor's aesthetic properties in "u"

			% % Close serial port when you close the window
			% dlg.CloseRequestFcn = {@MouseBehaviorInterface.ArduinoClose, obj.Arduino};

			%----------------------------------------------------
			% Create Left Panel: Monitor of Experiment (e.g., trial #, # correct, etc)
			%----------------------------------------------------
			leftPanel = uipanel(...				% Defines a UI panel
				'Parent', dlg,...						% Put left panel inside the monitor dlg box
				'Title', 'Experiment Summary',...		% Make the title of the panel "Experiemnt Summary"
				'Units', 'pixels'...					% Units = pixels
			);
			dlg.UserData.Ctrl.LeftPanel = leftPanel;	% Puts the left panel properties into the control properties of the Monitor window

			% Text: Number of trials completed
			trialCountText = uicontrol(...		% Displays the number of trials in the left panel
				'Parent', leftPanel,...					% Parent = leftPanel (puts it in the left panel of the Monitor window dlg box)
				'Style', 'text',...						% It's a text object
				'String', 'Trials completed: 0',...		% Initializes it to be zero
				'TooltipString', 'Number of trials completed in this session.',...	% Tooltip!
				'HorizontalAlignment', 'left',...		% Aligns the text object to left of panel
				'Units', 'pixels',...
				'FontSize', 13 ...						% font size 13
			);
			dlg.UserData.Ctrl.TrialCountText = trialCountText;	% Stores these properties in the control properties of the Monitor winodw

			%----------------------------------------------------
			% Create Right Panel: User-defined plot of event marker data
			%----------------------------------------------------
			rightPanel = uipanel(...			% Defines a UI panel
				'Parent', dlg,...						% Put right panel inside monitor dlg box
				'Title', 'Plot Options',...				% Panel title = Plot Options
				'Units', 'pixels'...					% pixels
			);
			dlg.UserData.Ctrl.RightPanel = rightPanel;	% Stores right panel properties in the control properties of the Monitor Window

%					%----------------------------------------------------
%					% Reference Event Selection (user selects the event marker to which timing will be compared in the plot)
%					%----------------------------------------------------
			text_eventZero = uicontrol(...		% Text for selecting the reference event in the Right Panel
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Reference Event',...
				'HorizontalAlignment', 'left'...				
			);
			dlg.UserData.Ctrl.Text_EventZero = text_eventZero;	% Stores properties in the monitor control properties

			popup_eventZero = uicontrol(...		% The pop up menu allowing you to select which event marker is reference
				'Parent', rightPanel,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventZero = popup_eventZero;	% Stores props

%					%----------------------------------------------------
%					% Plotted-Event Selection (user selects the event marker to plot)
%					%----------------------------------------------------
			text_eventOfInterest = uicontrol(...	% text to select event
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Event Of Interest',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_EventOfInterest = text_eventOfInterest;	% Store props

			popup_eventOfInterest = uicontrol(...	% Popup to select event marker
				'Parent', rightPanel,...
				'Style', 'popupmenu',...
				'String', obj.Arduino.EventMarkerNames...
			);
			dlg.UserData.Ctrl.Popup_EventOfInterest = popup_eventOfInterest;% Store props




%					%----------------------------------------------------
%					% Plot Type Selection 
%					%----------------------------------------------------
			text_figureName = uicontrol(...		% Text telling user the title of Figure should be entered below
				'Parent', rightPanel,...
				'Style', 'text',...
				'String', 'Figure Title',...
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Text_FigureName = text_figureName;	% Store props

			edit_figureName = uicontrol(...		% Editable text box for UI entry of Figure title
				'Parent', rightPanel,...
				'Style', 'edit',...
				'String', 'Raster Plot',...			% Default title now is Raster Plot
				'HorizontalAlignment', 'left'...
			);
			dlg.UserData.Ctrl.Edit_FigureName = edit_figureName;	% Store props

			button_plot = uicontrol(...			% Pushbutton to plot the raster. Callback is to raster GUI Fx
				'Parent', rightPanel,...
				'Style', 'pushbutton',...
				'String', 'Plot',...
				'Callback', @obj.Raster_GUI...
			);
			dlg.UserData.Ctrl.Button_Plot = button_plot;		% Store props


			%----------------------------------------------------
			% Stacked bar chart for trial results
			%----------------------------------------------------
			ax = axes(...					% initialize handle and properties of the trial results stacked bar graph
				'Parent', dlg,...
				'Units', 'pixels',...
				'XTickLabel', [],...
				'YTickLabel', [],...
				'XTick', [],...
				'YTick', [],...
				'Box', 'on'...
			);
			obj.Rsc.Monitor.UserData.Ctrl.Ax = ax;	% Store handle

			% Update session summary everytime a new trial's results are registered by Arduino
			obj.Arduino.Listeners.TrialRegistered = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @obj.OnTrialRegistered);
			%							% Callback to the OnTrialRegistered fx to update the Arduino Listener property of the Exp

			% Stretch barchart When dialog window is resized
			dlg.SizeChangedFcn = @MouseBehaviorInterface.OnMonitorDialogResized; 


%			%----------------------------------------------------
%			% REVEAL the Monitor Dlg Box
%			%----------------------------------------------------

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end



		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%			Trial Completion Fx
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function OnTrialRegistered(obj, ~, ~)
		% Executed when a new trial is completed
			% Count how many trials have been completed
			iTrial = obj.Arduino.TrialsCompleted;					% Fetches # of trials completed from Arduino property

			% Update the "Trials Completed" counter in the Monitor Window
			t = obj.Rsc.Monitor.UserData.Ctrl.TrialCountText;		% Get the handle of the trials completed text
			t.String = sprintf('Trials completed: %d', iTrial);		% Revise the handle with new trials completed #

			% Update the stacked bar plot when trial completed:
			ax = obj.Rsc.Monitor.UserData.Ctrl.Ax;					% Get handle of stacked bar - works like a histogram. thus result code n is plotted between n and n+1
			% Get a list of currently recorded result codes
			resultCodes = reshape([obj.Arduino.Trials.Code], [], 1);	% Puts the results codes into an [n x 1] shape
			resultCodeNames = obj.Arduino.ResultCodeNames;				% Fetches the result code names from Arduino
			allResultCodes = 1:(length(resultCodeNames) + 1);			% For plotting purposes, need +1 elements (because last result code plotted between n and n+1)
			resultCodeCounts = histcounts(resultCodes, allResultCodes);	% Divides up the count for e/a result code

			bars = MouseBehaviorInterface.StackedBar(ax, resultCodeCounts, resultCodeNa mes);	% plots the stacked bar on the approp handle
		end

		%----------------------------------------------------
		% Plot - Raster plot events for each trial
		%----------------------------------------------------
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Defines and stores handles for the new Raster object
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Raster_GUI(obj, ~, ~)								% Get handle of Monitor
			dlg = obj.Rsc.Monitor;
			popup_eventZero = dlg.UserData.Ctrl.Popup_EventZero;		% Get handle of reference event marker
			popup_eventOfInterest = dlg.UserData.Ctrl.Popup_EventOfInterest;	% Get handle of plotted event marker
			edit_figureName = dlg.UserData.Ctrl.Edit_FigureName;		% Get handle of UI figure title

			disp(popup_eventZero.Value)								% Display on serial the value of the reference event time
			disp(popup_eventOfInterest.Value)						% Display value of the plotted event time


			obj.Raster(popup_eventZero.Value, popup_eventOfInterest.Value)	% Stores handle of the raster plot data and also calls raster fx to plot
		end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Creates and tracks the Figure ID for the new raster object, refreshes correct figure ID on trial end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Raster(obj, eventCodeZero, eventCodeOfInterest, nBins)
			% First column in data is eventCode, second column is timestamp (since trial start)
			if nargin < 4					% If don't specify the # of bins, default = 10
				nBins = 10;
			end

			% Create axes object
			f = figure();					% Will plot raster in a new figure window
			ax = gca;						% Get handle of new figure axes

			% Store plot settings into axes object
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.NBins 				= nBins;

			% Store the axes object
			if ~isfield(obj.Rsc, 'LooseFigures')
				figId = 1;					% defines the first new figure
			else
				figId = length(obj.Rsc.LooseFigures) + 1;	% IDs subsequent figures
			end
			obj.Rsc.LooseFigures(figId).Ax = ax;	% stores handle of the pop up figure

			% Plot it for the first time
			obj.Raster_Execute([], [], figId);		% inits the raster in the approp figure window

			% Plot again everytime an event of interest occurs
			ax.UserData.Listener = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @(src, evnt) obj.Raster_Execute(src, evnt, figId));
			f.CloseRequestFcn = {@MouseBehaviorInterface.OnLooseFigureClosed, ax.UserData.Listener}; 	% if try to close window, prompts with a close request fx
		end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Handles and plots raster data
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Raster_Execute(obj, ~, ~, figId)		% does the business of plotting the raster
			data 				= obj.Arduino.EventMarkers;			% get handle of Event Markers array
			ax 					= obj.Rsc.LooseFigures(figId).Ax;	% get handle of the approp figure ID window
			eventCodeOfInterest = ax.UserData.EventCodeOfInterest;	% get handle of plotted event marker times
			eventCodeZero 		= ax.UserData.EventCodeZero;		% get handle of reference event marker times
			nBins 				= ax.UserData.NBins;				% get handle of # of bins to div data up into

			% Do not plot until the first trial with an instance of the plotted event
			if (isempty(data))
				return
			end

			% Separate eventsOfInterest into trials, divided by eventsZero
			eventsZero 			= find(data(:, 1) == eventCodeZero);		% EventMarker = 0 always Trial Init, thus finds positions of new trials
			eventsOfInterest 	= find(data(:, 1) == eventCodeOfInterest);	% Finds positions of all the event markers of interest



%**********************NOTE: AH edit - check for error when running:******************************************************************
			% If no trials have occurred, do not plot
			if (isempty(eventsZero)) 			%|| isempty(eventsOfInterest)) % removed this because want to plot non-event containing trials
				return
			end

			if ~isempty(eventsOfInterest)
				if eventsOfInterest(end) > eventsZero(end)
					edges = [eventsZero; eventsOfInterest(end)];		
				else
					edges = eventsZero;
			else
				edges = eventsZero;
			end

			
			edges(end) = edges(end) + 1; % Adding one so that final event gets plotted in the histogram


			% Get timestamps for events of interest
			[~, ~, trials] = histcounts(eventsOfInterest, edges); % bins tells us which trials events belong to
			% if (trials == 0)
			% 	return
			% end
			% if (isempty(trials))
			% 	return
			% end
			% eventsZero
			if ~isempty(eventsOfInterest)
				eventTimesOfInterest = data(eventsOfInterest, 2);  % takes the timestamps of the event markers of interest and puts in a list
			else
				eventTimesOfInterest = NaN*zeros(trials, 1);
			end
			% Get timestamps for zero events
			eventTimesZero 			= data(eventsZero(trials), 2); % takes the timestamps of the reference event and puts in a list
			
			% Substract two sets of timestamps to get relative times 
			if ~isempty(eventsOfInterest)
				eventTimesOfInterest = eventTimesOfInterest - eventTimesZero;
			else
				eventTimesOfInterest = NaN*zeros(trials, 1);
			end

%********************** /--end AH edit - check for error when running:******************************************************************

			% Plot histogram of selected event times
			plot(ax, eventTimesOfInterest, trials, '.k',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', [0 .5 .5],...
				'MarkerFaceColor', [0 .7 .7],...
				'LineWidth', 1.5);
			if ~isempty(eventsOfInterest)
				ax.XLim 			= [min(eventTimesOfInterest) - 100, max(eventTimesOfInterest) + 100];
			else
				ax.Lim				= [0, 100];
			end
			ax.YLim 			= [max([0, min(trials) - 1]), obj.Arduino.TrialsCompleted + 1];
			ax.YDir				= 'reverse';				% Flips the Y axis
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

			% Store plot options cause for some reason it's lost unless we do this.
			ax.UserData.EventCodeZero 		= eventCodeZero;
			ax.UserData.EventCodeOfInterest = eventCodeOfInterest;
			ax.UserData.NBins 				= nBins;		
		end
	end

	%----------------------------------------------------
	% Staic methods
	%----------------------------------------------------
	methods (Static)			% these methods don't require a certain class object to work. Could write them as stand alone fx, but put here to look neat in the file
		%----------------------------------------------------
		% Commmunicating with Arduino
		%----------------------------------------------------
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Parameter Change Callback
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function OnParamChanged(~, evnt, arduino), 
			% evnt (event data contains infomation on which elements were changed to what)
			% arduino is the property of exp object
			changedParam = evnt.Indices(1);			% Indices is a property of evnt - this pulls out what parameter was changed (e.g., param 1 = 1)
			newValue = evnt.NewData;				% Pulls out the new Value of that parameters (some number)
			
			% Add new parameter to update queue
			arduino.UpdateParams_AddToQueue(changedParam, newValue)	% puts the new param in a message queue to arduino
			% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
			arduino.UpdateParams_Execute()
		end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Run Arduino
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
		function ArduinoStart(~, ~, arduino)
			arduino.Start()
			fprintf('Started.\n')
		end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Pause Arduino
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function ArduinoStop(~, ~, arduino)
			arduino.Stop()
			fprintf('Stopped.\n')
		end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Arduino Reset
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function ArduinoReset(~, ~, arduino)
			arduino.Reset()
			fprintf('Reset.\n')
		end
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Terminate Arduino Connection
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
			% Retrieve handles of all dialog objects and axes to resize
			dlg = gcbo; 				% gets handle to the "get current call back object"
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
			button_plot = dlg.UserData.Ctrl.Button_Plot;

			u = dlg.UserData;
			
			% Bar plot axes should have constant height.
			ax.Position = [...
				u.DlgMargin,...
				u.DlgMargin,...
				dlg.Position(3) - 2*u.DlgMargin,... % Adjusts width to match new dlg box size
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

			% UI select plot options
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

			button_plot.Position = [...
				popup_eventOfInterest.Position(1),...
				popup_eventOfInterest.Position(2) - 2*text_eventZero.Position(4) - u.PanelSpacing,...
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

			% data = [# instances of result 1, # instances of result 2,..., # instances of result n]

			% Create a stacked horizontal bar plot
			data = reshape(data, 1, []); 		% put data in a 1xn row vector. each position is the number of instances of a result code
			bars = barh(ax, [data; nan(size(data))], 'stack'); % nan(size(data)) allows a stack plot rather than bar plot
			
			% Remove whitespace and axis ticks
			ax.XLim = [0, sum(data)];											% Plot is as wide as the number of instances (trials)
			ax.YLim = [1 - 0.5*bars(1).BarWidth, 1 + 0.5*bars(1).BarWidth];		% Strips padding around the bar
			ax.XTickLabel = [];													% no X tick labels
			ax.YTickLabel = [];													% no Y tick labels

			% Add labels and set color
			edges = [0, cumsum(data)]; 			% Extracts the end position of each stacked bar. Ex: cumsum([1,2,3]) = [1,3,6]. Thus, this defines edges
			
			for iData = 1:length(data)			% for all the result codes...
				percentage = round(data(iData)/sum(data) * 100);
				labelLong = sprintf('%s \n%dx\n(%d%%)', names{iData}, data(iData), percentage);	% if fits: name, # instances, %. %s = str, \n=line break, %dx = decimal, %% = prints a % sign
				labelMed = sprintf('''%d''\n%dx', iData, data(iData));							% if long doesn't fit: Result code #, # instances
				labelShort = sprintf('''%d''', iData);											% if med doesn't fit: Result code # only
				center = (edges(iData) + edges(iData + 1))/2;									% finds the center of the bar in question to put the label

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
				bars(iData).ButtonDownFcn = @MouseBehaviorInterface.OnStackedBarSingleClick;		% Callback to a more involved tooltip fx

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
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			%		Callback Fx for Clicking a Bar (fancy tooltip)	
			%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function OnStackedBarSingleClick(h, ~)
			% If text from another bar is force shown, hide it first
			t = findobj(gca, 'Tag', 'ForceShown'); % searches for any forceshown (visible) objects in the properties
			if ~isempty(t)			% Reset the tag to hide the previous tooltip. Note that t is not empty after this if statement...it's just a hidden obj
				t.Tag = '';
				t.Visible = 'off';
				t.BackgroundColor = 'none';
				t.EdgeColor = 'none';
			end

			% Force show text associated with bar clicked, unless it's already shown, in which case clicking again will hide it
			tLong = h.UserData.tLong;			% fetches tlong data for the bar just clicked (h)
			if strcmp(tLong.Visible, 'off')		% if the tooltip isn't already visible
				if ~isempty(t)					% If the tooltip is the one we just turned off, do nothing because don't want to turn it back on in this click!
					if t == tLong
						return
					end
				end
				tLong.Tag = 'ForceShown';		% updates the properties of this bar to 'ForceShown' and visible
				tLong.Visible = 'on';
				tLong.BackgroundColor = [1 1 .73];	% tool tip colors etc
				tLong.EdgeColor = 'k';
				uistack(tLong, 'top') 				% Bring to top
			end
		end
	end
end