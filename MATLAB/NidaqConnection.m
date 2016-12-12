classdef NidaqConnection < handle
	properties
		TimeStamps = nan(12*3600*1000, 1)
		Data = nan(12*3600*1000, 1)
	end

	properties (Transient)	% These properties will be discarded when saving to file
		Session = []
		DebugMode = false
		Connected = false
		SavePath = ''
		FileID = []
		Listeners
	end

	methods
		% Establish connection with daq device
		function obj = NidaqConnection(deviceName, channels, samplingRate)
			% Find available device(s) - to do: handle multiple daq cards
			d = daq.getDevices;
			if nargin < 1
				deviceName = d.ID;
			end
			if nargin < 2
				channels = d.Subsystems(1).ChannelNames(1);
			end
			if nargin < 3
				samplingRate = 1000;
			end

			% Create daq session
			s = daq.createSession('ni');
			obj.Session = s;
			addAnalogInputChannel(s, deviceName, channels, 'Voltage');
			s.Rate = samplingRate;
			s.IsContinuous = true;
		end

		% Called when data is available
		function OnDataAvailable(obj, event)
			% Write to file
			data = [event.TimeStamps, event.Data]';
			fwrite(obj.FileID, data, 'double');			

			% Write to workspace
			iStart = find(isnan(obj.TimeStamps), 1);
			iEnd = iStart + numel(event.TimeStamps) - 1;
			obj.TimeStamps(iStart:iEnd) = event.TimeStamps;
			obj.Data(iStart:iEnd) = event.Data;

			% Plot
			% plot(obj.TimeStamps(1:iEnd), obj.Data(1:iEnd))
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