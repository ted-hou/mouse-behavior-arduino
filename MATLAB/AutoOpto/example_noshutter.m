%%
exp = TwoColorExperiment();

%% Load params
exp.saveArduino();
exp.loadArduinoParams();
exp.saveArduinoParams();

%% Run calibration 
% 0.5NA, 0.33NA, 0.16NA, 0NA
exp.calibrate(mirrorPositions=[-570, -380, -190, 0], ...
    targetPowers=[0.025, 0.05, 0.1, 0.5, 2].*1e-3, ...
    wavelengths=[473, 635], ...
    stepDelays=[0.5, 0.5], ...
    maxIters=64, ...
    maxStationaryIters=4, ...
    powerMeterThreshold=10e-6);
exp.validate(validationDelay=[1, 1])

%% Or load calibration
% sampleCalibration = load('C:\Users\Assad Lab\Dropbox (HMS)\Data\daisy19\daisy19_20240411_didnot_plugin_opticfiber\daisy19_20240411.mat');
% sampleCalibration = sampleCalibration.obj;
% 
% exp.Params = sampleCalibration.Params;
% exp.Results = sampleCalibration.Results;

%% Make stim/lever plan
exp.planStim(nPulses=10, pulseWidth=0.05, ipi=0.95)
exp.planTask(includeLever=true, includeLick=true, nBlocksPerTask=1, nPositions=2, randomize=false);
exp.Plan.lever.positions = [2, 0, 1]; % lever 1, lever 2, then lick

exp.save();

%% Start both arduinos and cameras
% exp.MotorArduino.Start();
% exp.LaserArduino.Start();

% 1. Start motor arduino
% 2. Start camera acquisition (close at least one preview window)
% 3. Start laser/behavior arduino


%% Finish residual stim conditions if we haven't gone through all the conditions
exp.runStimSessionPlanned(residual=true, ignoreCompletion=true, iti=10);

%%
exp.save();

%% 
exp.runStimSession(nPulses=10, pulseWidth=0.5, ipi=0.5, preTrainDelay=8, postTrainDelay=1, planned=false)