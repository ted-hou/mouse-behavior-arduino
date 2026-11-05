%% 1 Start arduino
exp = TwoColorExperiment();

%%

exp.save();

exp.saveArduino();

exp.loadArduinoParams();

exp.saveArduinoParams();

%% Run calibration I realiged the lasers/lens so that 
% 0, -200, -400, -600 for fiber A
% 0, 0.16, 0.33, 0,50NA
% -3000, -2800, -2600, -2400 for fiber B
% 0, 0.16, 0.33, 0,50NA

% The blue laser was split into to using a dichroic, the power ratio
% between fibers A:B ~= 13:16 measured at tip of patch cable

% Fiber A goes into optrode (dot/0NA/tip of fiber/will be placed 500um
% higher than tip of neuropixel probe

% Fiber B goes into old motorized mirror (at -2800/0.13NA/~500um higher)

% exp.calibrate(mirrorPositions=[-2800], ...
%     fiberLaunchDivide=-1500, ... % Values less than -1500 is fiber B, will prompt for manual fiber change
%     targetPowers=[0.25, 0.5, 1, 5, 10, 20].*1e-3, ... targetPowers=[0.025, 0.05, 0.1, 0.5, 2].*1e-3, ...
%     wavelengths=[470, 593], ...
%     stepDelays=[0.5, 1], ...
%     maxIters=81, ...
%     maxStationaryIters=5, ...
%     powerMeterThreshold=1e-6, ...
%     stepSizeMultiplierGrad=0.1, ...
%     aoutMin=100, ...
%     stepSizeConst=500);

%% Or load calibration
sampleCalibration = load("C:\DATA\optrodecalibration\optrodecalibration_20261026_splitblue\optrodecalibration_20261026_splitblue.mat");
sampleCalibration = sampleCalibration.obj;

exp.Params = sampleCalibration.Params;
exp.Results = sampleCalibration.Results;

%%
exp.validate(validationDelay=[0.5, 0.5])
exp.save();
                   
%% Make stim/lever plan
exp.planTask(includeLever=true, includeLick=true, nBlocksPerTask=1, nPositions=1, randomize=false);
exp.Plan.task.positions = [0, 1]; % lick = 0, 1-4 = lever positions
exp.Plan.task.TIMEOUT_MAX = [10000, 10000];
% exp.Plan.task.VAR_REQUIRED_FOR_REWARD = [1, 1];
% exp.Plan.task.VAR_REQUIRED_FOR_PREMOVEMENT = [1, 1];

%% 2. Start VAR
% varL = VideoAssistantReferee(exp.LaserArduino, CamId=3, BodypartNames=["Jaw", "HandL"], ...
%     MemMapFolder='C:\DATA\MATLAB_MEMMAP');
% varL.Params = struct(ThresholdMin=[0, 0], ThresholdMax=[200, 200], NFramesBefore=10, NFramesAfter=10, NFramesOnging=15, NFramesThreshold=[2 3], MinLikelihood=[0.3, 0.3]);
% varL.Params.MinLikelihood = [0.6 0.4];
% varL.Params.NFramesThreshold = [2, 1];
% varL.Params.ThresholdMax=[100, 100];
% varL.Params.NFramesBefore=10;
% varL.Params.NFramesAfter=6;
% varL.Params.NFramesOnging=10;
% %%
% varR = VideoAssistantReferee(exp.LaserArduino, CamId=1, BodypartNames=["Jaw", "HandR"], ...
%     MemMapFolder='C:\DATA\MATLAB_MEMMAP');
% varR.Params = struct(ThresholdMin=[0, 0], ThresholdMax=[200, 200], NFramesBefore=10, NFramesAfter=10, NFramesOnging=15, NFramesThreshold=[2 3], MinLikelihood=[0.3, 0.3]);
% varR.Params.MinLikelihood = [0.6 0.4];
% varR.Params.NFramesThreshold = [2, 1];
% varR.Params.ThresholdMax=[100, 100];
% varR.Params.NFramesBefore=10;
% varR.Params.NFramesAfter=6;
% varL.Params.NFramesOnging=10;
% 
% %% 3. Start recording to disk, create memmap file to communicate with Python
% % Data will be written to the memmap file
% 
% %% 4. Start Python dlc live script
% % This will start writing Pose data back to the memmap file
% activate deeplabcut
% cd "C:\Users\assad\Documents\GitHub\mouse-behavior-arduino\MATLAB\examples" 
% python run_dlc_live_cam3.py
% 
% activate deeplabcut
% cd "C:\Users\assad\Documents\GitHub\mouse-behavior-arduino\MATLAB\examples" 
% python run_dlc_live_cam1.py
% 
% %% 5. Manually close the preview window, then create our own preview which draws pose estimates from dlc-live
% varL.preview()
% varR.preview()

%% Start recording
% SNr optrode, Surface is 3.62cm-0.47=3.15
% optic fiber is aligned to middle, about 300um anterior to center,
% shanks are arranged along ML (center is -3.28AP), about 200um posterior to center
% Probe: red side is facing anterior, metal/black side is facing posterior

%% Common module (spikeTimeBuffer)
stb = SpikeTimeBuffer(SpikeThreshold=-45, MaxDuration=6, UpdateInterval=0.02, UpdateIntervalPadding=0.01, Debug=false);
stb.connect('10.11.151.172');

%%
stb.start();

%% Create online decorder
od = OnlineDecoder(stb, exp.LaserArduino);
od.createDialog();
od.applyChannelMask(ml=1.3, ap=-3.28, dvFromDura=-4.7, rotation=0, dvFromDuraWindow=[-Inf, -3.8]);

%%
od.startTesting(UpdateInterval=0.02)
%%
od.stopTesting();
%%
stb.stop()

%% At end of session, save exp
exp.setParam('motor', 'MOTOR1_TARGET_1', 0); % Send lever motor to zero
exp.setParam('motor', 'MOTOR2_TARGET', 0); % Send laser/mirror motor to zero
exp.saveArduino();
exp.save();
