classdef VideoAssistantReferee < handle
    %VIDEOASSISTANTREFEREE
    %   to make sure mouse does not lick during reach trials, and vice versa

    properties
        Arduino
        Camera
        Params
        Buffer = struct(idx=[], t=[], pose=[])
        BufferLength = 30*10; % 300 frames ~= 10s

        MemMapFilePath
        MemMapFile
        Pose
    end

    methods
        function obj = VideoAssistantReferee(arduinoOrCamera, varargin)
            p = inputParser();
            p.addRequired('ArduinoOrCamera', @(x) isa(x, 'ArduinoConnection') || isa(x, 'CameraConnection'))
            p.addParameter('CamId', 3, @(x) isscalar(x) && isnumeric(x)) % Use left camera as default
            p.addParameter('MemMapFolder', "C:\MATLAB_MEMMAP\VideoAssistantReferee"); % ""
            p.parse(arduinoOrCamera, varargin{:})
            
            if isa(arduinoOrCamera, 'ArduinoConnection')
                obj.Arduino = p.Results.Arduino;
                obj.Camera = arduino.Cameras(p.Results.camId).Camera;
            else
                obj.Arduino = [];
                obj.Camera = arduinoOrCamera;
            end
            
            obj.Camera.VideoInput.LoggingMode = 'disk&memory';
            obj.MemMapFilePath = obj.CreateMemMapFile(p.Results.MemMapFolder); % This changes logging mode from 'disk' to 'disk&memory'!
        end

		function PreviewPose(obj)
			% Create a custom figure and axes
			fig = figure;
			ax = axes(fig);

			% Initialize an image object in the axes
			hImage = image(ax, zeros(480, 640, 3));
			preview(obj.Camera.VideoInput, hImage);

			setappdata(hImage, 'UpdatePreviewWindowFcn', @obj.PreviewPose_Update);
		end

		function PreviewPose_Update(obj, ~, event, hImage)
			% Get the current video frame from the event data
			frame = event.Data;

			% Add text annotation using insertText
			annotatedFrame = insertText(frame, obj.Pose(:, 1:2), [sprintf("Jaw %.2f", obj.Pose(1, 3)); sprintf("Hand %.2f", obj.Pose(2, 3))], ...
				'FontSize', 18, 'BoxColor', ["yellow", "red"], 'BoxOpacity', 0.4, 'AnchorPoint', 'LeftTop');

			% Update the image object with the annotated frame
			set(hImage, 'CData', annotatedFrame);
		end

    end

    % Private methods
    methods (Access={})
        function memMapFilePath = CreateMemMapFile(obj, folder)
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
            poseSize = 3*4; % 3 single floats per bodypart (there are 2: hand/jaw)

            % Create/Zero out the shared binary file (Header: 1 uint32 for frame index + image data)
            totalBytes = headerSize + frameSize + 2*poseSize; 
            fileID = fopen(memMapFilePath, 'w');
            fwrite(fileID, zeros(totalBytes, 1, 'uint8'));
            fclose(fileID);

            obj.MemMapFile = memmapfile(memMapFilePath, Writable=true, ...
                Format={ ...
                    'uint32', [1, 1], 'idx'; ... frame index
                    'uint8', [h, w, 3], 'frame'; ... image
                    'single', [2, 3], 'pose'; ... each row is [x, y, likelihood] for a different bodypart (hand; jaw)
                });
            obj.Camera.VideoInput.FramesAcquiredFcn = @obj.WriteToMemMap;
            obj.Camera.VideoInput.FramesAcquiredFcnCount = 1;

            fprintf("Created memmapfile at %s...\n", memMapFilePath);
        end

		function WriteToMemMap(obj, vid, ~)
			framesAvailable = vid.FramesAvailable;
			if framesAvailable > 0
				% Safely extract data and timestamps from memory without disrupting the disk write
				[data, ~, ~] = getdata(vid, framesAvailable);

				% Write frame index and image to memmap'd file
				mmf = obj.MemMapFile;
				frame = data(:, :, :, end);
				if ~isempty(frame)
					mmf.Data.frame = frame;
					mmf.Data.idx = uint32(vid.FramesAcquired);
				end
				% Read results back from Python (race conditions exist, to fix: use a handshake, or try tcp/ip instead of memmap)
				% but honestly we're talking microseconds here, so it probably does not matter for 30fps:
				% MATLAB sends a new frame and reads last pose estimate from Python (30Hz) -> Python sends back new pose data (30Hz)
				% We should probably improve by having MATLAB read Python pose as soon as that returns
				% But this function is called each time camera acquires a new frame, so we'd need a faster/separate timer which sounds like a new can of dragons
				obj.Pose = mmf.Data.pose;
				% fprintf("Frame %i, x=%.2f, y=%.2f, llh=%.2f\n", mmf.Data.idx, obj.Pose(1), obj.Pose(2), obj.Pose(3))
			end
        end
    end
end