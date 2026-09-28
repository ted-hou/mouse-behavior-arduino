classdef VideoAssistantReferee < handle
    %VIDEOASSISTANTREFEREE
    %   to make sure mouse does not lick during reach trials, and vice versa

    properties
        Arduino
        Camera
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
        function obj = VideoAssistantReferee(arduinoOrCamera, varargin)
            p = inputParser();
            p.addRequired('ArduinoOrCamera', @(x) isa(x, 'ArduinoConnection') || isa(x, 'CameraConnection'))
            p.addParameter('CamId', 3, @(x) isscalar(x) && isnumeric(x)) % Use left camera as default
            p.addParameter('BodypartNames', ["Jaw", "HandL", "HandR"], @(x) isstring && length(x)==3);
            p.addParameter('BufferLength', 300, @(x) isnumeric(x) & isscalar(x)) % 300 at 30fps = 10s
            p.addParameter('MemMapFolder', "C:\MATLAB_MEMMAP\VideoAssistantReferee"); % ""
            p.parse(arduinoOrCamera, varargin{:})
            
            if isa(arduinoOrCamera, 'ArduinoConnection')
                obj.Arduino = p.Results.Arduino;
                obj.Camera = arduino.Cameras(p.Results.camId).Camera;
            else
                obj.Arduino = [];
                obj.Camera = arduinoOrCamera;
            end
            
            obj.BodypartNames = p.Results.BodypartNames;
            obj.CurrentPose = zeros(length(obj.BodypartNames), 3, 'single');

            obj.initBuffer(p.Results.BufferLength);

            obj.Camera.VideoInput.LoggingMode = 'disk&memory';
            obj.MemMapFilePath = obj.createMemMapFile(p.Results.MemMapFolder); % This changes logging mode from 'disk' to 'disk&memory'!

        end

		function preview(obj)
			% Create a custom figure and axes
			fig = figure;
			ax = axes(fig);

			% Initialize an image object in the axes
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
            memMapFilePath = fullfile(folder, sprintf("memmap_var_%i.dat", obj.Camera.VideoInput.DeviceID));
            if exist(memMapFilePath, 'file')
                delete(memMapFilePath);
            end

            % Create the file
            sz = obj.Camera.VideoInput.VideoResolution;
            w = sz(1);
            h = sz(2);
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
            obj.Camera.VideoInput.FramesAcquiredFcn = @obj.onFrameAcquired;
            obj.Camera.VideoInput.FramesAcquiredFcnCount = 1;

            fprintf("Created memmapfile at %s...\n", memMapFilePath);
        end

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
			% Get the current video frame from the event data
			frame = event.Data;

			% Add text annotation using insertText
			annotatedFrame = insertText(frame, obj.CurrentPose(:, 1:3), [sprintf("%s %.2f", obj.BodypartNames(1), obj.CurrentPose(1, 3)); sprintf("%s %.2f", obj.BodypartNames(2), obj.CurrentPose(2, 3)); sprintf("%s %.2f", obj.BodypartNames(3), obj.CurrentPose(3, 3))], ...
				'FontSize', 18, 'BoxColor', ["yellow", "red", "blue"], 'BoxOpacity', 0.4, 'AnchorPoint', 'LeftTop');
            for frameShift = -1:-1:-10
                iFrame = obj.CurrentBufferIdx + frameShift;
                if iFrame <= 0
                    iFrame = obj.BufferLength + iFrame;
                end
			    annotatedFrame = insertText(annotatedFrame, 'circle', [obj.Buffer.Pose(:, 1:2, iFrame), 30+2*frameShift], ...
				    'Color', ["yellow", "red", "blue"], 'Opacity', 0.4, LineWidth=0);
            end

			% Update the image object with the annotated frame
			set(hImage, 'CData', annotatedFrame);
        end
    end
end