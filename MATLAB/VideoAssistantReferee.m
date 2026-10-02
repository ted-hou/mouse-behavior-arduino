classdef VideoAssistantReferee < handle
    %VIDEOASSISTANTREFEREE
    %   to make sure mouse does not lick during reach trials, and vice versa

    properties
        Params = struct(ThresholdMin=[10, 10, 10], ThresholdMax=[50, 50, 50], NFramesBefore=7, NFramesAfter=7, MinLikelihood=0.3)
        Arduino
        Camera
        SourceType
        MemMapFilePath
        MemMapFile
        BodypartNames
        CurrentPose
        CurrentFrameIdx = zeros(1, 'uint32') % This corresponds to CurrentPose, but should lag behind actual FramesAcquired by 1
        CurrentAbsTime = NaT(1, Format='uuuu-MM-dd HH:mm:ss.SSS'); % This corresponds to CurrentFrameIdx, but should lag behind actual FramesAcquired by 1
        CurrentSpeed
        CurrentResult = -1 % -1: none; 0: var-no-goal; 1: var-goal-stands
        Buffer = struct(FrameIdx=[], AbsTime=[], Pose=[]) % (BufferLength x 1, BufferLength x 1, nBodyparts x 3 x BufferLength)
        BufferLength = 0; % 300 frames ~= 10s
        CurrentBufferIdx = 0;
        RequestFrameIdx  = 0; % This is when Arduino sent '?', ususally at movement time
        RequestPending = false;
    end

    properties (Hidden)
        TestVideo % For testing on pre-recorded videos only
        TestEvents % For testing on pre-recorded videos only
    end

    methods
        function obj = VideoAssistantReferee(source, varargin)
            p = inputParser();
            p.addRequired('Source', @(x) isa(x, 'ArduinoConnection') || isa(x, 'CameraConnection') || ischar(x) || isstring(x))
            p.addParameter('CamId', 3, @(x) isscalar(x) && isnumeric(x)) % Use left camera as default
            p.addParameter('BodypartNames', ["Jaw", "HandL", "HandR"], @(x) isstring(x) && length(x)==3);
            p.addParameter('BufferLength', 300, @(x) isnumeric(x) & isscalar(x)) % 300 at 30fps = 10s
            p.addParameter('MemMapFolder', "C:\MATLAB_MEMMAP\VideoAssistantReferee"); % ""
            p.parse(source, varargin{:})
            
            if isa(source, 'ArduinoConnection')
                obj.Arduino = p.Results.Arduino;
                obj.Camera = arduino.Cameras(p.Results.camId).Camera;
                obj.TestVideo = [];
                obj.SourceType = "Arduino";
            elseif isa(source, 'CameraConnection')
                obj.Arduino = [];
                obj.Camera = source;
                obj.TestVideo = [];
                obj.SourceType = "Camera";
            elseif isfile(source)
                obj.Arduino = [];
                obj.Camera = [];
                obj.TestVideo = VideoReader(source);
                obj.SourceType = "TestVideo";
            else
                error("Invalid source %s", source)
            end
            
            obj.BodypartNames = p.Results.BodypartNames;
            obj.CurrentPose = zeros(length(obj.BodypartNames), 3, 'single');

            obj.initBuffer(p.Results.BufferLength);

            switch obj.SourceType
                case {"Arduino", "Camera"}
                    obj.Camera.VideoInput.LoggingMode = 'disk&memory';
                case "TestVideo"
            end
            obj.MemMapFilePath = obj.createMemMapFile(p.Results.MemMapFolder); % This changes logging mode from 'disk' to 'disk&memory'!

            if obj.SourceType == "Arduino"
                if ~isfield(obj.Arduino.Listeners, 'VAR_VARRequested') || ~isvalid(obj.Arduino.Listeners.VAR_VARRequested)
                    obj.Arduino.Listeners.VAR_VARRequested = addlistener(obj.Arduino, 'VARRequested', @obj.onVARRequested);
                end                
            end
        end

        % Create our own preview window for video, drawing DLC-live results
		function preview(obj)
			fig = figure;
			ax = axes(fig);
			hImage = image(ax, zeros(480, 640, 3));
            preview(obj.Camera.VideoInput, hImage);

			setappdata(hImage, 'UpdatePreviewWindowFcn', @obj.updatePreview);
        end

        function [pose, idx, t] = fetchBuffer(obj, nFrames)
            sel = obj.CurrentBufferIdx-nFrames+1 : obj.CurrentBufferIdx;
            sel(sel<=0) = sel(sel<=0) + obj.BufferLength;
            pose = obj.Buffer.Pose(:, :, sel);
            idx = obj.Buffer.FrameIdx(sel);
            t = obj.Buffer.AbsTime(sel);
        end
    end

    % Private methods
    methods (Access={})
        function memMapFilePath = createMemMapFile(obj, folder)
            % Create memmapfile
            % Create the folder if needed
            if ~exist(folder, 'dir')
                mkdir(folder)
            end
            memMapFilePath = fullfile(folder, "memmap_var.dat");
            if exist(memMapFilePath, 'file')
                delete(memMapFilePath);
            end

            % Create the file
            switch obj.SourceType
                case {"Arduino", "Camera"}
                    sz = obj.Camera.VideoInput.VideoResolution;
                    w = sz(1);
                    h = sz(2);
                case "TestVideo"
                    w = obj.TestVideo.Width;
                    h = obj.TestVideo.Height;
            end
            headerSize = 4; % uint32 for frame index
            frameSize = w*h*3; % uint8, 3 color channels
            poseSize = 3*4; % 3 single floats per bodypart (there should be 3: jaw, lefthand, righthand)

            % Create/Zero out the shared binary file (Header: 1 uint32 for frame index + image data)
            totalBytes = headerSize + frameSize + length(obj.BodypartNames)*poseSize; 
            fileID = fopen(memMapFilePath, 'w');
            fwrite(fileID, zeros(totalBytes, 1, 'uint8'));
            fclose(fileID);

            obj.MemMapFile = memmapfile(memMapFilePath, Writable=true, ...
                Format={ ...
                    'uint32', [1, 1], 'idx'; ... frame index
                    'uint8', [h, w, 3], 'frame'; ... image
                    'single', [length(obj.BodypartNames), 3], 'pose'; ... each row is [x, y, likelihood] for a different bodypart (hand; jaw)
                });

            switch obj.SourceType
                case {"Arduino", "Camera"}
                    obj.Camera.VideoInput.FramesAcquiredFcn = @obj.onFrameAcquired;
                    obj.Camera.VideoInput.FramesAcquiredFcnCount = 1;
                case "TestVideo"
        			fig = figure;
        			ax = axes(fig);
        			hImage = image(ax, zeros(480, 640, 3));
                    axis(ax, 'image')
                    ax.XAxis.Visible = false;
                    ax.YAxis.Visible = false;

                    hTimer = timer(Period=1/30, ExecutionMode="fixedDelay", BusyMode="queue");
                    hTimer.TimerFcn = @(~, ~) obj.onFrameAcquiredFromVideo(hImage);
                    hTimer.start();
            end

            fprintf("Created memmapfile at %s...\n", memMapFilePath);
        end

        % Call back used when a frame is read acquired from camera
		function onFrameAcquired(obj, vid, ~)
			framesAvailable = vid.FramesAvailable;
			if framesAvailable > 0
				% Safely extract data and timestamps from memory without disrupting the disk write
				[data, ~, ~] = getdata(vid, framesAvailable);

				% Write frame index and image to memmap'd file
				mmf = obj.MemMapFile;
                newFrameIdx = uint32(vid.FramesAcquired);
				frame = data(:, :, :, end);
				if ~isempty(frame)
					mmf.Data.frame = frame;
					mmf.Data.idx = newFrameIdx; % idx will be incremented
				end
				% Read results back from Python (race conditions exist, to fix: use a handshake, or try tcp/ip instead of memmap) but honestly it probably does not matter for 30fps:
				% MATLAB gets new frame from cam (30Hz) -> MATLAB sends a new frame and reads last pose estimate from Python -> Python sends back new pose data
				obj.CurrentPose = mmf.Data.pose;
				% fprintf("Frame %i, x=%.2f, y=%.2f, llh=%.2f\n", mmf.Data.idx, obj.Pose(1), obj.Pose(2), obj.Pose(3))

                % Write to buffer
                obj.addToBuffer(obj.CurrentFrameIdx, obj.CurrentAbsTime, obj.CurrentPose);
                obj.CurrentFrameIdx = newFrameIdx;
                obj.CurrentAbsTime = datetime('now');

                % Check whether a spurious movement occurred (during WARIFORTOUCH and TIMEOUT)
                if ismember(obj.Arduino.StateNames{obj.Arduino.GetState()}, {'WAITFORTOUCH', 'TIMEOUT'})
                    [isClear, obj.CurrentSpeed] = runVAR(obj, obj.Params.NFramesOnging);
                    if ~isClear
                        obj.Arduino.SendMessage('V 0');
                    end
                end

                % Check whether a spurious movement occurred (on arduino request, wait a few frames, then check)
                if obj.RequestPending && obj.CurrentFrameIdx >= obj.RequestFrameIdx + obj.Params.NFramesAfter
                    obj.RequestPending = false;
                    [isClear, obj.CurrentSpeed] = runVAR(obj, obj.Params.NFramesAfter + 1 + obj.Params.NFramesBefore);
                    obj.Arduino.SendMessage(sprintf('V %i', isClear));
                    obj.CurrentResult = isClear;
                else
                    obj.CurrentResult = -1;
                end
			end
        end

        % Call back used when a frame is read from file (for TESTING)
        function onFrameAcquiredFromVideo(obj, hImage)
            if hasFrame(obj.TestVideo)
                % Safely extract data and timestamps from memory without disrupting the disk write
                t = obj.TestVideo.CurrentTime;
                frame = readFrame(obj.TestVideo);

                % Write frame index and image to memmap'd file
                mmf = obj.MemMapFile;
                newFrameIdx = uint32(round(t*obj.TestVideo.FrameRate));
                if ~isempty(frame)
                    mmf.Data.frame = frame;
                    mmf.Data.idx = newFrameIdx; % idx will be incremented
                end
                % Read results back from Python (race conditions exist, to fix: use a handshake, or try tcp/ip instead of memmap) but honestly it probably does not matter for 30fps:
                % MATLAB gets new frame from cam (30Hz) -> MATLAB sends a new frame and reads last pose estimate from Python -> Python sends back new pose data
                obj.CurrentPose = mmf.Data.pose;
                % fprintf("Frame %i, x=%.2f, y=%.2f, llh=%.2f\n", mmf.Data.idx, obj.Pose(1), obj.Pose(2), obj.Pose(3))

                % Write to buffer
                obj.addToBuffer(obj.CurrentFrameIdx, obj.CurrentAbsTime, obj.CurrentPose);
                obj.CurrentFrameIdx = newFrameIdx;
                obj.CurrentAbsTime = datetime('now');

                % Calculate recent movement magnitudes
                [pose, ~, t] = obj.fetchBuffer(obj.Params.NFramesBefore + obj.Params.NFramesAfter + 1); % 15 frames ~ 0.5s
                p = pose(:, 3, :);
                x = pose(:, 1:2, :);
                x(p<obj.Params.MinLikelihood) = NaN;
                dx = diff(x, 1, 3); % x,y displacement
                dx = squeeze(sqrt(sum(dx(:, :, :).^2, 2))); % euclidean
                dt = seconds(diff(t));
                speed = [NaN(3, 1), dx./dt];

                % Check for spurious movements when a TestEvent occurs
                result = -1;
                hasSpuriousMovement = false;
                if ~isempty(obj.TestEvents)
                    for trialType = ["press", "lick"]
                        if any(obj.TestEvents.(trialType) == obj.CurrentFrameIdx - obj.Params.NFramesAfter)
                            fprintf("%s", trialType)
                            switch trialType
                                case "press"
                                    % Check for unwanted jaw movements
                                    if any(speed(1, :) > obj.Params.ThresholdMax(1))
                                        hasSpuriousMovement = true;
                                    end
                                case "lick"
                                    % Check for unwanted hand movements
                                    if any(speed(2, :) > obj.Params.ThresholdMax(2)) || any(speed(3, :) > obj.Params.ThresholdMax(3))
                                        hasSpuriousMovement = true;
                                    end
                            end
                            fprintf("hasSpuriousMovement=%s\n", string(hasSpuriousMovement))
                            if hasSpuriousMovement
                                result = 0;
                            else
                                result = 1;
                            end
                            break
                        end
                    end
                end

                obj.CurrentSpeed = speed(:, end);
                obj.CurrentResult = result;

                % Update preview
                if obj.SourceType == "TestVideo"
                    event = struct(Data=frame);
                    obj.updatePreview([], event, hImage);
                end
            end
        end

        function initBuffer(obj, bufferLength)
            obj.BufferLength = bufferLength;
            obj.Buffer = struct( ...
                FrameIdx=zeros(1, bufferLength, 'uint32'), ...
                AbsTime=NaT(1, bufferLength, Format='uuuu-MM-dd HH:mm:ss.SSS'), ...
                Pose=zeros(length(obj.BodypartNames), 3, bufferLength, 'single') ...
                );
            obj.CurrentBufferIdx = 0;
        end

        function addToBuffer(obj, frameIdx, absTime, pose)
            obj.CurrentBufferIdx = obj.CurrentBufferIdx + 1;
            if obj.CurrentBufferIdx > obj.BufferLength
                obj.CurrentBufferIdx = 1;
            end
            
            obj.Buffer.FrameIdx(obj.CurrentBufferIdx) = frameIdx;
            obj.Buffer.AbsTime(obj.CurrentBufferIdx) = absTime;
            obj.Buffer.Pose(:, :, obj.CurrentBufferIdx) = pose;
        end

        % Handle VAR requests for to-be-rewarded reach/lick
        function onVARRequested(obj)
            obj.RequestFrameIdx = obj.CurrentFrameIdx;
            obj.RequestPending = true;
            % isClear = runVAR(obj, 15);
        end

        % Handle ongoing VAR detection of spurious movements during
        % timeout/waitfortouch
        function [isClear, speed] = runVAR(obj, nFrames)
            [pose, ~, t] = obj.fetchBuffer(nFrames); % try 15 frames ~ 0.5s
            p = pose(:, 3, :);
            x = pose(:, 1:2, :);
            x(p<obj.Params.MinLikelihood) = NaN;
            dx = diff(x, 1, 3); % x,y displacement
            dx = squeeze(sqrt(sum(dx(:, :, :).^2, 2))); % euclidean
            dt = seconds(diff(t));
            speed = [NaN(3, 1), dx./dt];

            % Check for spurious movements when a TestEvent occurs
            isClear = true;
            isPressTrial = logical(obj.Arduino.GetParam('USE_LEVER'));
            
            % Reach task
            if isPressTrial
                % Check for unwanted jaw movements
                if any(speed(1, :) > obj.Params.ThresholdMax(1))
                    isClear = false;
                end
            % Lick task
            else
                % Check for unwanted hand movements
                if any(speed(2, :) > obj.Params.ThresholdMax(2)) || any(speed(3, :) > obj.Params.ThresholdMax(3))
                    isClear = false;
                end
            end

            speed = speed(:, end); % return current speed
        end

		function updatePreview(obj, ~, event, hImage)
            if ~isgraphics(hImage)
                return
            end
			% Get the current video frame from the event data
            frame = event.Data;
            colors = ["yellow", "red", "blue"];

            pMove = (obj.CurrentSpeed-obj.Params.ThresholdMin) ./ (obj.Params.ThresholdMax-obj.Params.ThresholdMin);
            pMove(isnan(pMove)) = 0;
            pMove(pMove<0) = 0;
            textColor = ["white", "white", "white"];
            textColor(pMove>=1) = "black";

            % Label dlc-live pose
            for iBodypart = 1:3
                frame = insertText(frame, obj.CurrentPose(iBodypart, 1:2), ...
                    sprintf("%s p=%.2f spd=%04.0f", obj.BodypartNames(iBodypart), obj.CurrentPose(1, 3), obj.CurrentSpeed(iBodypart)), ...
                    FontSize=9, TextColor=textColor(iBodypart), BoxColor=colors(iBodypart), BoxOpacity=min(1, floor(pMove(iBodypart))), AnchorPoint='LeftTop', Font='Courier');
            end
            for frameShift = -1:-2:-30
                iFrame = obj.CurrentBufferIdx + frameShift;
                if iFrame <= 0
                    iFrame = obj.BufferLength + iFrame;
                end
			    frame = insertShape(frame, 'filled-circle', [obj.Buffer.Pose(:, 1:2, iFrame), repmat(2+frameShift/30*1, [size(obj.Buffer.Pose, 1), 1])], ...
				    ShapeColor=colors, Opacity=0.4, LineWidth=1);
            end

            switch obj.CurrentResult
                case 0
                    frame(:, :, 1) = 255;
                case 1
                    frame(:, :, 2) = 255;
            end

			% Update the image object with the annotated frame
			set(hImage, 'CData', frame);
        end
    end
end