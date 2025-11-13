% filename = "C:\SERVER\desmond41\desmond41_20251029\desmond41_20251029\desmond41_20251029_g0\desmond41_20251029_g0_t0.imec0.ap.bin";
clear, clc
% pathname = 'C:\SERVER\desmond41\desmond41_20251029';
pathname = 'C:\SERVER\desmond41\desmond41_20251104'; %change this per session
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

% from parsing above, we have arrays of event timestamps
% every event has an on and off, subtract off-on and get duration
% from durations, make boolean arrays of same length as event lists

% array of valid lick events, requires minimum duration > 0.9ms
selLick = (tr.DigitalEvents.LickOff - tr.DigitalEvents.LickOn) > 0.9e-3;
% array of valid press events, requires minimum duration > 2ms
selPress = (tr.DigitalEvents.PressOff - tr.DigitalEvents.PressOn) > 1.9e-3;

% make trials struct that has 3 fields
% correctPress is a field that contains multiple objects of class Trial
% trials.correctPress is 1x62 array of Trial objects, so 62 movements
% each object (movement) has a start and stop property (timestamp)
% start is timeoutoff, stop is onset of movement (selpress or sellick)
trials.correctPress = Trial([0, tr.DigitalEvents.TimeoutOff, Inf], tr.DigitalEvents.PressOn(selPress), stopMode='first'); % I think these include opto lever retract
trials.correctLick = Trial([0, tr.DigitalEvents.TimeoutOff, Inf], tr.DigitalEvents.LickOn(selLick), stopMode='first'); % I think these include opto lever retract
trials.reward = Trial([0, tr.DigitalEvents.TimeoutOff, Inf], tr.DigitalEvents.RewardOn, stopMode='first'); % Surrogate for move, includes both kinds mvmt

%% Get baseline and move spike rates
% warning: this section takes a while to run
clear p

% set windows for calculating average baseline and movement spike rate
% 0 = onset of movement (end of trial)
p.baselineWindow = [-6, -2];
p.moveWindow = [-0.5, 0];

clear spikeRates
spikes = cell(384, 1);

% 2d array of (rows, cols) = (channel #, avg rate during window)
% every mvmt contributes one column to both baseline and move spikerates
spikeRates.baseline = NaN(384, length(trials.reward)); % (rows, cols)
spikeRates.move = NaN(384, length(trials.reward));
% iterate thru mvmts
for iTrial = 1:length(trials.reward)
    tr.ReadIMEC(Channels=1:384, TimeWindow=trials.reward(iTrial).Stop + p.baselineWindow, ReadMode='simple') % pulls voltage data -6 to -2s before ith mvmt
    isBelowThreshold = tr.Amplifier.Data < threshold; % spike detection function
    for iChannel = 1:384 % apply boolean threshold crossing
        spikes{iChannel} = strfind(isBelowThreshold(iChannel, :), [0, 1]) + 1;
    end % convert to rates
    spikeRates.baseline(1:384, iTrial) = cellfun(@length, spikes) ./ diff(p.baselineWindow);

    % do same for movement windowa
    tr.ReadIMEC(Channels=1:384, TimeWindow=trials.reward(iTrial).Stop + p.moveWindow, ReadMode='simple')
    isBelowThreshold = tr.Amplifier.Data < threshold;
    for iChannel = 1:384
        spikes{iChannel} = strfind(isBelowThreshold(iChannel, :), [0, 1]) + 1;
    end
    spikeRates.move(1:384, iTrial) = cellfun(@length, spikes) ./ diff(p.moveWindow);
end

% spikeRates.baseline is 2d array, all channels by all avg firing rates
% columns is per trial
% note: we are working with CHANNEL readouts, not sorted spikes
% so spikes on multiple channels are overcounted
% this is fine for our purposes.

%% Fit LM
close all

% split into first 30 trials for training, rest for testing
nTrialsTrain = 30;
nTrialsTest = length(trials.reward) - nTrialsTrain;

% matrices for training and testing
% xtrain has length(trials.rewards) samples, each is 384-dimensional
XTrain = transpose([spikeRates.baseline(:, 1:nTrialsTrain), spikeRates.move(:, 1:nTrialsTrain)]);
% ytrain is length(trials.rewards) labels (0s then 1s)
yTrain = [zeros(nTrialsTrain, 1); ones(nTrialsTrain, 1)];
XTest = transpose([spikeRates.baseline(:, nTrialsTrain+1:end), spikeRates.move(:, nTrialsTrain+1:end)]);
yTest = [zeros(nTrialsTest, 1); ones(nTrialsTest, 1)];

% This is needed because numTrials << numNeurons, so the regression won't
% work well. But the population-average (1D) works fairly well. Could also
% try the first n PCs (PCA, n<numNeurons) if we need better performance
XTrain = mean(XTrain, 2); % collapse channels into single mean firing
XTest = mean(XTest, 2);

% so we end up with ntrials vector of average firing rates
% and corresponding label vector

%fit logistic regression model
mdl = fitglm(XTrain, yTrain, 'linear', Distribution='binomial', Link='logit');
% predict on test data
yHatMove = mdl.predict(XTest(yTest==1, :)); % should cluster near 1
yHatBaseline = mdl.predict(XTest(yTest==0, :)); % should cluster near 0

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

%% How early can we detect movement?

% first stupid version
% run decoder from above on 100ms intervals of spike data from -2 to 0s
% use xtest and y test in a scatter plot
% blue move, red baseline
% x is time (avg firing rate calculated at 100ms intervals)
% y is probability of movement (decoder value)
% horizontal line at p = 0.5
% should see clusters separating  vertically over time

% i think i have to rerun readimec because i need firing rates w higher
% resolution

% so i think i should redo readimec and get voltage data in time rois
% 

















