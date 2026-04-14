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
        UpdateIntervalActual % Measured update interval
        IP
        Filter
    end

    properties (Transient)
        Timer
        Debug = false % Set to true to print debug messages
        LastUpdated = 0
        Pool
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
            [B, A] = butter(2, [300, 9000]/(obj.SampleRate/2));
            obj.Filter = struct(B=B, A=A);
        end

        function connect(obj, ip)
            if nargin < 2
                ip = obj.IP;
            end
            obj.IP = ip;
            obj.SGLX = SpikeGL(ip);
        end

        % Not thread safe (apparently because reference to obj.SGLX)
        function [data, t0] = fetch(obj, duration)
            nSamples = ceil(duration*obj.SampleRate);
            % data: nSamples x nChannels (int16)
            % headCt: sampleIndex of first sample in matrix
            [data, headSampleIndex] = FetchLatest(obj.SGLX, 2, 0, min(nSamples, obj.SampleRate*2)); %% js=2: use filtered IM stream buffer; ip=0:?
            data = double(data).*obj.Int16ToMicroVolts; % Convert to uV
            t0 = double(headSampleIndex - 1) ./ obj.SampleRate;
        end

        function t = getTime(obj)
            sampleIndex = GetStreamSampleCount(obj.SGLX, 2, 0);
            t = double(sampleIndex - 1) ./ obj.SampleRate;
        end

        function i = timestampToSampleIndex(obj, t)
            i = round(t.*obj.SampleRate + 1);
        end

        function onUpdate(obj)
            currentTime = obj.getTime();
            timeElapsed = currentTime - obj.LastUpdated;
            [data, t0] = obj.fetch(min(timeElapsed + obj.UpdateIntervalPadding, min(obj.MaxDuration, 0.1))); % SpikeGLX only has 2 seconds of buffered data

            % Can we parfeval everything below?
            discardBefore = currentTime - obj.MaxDuration;

            % SpikeTimeBuffer.detectSpikes(data, t0, currentTime, obj.SampleRate, obj.SpikeThreshold, obj.SpikeTimes, discardBefore, obj.Filter.B, obj.Filter.A);
            F = parfeval(obj.Pool, @SpikeTimeBuffer.detectSpikes, 2, data, t0, currentTime, obj.SampleRate, obj.SpikeThreshold, obj.SpikeTimes, discardBefore, obj.Filter.B, obj.Filter.A);
            afterAll(F, @obj.updateSpikeTimes, 0);

            if obj.Debug
                obj.print();
            end
        end

        function updateSpikeTimes(obj, spikeTimes, currentTime)
            obj.SpikeTimes = spikeTimes;
            obj.UpdateIntervalActual = currentTime - obj.LastUpdated;
            obj.LastUpdated = currentTime;
        end

        function print(obj)
            % persistent ll
            tDisp = seconds(obj.LastUpdated);
            tDisp.Format = 'hh:mm:ss.SSS';
            fprintf('Iteration %i: LastUpdate = %s, UpdateIntervalActual=%.1f ms, TimerAverage = %.1f ms; Channel0 = %.1f sp/s, Channel4 = %.1f sp/s\n', ...
                obj.Timer.TasksExecuted, tDisp, 1000*obj.UpdateIntervalActual, 1000*obj.Timer.AveragePeriod, length(obj.SpikeTimes{1})./obj.MaxDuration, length(obj.SpikeTimes{5})./obj.MaxDuration);
        end

        function start(obj)
            if isempty(obj.Pool) || ~isvalid(obj.Pool)
                if ~isempty(gcp("nocreate"))
                    delete(gcp("nocreate"))
                end
                % obj.Pool = parpool('Threads');
                obj.Pool = backgroundPool;
            end
            obj.connect(obj.IP);
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = timer();
            obj.Timer.Period = obj.UpdateInterval;
            obj.Timer.ExecutionMode = 'fixedSpacing'; % fixedRate, fixedDelay, fixedSpacing; 'fixedSpacing' worked best it seems
            obj.Timer.TimerFcn = @(~, ~) obj.onUpdate();

            start(obj.Timer);
        end

        function stop(obj)
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = [];
            if ~isempty(obj.Pool) && isvalid(obj.Pool)
                delete(obj.Pool);
            end
        end

        function value = isRunning(obj)
            value = ~isempty(obj.Timer) && isvalid(obj.Timer);
        end

        function sr = getSpikeRates(obj, window)
            sr = zeros(1, 384);
            for iChannel = 1:384
                sr(iChannel) = nnz(obj.SpikeTimes{iChannel} >= window(1) & obj.SpikeTimes{iChannel} < window(2)) ./ (window(2) - window(1));
            end
        end

    end

    methods (Static)

        function [spikeTimes, currentTime] = detectSpikes(data, t0, currentTime, sampleRate, spikeThreshold, spikeTimes, discardBefore, B, A)
            data = filter(B, A, data); % Bandpass
            data = data - mean(data, 2); % CAR, we do mean since it's faster(?) than median 

            isBelowThreshold = data < spikeThreshold;
            % spikeTimes = cell(384, 1);
            for iChannel = 1:384
                st = [spikeTimes{iChannel}, t0 + strfind(isBelowThreshold(:, iChannel)', [0,0,0,0,0, 1, 1, 1])./sampleRate];
                st(st < discardBefore) = [];
                spikeTimes{iChannel} = unique(st);
            end
        end
        % % Multichannel: data is nSamples x nChannels
        % function [data] = filterData(data, B, A)
        %     % [B, A] = butter(2, [300, 9000]/(sampleRate/2)); % Bandpass
        %     data = filter(B, A, data); % Bandpass
        %     data = data - mean(data, 2); % CAR, we do mean since it's faster(?) than median 
        % end
        % 
        % % Singlechannel: data is 1 x nSamples, for parallel processing with
        % % parfeval
        % function [spikeTimes, currentTime, iChannel] = detectSpikes(data, t0, currentTime, sampleRate, spikeThreshold, spikeTimes, discardBefore, iChannel)
        %     st = [spikeTimes, t0 + strfind(data < spikeThreshold, [0,0,0,0,0, 1, 1, 1])./sampleRate];
        %     st(st < discardBefore) = [];
        %     spikeTimes = unique(st);
        % end

    end
end