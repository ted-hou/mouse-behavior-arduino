%% General scheme:
% 1. Start session, record 30 rewarded trials (15 reach, 15 lick)
% 2. For each rewarded trial, get spikerate.baseline and spikerate.move (384, nTrials)
% 3. Build decoder via fitglm(): pMove as a function of spikerate
% 4. For the rest of the session, monitor spikerates continuously, stimOn when pMove > theta (try theta=0.5)

%% Common module (spikeTimeBuffer)



%% Training (record)
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