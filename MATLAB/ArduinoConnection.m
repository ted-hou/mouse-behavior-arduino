%% ArduinoConnection: serial port connection to an Arduino
classdef ArduinoConnection < handle
	properties
		StateNames = {}
		StateCanUpdateParams = logical([])
		ParamNames = {}
		ResultCodeNames = {}
		EventMarkers = []
		EventMarkersUntrimmed = []
		EventMarkerNames = {}
		Trials = struct([])
		ExperimentFileName = ''			% Contains 'C://path/filename.mat'
		Cameras = struct([])
		Camera = []
        AnalogOutputEvents = []
        AnalogOutputResolution = NaN
	end

	properties (SetObservable, AbortSet)
		ParamValues = []
		TrialsCompleted = 0
	end

	properties (Transient)	% These properties will be discarded when saving to file
		DebugMode = true
		Connected = false
		AutosaveEnabled = false
		SerialConnection = []
		State = []
		ParamUpdateQueue = []
		EventMarkersBuffer = []
		Listeners
    end

    properties (Transient, Hidden)
        AnalogOutputEventIndex = 0
    end

	events
		StateChanged
	end

	methods
		function obj = ArduinoConnection(arduinoPortName)
			if strcmp(arduinoPortName, '/offline')
				obj.Connected = false;
				obj.LoadExperiment()
			else
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
				serialPort.BytesAvailableFcn = @obj.OnMessageReceived;
				serialPort.BytesAvailableFcnMode = 'terminator';

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

		end

		%-----------------------------------------------~~
		%		File I/O
		%-----------------------------------------------~~
		% Save parameters to parameter file
		function varargout = SaveParameters(obj)
			% Fetch params from object
			parameterNames = obj.ParamNames; 		% store parameter names
			parameterValues = obj.ParamValues; 		% store parameter values

			% Prompt user to select save path
			if ~obj.IsMotorController()
				[filename, filepath] = uiputfile(['parameters_', datestr(now, 'yyyymmdd'), '.mat'], 'Save current parameters to file');
			else
				[filename, filepath] = uiputfile(['parameters_', datestr(now, 'yyyymmdd'), '_motor.mat'], 'Save current parameters to file');
			end
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				varargout = {''};
				return
			end
			% Save to file
			save([filepath, filename], 'parameterNames', 'parameterValues');

			varargout = {[filepath, filename]};
		end

		% Load parameters from parameter/experiment file
		function varargout = LoadParameters(obj, errorMessage)
			varargout = {''};
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
				obj.LoadParameters('The file you selected was not loaded because it does not contain experiment parameters. Select another file instead?')
			else
				% If loaded parameterNames contains a different number of parameters from arduino object
				if (length(p.parameterNames) ~= length(obj.ParamNames))
					obj.LoadParameters('The file you selected was not loaded because parameter names do not match the ones used by Arduino. Select another file instead?')	
				else
					paramHasSameName = cellfun(@strcmp, p.parameterNames, obj.ParamNames);
					% If loaded parameterNames names are different from arduino object
					if (sum(paramHasSameName) ~= length(paramHasSameName))			
						obj.LoadParameters('The file you selected was not loaded because the number of parameters does not match the ones used by Arduino. Select another file instead?')
					else
						% If all checks pass, upload to Arduino
						% Add all parameters to update queue
						for iParam = 1:length(p.parameterNames)
							obj.UpdateParams_AddToQueue(iParam, p.parameterValues(iParam))
						end
						% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
						obj.UpdateParams_Execute()
						% Return file path
						varargout = {[filepath, filename]};
					end
				end
			end
		end

		function SaveExperiment(obj)
			% Save everything to the experimental file
			save(obj.ExperimentFileName, 'obj');
		end

		function SaveAsExperiment(obj)
			if ~obj.IsMotorController()
				[filename, filepath] = uiputfile(['exp_name_',datestr(now, 'yyyymmdd'),'.mat'],'Save Experiment As New File');
			else
				[filename, filepath] = uiputfile(['exp_name_',datestr(now, 'yyyymmdd'),'_motor.mat'],'Save Experiment As New File');
			end
			% Exit if no file selected
			if ~(ischar(filename) && ischar(filepath))
				return
			end
			obj.ExperimentFileName = [filepath, filename];
			obj.SaveExperiment()
			% If online, enable autosave
			if obj.Connected
				obj.AutosaveEnabled = true;
				fprintf('Autosave enabled. Saving to %s after each trial.\n', obj.ExperimentFileName)
			else
				obj.AutosaveEnabled = false;
			end
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
			% If loaded file does not contain experiment
			if ~isfield(p, 'obj')
				% Ask the Grad Student if he wants to select another file instead
				obj.LoadExperiment('The file you selected was not loaded because it does not contain an ArduinoConnection object. Select another file instead?')
			% If p.obj is not the correct class
			elseif ~isa(p.obj, 'ArduinoConnection')
				obj.LoadExperiment('The file you selected was not loaded because it does not contain an ArduinoConnection object. Select another file instead?')
			else
				% If all checks are good then do the deed
				% Disable autosave first
				obj.AutosaveEnabled = false;

				% If we're doing this offline (w/o arduino), also load experiment setup
				if ~obj.Connected
					obj.StateNames = p.obj.StateNames;
					obj.StateCanUpdateParams = p.obj.StateCanUpdateParams;
					obj.ParamNames = p.obj.ParamNames;
					obj.ParamValues = p.obj.ParamValues;
					obj.ResultCodeNames = p.obj.ResultCodeNames;
					obj.EventMarkerNames = p.obj.EventMarkerNames;
					obj.StateNames = p.obj.StateNames;
				end

				% Load relevant experiment data
				obj.EventMarkers 			= p.obj.EventMarkers;
				obj.EventMarkersUntrimmed 	= p.obj.EventMarkersUntrimmed;
				obj.Trials 					= p.obj.Trials;
				obj.TrialsCompleted 		= p.obj.TrialsCompleted;

				% Load camera stuff if available
				if ~isempty(p.obj.Cameras)
					obj.Cameras = p.obj.Cameras;
				end

				% Add all parameters to update queue
				for iParam = 1:length(p.obj.ParamValues)
					obj.UpdateParams_AddToQueue(iParam, p.obj.ParamValues(iParam))
				end
				% Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
				obj.UpdateParams_Execute()

				% Store the save path
				obj.ExperimentFileName = [filepath, filename];

				% Re-enable autosave if online
				if obj.Connected
					obj.AutosaveEnabled = true;
				end
			end
		end

		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		%	Serial comms
		%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
		function SendMessage(obj, messageChar, arg1, arg2)
			% Do nothing unless connected
			if isempty(obj.SerialConnection)
				return
			end

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
			fprintf(obj.SerialConnection, '%s#', stringToWrite, 'sync');
		end

		function OnMessageReceived(obj, ~, ~)
			if (~obj.Connected)
				obj.Connected = true;
			end

			% Remove leading and trailing white spaces
			messageString = fgetl(obj.SerialConnection);
			messageString = strtrim(messageString);

			% First character contains the command
			command = messageString(1);
			if length(messageString) > 1
				value = messageString(2:end);
			end

			switch command
                case '$'
					% New state entered - "$1" we've entered the second state.
					% New state entered - "$2 1" we've entered the second state on machine 2.
					% Convert zero-based state indices (Arduino) to one-based indices (MATLAB)
					subStrings = strsplit(strtrim(value), ' ');
                    if length(subStrings) == 1
                        index = 1;
                        state = str2double(subStrings{1}) + 1;
                        obj.SetState(state, index);
                    else
                        index = str2double(subStrings{1}) + 1;
                        state = str2double(subStrings{2}) + 1;
                        obj.SetState(state, index);
                    end

					% Trigger StateChanged Event
					notify(obj, 'StateChanged')

					% Debug message
					if obj.DebugMode
                        fprintf('\tSTATE_%i: %s\n', index, obj.StateNames{obj.GetState(index)})
					end
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
                    disp()
					subStrings = strsplit(strtrim(value), ' ');
					eventCode = str2num(subStrings{1}) + 1; % Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					timeStamp = str2num(subStrings{2});
					absTime = now;
					obj.EventMarkersBuffer = [obj.EventMarkersBuffer; eventCode, timeStamp, absTime];
					obj.EventMarkersUntrimmed = [obj.EventMarkersUntrimmed; eventCode, timeStamp, absTime];

					% Debug message
					if obj.DebugMode
						fprintf('		EVENT: %s - %d\n', obj.EventMarkerNames{eventCode}, timeStamp)
					end
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

					% Move eventMarkers from this trial into permanent storage
					obj.EventMarkers = [obj.EventMarkers; obj.EventMarkersBuffer];
					obj.EventMarkersBuffer = []; % Clear buffer

					% Store trial results in as a new trial
					iTrial = obj.TrialsCompleted + 1;
					resultCode = str2num(strtrim(value)) + 1; % Convert to one-based index
					obj.Trials(iTrial).Code = resultCode;
					obj.Trials(iTrial).CodeName = obj.ResultCodeNames{resultCode};
					obj.Trials(iTrial).Parameters = obj.ParamValues;
					obj.TrialsCompleted = iTrial;

					% Debug message
					if obj.DebugMode
						fprintf('RESULT: %s\n', obj.ResultCodeNames{resultCode})
					end
				case '*'
					% Arduino sent error code interpretations - "# 0 ERROR_LEVER_NOT_PRESSED" means error code -1
					subStrings = strsplit(strtrim(value), ' ');
					% Convert zero-based indices (Arduino) to one-based indices (MATLAB)
					codeId = str2num(subStrings{1}) + 1;
					% Register parameter name and value
					obj.ResultCodeNames{codeId} = subStrings{2};
				case '~'
					fprintf('\nUp and running.\n')
                case ':'
					% Arduino sent analogWriteResolution - ": 12"
					subStrings = strsplit(strtrim(value), ' ');
					obj.AnalogOutputResolution = str2num(subStrings{1});
                    if ~isempty(obj.AnalogOutputEvents)
                        warning('AnalogOutputEvents is not empty, but is being overriden. If you are reading this, arduino probably sent the ":" symbol more than once')
                    end
                    obj.AnalogOutputEventIndex = 0;
                    obj.AnalogOutputEvents = NaN(100, 4);
                case '%'
					% Arduino sent analogOutputEvent - "% channel value timestamp"
					% Arduino sent an event code and its timestamp - "& 0 100"
					subStrings = strsplit(strtrim(value), ' ');
					channel = str2num(subStrings{1}); % Both arduino and matlab use 1 based index, i.e., channel 1 or 2
					value = str2num(subStrings{2});
                    timestamp = str2num(subStrings{3});
					absTime = now;
                    obj.AnalogOutputEventIndex = obj.AnalogOutputEventIndex + 1;
                    
                    % Allocate a bigger array if necessary
                    if obj.AnalogOutputEventIndex > size(obj.AnalogOutputEvents, 1)
                        obj.AnalogOutputEvents = vertcat(obj.AnalogOutputEvents, NaN(size(obj.AnalogOutputEvents))); % Woah you just walk around with that thing?
                    end

					obj.AnalogOutputEvents(obj.AnalogOutputEventIndex, :) = [channel, value, timestamp, absTime];

					% Debug message
					if obj.DebugMode
						fprintf('		ANALOG_OUT: Channel %i set to %i.\n', channel, value)
					end
				otherwise
					% Arduino sent a message
					fprintf('%s\n', messageString)
			end
		end

		% Called each time a state changes
		function OnStateChanged(obj, ~, ~)
			% If new state allows parameter update, execute the update queue
			if obj.StateCanUpdateParams(obj.GetState())
				obj.UpdateParams_Execute()
			end
        end

        function SetState(obj, state, index)
            if nargin < 3
                index = 1;
            end
            obj.State(index) = state;
        end

        function state = GetState(obj, index)
            if nargin < 2
                index = 1;
            end

            if isempty(obj.State)
                state = -1;
            else
                state = obj.State(index);
            end
        end

		% Read a parameter
		function varargout = GetParam(obj, index)
			p = inputParser;
			addRequired(p, 'Index', @(x) isnumeric(x) || ischar(x));
			parse(p, index);
			index = p.Results.Index;

			if ischar(index)
				index = find(strcmpi(index, obj.ParamNames));
			end

			if isempty(index)
				varargout = {[]};
			else
				index = index(1);
				varargout = {obj.ParamValues(index)};
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
			if obj.StateCanUpdateParams(obj.GetState()) && ~isempty(obj.ParamUpdateQueue) 
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
			obj.EventMarkersBuffer = [];
		end

		% Trigger a soft restart on arduino
		function Reset(obj)
			obj.EventMarkers = [];
			obj.EventMarkersUntrimmed = [];
			obj.EventMarkersBuffer = [];
			obj.Trials = struct([]); 
			obj.TrialsCompleted = 0;
			obj.State = [];

			obj.SendMessage('R')
		end

		% Terminate connection with arduino
		function Close(obj)
			if ~isempty(obj.SerialConnection)
				fclose(obj.SerialConnection);
			end
		end

		% Disconnect serial
		function Reconnect(obj)
			if ~isempty(obj.SerialConnection)
				fclose(obj.SerialConnection);
				fopen(obj.SerialConnection);
			end
		end

		% Send optogenetic pulse train
		function success = OptogenStim(obj)
			if obj.OptogenStimAvailable()
				if obj.DebugMode
                	disp('Sent stim command')
                end
				obj.SendMessage('L')
                success = true;
            else
                warning('Cannot stim')
                success = false;
            end
		end

		function canStim = OptogenStimAvailable(obj)
			if obj.Connected
				if strcmpi(obj.StateNames{obj.GetState()}, 'IDLE')
					canStim = true;
				else
					canStim = false;
				end
			else
				canStim = false;
			end
		end

		% Motor
		function b = IsMotorController(obj)
			if obj.Connected
				if any(strcmpi(obj.ParamNames, 'UNITS_PER_REV')) || any(strcmpi(obj.ParamNames, 'MOTOR1_UNITS_PER_REV'))
					b = true;
				else
					b = false;
				end
			else
				b = false;
			end
		end

		function ZeroMotor(obj)
			if obj.CanZeroMotor()
				obj.SendMessage('Z');
			end
		end

		function b = CanZeroMotor(obj)
			if obj.IsMotorController() && all(strcmpi(obj.StateNames(obj.State), 'IDLE'))
				b = true;
			else
				b = false;
			end
		end

		function MoveMotor(obj, motorIndex, distance)
			if obj.CanMoveMotor()
				obj.SendMessage(sprintf('M %i %.4f', motorIndex, distance));
			end
		end

		function b = CanMoveMotor(obj)
			if obj.IsMotorController() && all(strcmpi(obj.StateNames(obj.State), 'IDLE'))
				b = true;
			else
				b = false;
			end
		end

		function LockMotor(obj, lock)
			if obj.CanLockMotor()
				if lock
					obj.SendMessage('L');
				else
					obj.SendMessage('U');
				end
			end
		end

		function b = CanLockMotor(obj)
			if obj.IsMotorController() && all(strcmpi(obj.StateNames(obj.State), 'IDLE'))
				b = true;
			else
				b = false;
			end
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
					if contains(portName, 'tty.usbmodem')
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
						com = str2num(coms{i}(4:end));
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
					if contains(portFriendlyName, 'Arduino')
						port = portName;
						return
					end
				end
			end

			port = 'COM4';
		end
	end
end
