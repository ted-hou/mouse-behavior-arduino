% FlyCap-CED Data Parser
% 	A tool to align Flycap video capture data to timestamps on CED
% 	
% 		Created:  ahamilos 12/1/17
% 		Modified: ahamilos 12/1/17
% 
% Update History:
% 	12/1/17: Initial version and testing
% 
% 
% ----------------------------------------------------------------------------------

%% Debug mode------------------------------
% 
% Video file set up:
%  vid = the video file
%  IRtrig = CED IR trigger timestamp
%  strobe = CED strobe output from camera
% 
% -----------------------------------------

%% Instructions for runtime----------------
% 
% 	1. Start CED
% 	2. Begin camera recording
% 	3. Start Arduino
% 	4. Run experiment
% 	5. Stop camera
% 	6. Stop CED
% -----------------------------------------

% Define the IR trigger timestamps:
% 
IRtrig = Data7__Stopped__trigIR.times;
strobe = Data7__Stopped__camO.times;
vid = testcam_2017_12_01_174722;


% Trim the CED camera frame timestamps----------------------------------------------
% 
% 	1. Find the position of the trigger:
% 
frame1CEDPosition = find(strobe > IRtrig, 1);
% 
% 	2. Trim the CED strobe times so the frame times match those saved in trimmed video file
% 
cedFrameTimes = strobe(frame1CEDPosition:end);



% Trim the saved video frames to match CED timestamps-------------------------------
% 
% 	1. Extract the pixel values for the trigger IR LED:
% 
for n = 1:length(vid)
	IRPixelValues(n) = vid(n).cdata(480,395,1);
end
% 
% 	2. Find the first frame after the trigger:
% 
frame1VideoPosition = find(IRPixelValues < 100, 1);
% 
%	3. Trim the video to match the trimmed CED timestamps:
%
cedMatchedVideo = vid(frame1VideoPosition:end);
% 





% Image difference calculation------------------------------------------------------
% 
% 	1. Assign reference image:
% 
reference = cedMatchedVideo(1).cdata(:,:,1);
% 
%	2. Calculate difference frames
% 
differenceFrames = [];
% 
for nFrames = 1:length(cedMatchedVideo)
	differenceFrames(:,:,nFrames) = cedMatchedVideo(nFrames).cdata(:,:,1) - reference;
end
% 
% debug************************************
	figure,
	imagesc(differenceFrames(:,:,230))
	figure,
	imagesc(differenceFrames(:,:,1000))	
%******************************************
% 
% 	3. Calculate the difference vector
% 
differenceArray = [];
for nframes = 1:length(differenceFrames)
	differenceArray(nframes) = sum(sum(differenceFrames(:,:,nFrames)));
end
% 
figure,
plot(differenceArray)

implay(vid)
implay(cedMatchedVideo)
























