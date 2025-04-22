%%
exp = TwoColorExperiment();

%% Load params
exp.saveArduino();
exp.loadArduinoParams();
exp.saveArduinoParams();

%% Run calibration I realiged the lasers/lens so that position targets should be 0, -200, -400, -600
% 0.5NA, 0.33NA, 0.16NA, 0NA
exp.calibrate(mirrorPositions=[-600, -400, -200, 0], ...
    targetPowers=[0.025, 0.05, 0.1, 0.5, 2].*1e-3, ... targetPowers=[0.025, 0.05, 0.1, 0.5, 2].*1e-3, ...
    wavelengths=[470, 635], ...
    stepDelays=[0.5, 0.5], ...
    maxIters=64, ...
    maxStationaryIters=4, ...
    powerMeterThreshold=1e-6);
exp.validate(validationDelay=[2, 2])

%% Or load calibration
sampleCalibration = load('C:\DATA\optrodecalibration_20250415\optrodecalibration_20250415.mat');
sampleCalibration = sampleCalibration.obj;

exp.Params = sampleCalibration.Params;
exp.Results = sampleCalibration.Results;

%% Make stim/lever plan
exp.planStim(nPulses=10, pulseWidth=0.05, ipi=0.95)
exp.planTask(includeLever=true, includeLick=true, nBlocksPerTask=1, nPositions=2, randomize=false);
exp.Plan.task.positions = [2, 0, 1]; % lever 1 (initial), lever 2, then lick
exp.Plan.task.TIMEOUT_MAX = [10000, 10000, 10000];

exp.save();

% exp.LaserArduino.DebugMode = true;
%% Start both arduinos and cameras
% exp.MotorArduino.Start();
% exp.LaserArduino.Start();

% 1. Start motor arduino
% 2. Start camera acquisition (close at least one preview window)
% 3. Start laser/behavior arduino


%% Finish residual stim conditions if we haven't gone through all the conditions
exp.runStimSessionPlanned(residual=true, ignoreCompletion=true, iti=10);
% 
% %%
% exp.save();
% 
% %% 
% exp.runStimSession(nPulses=10, pulseWidth=0.5, ipi=0.5, preTrainDelay=8, postTrainDelay=1, planned=false)

%%
exp.runStimTrain(4, 1, 1, nPulses=150, pulseWidth=0.01, ipi=0.99, preTrainDelay=2, postTrainDelay=2);
