%% 1. Start camera
clc
cc = CameraConnection('Format', 'MJPG_640x480',...
    'FrameRate', 30,...
    'FileFormat', 'MPEG-4');
mkdir("E:\Data\Test")
cc.SaveAs("E:\Data\Test\test_1.mp4");

var = VideoAssistantReferee(cc, BodypartNames=["Jaw", "HandL", "HandR"], ...
    MemMapFolder='E:\MATLAB_MEMMAP');


%% Start recording to disk, create memmap file to communicate with Python
% Data will be written to the memmap file

%% Start Python dlc live script
% This will start writing Pose data back to the memmap file

%% Manually close the preview window, then create our own preview which draws pose estimates from dlc-live
var.preview()