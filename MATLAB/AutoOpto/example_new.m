exp = TwoColorExperiment();

%% Run calibration
exp.calibrate(mirrorPositions=[-500, -333, -167, 0], ...
    targetPowers=[0.5, 2, 8].*1e-3, ...
    wavelengths=[473, 593], ...
    stepDelays=[0.5, 8], ...
    maxIters=64, ...
    maxStationaryIters=8, ...
    powerMeterThreshold=50e-6);
exp.validate(validationDelay=[1, 8])

%% Or load calibration

sampleCalibration = load('tce_test_calibration.mat');
sampleCalibration = sampleCalibration.obj;

exp.Params = sampleCalibration.Params;
exp.Results = sampleCalibration.Results;

% Make stim/lever plan
exp.planStim(nPulses=10, pulseWidth=0.01, ipi=0.5, preTrainDelay=8, postTrainDelay=1)
exp.planLever(nBlocksPerPosition=1, nPositions=2, randomize=true);
exp.Plan.lever.positions = [2, 1];

exp.save();

%% Start both arduinos
exp.MotorArduino.Start();
exp.LaserArduino.Start();

%% Finish residuals if we haven't gone through all the conditions (at least
% once)
exp.runStimSessionPlanned(residual=true, ignoreCompletion=false, iti=10);

