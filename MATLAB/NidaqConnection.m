classdef NidaqConnection < handle
	properties
		BufferTimeStamps = []			% timestamps for each datapoint
		BufferData = []
		StartTime = []
		Channels = []
	end

	properties (Transient)	% These properties will be discarded when saving to file
		Session = []
		Devices = []
		DebugMode = false
		Connected = false
		Record = false
		SavePath = ''
		FileID = []
		Ax = []
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

			obj.QueryChannels();		% creates object with all the NiDAQ channels

			% Create daq session
			s = daq.createSession('ni');		% creates NiDAQ sesh
			s.Rate = 1000;						% sets sampling rate to 1 kHz default
			s.IsContinuous = true;				% DAQ records in continuous mode
			obj.Session = s;					% Puts all the session info into a Session object (h.Session)
			
			for iChannel = 1:length(obj.Channels)					% for each channel in NiDAQ
				channelId = obj.Channels(iChannel).Id;					% get ID of the channel
				channelName = obj.Channels(iChannel).Name;				% get name of channel
				channelType = obj.Channels(iChannel).Type;				% get channel type

				if strcmp(channelType, 'Analog')						% If channel is ANALOG - configures channel to read input appropriately
					ch = addAnalogInputChannel(s, deviceName, channelId, 'Voltage');
					ch.TerminalConfig = 'SingleEnded'; % 'SingleEnded' so BNC ground is used as ground. If the default 'Differential' mode is used, another analog channel is used as ground.
				end
				if strcmp(channelType, 'Digital')						% If channel is DIGITAL - configures channel to read input approp.
					addDigitalChannel(s, deviceName, channelId, 'InputOnly');
				end
			end

			prepare(s)					% Prepares the session (must be a matlab fx)
		end

		function QueryChannels(obj)		% UI Choose which channels to pay attention to
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
				'Data', [channelNames, repmat({false}, [numChannels, 1]), repmat({'Analog'}, [numChannels, 1])],...
				'RowName', channelNames,...
				'ColumnName', {'Channel Description', 'Enable Channel', 'Type'},...
				'ColumnFormat', {'char', 'logical', 'char'},...
				'ColumnEditable', [true, true, false]...
			);
			% Set table pos
			table_analogChannels.Position(2) = buttonHeight + 2*ctrlSpacing;
			table_analogChannels.Position(3:4) = table_analogChannels.Extent(3:4);

			channelNames = obj.Devices.Subsystems(3).ChannelNames;
			numChannels = length(channelNames);
			table_digitalChannels = uitable(...
				'Parent', dlg,...
				'Data', [channelNames, repmat({false}, [numChannels, 1]), repmat({'Digital'}, [numChannels, 1])],... % inside the table: first column is the channel name, second is false for each cell, third column just says digital. the [numChannels, 1] just says that cell will be repeated for the length of numChannels
				'RowName', channelNames,...
				'ColumnName', {'Channel Description', 'Enable Channel', 'Type'},...
				'ColumnFormat', {'char', 'logical', 'char'},...
				'ColumnEditable', [true, true, false]...
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
				ctrlPosBase(1) + ctrlPosBase(3) - 0.5*buttonWidth + 0.5*ctrlSpacing,...
				ctrlPosBase(2) - buttonHeight - ctrlSpacing,...
				buttonWidth,...	
				buttonHeight...
			];
			button_confirm = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'Position', ctrlPos,...
				'String', 'Confirm',...
				'Callback', {@obj.QueryChannels_OnConfirm, dlg, table_analogChannels, table_digitalChannels}...
			);						% selects the channels will listen to @obj.QueryChannels_OnConfirm

			% Adjust window size
			dlg.Position(3:4) = [...
				table_analogChannels.Position(3) + table_digitalChannels.Position(3) + 4*ctrlSpacing,...
				max([table_analogChannels.Position(4); table_digitalChannels.Position(4)]) + buttonHeight + 3*ctrlSpacing...
			];

			dlg.Visible = 'on';

			uiwait(dlg)
		end

		function QueryChannels_OnConfirm(obj, ~, ~, dlg, table_analogChannels, table_digitalChannels) % Store which channels you listen to

%table...Data: [channelNames in each row, true for ones you want, 'Digital or Analog']

			data_analog = table_analogChannels.Data;					% Copies over table that tells which channels will be listened to
			data_digital = table_digitalChannels.Data;
			channelIds_analog = find(cell2mat(data_analog(:, 2)));		% Finds all the selected channels (each rep'd by a number, that's what you're finding. for ex, A0 = 1, A1 = 2...D0_2 = 56...)
			channelIds_digital = find(cell2mat(data_digital(:, 2)));

			i = 0;
			for iChannel = channelIds_analog'					% For each selex Analog channel #...
				i = i + 1;
				obj.Channels(i).Id = obj.Devices.Subsystems(1).ChannelNames{iChannel, 1}; % get the channel's ID
				obj.Channels(i).Name = data_analog{iChannel, 1};						  % get the channel's name (e.g., A0)
				obj.Channels(i).Type = data_analog{iChannel, 3};						  % get the channel's type (analog)
			end

			for iChannel = channelIds_digital'
				i = i + 1;
				obj.Channels(i).Id = obj.Devices.Subsystems(3).ChannelNames{iChannel, 1};
				obj.Channels(i).Name = data_digital{iChannel, 1};
				obj.Channels(i).Type = data_digital{iChannel, 3};
			end

			delete(dlg)
		end

		% Called when data is available
		function OnDataAvailable(obj, event)    
			% Log acquisition start time
			if isempty(obj.StartTime)
				obj.StartTime = event.TriggerTime;
			end

			if (~obj.Record)
				obj.Record = true;
			end

			% Write to file
			data = horzcat(event.TimeStamps, event.Data);
			fwrite(obj.FileID, data, 'double');	

			% % Write to file
			% data = [event.TimeStamps, event.Data]';
			% fwrite(obj.FileID, data, 'double');			

			% Write to workspace
			obj.BufferTimeStamps = [obj.BufferTimeStamps; event.TimeStamps];
			obj.BufferData = [obj.BufferData; event.Data];

			% Update all plots
			if ~isobject(obj.Ax)
				f = figure('Name', 'NiDAQ', 'NumberTitle', 'off');
				obj.Ax = axes('Parent', f);
			end
			obj.Plot(obj.Ax)
		end

		% Plot selected channels - to be called whenever data is available
		function Plot(obj, ax)
			plot(ax, obj.BufferTimeStamps, obj.BufferData)
			legend({obj.Channels.Name})
			xlabel('Time (s)')
			ylabel('Voltage (V)')
		end

		function ClearBuffer(obj)
			obj.BufferTimeStamps = [];
			obj.BufferData = [];
		end

		% Start data acquisition
		function Start(obj)
			% DataAvailable callback function - listens for when new datapoint on the DAQ
			lh = addlistener(obj.Session, 'DataAvailable', @(src, event) obj.OnDataAvailable(event));
			obj.Listeners.DataAvailable = lh;

			% Prompt user to designate save path if undefined
			if isempty(obj.SavePath)
				obj.SelectSavePath()
			end

			% Create/reopen .bin file
			obj.FileID = fopen([obj.SavePath, '.bin'], 'w');  %CAUTION!! 'w' means you'll erase and write over the filepath you put here!! Use 'r' to read!

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