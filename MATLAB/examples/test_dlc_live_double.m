%% 1 Start arduino
exp = TwoColorExperiment();

%%

exp.save();

exp.saveArduino();

exp.loadArduinoParams();

exp.saveArduinoParams();
%%
exp.planTask(includeLever=true, includeLick=true, nBlocksPerTask=1, nPositions=1, randomize=false);
exp.Plan.task.positions = [0, 1]; % lick = 0, 1-4 = lever positions
exp.Plan.task.TIMEOUT_MAX = [10000, 100];
exp.Plan.task.VAR_REQUIRED_FOR_REWARD = [1, 1];
exp.Plan.task.VAR_REQUIRED_FOR_PREMOVEMENT = [1, 1];

%% 2. Start VAR
varL = VideoAssistantReferee(exp.LaserArduino, CamId=3, BodypartNames=["Jaw", "HandL"], ...
    MemMapFolder='C:\DATA\MATLAB_MEMMAP');
varL.Params = struct(ThresholdMin=[0, 0], ThresholdMax=[200, 200], NFramesBefore=10, NFramesAfter=10, NFramesOnging=15, NFramesThreshold=[2 3], MinLikelihood=[0.3, 0.3]);
varL.Params.MinLikelihood = [0.6 0.4];
varL.Params.NFramesThreshold = [2, 2];
varL.Params.ThresholdMax=[100, 150];
varL.Params.NFramesBefore=10;
varL.Params.NFramesAfter=5;
%%
varR = VideoAssistantReferee(exp.LaserArduino, CamId=1, BodypartNames=["Jaw", "HandR"], ...
    MemMapFolder='C:\DATA\MATLAB_MEMMAP');
varR.Params = struct(ThresholdMin=[0, 0], ThresholdMax=[200, 200], NFramesBefore=10, NFramesAfter=10, NFramesOnging=15, NFramesThreshold=[2 3], MinLikelihood=[0.3, 0.3]);
varR.Params.MinLikelihood = [0.6 0.4];
varR.Params.NFramesThreshold = [2, 2];
varR.Params.ThresholdMax=[100, 150];
varR.Params.NFramesBefore=10;
varR.Params.NFramesAfter=5;

%% 3. Start recording to disk, create memmap file to communicate with Python
% Data will be written to the memmap file

%% 4. Start Python dlc live script
% This will start writing Pose data back to the memmap file
activate deeplabcut
cd "C:\Users\assad\Documents\GitHub\mouse-behavior-arduino\MATLAB\examples" 
python run_dlc_live_cam3.py

activate deeplabcut
cd "C:\Users\assad\Documents\GitHub\mouse-behavior-arduino\MATLAB\examples" 
python run_dlc_live_cam1.py

%% 5. Manually close the preview window, then create our own preview which draws pose estimates from dlc-live
varL.preview()
varR.preview()
%%
varR.Params.MinLikelihood = [0.2 0.2];
varL.Params.MinLikelihood = [0.2 0.2];

%% 6. Start behavior
% Notes: 20261015, daisy38:
% tried 20 trials each (blocks of 20) in the interest of time
%% 7. Stop behavior
% stop camera recording
% quit python (ctrl+c)
exp.save()