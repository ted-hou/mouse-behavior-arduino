%%
exp = TwoColorExperiment();

%% Load params
exp.saveArduino();
exp.loadArduinoParams();
exp.saveArduinoParams();

%% Run calibration 
% 0.5NA, 0.33NA, 0.16NA, 0NA
% exp.calibrate(mirrorPositions=[-570, -380, -190, 0], ...
%     targetPowers=[0.5, 2, 8].*1e-3, ...
%     wavelengths=[473, 593], ...
%     stepDelays=[0.5, 8], ...
%     maxIters=64, ...
%     maxStationaryIters=8, ...
%     powerMeterThreshold=50e-6);
% exp.validate(validationDelay=[1, 8])

%% Or load calibration

sampleCalibration = load('calibration_20240403.mat');
sampleCalibration = sampleCalibration.exp;

exp.Params = sampleCalibration.Params;
exp.Results = sampleCalibration.Results;

%% Make stim/lever plan
exp.planStim(nPulses=10, pulseWidth=0.01, ipi=0.5, preTrainDelay=8, postTrainDelay=1)
exp.planLever(nBlocksPerPosition=1, nPositions=2, randomize=true);
exp.Plan.lever.positions = [2, 1];

exp.save();

%% Start both arduinos and cameras
% exp.MotorArduino.Start();
% exp.LaserArduino.Start();

% 1. Start motor arduino
% 2. Start camera acquisition (close at least one preview window)
% 3. Start laser/behavior arduino


%% Finish residual stim conditions if we haven't gone through all the conditions
exp.runStimSessionPlanned(residual=true, ignoreCompletion=false, iti=10);

%%
exp.save();

%% 
exp.runStimSession(nPulses=10, pulseWidth=0.10, ipi=0.5, preTrainDelay=8, postTrainDelay=1, planned=false)