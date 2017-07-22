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
			ax.XLim 			= [ax.XLim(1) - 100, ax.XLim(2) + 100];
			ax.YLim 			= [0, obj.Arduino.TrialsCompleted + 1];
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