%% ArduinoConnection: serial port connection to an Arduino
classdef ArduinoConnection < handle
	properties
		StateNames = {}
		StateCanUpdateParams = logical([])
		ParamNames = {}
		ResultCodeNames = {}
		EventMarkers = []
		EventMarkerNames = {}
		Trials = struct([])
		ExperimentFileName = ''			% Contains 'C://path/filename.mat'
	end

	properties (SetObservable, AbortSet)
		ParamValues = []
		TrialsCompleted = 0
	end

	properties (Transient)	% These properties will be discarded when saving to file
		DebugMode = false
		Connected = false
		SerialConnection = []
		ArduinoMessageString = ''
		State = []
		ParamUpdateQueue = []
		AutosaveEnabled = false
		Listeners
	end

	events
		StateChanged
	end

	methods
		function obj = ArduinoConnection()
			%-----------------------------------------------
			%		Find USB Port
			%-----------------------------------------------
			selection = questdlg(...
				'Choose the device you are running.',...
				'Choose device',...
				'Arduino','Teensy','Arduino'...
			);
			switch selection
				case 'Arduino'
					arduinoPortName = [];
				case 'Teensy'
					arduinoPortName = inputdlg('Specify COM port:', 'USB Port', 1, {'COM1'});
					arduinoPortName = arduinoPortName{1};
			end

			if isempty(arduinoPortName)
				arduinoPortName = obj.findFirstArduinoPort();
			end
			if isempty(arduinoPortName)
				disp('Can''t find serial port with Arduino')
				return
			end

			%-----------------------------------------------
			%		Start Serial Connection
			%-----------------------------------------------

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
			fopen(serialPort);

			% wait for Arduino startup
			% (we expect the Arduino to write '~' to the Serial port upon starting up)
			fprintf('Waiting for Arduino startup')
			obj.SendMessage('R')
			while (~obj.Connected)
				fprintf('.')
				pause(0.5)
			end

			% Add event handler to detect state changes
			obj.Listeners.StateChanged = addlistener(obj, 'StateChanged', @obj.OnStateChanged);
		end

		%-----------------------------------------------~~
		%		File I/O
		%-----------------------------------------------~~
		% Save parameters to parameter file
		function SaveParameters(obj)
			% Fetch params from object
			parameterNames = obj.ParamNames; 		% store parameter names
			parameterValues = obj.ParamValues; 		% store parameter values

			% Prompt user to select save path
			[filename, filepath] = uiputfile(['parameters_', datestr(now, 'yyyymmdd_HHMM'), '.mat'], 'Save current parameters to file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			% Save to file
			save([filepath, filename], 'parameterNames', 'parameterValues');
		end

		% Load parameters from parameter/experiment file
		function LoadParameters(obj, table_params, errorMessage)
			if nargin < 3
				errorMessage = '';
			end
			if nargin < 2
				table_params = [];
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

			[filename, filepath] = uigetfile('*.mat', 'Load parameters from file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			% Load file
			p = load([filepath, filename]);
			% If loaded file does not contain parameters
			if ~(isfield(p, 'parameterNames') && isfield(p, 'parameterValues'))
				% Ask the Grad Student if he wants to selcet another file instead
				obj.LoadParameters(table_params, 'The file you selected was not loaded because it does not contain experiment parameters. Select another file instead?')
			else
				% If loaded parameterNames contains a different number of parameters from arduino object
				if (length(p.parameterNames) ~= length(obj.ParamNames))
					obj.LoadParameters(table_params, 'The file you selected was not loaded because parameter names do not match the ones used by Arduino. Select another file instead?')	
				else
					paramHasSameName = cellfun(@strcmp, p.parameterNames, obj.ParamNames);
					% If loaded parameterNames names are different from arduino object
					if (sum(paramHasSameName) ~= length(paramHasSameName))			
						obj.LoadParameters(table_params, 'The file you selected was not loaded because the number of parameters does not match the ones used by Arduino. Select another file instead?')
					else
						% If all checks pass, upload to Arduino
						% Add all parameters to update queue
						for iParam = 1:length(p.parameterNames)
							obj.UpdateParams_AddToQueue(iParam, p.parameterValues(iParam))
						end
						% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
						obj.UpdateParams_Execute()
						% Update parameter display
						if ~isempty(table_params)
							table_params.Data = obj.ParamValues';
						end
					end
				end
			end
		end

		function SaveExperiment(obj)
			% Save everything to the experimental file
			save(obj.ExperimentFileName, 'obj');
		end

		function SaveAsExperiment(obj)
			[filename, filepath] = uiputfile(['exp_name_',datestr(now, 'yyyymmdd_HHMM'),'.mat'],'Save Experiment As New File');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			obj.ExperimentFileName = [filepath, filename];
			obj.SaveExperiment()
			obj.AutosaveEnabled = true;
		end

		function LoadExperiment(obj, errorMessage)
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

			[filename, filepath] = uigetfile('*.mat', 'Load previous experiment from file');
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			% Load file
			p = load([filepath, filename]);
			% If loaded file does not contain parameters
			if ~isfield(p, 'obj')
				% Ask the Grad Student if he wants to select another file instead
				obj.LoadExperiment('The file you selected was not loaded because it does not contain an ArduinoConnection object. Select another file instead?')
			% If p.obj is not the correct class
			elseif ~isa(p.obj, 'ArduinoConnection')
				obj.LoadExperiment('The file you selected was not loaded because it does not contain an ArduinoConnection object. Select another file instead?')
			else
				% If all checks are good then do the deed
				% Disable autosave first
				autosave = obj.AutosaveEnabled;
				obj.AutosaveEnabled = false;

				% Load relevant experiment data
				obj.EventMarkers 	= p.obj.EventMarkers;
				obj.ParamValues 	= p.obj.ParamValues;
				obj.Trials 			= p.obj.Trials;
				obj.TrialsCompleted = p.obj.TrialsCompleted;

				% Store the save path
				obj.ExperimentFileName = [filepath, filename];

				% Re-enable autosave if it was on
				obj.AutosaveEnabled = autosave;
			end
		end

		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%	Serial comms
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
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
					% New state entered - "$1" we've entered the second state.
					% Convert zero-based state indices (Arduino) to one-based indices (MATLAB)
					obj.State = str2num(strtrim(value)) + 1;

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
				case '`'
					% Result code returned, this is only expected once per trial
					% Store the results in as a new trial
					iTrial = obj.TrialsCompleted + 1;
					resultCode = str2num(strtrim(value)) + 1; % Convert to one-based index
					obj.Trials(iTrial).Code = resultCode;
					obj.Trials(iTrial).CodeName = obj.ResultCodeNames{resultCode};
					obj.Trials(iTrial).Parameters = obj.ParamValues;
					obj.TrialsCompleted = iTrial;
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

		% Trigger a soft restart on arduino
		function Reset(obj)
			obj.SendMessage('R')
		end

		% Terminate connection with arduino
		function Close(obj)
			fclose(obj.SerialConnection)
		end

		% Disconnect serial
		function Reconnect(obj)
			fclose(obj.SerialConnection)
			fopen(obj.SerialConnection)
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

			port = 'COM4';
		end
    end
end
