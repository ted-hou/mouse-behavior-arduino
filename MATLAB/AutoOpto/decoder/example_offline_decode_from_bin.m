% filename = "C:\SERVER\desmond41\desmond41_20251029\desmond41_20251029\desmond41_20251029_g0\desmond41_20251029_g0_t0.imec0.ap.bin";
clear, clc
% pathname = 'C:\SERVER\desmond41\desmond41_20251029';
pathname = 'C:\SERVER\desmond41\desmond41_20251104';
threshold = -75; %uV, must be negative
assert(threshold < 0)

%% Load some neuropixel data
% Keep streaming data, make a large buffer (10s) of spike times
tr = TetrodeRecording();
tr.SelectFiles(NeuropixelPath=pathname);


%% For offline, try defining trials using just nidq digital inputs (for online we'll prolly use arduino/MouseBehaviorInterface events)
tr.LoadNeuropixelIO();
tr.ParseNeuropixelIO(DigitalChannels={'Sync', 0; 'Lick', 1; 'Press', 2; 'Reward', 3; 'Timeout', 4; 'Mot2Busy', 5; 'CueLeft', 6; 'CueRight', 7});

%% Parse into trials
clear trials

selLick = (tr.DigitalEvents.LickOff - tr.DigitalEvents.LickOn) > 0.9e-3;
selPress = (tr.DigitalEvents.PressOff - tr.DigitalEvents.PressOn) > 1.9e-3;

trials.correctPress = Trial([0, tr.DigitalEvents.TimeoutOff, Inf], tr.DigitalEvents.PressOn(selPress), stopMode='first'); % I think these include opto lever retract
trials.correctLick = Trial([0, tr.DigitalEvents.TimeoutOff, Inf], tr.DigitalEvents.LickOn(selLick), stopMode='first'); % I think these include opto lever retract
trials.reward = Trial([0, tr.DigitalEvents.TimeoutOff, Inf], tr.DigitalEvents.RewardOn, stopMode='first'); % Surrogate for move

%% Get baseline and move spike rates
clear p
p.baselineWindow = [-6, -2];
p.moveWindow = [-0.5, 0];

clear spikeRates
spikes = cell(384, 1);
spikeRates.baseline = NaN(384, length(trials.reward));
spikeRates.move = NaN(384, length(trials.reward));
for iTrial = 1:length(trials.reward)
    tr.ReadIMEC(Channels=1:384, TimeWindow=trials.reward(iTrial).Stop + p.baselineWindow, ReadMode='simple')
    isBelowThreshold = tr.Amplifier.Data < threshold;
    for iChannel = 1:384
        spikes{iChannel} = strfind(isBelowThreshold(iChannel, :), [0, 1]) + 1;
    end
    spikeRates.baseline(1:384, iTrial) = cellfun(@length, spikes) ./ diff(p.baselineWindow);


    tr.ReadIMEC(Channels=1:384, TimeWindow=trials.reward(iTrial).Stop + p.moveWindow, ReadMode='simple')
    isBelowThreshold = tr.Amplifier.Data < threshold;
    for iChannel = 1:384
        spikes{iChannel} = strfind(isBelowThreshold(iChannel, :), [0, 1]) + 1;
    end
    spikeRates.move(1:384, iTrial) = cellfun(@length, spikes) ./ diff(p.moveWindow);
end

%% Fit LM
close all
nTrialsTrain = 30;
nTrialsTest = length(trials.reward) - nTrialsTrain;
XTrain = transpose([spikeRates.baseline(:, 1:nTrialsTrain), spikeRates.move(:, 1:nTrialsTrain)]);
yTrain = [zeros(nTrialsTrain, 1); ones(nTrialsTrain, 1)];
XTest = transpose([spikeRates.baseline(:, nTrialsTrain+1:end), spikeRates.move(:, nTrialsTrain+1:end)]);
yTest = [zeros(nTrialsTest, 1); ones(nTrialsTest, 1)];

% This is needed because numTrials << numNeurons, so the regression won't
% work well. But the population-average (1D) works fairly well. Could also
% try the first n PCs (PCA, n<numNeurons) if we need better performance
XTrain = mean(XTrain, 2);
XTest = mean(XTest, 2);

mdl = fitglm(XTrain, yTrain, 'linear', Distribution='binomial', Link='logit');
yHatMove = mdl.predict(XTest(yTest==1, :));
yHatBaseline = mdl.predict(XTest(yTest==0, :));

ax = axes(figure);
hold(ax, 'on')
histogram(ax, yHatMove, -0.1:0.05:1.1, FaceColor='blue', FaceAlpha=0.2, DisplayName='peri-move')
histogram(ax, yHatBaseline, -0.1:0.05:1.1, FaceColor='red', FaceAlpha=0.2, DisplayName='baseline')

% histogram(ax, yHatMove, 50, FaceColor='blue', FaceAlpha=0.2, DisplayName='peri-lick')
% histogram(ax, yHatBaseline, 50, FaceColor='red', FaceAlpha=0.2, DisplayName='baseline')

% score(iExp, iHpMove, iHpBaseline, iHpNTrials) = sum(yHatMove > max(yHatBaseline)) ./ length(yHatMove);


xlabel('p(move)')
ylabel('no. trials')
title(ax, sprintf('%s', tr.GetExpName()), Interpreter='none')
legend(ax)

%% Now try applying the model to random times in the session (after timeout_start)