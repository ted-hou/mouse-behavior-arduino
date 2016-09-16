%% MouseBehaviorInterface: construct graphical user interface to interact with arduino
classdef MouseBehaviorInterface < handle
	properties
		Arduino
		Rsc
	end

	methods
		function obj = MouseBehaviorInterface()
			% Establish arduino connection
			obj.Arduino = ArduinoConnection;

			% Creata Experiment Control window with all the knobs and buttons you need to set up an experiment. 
			obj.CreateWindow_ExperimentControl()

			% Create Monitor window with all thr trial results and plots and stuff so the Grad Student is ON TOP OF THE SITUATION AT ALL TIMES.
			obj.CreateWindow_Monitor()
		end

		function CreateWindow_ExperimentControl(obj)
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

			% Terminate button - terminate connection w/ arduino and close GUI
			ctrlPosBase = button_stop.Position;
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

		function CreateWindow_Monitor(obj)
			% Size and position of controls
			dlgHeight = 400;
			dlgWidth = 200;
			dlgMarginTop = 10;
			buttonWidth = 50; % Width of buttons
			textHeight = 40; % Height of a line of text
			ctrlSpacing = 10; % Spacing between ui elements

			% Create the dialog
			dlg = dialog(...
				'Name', 'Monitor',...
				'WindowStyle', 'normal',...
				'Position', [0, 0, dlgWidth, dlgHeight],...
				'Resize', 'on',...
				'Visible', 'off'... % Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.Monitor = dlg;

			% Close serial port when you close the window
			dlg.CloseRequestFcn = {@MouseBehaviorInterface.ArduinoClose, obj.Arduino};

			%----------------------------------------------------
			% Text: Number of trials completed
			%----------------------------------------------------
			text_trialCount = uicontrol(...
				'Parent', dlg,...
				'Style', 'text',...
				'String', 'Trials completed: 0',...
				'TooltipString', 'Number of trials completed in this session.',...
				'Position', [0, dlgHeight - dlgMarginTop - textHeight, dlgWidth, textHeight],...
				'FontSize', 14 ...
			);
			obj.Rsc.Ctrl.Text_TrialCount = text_trialCount;

			% Update session summary everytime a new trial's results are registered by Arduino
			obj.Arduino.Listeners.TrialRegistered = addlistener(obj.Arduino, 'TrialsCompleted', 'PostSet', @obj.OnTrialRegistered);

			%----------------------------------------------------
			% Stacked bar chart for trial results
			%----------------------------------------------------

			% Resize dialog so it fits all controls
			% dlg.Position(3) = table_params.Position(3) + buttonWidth + 4*ctrlSpacing;
			% dlg.Position(4) = table_params.Position(4) + 3*ctrlSpacing;

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end

		function OnTrialRegistered(obj, ~, evnt)
			iTrial = evnt.AffectedObject.TrialsCompleted;
			% When a new trial is finished and registered, update the "Trials Completed" counter.
			obj.Rsc.Ctrl.Text_TrialCount.String = sprintf('Trials completed: %d', iTrial);
		end		
	end

	methods (Static)
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
		function ArduinoClose(~, ~, arduino)
			selection = questdlg(...
				'Closing this window will terminate connection with Arduino. Proceed?',...
				'Close Window',...
				'Yes','No','Yes'...
			);
			switch selection
				case 'Yes'
					arduino.Close()
					delete(gcf)
		            fprintf('Connection closed.\n')
				case 'No'
					return
			end
		end

		%----------------------------------------------------
		% Plots
		%----------------------------------------------------
		function [ax, bars] = StackedBar(data, names, colors)
			% Default params
			if nargin < 3
				colors = {[.2, .8, .2], [1 .2 .2], [.9 .2 .2], [.8 .2 .2], [.7 .2 .2]};
			end

			% Create a stacked horizontal bar plot
			bars = barh([data; nan(size(data))], 'stack');
			ax = gca;
			
			% Remove whitespace and axis ticks
			xlim([0, sum(data)])
			ylim([1 - 0.5*bars(1).BarWidth, 1 + 0.5*bars(1).BarWidth])
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

				t = text(center, 1, labelLong, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
				bars(iData).UserData.tLong = t;

				% Hide parts of the label if it's wider than the bar
				if (t.Extent(3) > data(iData))
					t.Visible = 'off';
					t = text(center, 1, labelMed, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
					bars(iData).UserData.tMed = t;
					if (t.Extent(3) > data(iData))
						t.Visible = 'off';
						t = text(center, 1, labelShort, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
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

			% Figure resize listener
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