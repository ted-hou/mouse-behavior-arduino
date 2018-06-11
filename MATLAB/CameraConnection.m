%% CameraConnection: records footage from a windows webcam
classdef CameraConnection < handle
	properties
		EventLog = struct([])
		Params
	end

	properties (Transient)	% These properties will be discarded when saving to file
		VideoInput
		Source
		Rsc
	end

	methods
		function obj = CameraConnection(varargin)
			p = inputParser;
			addParameter(p, 'CameraID', [], @isnumeric);
			addParameter(p, 'Format', '', @ischar);
			addParameter(p, 'Filename', '', @ischar);
			addParameter(p, 'FileFormat', 'MPEG-4', @ischar);
			addParameter(p, 'FrameRate', 30, @isnumeric); % Framerate for storage (not acquisition). i.e. 60fps acquisition + 30 fps storage == video playing at 1/2 speed
			addParameter(p, 'FrameGrabInterval', 1, @(x) isnumeric(x) && floor(x) == x); % Set to 2 to skip every other frame
			addParameter(p, 'TimestampInterval', 10, @(x) isnumeric(x) && floor(x) == x); % Set to 10 to register a timestamp every 10 frames
			addParameter(p, 'DialogPosition', [], @isnumeric);
			parse(p, varargin{:});
			camID 				= p.Results.CameraID;
			camFormat 			= p.Results.Format;
			filename 			= p.Results.Filename;
			fileFormat 			= p.Results.FileFormat;
			frameRate 			= p.Results.FrameRate;
			frameGrabInterval 	= p.Results.FrameGrabInterval;
			timestampInterval 	= p.Results.TimestampInterval;
			dialogPosition 		= p.Results.DialogPosition;

			hwinfo = imaqhwinfo('winvideo');

			if isempty(hwinfo.DeviceIDs)
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
				% [formats, maxFrameRates] = obj.GetAvailableFormats(camID);
				% formatDisplayNames = cellfun(@(a, b) [a, ' - ', num2str(round(b)), ' fps'], formats, num2cell(maxFrameRates), 'UniformOutput', false);
				formats = obj.GetAvailableFormats(camID);
				formatDisplayNames = formats;

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
				set(obj.Source, 'FrameRate', frameRates{selection});
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

			% Disk logging parameters
			obj.VideoInput.LoggingMode = 'disk';
			obj.Params.Filename = filename;
			obj.Params.FileFormat = fileFormat;
			obj.Params.FrameRate = frameRate;

			% Create camera control dialog
			obj.CreateDialog_CameraControl(dialogPosition);

			% Open preview window
			obj.Preview();
		end

		function CreateDialog_CameraControl(obj, position)
			if nargin < 2
				position = [20, 550];
			end

			% If object already exists, show window
			if isfield(obj.Rsc, 'CameraControl')
				if isvalid(obj.Rsc.CameraControl)
					figure(obj.Rsc.CameraControl)
					return
				end
			end

			% Size and position of controls
			buttonWidth = 50; % Width of buttons
			buttonHeight = 20; % Height of 
			ctrlSpacing = 10; % Spacing between ui elements

			% Create the dialog
			hwinfo = imaqhwinfo('winvideo');
			dlg = dialog(...
				'Name', hwinfo.DeviceInfo(obj.VideoInput.DeviceID).DeviceName,...
				'WindowStyle', 'normal',...
				'Units', 'pixels',...
				'Resize', 'off',...
				'Visible', 'off'... % Hide until all controls created
			);
			% Store the dialog handle
			obj.Rsc.CameraControl = dlg;

			% Preview button
			hButtonPreview = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'String', 'Preview',...
				'Callback', {@(~, ~) obj.Preview},...
				'Position', [ctrlSpacing, ctrlSpacing, buttonWidth, buttonHeight]);
			hPrev = hButtonPreview;

			% Start button
			hButtonStart = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'String', 'Start',...
				'TooltipString', 'Start recording to disk.',...
				'Callback', {@(~, ~) obj.Start},...
				'Position', hPrev.Position);
			hPrev = hButtonStart;
			hPrev.Position(1) = hPrev.Position(1) + hPrev.Position(3) + ctrlSpacing;
 
			% Record button
			hButtonStop = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'String', 'Stop',...
				'TooltipString', 'Stop recording to disk.',...
				'Callback', {@(~, ~) obj.Stop},...
				'Position', hPrev.Position);
			hPrev = hButtonStop;
			hPrev.Position(1) = hPrev.Position(1) + hPrev.Position(3) + ctrlSpacing;
 
			% Terminate button
			hButtonTerminate = uicontrol(...
				'Parent', dlg,...
				'Style', 'pushbutton',...
				'String', 'Terminate',...
				'TooltipString', 'Stop recording to disk.',...
				'Callback', {@(~, ~) obj.Delete},...
				'Position', hPrev.Position);
			hPrev = hButtonTerminate;
			hPrev.Position(1) = hPrev.Position(1) + hPrev.Position(3) + ctrlSpacing;
 
			% Resize dialog
			dlg.Position(3:4) = [5*ctrlSpacing + 4*buttonWidth, 2*ctrlSpacing + buttonHeight];
			if ~isempty(position)
				dlg.OuterPosition(1:2) = position;
			end

			% Unhide dialog now that all controls have been created
			dlg.Visible = 'on';
		end

		function SaveAs(obj, filename)
			if nargin < 2
				filename = obj.Params.Filename;
			end

			if isempty(filename)
				filename = datestr(now, 'yyyymmdd_HHMMSS');
			end

			obj.Params.Filename = filename;

			% Delete existing video file
			if ~isempty(obj.VideoInput.DiskLogger)
				delete(obj.VideoInput.DiskLogger)
			end

			% Write video to disk
			videoFile = VideoWriter(obj.Params.Filename, obj.Params.FileFormat);
			if isempty(obj.Params.FrameRate)
				obj.Params.FrameRate = str2double(obj.Source.FrameRate);
			end
			videoFile.FrameRate = obj.Params.FrameRate;
			obj.VideoInput.DiskLogger = videoFile;
		end

		% Executed every 10 frames by default
		function OnTrigger(obj, ~, evnt)
			iEvent = length(obj.EventLog) + 1;
			obj.EventLog(iEvent).Timestamp = datenum(evnt.Data.AbsTime);
			obj.EventLog(iEvent).FrameNumber = evnt.Data.FrameNumber;
		end

		% Open preview window
		function varargout = Preview(obj)
			hImage = preview(obj.VideoInput);
			hFigure = ancestor(hImage, 'figure');

			obj.Rsc.PreviewWindow = hFigure;
			obj.Rsc.PreviewImage = hImage;

			varargout = {hImage, hFigure};
		end

		function ClosePreview(obj)
			closepreview(obj.VideoInput)
		end

		function Start(obj)
			if islogging(obj.VideoInput)
				error('The grad student needs to end current recording before he restart.')
			end

			if isempty(obj.VideoInput.DiskLogger)
				obj.SaveAs()
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

			if isvalid(obj.Rsc.CameraControl)
				delete(obj.Rsc.CameraControl)
			end

			fprintf(1, 'Camera connection closed.\n')
		end

		function Plot(obj)
			figure();
			subplot(1, 2, 1)
			plot(arrayfun(@(x) datetime(x, 'ConvertFrom', 'datenum'), [obj.EventLog.Timestamp]), [obj.EventLog.FrameNumber]);
			xlabel('Time')
			ylabel('Frame Number')
			subplot(1, 2, 2);
			datetimes = arrayfun(@(x) datetime(x, 'ConvertFrom', 'datenum'), [obj.EventLog.Timestamp]);
			durations = seconds(diff(datetimes));
			frames = [obj.EventLog(2:end).FrameNumber] - [obj.EventLog(1:end - 1).FrameNumber];
			frameRates = frames./durations;
			plot(datetimes(1:end - 1) + diff(datetimes), frameRates);
			xlabel('Time')
			ylabel('Frame rate')
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

            maxFrameRates = zeros(1, length(formats));
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
