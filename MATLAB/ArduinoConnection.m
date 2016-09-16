%% ArduinoConnection: serial port connection to an Arduino
classdef ArduinoConnection < handle
	properties
		DebugMode = false
		Connected = false
		SerialConnection = []
		ArduinoMessageString = ''
		State = []
		StateNames = {}
		StateCanUpdateParams = logical([])
		ParamNames = {}
		ParamValues = []
		ParamUpdateQueue = []
		ResultCodeNames = {}
		EventMarkers = []
		EventMarkerNames = {}
		Trials = struct([])
		Listeners
	end

	properties (SetObservable)
		TrialsCompleted = 0
	end

	events
		StateChanged
	end

	methods
		function obj = ArduinoConnection()
			obj.ArduinoMessageString = '';
			serialPort = [];
			arduinoPortName = obj.findFirstArduinoPort();

			if isempty(arduinoPortName)
				disp('Can''t find serial port with Arduino')
				return
			end

			% Define the serial port object.
			fprintf('Starting serial on port: %s\n', arduinoPortName)
			serialPort = serial(arduinoPortName);
			
			% Set the baud rate
			serialPort.BaudRate = 115200;
			
			% Add a callback function to be executed whenever 1 byte is available
			% to be read from the port's buffer.
			serialPort.BytesAvailableFcn = @(port, event)obj.ReadMessage(port, event);
			serialPort.BytesAvailableFcnMode = 'byte';
			serialPort.BytesAvailableFcnCount = 1;

			% Open the serial port for reading and writing.
			obj.SerialConnection = serialPort;
			fopen(serialPort)

			% wait for Arduino startup
			% (we expect the Arduino to write '~' to the Serial port upon starting up)
			fprintf('Waiting for Arduino startup')
			while (~obj.Connected)
				fprintf('.')
				pause(0.5)
			end

			% Add event handler to detect state changes
			obj.Listeners.StateChanged = addlistener(obj, 'StateChanged', @obj.OnStateChanged);
		end

		function SendMessage(obj, messageChar, arg1, arg2)
			switch nargin
				case 2
					stringToSend = sprintf('%s', messageChar);
				case 3
					stringToSend = sprintf('%s %d', messageChar, arg1);
				case 4
					stringToSend = sprintf('%s %d %d', messageChar, arg1, arg2);
			end
			obj.SendString(stringToSend)
		end

		function SendString(obj, stringToWrite)
			fprintf(obj.SerialConnection,'%s#',stringToWrite, 'sync')

			% DEBUGING
			if obj.DebugMode
				disp(['To Arduino: "', stringToSend, '"' ])
			end
		end

		function ReadMessage(obj, port, event)
			%arduinoPort = port;
			% As long as there are still bytes to be read in the buffer...
			while (obj.SerialConnection.BytesAvailable > 0)
				charIn = char(fread(obj.SerialConnection,1,'char'));

				% on carriage return, call message callback and reset ArduinoMessageString
				if (charIn == sprintf('\n'))

					% we confirm that the connection was established once the first message is recieved
					if (~obj.Connected)
						obj.Connected = true;
					end
					obj.OnMessageReceived()
					obj.ArduinoMessageString = '';
					return % process at most one message per function call to minimize time of call

				% otherwise keep accumulating characters into ArduinoMessageString
				elseif (charIn ~= sprintf('\r'))
					obj.ArduinoMessageString = [obj.ArduinoMessageString charIn];
				end
			end
		end

		function OnMessageReceived(obj)
			% Remove leading and trailing white spaces
			messageString = obj.ArduinoMessageString;
			messageString = strtrim(messageString);

			% First character contains the command
			command = messageString(1);
			if length(messageString) > 1
				value = messageString(2:end);
			end

			switch command
				case '$'
					% New state entered - "$1" we've entered the second state. "$5 100" we've enetered the 6th state, and trial result is 100 (negative numbers used as error codes).
					subStrings = strsplit(strtrim(value), ' ');

					% Convert zero-based state indices (Arduino) to one-based indices (MATLAB)
					obj.State = str2num(subStrings{1}) + 1;

					% If result received, store the results in a new Trial structure
					if length(subStrings) > 1
						obj.TrialsCompleted = obj.TrialsCompleted + 1;
						resultCode = str2num(subStrings{2}) + 1;
						obj.Trials(obj.TrialsCompleted).Code = obj.ResultCodeNames{resultCode};
						obj.Trials(obj.TrialsCompleted).Result = str2num(subStrings{3});
						obj.Trials(obj.TrialsCompleted).Parameters = obj.ParamValues;

						fprintf('Result: %d ms (%s)\n', obj.Trials(obj.TrialsCompleted).Result, obj.Trials(obj.TrialsCompleted).Code)
					end

					% Trigger StateChanged Event
					notify(obj, 'StateChanged')
				case '@'
					% Arduino sent the name of a state - "@ 1 IDLE"
					subStrings = strsplit(strtrim(value), ' ');
					% Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					stateId = str2num(subStrings{1}) + 1;
					% Register state name and whether this states allows param update
					obj.StateNames{stateId} = subStrings{2};
					obj.StateCanUpdateParams(stateId) = logical(str2num(subStrings{3}));
				case '&'
					% Arduino sent an event code and its timestamp - "& 0 100"
					subStrings = strsplit(strtrim(value), ' ');
					eventCode = str2num(subStrings{1}) + 1; % Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					timeStamp = str2num(subStrings{2});
					obj.EventMarkers = [obj.EventMarkers; eventCode, timeStamp];
				case '+'
					% Arduino sent the name of an event marker - "+ 0 TRIAL_START"
					subStrings = strsplit(strtrim(value), ' ');
					% Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					eventMarkerId = str2num(subStrings{1}) + 1;
					% Register event marker names so MATLAB KNOWs WHAT IS GOING ON WHEN SHIT GOES DOWN
					obj.EventMarkerNames{eventMarkerId} = subStrings{2};
				case '#'
					% Arduino sent the name and default value of a parameter - "# 1 INTERVAL_MIN 1250"
					subStrings = strsplit(strtrim(value), ' ');
					% Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					paramId = str2num(subStrings{1}) + 1;
					% Register parameter name and value
					obj.ParamNames{paramId} = subStrings{2};
					obj.ParamValues(paramId) = str2num(subStrings{3});
				case '*'
					% Arduino sent error code interpretations - "# 0 ERROR_LEVER_NOT_PRESSED" means error code -1
					subStrings = strsplit(strtrim(value), ' ');
					% Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					codeId = str2num(subStrings{1}) + 1;
					% Register parameter name and value
					obj.ResultCodeNames{codeId} = subStrings{2};
				case '~'
					fprintf('\nUp and running.\n')
				otherwise
					% Arduino sent a message
					fprintf('%s\n', messageString)
			end
		end

		% Called each time a state changes
		function OnStateChanged(obj, ~, ~)
			% If new state allows parameter update, execute the update queue
			if obj.StateCanUpdateParams(obj.State)
				obj.UpdateParams_Execute()
			end
		end

		% Update a single parameter by index
		function SetParam(obj, paramId, value)
			% Update parameter value in MATLAB
			obj.ParamValues(paramId) = value;
            % Convert zero-based indices (Arduino) to one-based indices (MATLAB)
			paramId = paramId - 1;
			% Send new parameter to arduino via serial comms ("P id newValue")
			obj.SendMessage(sprintf('P %d %d', paramId, value))
		end

		% Add parameter update arguments to queue
		function UpdateParams_AddToQueue(obj, paramId, value)
			% If parameter queue is empty, add as a new item
			if isempty(obj.ParamUpdateQueue)
				obj.ParamUpdateQueue = [obj.ParamUpdateQueue; paramId, value];
			else
				posInQueue = find(obj.ParamUpdateQueue(:, 1) == paramId);
				% If parameter not in queue, add as new item
				if isempty(posInQueue)
					obj.ParamUpdateQueue = [obj.ParamUpdateQueue; paramId, value];
				% If parameter already in queue, replace existing item in queue
				else
					obj.ParamUpdateQueue(posInQueue, 2) = value;
				end
			end
		end

		% Update parameters and clear queue, do nothing if queue is empty
		function UpdateParams_Execute(obj)
			% Only execute non-empty queues when current state allows param update
			if obj.StateCanUpdateParams(obj.State) & ~isempty(obj.ParamUpdateQueue) 
				for iQueue = 1:size(obj.ParamUpdateQueue, 1)
					paramId = obj.ParamUpdateQueue(iQueue, 1);
					value = obj.ParamUpdateQueue(iQueue, 2);
					obj.SetParam(paramId, value)
				end
				% Clear the queue 
				obj.ParamUpdateQueue = [];
				% Send 'O' to tell arduino we're done updating parameters
				obj.SendMessage('O')
				fprintf('Parameters updated.\n')
			end
		end

		% Break arduino from IDLE state and begin experiment
		function Start(obj)
			obj.SendMessage('G')
		end

		% Interrupt current trial and return to IDLE
		function Stop(obj)
			obj.SendMessage('Q')
		end

		% Terminate connection with arduino
		function Close(obj)
			fclose(obj.SerialConnection)
		end
	end

	methods (Static)

		function port = findFirstArduinoPort()
			% finds the first port with an Arduino on it.

			serialInfo = instrhwinfo('serial');
			archstr = computer('arch');

			port = [];

			% OSX code:
			if strcmp(archstr,'maci64')
				for portN = 1:length(serialInfo.AvailableSerialPorts)
					portName = serialInfo.AvailableSerialPorts{portN};
					if strfind(portName,'tty.usbmodem')
						port = portName;
						return
					end
				end
			else
			% PC code:
				% code from Benjamin Avants on Matlab Answers
				% http://www.mathworks.com/matlabcentral/answers/110249-how-can-i-identify-com-port-devices-on-windows

				Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
				% Find Connected serial devices and clean up the output
				[~, list] = dos(['REG QUERY ' Skey]);
				list = strread(list,'%s','delimiter',' ');
				coms = 0;
				for i = 1:numel(list)
				  if strcmp(list{i}(1:3),'COM')
						if ~iscell(coms)
							coms = list(i);
						else
							coms{end+1} = list{i};
						end
					end
				end
				key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
				% Find all installed USB devices entries and clean up the output
				[~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
				vals = textscan(vals,'%s','delimiter','\t');
				vals = cat(1,vals{:});
				out = 0;
				% Find all friendly name property entries
				for i = 1:numel(vals)
					if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
						if ~iscell(out)
							out = vals(i);
						else
							out{end+1} = vals{i};
						end
					end
				end
				% Compare friendly name entries with Connected ports and generate output
				for i = 1:numel(coms)
					match = strfind(out,[coms{i},')']);
					ind = 0;
					for j = 1:numel(match)
						if ~isempty(match{j})
							ind = j;
						end
					end
					if ind ~= 0
						com = str2double(coms{i}(4:end));
						% Trim the trailing ' (COM##)' from the friendly name - works on ports from 1 to 99
						if com > 9
							len = 8;
						else
							len = 7;
						end
						devs{i,1} = out{ind}(27:end-len);
						devs{i,2} = coms{i};
					end
				end
				% get the first arduino port
				for i = 1:numel(coms)
					[portFriendlyName, portName] = devs{i,:};
					if strfind(portFriendlyName, 'Arduino')
						port = portName;
						return
					end
				end
			end
		end
    end
end
