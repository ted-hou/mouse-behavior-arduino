%%
exp = TwoColorExperiment();

%% Load params
exp.saveArduino();
exp.loadArduinoParams();
exp.saveArduinoParams();

%% Run calibration 
% 0.33NA, 0NA
exp.calibrate(mirrorPositions=[-380, 0], ...
    targetPowers=[0.050, 2].*1e-3, ...
    wavelengths=[473], ...
    stepDelays=[2], ...
    maxIters=64, ...
    maxStationaryIters=4, ...
    powerMeterThreshold=10e-6);
exp.validate(validationDelay=[8])
exp.save();
%% Or load calibration
% I saved it into daisy22 by mistake, copy over the calibration data but
% % this time use the correct save path (daisy21)
% sampleCalibration = load('C:\Users\Assad Lab\Dropbox (HMS)\Data\daisy22\daisy21_20240510\daisy21_20240510.mat');
% sampleCalibration = sampleCalibration.obj;
% 
% exp.Params = sampleCalibration.Params;
% exp.Results = sampleCalibration.Results;
% exp.save();
%% Make stim/lever plan
% exp.planStim(nPulses=10, pulseWidth=0.2, ipi=1, preTrainDelay=8, postTrainDelay=1)
% exp.planLever(nBlocksPerPosition=1, nPositions=2, randomize=true);
% exp.Plan.lever.positions = [2, 1];

exp.save();

%% No Behavior straight stim
% exp.runStimSession(nPulses=10, pulseWidth=0.01, ipi=0.99, preTrainDelay=8, postTrainDelay=1, planned=false)
% exp.runStimSession(nPulses=10, pulseWidth=0.20, ipi=0.80, preTrainDelay=8, postTrainDelay=1, planned=false)
% exp.runStimSession(nPulses=10, pulseWidth=0.05, ipi=0.95, preTrainDelay=8, postTrainDelay=1, planned=false)
% exp.runStimSession(nPulses=10, pulseWidth=0.01, ipi=0.99, preTrainDelay=8, postTrainDelay=1, planned=false)

%% Give juice once every 10 stim trains

% 25uW, 10 trains per pos
for i = 1:10
    for iMirrorPos = 1:2
        exp.runStimTrain(iMirrorPos, 1, 1, nPulses=10, pulseWidth=0.200, ipi=0.8, preTrainDelay=5, postTrainDelay=1);
        pause(10);
    end
end

% Give juice:
doReward(exp);

% 25uW, 10 trains per pos
for i = 1:10
    for iMirrorPos = 1:2
        exp.runStimTrain(iMirrorPos, 1, 1, nPulses=10, pulseWidth=0.200, ipi=0.8, preTrainDelay=5, postTrainDelay=1);
        pause(10);
    end
end

% 2mW, 10 trains per pos
for i = 1:10
    for iMirrorPos = 1:2
        exp.runStimTrain(iMirrorPos, 2, 1, nPulses=10, pulseWidth=0.200, ipi=0.8, preTrainDelay=5, postTrainDelay=1);
        pause(10);
    end
end

% Give juice:
% Do 10 trains per condition (only two conditions i.e. two mirror
% positions)
doReward(exp);

% 2mW, 10 trains per pos
for i = 1:10
    for iMirrorPos = 1:2
        exp.runStimTrain(iMirrorPos, 2, 1, nPulses=10, pulseWidth=0.200, ipi=0.8, preTrainDelay=5, postTrainDelay=1);
        pause(10);
    end
end



function doReward(exp)
    DEBUG = true;
    assert(isa(exp, 'TwoColorExperiment'))
    exp.LaserArduino.SendMessage('J');
    if DEBUG
        fprintf('Requesting reward.\n');
    end
    pause(0.1);
    while ~strcmpi('IDLE', exp.getStateName('laser'))
        pause(0.01);
    end
    fprintf('Reward complete.\n');   
end
