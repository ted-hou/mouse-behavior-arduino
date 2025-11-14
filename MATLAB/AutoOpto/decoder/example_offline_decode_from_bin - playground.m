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

%% temporarily splitting this section for ease of running

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

% PARAMETERS
testTrial = 7;                          % which test trial to analyze, 37 out of total
binSize = 0.1;                            % 100 ms
edges = -6:binSize:0;                     % edges from -6 to 0 sec
centers = edges(1:end-1) + binSize/2;     % center time of each bin
nBins = length(centers);

% GET EVENT TIME FOR THIS TRIAL
eventTime = trials.correctPress(37).Stop;

% STORAGE
pBins = nan(1, nBins);
labelBins = nan(1, nBins);

% LOOP OVER 100 ms BINS
for b = 1:nBins
    
    % Current bin window relative to movement
    t0 = eventTime + edges(b);
    t1 = eventTime + edges(b+1);

    % Read data for this bin
    tr.ReadIMEC(Channels=1:384, TimeWindow=[t0 t1], ReadMode='simple');

    % Spike detection (same as training)
    isBelow = tr.Amplifier.Data < threshold;
    spikeCounts = sum(diff(isBelow,1,2)==1,2);   % 0→1 crossings
    rate = spikeCounts / binSize;                % Hz
    
    % Decoder input: population-average
    X = mean(rate);

    % Decoder output
    pBins(b) = mdl.predict(X);

    % True label for the bin (0 = baseline, 1 = move)
    if centers(b) < -0.5
        labelBins(b) = 0;  % baseline
    else
        labelBins(b) = 1;  % movement-related bin
    end
end

%plot
figure; hold on

% baseline bins (red)
scatter(centers(labelBins==0), pBins(labelBins==0), 40, 'r', 'filled')

% movement bins (blue)
scatter(centers(labelBins==1), pBins(labelBins==1), 40, 'b', 'filled')

% connecting line
plot(centers, pBins, 'k-', 'LineWidth', 1.5)

yline(0.5,'k--','LineWidth',1.2)
xlabel('Time relative to movement (s)')
ylabel('Decoder output p(move)')
title(sprintf('Decoder trajectory for test trial %d', testTrial))
ylim([0 1])
legend({'baseline bins','movement bins'}, 'Location','best')

%% DO FOR ALL TRIALS TG

% PARAMETERS
binSize = 0.1;                   % 100 ms
edges = -6:binSize:0;            % -6 → 0 seconds
centers = edges(1:end-1) + binSize/2;
nBins = length(centers);

% Which trials?  (all test trials)
testTrialIdx = (nTrialsTrain+1) : length(trials.reward);
nTestTrials = length(testTrialIdx);

% STORAGE
pAll = nan(nTestTrials, nBins);   % decoder outputs
labelAll = nan(nTestTrials, nBins);  % true labels per bin (0 or 1)

% LOOP OVER ALL TEST TRIALS
for t = 1:nTestTrials
    
    fullIndex = testTrialIdx(t);        % convert test index → full index
    eventTime = trials.reward(fullIndex).Stop;
    
    for b = 1:nBins
        
        t0 = eventTime + edges(b);
        t1 = eventTime + edges(b+1);

        % Load voltage data for this bin
        tr.ReadIMEC(Channels=1:384, TimeWindow=[t0 t1], ReadMode='simple');

        % Spike detection (0→1 crossings)
        isBelow = tr.Amplifier.Data < threshold;
        spikeCounts = sum(diff(isBelow,1,2)==1,2);
        rate = spikeCounts / binSize;

        % Decoder input: population-average firing rate
        X = mean(rate);

        % Decoder prediction
        pAll(t, b) = mdl.predict(X);

        % True bin label
        labelAll(t, b) = double(centers(b) >= -0.5);   % 0=baseline, 1=move

    end
end

% PLOT ALL TRIALS ON ONE FIGURE
figure; hold on

for t = 1:nTestTrials
    
    % Get data for this trial
    p_t = pAll(t,:);
    lab_t = labelAll(t,:);   % 0 or 1 per bin
    
    % Scatter, using red for baseline and blue for movement
    scatter(centers(lab_t==0), p_t(lab_t==0), 25, 'r', 'filled');
    scatter(centers(lab_t==1), p_t(lab_t==1), 25, 'b', 'filled');

    % connecting line
    plot(centers, p_t, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
end

yline(0.5, 'k--', 'LineWidth', 1.5);
xlabel('Time (s) relative to movement');
ylabel('Decoder output p(move)');
title('Decoder trajectories for ALL test trials');
ylim([0 1])


%% COUNT CORRECT PER TIME BIN

% 4-COLOR HISTOGRAM OF DECODER PERFORMANCE
% Categories:
% 1 = correct baseline (dark red)
% 2 = incorrect -> predicted move during baseline (light blue)
% 3 = incorrect -> predicted baseline during movement (light red)
% 4 = correct movement (dark blue)

% Preallocate category counts
catCounts = zeros(4, nBins);

for b = 1:nBins
    
    % ground truth for this bin
    isMoveBin = centers(b) >= -0.5;   % true label: movement vs baseline
    
    for t = 1:nTrials
        
        p = pAll(t,b);
        
        if ~isMoveBin
            % TRUE BASELINE
            if p < 0.99
                % correct baseline
                catCounts(1,b) = catCounts(1,b) + 1;
            else
                % incorrect movement prediction
                catCounts(2,b) = catCounts(2,b) + 1;
            end
            
        else
            % TRUE MOVEMENT
            if p < 0.99
                % incorrect baseline prediction
                catCounts(3,b) = catCounts(3,b) + 1;
            else
                % correct movement
                catCounts(4,b) = catCounts(4,b) + 1;
            end
        end
    end
end

% Normalize by number of trials
catProportions = catCounts ./ nTrials;   % 4 × nBins

% Plot
figure; hold on
bar(centers, catProportions', 'stacked');

% Define colors in row order:
% dark red, light blue, light red, dark blue
myColors = [
    1 0 0;    % correct baseline
    0.98 0.85 0.87;  % incorrect baseline->movement
    0.5843 0.8157 0.9882;  % incorrect movement->baseline
    0 0 1     % correctmovement
];
colororder(myColors);

xlabel('Time (s relative to movement)')
ylabel('Proportion of trials')
title('Decoder correctness by time bin')
ylim([0 1])
xline(-0.5, '--k', 'LineWidth', 1.5)  % boundary between baseline and movement



