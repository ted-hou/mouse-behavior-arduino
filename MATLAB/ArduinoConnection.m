%% ArduinoConnetion: serial port connection to an Arduino
classdef ArduinoConnection < handle

properties
	debugMode = false;
	connected = false;
	serialConnection = [];
	arduinoMessageString = '';
	messgeCallbackFcn = [];
end

methods
	function obj = ArduinoConnection(messgeCallbackFcn)
		obj.messgeCallbackFcn = messgeCallbackFcn;
		obj.arduinoMessageString = '';
		serialPort = [];
		arduinoPortName = obj.findFirstArduinoPort();

		if isempty(arduinoPortName)
		    disp('Can''t find serial port with Arduino')
		    return
		end

		% Define the serial port object.
		fprintf('Starting serial on port: %s\n', arduinoPortName);
		serialPort = serial(arduinoPortName);
		
		% Set the baud rate
		serialPort.BaudRate = 115200;
		
		% Add a callback function to be executed whenever 1 byte is available
		% to be read from the port's buffer.
		serialPort.BytesAvailableFcn = @(port, event)obj.readMessage(port, event);
		serialPort.BytesAvailableFcnMode = 'byte';
		serialPort.BytesAvailableFcnCount = 1;

		% Open the serial port for reading and writing.
		obj.serialConnection = serialPort;
		fopen(serialPort);

		% wait for Arduino startup
		% (we expect the Arduino to write 'S' to the Serial port upon starting up)
		fprintf('Waiting for Arduino startup')
		while (~obj.connected)
		    fprintf('.');
		    pause(0.5);
		end
		fprintf('\n')
	end


	function writeMessage(obj, messageChar, arg1, arg2)
	    stringToSend = sprintf('%s %d %d',messageChar, arg1, arg2);
	    obj.writeString(stringToSend);
	end

	function writeString(obj, stringToWrite)
	    fprintf(obj.serialConnection,'%s\n',stringToWrite, 'sync');

	    % DEBUGING
	    if obj.debugMode
	    	disp(['To Arduino: "', stringToSend, '"' ]);
	    end
	end

	function readMessage(obj, port, event)
	    %arduinoPort = port;
	    % As long as there are still bytes to be read in the buffer...
	    while (obj.serialConnection.BytesAvailable > 0)
	        charIn = char(fread(obj.serialConnection,1,'char'));

	        % on carriage return, call message callback and reset arduinoMessageString
	        if (charIn == sprintf('\n'))

	        	% we confirm that the connection was established once the first message is recieved
	            if (~obj.connected)
	            	obj.connected = true;
	            end
	            feval(obj.messgeCallbackFcn, obj.arduinoMessageString);
	            obj.arduinoMessageString = '';
	            return % process at most one message per function call to minimize time of call

	        % otherwise keep accumulating characters into arduinoMessageString
	        elseif (charIn ~= sprintf('\r'))
	            obj.arduinoMessageString = [obj.arduinoMessageString charIn];
	        end
	    end
	end

	function fclose(obj)
		fclose(obj.serialConnection)
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
		    % Find connected serial devices and clean up the output
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
		    % Compare friendly name entries with connected ports and generate output
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
