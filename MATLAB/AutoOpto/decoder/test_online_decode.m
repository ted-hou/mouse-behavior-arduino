%% General scheme:
% 1. Start session, record 30 rewarded trials (15 reach, 15 lick)
% 2. For each rewarded trial, get spikerate.baseline and spikerate.move (384, nTrials)
% 3. Build decoder via fitglm(): pMove as a function of spikerate
% 4. For the rest of the session, monitor spikerates continuously, stimOn when pMove > theta (try theta=0.5)
exp = TwoColorExperiment();
%%
exp.save();
exp.saveArduino();
%% Common module (spikeTimeBuffer)
stb = SpikeTimeBuffer(SpikeThreshold=-45, MaxDuration=6, UpdateInterval=0.02, UpdateIntervalPadding=0.01, Debug=false);
stb.connect('10.11.151.172');
%%
stb.start();
%%
stb.stop();

%% Create online decorder
od = OnlineDecoder(stb, exp.LaserArduino);

%% Start collect training data (run this and let the mouse do task) 
% While in STATE_WAITFORTOUCH or STATE_TIMEOUT, continuously generate a 6s buffer of spike times
% onEnter STATE_WAITFORTOUCH or STATE_TIMEOUT, discard buffered spike times
% While in STATE_WAITFORTOUCH or STATE_TIMEOUT, on EVENT_LICK_ON or EVENT_LEVER TOUCHED, calculate spike rates for [-0.5, 0] and [min(-6, -validBufferLength), -2] 
% Accumute spikerate.move and spikerate.baseline, and trialInfo (correct/incorrect reach/lick, tTimeoutStart, tMove)
od.clearEventBuffer();
od.clearTrainingData();
od.startTraining(MinTrialLength=1, BaselineWindow=[-6, -1], MoveWindow=[-0.5, 0]);

%% Stop collect training data
od.stopTraining();

%% Fit model that predicts p(move) as a function of spike rate (logistic regression, usually)
od.fitModel(Holdout=0.1, ShowPlot=true)

%% Test decoder performace by continuously printing decoded p(move)
od.Debug = true;
od.startTesting(UpdateInterval=0.02, BinWidth=0.1);

%% Stop testing decoder
od.stopTesting();
od.Debug = false;

%% Opto-ing

% When in STATE_WAITFORTOUCH or STATE_TIMEOUT
% onEachLoop: fetch spike rates from the last 100ms
% Decode yMove = f(spikeRate_last100ms)
% Start stim when yMove > 0.5 (or some theta)
% onEvent: LEVER_PRESSED or LICK_ON, stop stim
