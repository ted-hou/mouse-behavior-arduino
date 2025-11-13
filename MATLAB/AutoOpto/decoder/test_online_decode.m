%% General scheme:
% 1. Start session, record 30 rewarded trials (15 reach, 15 lick)
% 2. For each rewarded trial, get spikerate.baseline and spikerate.move (384, nTrials)
% 3. Build decoder via fitglm(): pMove as a function of spikerate
% 4. For the rest of the session, monitor spikerates continuously, stimOn when pMove > theta (try theta=0.5)

%% Common module (spikeTimeBuffer)
stb = SpikeTimeBuffer(SpikeThreshold=-30, MaxDuration=6, UpdateInterval=0.02, UpdateIntervalPadding=0.01, Debug=true);
stb.connect('10.11.151.172');
stb.start();
%%
stb.stop();
%% Plot a channel (for testing)
% channel = 4 + 1;
% nSamples=300;
% stb.connect();[data, headSampleIndex] = FetchLatest(stb.SGLX, 2, 0, nSamples*2); %% js=2: use filtered IM stream buffer; ip=0:?4
% data = double(data.*stb.Int16ToMicroVolts);
% 
% [B, A] = butter(2, [300, 9000]/(stb.SampleRate/2));
% data = filter(B, A, data);
% data = data - median(data, 2);
% 
% plot(data(:, channel))
% xlim([nSamples+1, 2*nSamples])
% ylim([-61.5, 61.5])
%% Training (record)
exp = TwoColorExperiment();
od = OnlineDecoder(stb, exp.LaserArduino);

% While in STATE_WAITFORTOUCH or STATE_TIMEOUT, continuously generate a 6s buffer of spike times
% onEnter STATE_WAITFORTOUCH or STATE_TIMEOUT, discard buffered spike times
% While in STATE_WAITFORTOUCH or STATE_TIMEOUT, on EVENT_LICK_ON or EVENT_LEVER TOUCHED, calculate spike rates for [-0.5, 0] and [min(-6, -validBufferLength), -2] 
% Accumute spikerate.move and spikerate.baseline, and trialInfo (correct/incorrect reach/lick, tTimeoutStart, tMove)

%% Training (build model)
% Call a function to stop collecting training data
% Some manual curation
% Build GLM
% k-fold validate GLM, find best theta

%% Opto-ing

% When in STATE_WAITFORTOUCH or STATE_TIMEOUT
% onEachLoop: fetch spike rates from the last 100ms
% Decode yMove = f(spikeRate_last100ms)
% Start stim when yMove > 0.5 (or some theta)
% onEvent: LEVER_PRESSED or LICK_ON, stop stim