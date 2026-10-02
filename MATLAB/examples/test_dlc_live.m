% % %% 1a. Start camera
% clc
% cc = CameraConnection(CameraID=3, ...
%     Format='MJPG_640x480',...
%     FrameRate=30,...
%     FileFormat='MPEG-4');
% mkdir("C:\Data\Test_DLCLive")
% cc.SaveAs("C:\Data\Test_DLCLive\test_1.mp4");
% 
% var = VideoAssistantReferee(cc, BodypartNames=["Jaw", "HandL", "HandR"], ...
%     MemMapFolder='C:\DATA\MATLAB_MEMMAP');
% var.Params = struct(ThresholdMin=[0, 0, 0], ThresholdMax=[100, 125, 125], NFramesBefore=7, NFramesAfter=4, NFramesOnging=15, MinLikelihood=0.2);

%% 1b. Use recorded video file instead of camera

% %% Load CompleteExperiment from this session
% load("C:\SERVER\Units\SNr_CoChR_VGATCre\SingleUnit_NonDuplicate_NonDrift_SNr_ValidVideos\desmond46_20260717_Channel105_Unit1.mat");
% 
% exp = CompleteExperiment3(eu, cameras='l', deeplabcutPath='C:\SERVER\DeepLabCut\Results\FourPawsJawTongueSpine_Emma');
% exp.alignTimestamps(refEventNameArduino={'TIMEOUT_END'}, refEventNameEphys={'TimeoutOff'}, trialDurationTolerance=2);
% events.press = uint32(round(interp1(exp.vtdL.Timestamp, exp.vtdL.FrameNumber, eu.EventTimes.FirstPress, 'linear')));
% events.lick = uint32(round(interp1(exp.vtdL.Timestamp, exp.vtdL.FrameNumber, eu.EventTimes.FirstLick, 'linear')));
% 
% % Calculate expected movements
% speed.Jaw = sqrt(sum(diff([exp.vtdL.Jaw_X(1:2:end), exp.vtdL.Jaw_Y(1:2:end)], 1, 1).^2, 2)) ./ diff(exp.vtdL.Timestamp(1:2:end));
% speed.HandL = sqrt(sum(diff([exp.vtdL.HandIpsiCam_X(1:2:end), exp.vtdL.HandIpsiCam_Y(1:2:end)], 1, 1).^2, 2)) ./ diff(exp.vtdL.Timestamp(1:2:end));
% speed.HandR = sqrt(sum(diff([exp.vtdL.HandContraCam_X(1:2:end), exp.vtdL.HandContraCam_Y(1:2:end)], 1, 1).^2, 2)) ./ diff(exp.vtdL.Timestamp(1:2:end));
% % 
% % %%
% % fig = figure;
% % tl = tiledlayout(fig, 3, 1);
% % for fn = ["Jaw", "HandL", "HandR"]
% %     ax = nexttile(tl);
% %     hold(ax, 'on')
% %     histogram(ax, speed.(fn), 1:2.5:500)
% %     xline(ax, quantile(speed.(fn), 0.95))
% %     xline(ax, quantile(speed.(fn), 0.50))
% %     xlabel(ax, sprintf("%s speed (px/s)", fn))
% %     hold(ax, 'off')
% % end
% 
% 
% clc
% close all
% var = VideoAssistantReferee("C:\DATA\desmond46\desmond46_20260728\desmond46_20260728_laser_3.mp4", BodypartNames=["Jaw", "HandL", "HandR"], ...
%     MemMapFolder='C:\DATA\MATLAB_MEMMAP');
% var.TestEvents = events;
% var.Params = struct(ThresholdMin=[10, 10, 10], ThresholdMax=[100, 125, 125], NFramesBefore=7, NFramesAfter=4, NFramesOnging=15, MinLikelihood=0.2);
% var.TestVideo.CurrentTime = 1295;

%% 1c. Start arduino
clc
h = MouseBehaviorInterface('COM7');
% cc = CameraConnection(CameraID=3, ...
%     Format='MJPG_640x480',...
%     FrameRate=30,...
%     FileFormat='MPEG-4');
% mkdir("C:\Data\Test_DLCLive")
% cc.SaveAs("C:\Data\Test_DLCLive\test_1.mp4");

var = VideoAssistantReferee(h.Arduino, CamId=3, BodypartNames=["Jaw", "HandL", "HandR"], ...
    MemMapFolder='C:\DATA\MATLAB_MEMMAP');
var.Params = struct(ThresholdMin=[0, 0, 0], ThresholdMax=[200, 250, 250], NFramesBefore=7, NFramesAfter=4, NFramesOnging=15, NFramesThreshold=3, MinLikelihood=0.2);
var.Params.MinLikelihood = .15;
h.Arduino.SaveAsExperiment('C:\DATA\Test_DLCLive')

%% Start recording to disk, create memmap file to communicate with Python
% Data will be written to the memmap file

%% Start Python dlc live script
% This will start writing Pose data back to the memmap file

%% Manually close the preview window, then create our own preview which draws pose estimates from dlc-live
var.preview()