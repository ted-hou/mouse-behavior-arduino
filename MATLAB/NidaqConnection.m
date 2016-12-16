classdef NidaqConnection < handle
	properties
		BufferTimeStamps = []
		BufferData = []
		StartTime = []
		Channels = []
		ChannelNames = []
	end

	properties (Transient)	% These properties will be discarded when saving to file
		Session = []
		Devices = []
		DebugMode = false
		Connected = false
		SavePath = ''
		FileID = []
		Listeners
	end

	methods
		% Establish connection with daq device
		function obj = NidaqConnection(deviceName)
			% Find available device(s) - to do: handle multiple daq cards
			d = daq.getDevices;
			obj.Devices = d;
			if nargin < 1
				deviceName = d.ID;
			end

			obj.QueryChannels();

			% Create daq session
			s = daq.createSession('ni');
			s.Rate = 1000;
			s.IsContinuous = true;
			obj.Session = s;
			
			addAnalogInputChannel(s, deviceName, obj.Channels, 'Voltage');

			prepare(s)
		end

		function QueryChannels(obj)
			% Size and position of controls
			buttonWidth = 50; % Width of buttons
			buttonHeight = 20; % Height of 
			ctrlSpacing = 10; % Spacing between ui elements

			dlg = dialog(...
				'Name', 'Select Nidaq Channels...',...
				'Resize', 'on',...
				'Visible', 'off'... % Hide until all controls created
			);

			% Create channels table
			channelNames = obj.Devices.Subsystems(1).ChannelNames;
			numChannels = length(channelNames);
			table_analogChannels = uitable(...
				'Parent', dlg,...
				'Data', [channelNames, repmat({false}, [numChannels, 1])],...
				'RowName', channelNames,...
				'ColumnName', {'Channel Description', 'Enable Channel'},...
				'ColumnFormat', {'char', 'logical'},...
				'ColumnEditable', [true, true]...
			);
			% Set table pos
			table_analogChannels.Position(2) = buttonHeight + 2*ctrlSpacing;
			table_analogChannels.Position(3:4) = table_analogChannels.Extent(3:4);

			channelNames = obj.Devices.Subsystems(3).ChannelNames;
			numChannels = length(channelNames);
			table_digitalChannels = uitable(...
				'Parent', dlg,...
				'Data', [channelNames, repmat({false}, [numChannels, 1])],...
				'RowName', channelNames,...
				'ColumnName', {'Channel Description', 'Enable Channel'},...
				'ColumnFormat', {'char', 'logical'},...
				'ColumnEditable', [true, true]...
			);
			% Set table pos
			ctrlPosBase = table_analogChannels.Position;
			table_digitalChannels.Position(1:2) = [...
				ctrlPosBase(1) + ctrlPosBase(3) + ctrlSpacing,...
				ctrlPosBase(2)...
			];
			table_digitalChannels.Position(3:4) = table_digitalChannels.Extent(3:4);

			% Confirm button
			ctrlPosBase = table_analogChannels.Position;
			ctrlPos = [...
				ctrlPosBase(1) + ctrlPosBase(3) - 0.5*buttonWidth,...
				ctrlPosBase(2) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];			
			button_confirm = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Confirm',...
				'Callback', {@obj.QueryChannels_OnConfirm, dlg, table_analogChannels}...
			);

			% Adjust window size
			dlg.Position(3:4) = [...
				table_analogChannels.Position(3) + table_digitalChannels.Position(3) + 4*ctrlSpacing,...
				max([table_analogChannels.Position(4); table_digitalChannels.Position(4)]) + buttonHeight + 3*ctrlSpacing...
			];

			dlg.Visible = 'on';

			uiwait(dlg)
		end

		function QueryChannels_OnConfirm(obj, ~, ~, dlg, table_analogChannels)
			data = table_analogChannels.Data
			channelIds = find(cell2mat(data(:, 2)));
			obj.Channels = obj.Devices.Subsystems(1).ChannelNames(channelIds, 1);
			obj.ChannelNames = data(channelIds, 1);
			delete(dlg)
		end

		% Called when data is available
		function OnDataAvailable(obj, event)
			% Write to file
			data = [event.TimeStamps, event.Data]';
			fwrite(obj.FileID, data, 'double');			

			% Write to workspace
			obj.BufferTimeStamps = [obj.BufferTimeStamps; event.TimeStamps];
			obj.BufferData = [obj.BufferData; event.Data];

			% Log acquisition start time
			if isempty(obj.StartTime)
				obj.StartTime = event.TriggerTime;
			end

			% Update all plots
			obj.Plot()
		end

		% Plot selected channels - to be called whenever data is available
		function Plot(obj)
			plot(obj.BufferTimeStamps, obj.BufferData)
			legend(obj.ChannelNames)
			xlabel('Time (s)')
			ylabel('Voltage (V)')
		end

		function [timeStamps, data] = GetAndClearBuffer(obj)
			timeStamps = obj.BufferTimeStamps;
			data = obj.BufferData;
			obj.BufferTimeStamps = [];
			obj.BufferData = [];
		end

		% Start data acquisition
		function Start(obj)
			% DataAvailable callback function
			lh = addlistener(obj.Session, 'DataAvailable', @(src, event) obj.OnDataAvailable(event));
			obj.Listeners.DataAvailable = lh;

			% Prompt user to designate save path if undefined
			if isempty(obj.SavePath)
				obj.SelectSavePath()
			end

			% Create/reopen .bin file
			obj.FileID = fopen([obj.SavePath, '.bin'], 'w');

			% Begin daq session
			startBackground(obj.Session);
		end

		% Terminate data acquisition
		function Stop(obj)
			stop(obj.Session)
			delete(obj.Listeners.DataAvailable)
			fclose(obj.FileID);
		end

		function Save(obj)
			save(obj.SavePath, 'obj')
		end

		function SelectSavePath(obj)
			[filename, filepath] = uiputfile(['data_',datestr(now, 'yyyymmdd'),'.bin'],'Save Data To New File');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			filename = strsplit(filename, '.bin');
			filename = filename{1};
			obj.SavePath = [filepath, filename];
		end
	end
end