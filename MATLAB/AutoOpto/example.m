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

%%
exp.runStimSession(nPulses=10, pulseWidth=0.01, ipi=0.5, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)

exp.runStimSession(nPulses=10, pulseWidth=0.1, ipi=1, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)

exp.runStimSession(nPulses=10, pulseWidth=0.25, ipi=1.25, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)

exp.runStimSession(nPulses=10, pulseWidth=0.5, ipi=1.25, preTrainDelay=8, postTrainDelay=1, waitForUserTimeout=1)


%% Turned laser off
exp.runStimTrain(1, 1, 1, nPulses=10, pulseWidth=0.1, ipi=1, preTrainDelay=1, postTrainDelay=1);
exp.runStimTrain(1, 1, 1, nPulses=10, pulseWidth=0.25, ipi=1.25, preTrainDelay=1, postTrainDelay=1);
exp.runStimTrain(1, 1, 1, nPulses=10, pulseWidth=0.5, ipi=1.25, preTrainDelay=1, postTrainDelay=1);