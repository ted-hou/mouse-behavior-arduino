%% 1. Start camera
clc
obj = CameraConnection('Format', 'MJPG_640x480',...
    'FrameRate', 30,...
    'FileFormat', 'MPEG-4', ...
    'MemMapPath', 'E:\MATLAB_MEMMAP');
mkdir("E:\Data\Test")
% This creates the memmap file, path specified by CameraConnection constructor
obj.SaveAs("E:\Data\Test\test_1.mp4");

%% Start recording to disk, create memmap file to communicate with Python
% Data will be written to the memmap file

%% Start Python dlc live script
% This will start writing Pose data back to the memmap file

%% Manually close the preview window, then create our own preview which draws pose estimates from dlc-live
obj.PreviewPose()