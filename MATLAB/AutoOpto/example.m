exp = TwoColorExperiment();
%%
exp.calibrate(mirrorPositions=[-300, 0], ...
    targetPowers=[0.5, 2, 4, 8, 12].*1e-3, ...
    wavelengths=[473, 593], ...
    stepDelays=[0.5, 8], ...
    maxIters=64, ...
    maxStationaryIters=8, ...
    powerMeterThreshold=50e-6);
exp.validate(validationDelay=[1, 8])

%% Set-up stim/lever plan
% Make stim/lever position plan, this also registers listeners to arduino
% request_opto/move_lever requests, The planned list of stim conditions and
% lever positions are finite in length, we'll just restart from the top if 
% arduino keeps asking.
exp.planStim(nPulses=10, pulseWidth=0.01, ipi=0.5, preTrainDelay=8, postTrainDelay=1);
exp.planLever(nBlocksPerPosition=3, nPositions=4, randomize=true); % We do 10 trials per block per position, so don't make this too long

% Finish residuals



%% Manual stim (all conditions randomized)
exp.runStimSession(nPulses=10, pulseWidth=0.01, ipi=0.5, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)

exp.runStimSession(nPulses=10, pulseWidth=0.1, ipi=1, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)

exp.runStimSession(nPulses=10, pulseWidth=0.25, ipi=1.25, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)

exp.runStimSession(nPulses=10, pulseWidth=0.5, ipi=1.25, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)


%% Manual stim (one train)
exp.runStimTrain(1, 1, 1, nPulses=10, pulseWidth=0.1, ipi=1, preTrainDelay=1, postTrainDelay=1);
