clc
cc = CameraConnection('Format', 'MJPG_640x480',...
    'FrameRate', 30,...
    'FileFormat', 'MPEG-4', ...
    'MemMapPath', 'E:\MATLAB_MEMMAP');
mkdir("E:\Data\Test")
cc.SaveAs("E:\Data\Test\test_1.mp4");


%%
cc.PreviewPose()