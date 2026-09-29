classdef VideoAssistantReferee < handle
    %VIDEOASSISTANTREFEREE
    %   to make sure mouse does not lick during reach trials, and vice versa

    properties
        Arduino
        Camera
        Video % For testing on pre-recorded videos only
        Source
        MemMapFilePath
        MemMapFile
        BodypartNames
        CurrentPose
        CurrentFrameIdx = zeros(1, 'uint32') % This corresponds to CurrentPose, but should lag behind actual FramesAcquired by 1
        CurrentAbsTime = NaT(1, Format='uuuu-MM-dd HH:mm:ss.SSS'); % This corresponds to CurrentFrameIdx, but should lag behind actual FramesAcquired by 1
        Buffer = struct(FrameIdx=[], AbsTime=[], Pose=[]) % (BufferLength x 1, BufferLength x 1, nBodyparts x 3 x BufferLength)
        BufferLength = 0; % 300 frames ~= 10s
        CurrentBufferIdx = 0;
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
                obj.Video = [];
                obj.Source = "Arduino";
            elseif isa(source, 'CameraConnection')
                obj.Arduino = [];
                obj.Camera = source;
                obj.Video = [];
                obj.Source = "Camera";
            elseif isfile(source)
                obj.Arduino = [];
                obj.Camera = [];
                obj.Video = VideoReader(source);
                obj.Source = "Video";
            else
                error("Invalid source %s", source)
            end
            
            obj.BodypartNames = p.Results.BodypartNames;
            obj.CurrentPose = zeros(length(obj.BodypartNames), 3, 'single');

            obj.initBuffer(p.Results.BufferLength);

            switch obj.Source
                case {"Arduino", "Camera"}
                    obj.Camera.VideoInput.LoggingMode = 'disk&memory';
                case "Video"
            end
            obj.MemMapFilePath = obj.createMemMapFile(p.Results.MemMapFolder); % This changes logging mode from 'disk' to 'disk&memory'!

        end

        % Create our own preview window for video, drawing DLC-live results
		function preview(obj)
			fig = figure;
			ax = axes(fig);
			hImage = image(ax, zeros(480, 640, 3));
			preview(obj.Camera.VideoInput, hImage);

			setappdata(hImage, 'UpdatePreviewWindowFcn', @obj.updatePreview);
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
            switch obj.Source
                case {"Arduino", "Camera"}
                    sz = obj.Camera.VideoInput.VideoResolution;
                    w = sz(1);
                    h = sz(2);
                case "Video"
                    w = obj.Video.Width;
                    h = obj.Video.Height;
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

            switch obj.Source
                case {"Arduino", "Camera"}
                    obj.Camera.VideoInput.FramesAcquiredFcn = @obj.onFrameAcquired;
                    obj.Camera.VideoInput.FramesAcquiredFcnCount = 1;
                case "Video"
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
			end
        end

        % Call back used when a frame is read from file (for TESTING)
        function onFrameAcquiredFromVideo(obj, hImage)
            if hasFrame(obj.Video)
                % Safely extract data and timestamps from memory without disrupting the disk write
                t = obj.Video.CurrentTime;
                frame = readFrame(obj.Video);

                % Write frame index and image to memmap'd file
                mmf = obj.MemMapFile;
                newFrameIdx = uint32(round(t*obj.Video.FrameRate));
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

                % Update preview
                if obj.Source == "Video"
                    event = struct(Data=frame);
                    obj.updatePreview([], event, hImage);
                end

                % fprintf("Read frame %i\n", newFrameIdx);
            end
        end

        function initBuffer(obj, bufferLength)
            obj.BufferLength = bufferLength;
            obj.Buffer = struct( ...
                FrameIdx=zeros(bufferLength, 1, 'uint32'), ...
                AbsTime=NaT(bufferLength, 1, Format='uuuu-MM-dd HH:mm:ss.SSS'), ...
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

		function updatePreview(obj, ~, event, hImage)
            if ~isgraphics(hImage)
                return
            end
			% Get the current video frame from the event data
			frame = event.Data;

			% Add text annotation using insertText
			annotatedFrame = insertText(frame, obj.CurrentPose(:, 1:2), ...
                [ ...
                    sprintf("%s %.2f", obj.BodypartNames(1), obj.CurrentPose(1, 3)); ...
                    sprintf("%s %.2f", obj.BodypartNames(2), obj.CurrentPose(2, 3)); ...
                    sprintf("%s %.2f", obj.BodypartNames(3), obj.CurrentPose(3, 3)) ...
                ], ...
				'FontSize', 9, 'BoxColor', ["yellow", "red", "blue"], 'BoxOpacity', 0.4, 'AnchorPoint', 'LeftTop');
            for frameShift = -1:-2:-30
                iFrame = obj.CurrentBufferIdx + frameShift;
                if iFrame <= 0
                    iFrame = obj.BufferLength + iFrame;
                end
			    annotatedFrame = insertShape(annotatedFrame, 'filled-circle', [obj.Buffer.Pose(:, 1:2, iFrame), repmat(2+frameShift/30*1, [size(obj.Buffer.Pose, 1), 1])], ...
				    'ShapeColor', ["yellow", "red", "blue"], 'Opacity', 0.4, LineWidth=1);
            end

			% Update the image object with the annotated frame
			set(hImage, 'CData', annotatedFrame);
        end
    end
end