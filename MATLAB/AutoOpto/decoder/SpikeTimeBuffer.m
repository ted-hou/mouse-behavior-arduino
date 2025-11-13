classdef SpikeTimeBuffer < handle
    %SPIKETIMEBUFFER Keeps a buffer of recent spike times

    properties
        SGLX
        SpikeTimes
        SpikeThreshold
        Int16ToMicroVolts
        SampleRate
        MaxDuration % Buffer capacity in seconds
        UpdateInterval
        UpdateIntervalPadding
        IP
    end

    properties (Transient)
        Timer
        Debug = false % Set to true to print debug messages
        LastUpdated = 0
    end

    properties (Transient, Hidden)
        LineLength = 0
    end

    methods
        function obj = SpikeTimeBuffer(varargin)
            p = inputParser();
            p.addParameter('SpikeThreshold', -75, @isnumeric) % Spike detection threshold (uV)
            p.addParameter('Int16ToMicroVolts', 3.027343750000000, @isnumeric) % IMEC records in int16, to convert to uV, multiply by this factor
            p.addParameter('SampleRate', 30000, @isnumeric);
            p.addParameter('MaxDuration', 10, @isnumeric);
            p.addParameter('UpdateInterval', 0.02, @isnumeric)
            p.addParameter('UpdateIntervalPadding', 0.02, @isnumeric)
            p.addParameter('IP', '10.11.151.172', @ischar)
            p.addParameter('Debug', false, @islogical)
            p.parse(varargin{:})
            obj.SpikeThreshold = p.Results.SpikeThreshold;
            obj.Int16ToMicroVolts = p.Results.Int16ToMicroVolts;
            obj.SampleRate = p.Results.SampleRate;
            obj.MaxDuration = p.Results.MaxDuration;
            obj.UpdateInterval = p.Results.UpdateInterval;
            obj.UpdateIntervalPadding = p.Results.UpdateIntervalPadding;
            obj.IP = p.Results.IP;
            obj.Debug = p.Results.Debug;
            assert(obj.SpikeThreshold < 0, 'SpikeThreshold must be negative, is %g.', obj.SpikeThreshold)

            obj.SpikeTimes = cell(384, 1);
        end

        function connect(obj, ip)
            if nargin < 2
                ip = obj.IP;
            end
            obj.IP = ip;
            obj.SGLX = SpikeGL(ip);
        end

        function spikeTimes = detectSpikes(obj, duration)
            nSamples = ceil(duration*obj.SampleRate);
            % data: nSamples x nChannels (int16)
            % headCt: sampleIndex of first sample in matrix
            [data, headSampleIndex] = FetchLatest(obj.SGLX, 2, 0, min(2*nSamples, obj.SampleRate*2)); %% js=2: use filtered IM stream buffer; ip=0:?

            data = double(data).*obj.Int16ToMicroVolts; % Convert to uV
            [B, A] = butter(2, [300, 9000]/(obj.SampleRate/2)); % Bandpass
            data = filter(B, A, data); % Bandpass
            data = data(nSamples+1:end, :);
            data = data - mean(data, 2); % CAR, we do mean since it's faster(?) than median 

            t0 = double(headSampleIndex - 1) ./ obj.SampleRate;
            isBelowThreshold = data < obj.SpikeThreshold;
            spikeTimes = cell(384, 1);
            for iChannel = 1:384
                spikeTimes{iChannel} = t0 + strfind(isBelowThreshold(:, iChannel)', [0,0,0,0,0, 1, 1, 1])./obj.SampleRate;
            end
        end

        function t = getTime(obj)
            sampleIndex = GetStreamSampleCount(obj.SGLX, 2, 0);
            t = double(sampleIndex - 1) ./ obj.SampleRate;
        end

        function onUpdate(obj)
            currentTime = obj.getTime();
            timeElapsed = currentTime - obj.LastUpdated;
            spikeTimes = obj.detectSpikes(min(timeElapsed + obj.UpdateIntervalPadding, min(obj.MaxDuration, 2)));
            % append new spiketimes
            for iChannel = 1:384
                st = [obj.SpikeTimes{iChannel}, spikeTimes{iChannel}];
                st(st < currentTime - obj.MaxDuration) = [];
                obj.SpikeTimes{iChannel} = unique(st);
            end
            if obj.Debug
                fprintf(repmat('\b', [1, obj.LineLength]));
                currentTimeDisp = seconds(currentTime);
                currentTimeDisp.Format = 'hh:mm:ss.SSS';
                obj.LineLength = fprintf('Iteration %i: CurrentTime = %s, TimeElapsed = %.1f ms (TimerAverage = %.1f ms), Channel0 = %.1f sp/s, Channel4 = %.1f sp/s\n', obj.Timer.TasksExecuted, currentTimeDisp, 1000*timeElapsed, 1000*obj.Timer.AveragePeriod, length(obj.SpikeTimes{1})./obj.MaxDuration, length(obj.SpikeTimes{5})./obj.MaxDuration);
            end
            obj.LastUpdated = currentTime;
        end

        function start(obj)
            obj.connect(obj.IP);
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
            end
            obj.Timer = timer();
            obj.Timer.Period = obj.UpdateInterval;
            obj.Timer.ExecutionMode = 'fixedRate'; % fixedDelay, fixedSpacing
            obj.Timer.TimerFcn = @(~, ~) obj.onUpdate();

            start(obj.Timer);
        end

        function stop(obj)
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
            end
            obj.Timer = [];
        end
    end
end