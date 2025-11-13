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
        SpikeDetectionInterval
        IP
    end

    properties (Transient)
        UpdateTimer
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
            p.addParameter('UpdateInterval', 0.01, @isnumeric)
            p.addParameter('SpikeDetectionInterval', 0.1, @isnumeric)
            p.addParameter('IP', '10.11.151.172', @ischar)
            p.parse(varargin{:})
            obj.SpikeThreshold = p.Results.SpikeThreshold;
            obj.Int16ToMicroVolts = p.Results.Int16ToMicroVolts;
            obj.SampleRate = p.Results.SampleRate;
            obj.MaxDuration = p.Results.MaxDuration;
            obj.UpdateInterval = p.Results.UpdateInterval;
            obj.SpikeDetectionInterval = p.Results.SpikeDetectionInterval;
            obj.IP = p.Results.IP;
            assert(obj.SpikeThreshold < 0, 'SpikeThreshold must be negative, is %g.', obj.SpikeThreshold)

            obj.SpikeTimes = cell(384, 1);
        end

        function Connect(obj, ip)
            if nargin < 2
                ip = obj.IP;
            end
            obj.IP = ip;
            obj.SGLX = SpikeGL(ip);
        end

        function spikeTimes = SpikeDetect(obj, duration)
            nSamples = ceil(duration*obj.SampleRate);
            % data: nSamples x nChannels (int16)
            % headCt: sampleIndex of first sample in matrix
            [data, headSampleIndex] = FetchLatest(obj.SGLX, 2, 0, 2*nSamples); %% js=2: use filtered IM stream buffer; ip=0:?

            data = double(data).*obj.Int16ToMicroVolts; % Convert to uV
            [B, A] = butter(2, [300, 9000]/(obj.SampleRate/2)); % Bandpass
            data = filter(B, A, data); % Bandpass
            data = data(nSamples+1:end, :);
            data = data - median(data, 2); % CAR

            t0 = double(headSampleIndex - 1) ./ obj.SampleRate;
            isBelowThreshold = data < obj.SpikeThreshold;
            spikeTimes = cell(384, 1);
            for iChannel = 1:384
                spikeTimes{iChannel} = t0 + strfind(isBelowThreshold(:, iChannel)', [0, 1, 1, 1])./obj.SampleRate;
            end
        end

        function t = GetTime(obj)
            sampleIndex = GetStreamSampleCount(obj.SGLX, 2, 0);
            t = double(sampleIndex - 1) ./ obj.SampleRate;
        end

        function OnUpdate(obj)
            currentTime = obj.GetTime();
            spikeTimes = obj.SpikeDetect(obj.SpikeDetectionInterval);
            % append new spiketimes
            for iChannel = 1:384
                st = [obj.SpikeTimes{iChannel}, spikeTimes{iChannel}];
                st(st < currentTime - obj.MaxDuration) = [];
                obj.SpikeTimes{iChannel} = unique(st);
            end
            fprintf(repmat('\b', [1, obj.LineLength]));
            currentTimeDisp = seconds(currentTime);
            currentTimeDisp.Format = 'hh:mm:ss.SSS';
            obj.LineLength = fprintf('CurrentTime = %s, Channel0 = %g sp/s, Channel118 = %g sp/s\n', currentTimeDisp, length(obj.SpikeTimes{1})./obj.MaxDuration, length(obj.SpikeTimes{119})./obj.MaxDuration);
        end

        function StartUpdate(obj)
            obj.Connect(obj.IP);
            if ~isempty(obj.UpdateTimer) && isvalid(obj.UpdateTimer)
                stop(obj.UpdateTimer);
            end
            obj.UpdateTimer = timer();
            obj.UpdateTimer.Period = obj.UpdateInterval;
            obj.UpdateTimer.ExecutionMode = 'fixedRate';
            obj.UpdateTimer.TimerFcn = @(~, ~) obj.OnUpdate();

            start(obj.UpdateTimer);
        end

        function StopUpdate(obj)
            if ~isempty(obj.UpdateTimer) && isvalid(obj.UpdateTimer)
                stop(obj.UpdateTimer);
            end
            obj.UpdateTimer = [];
        end
    end
end