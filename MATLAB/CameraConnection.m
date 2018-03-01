classdef CameraConnection < handle
	properties
		VideoInput
		Source
		EventLog = struct([])
	end

	properties (Transient)	% These properties will be discarded when saving to file
	end

	methods
		function obj = CameraConnection(varargin)
			p = inputParser;
			addParameter(p, 'CameraID', [], @isnumeric);
			addParameter(p, 'Format', '', @ischar);
			addParameter(p, 'Filename', '', @ischar);
			addParameter(p, 'FileFormat', 'MPEG-4', @ischar);
			addParameter(p, 'FrameRate', [], @isnumeric); % Framerate for storage (not acquisition). i.e. 60fps acquisition + 30 fps storage == video playing at 1/2 speed
			addParameter(p, 'FrameGrabInterval', 1, @(x) isnumeric(x) && floor(x) == x); % Set to 2 to skip every other frame
			addParameter(p, 'TimestampInterval', 10, @(x) isnumeric(x) && floor(x) == x); % Set to 10 to register a timestamp every 10 frames
			parse(p, varargin{:});
			camID 				= p.Results.CameraID;
			camFormat 			= p.Results.Format;
			filename 			= p.Results.Filename;
			fileFormat 			= p.Results.FileFormat;
			frameRate 			= p.Results.FrameRate;
			frameGrabInterval 	= p.Results.FrameGrabInterval;
			timestampInterval 	= p.Results.TimestampInterval;

			hwinfo = imaqhwinfo('winvideo');

			if length(hwinfo.DeviceIDs) == 0
				error('No webcam connected!');
			end

			% If cameraID is not specified, prompt selection
			if isempty(camID)
				if length(hwinfo.DeviceIDs) == 1
					camID = 1; % If there's only one camera connected, don't bother with the prompt
				else
					[camID, ok] = listdlg(...
						'ListString', {hwinfo.DeviceInfo.DeviceName},...
						'SelectionMode', 'single',...
						'Name', 'Cameras',...
						'PromptString', 'Select camera:',...
						'ListSize', [250, 100]...
						);

					if ~ok
						error('No camera selected.')
					end
				end
			end


			% Select input format if unspecified
			if ~ismember(camFormat, hwinfo.DeviceInfo(camID).SupportedFormats) 
				% Get all available formats and max framerate for each format
				[formats, maxFrameRates] = obj.GetAvailableFormats(camID);

				formatDisplayNames = cellfun(@(a, b) [a, ' - ', num2str(round(b)), ' fps'], formats, num2cell(maxFrameRates), 'UniformOutput', false);

				[selection, ok] = listdlg(...
					'ListString', formatDisplayNames,...
					'SelectionMode', 'single',...
					'Name', 'Formats',...
					'PromptString', 'Select input format:',...
					'ListSize', [250, 100]...
					);
				if ~ok
					error('No format selected')
				end
				camFormat = formats{selection};
			end

			% Connect to camera
			obj.VideoInput = videoinput('winvideo', camID, camFormat);
			obj.Source = getselectedsource(obj.VideoInput);
			frameRates = set(obj.Source, 'FrameRate');

			if length(frameRates) > 1 
				[selection, ok] = listdlg(...
					'ListString', frameRates,...
					'SelectionMode', 'single',...
					'Name', 'Frame Rate',...
					'PromptString', 'Select frame rate:',...
					'ListSize', [250, 250]...
					);
				if ~ok
					error('No frame rate selected')
				end
				frameRate = frameRates{selection};
				set(obj.Source, 'FrameRate', frameRate);
			end

			% Set up video storage
			if isempty(filename)
				filename = datestr(now, 'yyyymmdd_HHMMSS');
			end

			if islogging(obj.VideoInput)
				error('Stop current recording first!')
			end

			% Don't stop acquisition till we call stop()
			obj.VideoInput.TriggerRepeat = Inf;

			% Set to 2 to grab every other frame, etc.
			obj.VideoInput.FrameGrabInterval = frameGrabInterval;

			% Register a timestamp every 10 frames.
			obj.VideoInput.FramesPerTrigger = timestampInterval;
			obj.VideoInput.TriggerFcn = @obj.OnTrigger;

			% Write video to disk
			obj.VideoInput.LoggingMode = 'disk';
			videoFile = VideoWriter(filename, fileFormat);
			if isempty(frameRate)
				frameRate = str2num(obj.Source.FrameRate);
			end
			videoFile.FrameRate = frameRate;
			obj.VideoInput.DiskLogger = videoFile;

			% Open preview window
			obj.Preview()
		end

		% Executed every 10 frames by default
		function OnTrigger(obj, src, evnt)
			iEvent = length(obj.EventLog) + 1;
			obj.EventLog(iEvent).Timestamp = evnt.Data.AbsTime;
			obj.EventLog(iEvent).FrameNumber = evnt.Data.FrameNumber;
		end

		% Open preview window
		function Preview(obj)
			preview(obj.VideoInput);
		end

		function ClosePreview(obj)
			closepreview(obj.VideoInput)
		end

		function videoFile = Start(obj)
			if islogging(obj.VideoInput)
				error('The grad student needs to end current recording before he restart.')
			end

			fprintf(1, 'Loggin video to disk...\n')

			start(obj.VideoInput)
		end

		% Stop recording
		function Stop(obj)
			if ~islogging(obj.VideoInput)
				error('The grad student needs to start recording before he can end it.')
			end

			stop(obj.VideoInput)

			% Wait until all frames are saved
			while (obj.VideoInput.DiskLoggerFrameCount ~= obj.VideoInput.FramesAcquired) 
				pause(.1)
			end

			fprintf(1, 'Video logging ended.\n')
		end

		% Terminates connection to camera
		function Delete(obj)
			if isvalid(obj.VideoInput)
				if islogging(obj.VideoInput)
					obj.Stop();
				end
				delete(obj.VideoInput)
			end
		end
	end

	methods (Static)
		function varargout = GetAvailableFormats(camID)
			hwinfo = imaqhwinfo('winvideo');

			formats = hwinfo.DeviceInfo(camID).SupportedFormats;

			if nargout <= 1
				varargout = {formats};
				return
			end

			fprintf(1, ['Checking available formats/framerates for ''', hwinfo.DeviceInfo(camID).DeviceName, ''' (', num2str(camID), '):\n'])

			for iFormat = 1:length(formats)
				vid = videoinput('winvideo', camID, formats{iFormat});
				frameRates = set(getselectedsource(vid), 'FrameRate');
				maxFrameRates(iFormat) = max(cellfun(@str2num, frameRates));
				delete(vid);
				fprintf(1, ['	', formats{iFormat}, ' - ', num2str(maxFrameRates(iFormat)), ' fps;\n'])
			end

			varargout = {formats, maxFrameRates};
		end

		function varargout = GetAvailableCameras()
			hwinfo = imaqhwinfo('winvideo');
			varargout = {length(hwinfo.DeviceIDs), hwinfo.DeviceInfo};
		end
	end
end
