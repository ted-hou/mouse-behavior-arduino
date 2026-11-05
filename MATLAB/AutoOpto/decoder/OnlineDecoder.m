classdef OnlineDecoder < handle
    %ONLINEDECODER Gives movement probability based on spike

    properties
        SpikeTimeBuffer
        Arduino
        EventBuffer = struct(LEVER_PRESSED=[], LICK=[], TIMEOUT_START=[], HasMadeFirstMove=false)
        Params = struct(Train=[], Test=[], Opto=[])
        Data = struct(Train=struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={}), Test=struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={}))
        Model
        ChannelMask
        Buffer = struct(Data=struct(t=[], x=[], xMasked=[], p=[]), CurrentIndex=[], Length=0)
        Debug = false
    end

    properties (Transient, SetAccess=protected)
        Mode = "off" % "off", "training", "testing", "opto"
        PMove = NaN
        IsLaserOn = [false, false]
        HasStimHappened = false
        ArduinoState = ""
        Files = struct(DecodedData=-1, Events=-1);
    end

    properties (Transient)
        Timer
        OptoTimer
        Listeners
        Dialog
        UIHandles
    end

    methods
        function obj = OnlineDecoder(stb, ac)
            if isempty(stb) || isempty(ac)
                return
            end
            obj.SpikeTimeBuffer = stb;
            obj.Arduino = ac;
            obj.Mode = "off";
            obj.Listeners.StateChanged = addlistener(obj.Arduino, 'StateChanged', @obj.onStateChanged);
            obj.Listeners.EventMarkerReceived = addlistener(obj.Arduino, 'EventMarkerReceived', @obj.onEventMarkerReceived);
            obj.initBuffer(round(6/0.02));
        end

        function mask = applyChannelMask(obj, varargin)
            % See OnlineDecoder.getChannelMap() for explanations;
            p = inputParser();
            p.addParameter('ml', 1.300, @(x) isnumeric(x) && x>=0); % ML (left hemisphere is negative, we implant on the right mostly)
            p.addParameter('ap', -3.280, @isnumeric);
            p.addParameter('dvFromDura', -4.700, @isnumeric); % tip depth from dura (which is usually 200um below bregma for SNr)
            p.addParameter('rotation', 0, @isnumeric); % degress of CCW rotation along z axis looking from above (default is zero for the orientation described above)
            p.addParameter('mlWindow', [-Inf, Inf], @(x) isnumeric(x) && length(x)==2)
            p.addParameter('apWindow', [-Inf, Inf], @(x) isnumeric(x) && length(x)==2)
            p.addParameter('dvFromDuraWindow', [-Inf, Inf], @(x) isnumeric(x) && length(x)==2)
            p.parse(varargin{:})
            ml = p.Results.ml;
            ap = p.Results.ap;
            dvFromDura = p.Results.dvFromDura;
            rotation = p.Results.rotation;
            mlWindow = p.Results.mlWindow;
            apWindow = p.Results.apWindow;
            dvFromDuraWindow = p.Results.dvFromDuraWindow;

            map = OnlineDecoder.getChannelMap(ml=ml, ap=ap, dvFromDura=dvFromDura, rotation=rotation);
            mask = map.ml >= mlWindow(1) & map.ml <= mlWindow(2);
            mask = mask & (map.ap >= apWindow(1) & map.ap <= apWindow(2));
            mask = mask & (map.dvFromDura >= dvFromDuraWindow(1) & map.dvFromDura <= dvFromDuraWindow(2));

            obj.ChannelMask = mask;
        end

        % Start collecting training data
        function startTraining(obj, varargin)
            p = inputParser();
            p.addParameter('MinTrialLength', 1, @isnumeric)
            p.addParameter('BaselineWindow', [-6, -1], @(x) isnumeric(x) && length(x)==2)
            p.addParameter('MoveWindow', [-0.5, 0], @(x) isnumeric(x) && length(x)==2)
            p.parse(varargin{:})
            obj.Params.Train.MinTrialLength = p.Results.MinTrialLength;
            obj.Params.Train.BaselineWindow = p.Results.BaselineWindow;
            obj.Params.Train.MoveWindow = p.Results.MoveWindow;

            assert(obj.Mode == "off", "Current mode is %s, expected ""off"".", obj.Mode)
            assert(obj.SpikeTimeBuffer.isRunning(), "SpikeTimeBuffer is not running.")
            obj.Mode = "training";
        end

        function stopTraining(obj)
            assert(obj.Mode == "training", "Current mode is %s, expected ""training"".", obj.Mode)
            obj.Mode = "off";
        end

        function startTesting(obj, varargin)
            assert(obj.Mode == "off", "Current mode is %s, expected ""off"".", obj.Mode)
            obj.Mode = "testing";

            p = inputParser();
            p.addParameter('UpdateInterval', 0.02, @isnumeric)
            p.addParameter('BinWidth', 0.1, @isnumeric)
            p.parse(varargin{:})
            updateInterval = p.Results.UpdateInterval;
            binWidth = p.Results.BinWidth;

            obj.Params.Test.UpdateInterval = updateInterval;
            obj.Params.Test.BinWidth = binWidth;

            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = timer();
            obj.Timer.Period = updateInterval;
            obj.Timer.ExecutionMode = 'fixedRate'; % fixedDelay, fixedSpacing
            obj.Timer.TimerFcn = @(~, ~) obj.onTestingUpdate();

            start(obj.Timer);
        end

        function stopTesting(obj)
            assert(obj.Mode == "testing", "Current mode is %s, expected ""testing"".", obj.Mode)
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = [];
            obj.Mode = "off";
        end

        function onTestingUpdate(obj)
            [pMove, t, X] = obj.decodeNow(obj.Params.Test.BinWidth);
            obj.PMove = pMove;

            if obj.Debug
                currentTimeDisp = seconds(t);
                currentTimeDisp.Format = 'hh:mm:ss.SSS';
                fprintf('CurrentTime = %s, X = %.1f sp/s, P(Move) = %.0f%%\n', currentTimeDisp, X, 100*pMove);
            end
        end

        function planAutoOpto(obj, varargin)
            p = inputParser();
            p.addParameter('AOutValues', [4095, 0], @isnumeric) % 0 - laser off control; if two rows, 2nd row is for laser 2 (orange)
            p.addParameter('Durations', [1, 3], @isnumeric);
            p.parse(varargin{:})

            % condition(iCond, :) =: [laser, aout, duration]
            conditions = zeros(size(p.Results.AOutValues, 1)*size(p.Results.AOutValues, 2)*length(p.Results.Durations), 2);

            iCond = 0;
            for iLaser = 1:size(p.Results.AOutValues, 1)
                for iAOutValue = 1:size(p.Results.AOutValues, 2)
                    for iDuration = 1:length(p.Results.Durations)
                        iCond = iCond + 1;
                        conditions(iCond, 1:3) = [iLaser, p.Results.AOutValues(iLaser, iAOutValue), p.Results.Durations(iDuration)];
                    end
                end
            end

            % Randomize conditions
            conditions = conditions(randperm(size(conditions, 1)), :);

            % Save plan
            plan = struct('Length', [], 'Index', 0, 'Completed', false, 'Conditions', []);
            plan.Length     = size(conditions, 1);
            plan.Index      = 0;
            plan.Completed  = false;
            plan.Conditions = conditions; % (iCond, [iLaser, aout, duration])

            obj.Params.Opto.Plan = plan;

            fprintf("AutoOpto plan contains %i conditions in the following (randomized) order:\n", plan.Length);
            disp(plan.Conditions)
        end

        function startAutoOpto(obj, varargin)
            assert(obj.Mode == "off", "Current mode is %s, expected ""off"".", obj.Mode)            
            obj.Mode = "opto";

            p = inputParser();
            p.addParameter('UpdateInterval', 0.02, @isnumeric)
            p.addParameter('BinWidth', 0.1, @isnumeric)
            p.addParameter('Threshold', 0.5, @(x) isnumeric(x) && x<=1 && x>=0)
            % p.addParameter('Duration', 0.5, @(x) isnumeric(x) && x>=0)
            % p.addParameter('AOutValue', 4095, @isnumeric)
            p.addParameter('WaitAtLeastSeconds', 1)
            p.parse(varargin{:})
            updateInterval = p.Results.UpdateInterval;
            binWidth = p.Results.BinWidth;

            obj.Params.Opto.UpdateInterval = updateInterval;
            obj.Params.Opto.BinWidth = binWidth;
            obj.Params.Opto.Threshold = p.Results.Threshold;
            % obj.Params.Opto.Duration = p.Results.Duration;
            % obj.Params.Opto.AOutValue = p.Results.AOutValue;
            obj.Params.Opto.WaitAtLeastSeconds = p.Results.WaitAtLeastSeconds;

            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = timer();
            obj.Timer.Period = updateInterval;
            obj.Timer.ExecutionMode = 'fixedRate'; % fixedDelay, fixedSpacing
            obj.Timer.TimerFcn = @(~, ~) obj.onAutoOptoUpdate();

            start(obj.Timer);
        end

        function stopAutoOpto(obj)
            assert(obj.Mode == "opto", "Current mode is %s, expected ""opto"".", obj.Mode)
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = [];
            if ~isempty(obj.OptoTimer) && isvalid(obj.OptoTimer)
                stop(obj.OptoTimer);
                delete(obj.OptoTimer);
            end
            obj.OptoTimer = [];
            if any(obj.IsLaserOn)
                obj.setLaser(1, false);
                obj.setLaser(2, false);
            end
            obj.Mode = "off";
        end

        function onAutoOptoUpdate(obj)
            [pMove, t, X] = obj.decodeNow(obj.Params.Opto.BinWidth);
            obj.PMove = pMove;

            % In TIMEOUT/WAITFORTOUCH, start opto if pMove exceeds threshold
            % obj.getTimeSinceTimeoutStart(t)
            if pMove > obj.Params.Opto.Threshold && ~any(obj.IsLaserOn) && ismember(obj.ArduinoState, ["TIMEOUT", "WAITFORTOUCH"]) && ~obj.HasStimHappened && obj.getTimeSinceTimeoutStart(t) >= obj.Params.Opto.WaitAtLeastSeconds
                % Fetch conditions from plan
                obj.Params.Opto.Plan.Index = obj.Params.Opto.Plan.Index + 1;
                if obj.Params.Opto.Plan.Index > obj.Params.Opto.Plan.Length
                    obj.Params.Opto.Plan.Completed = true;
                    obj.Params.Opto.Plan.Index = 1;
                end
                iLaser = obj.Params.Opto.Plan.Conditions(obj.Params.Opto.Plan.Index, 1);
                aout = obj.Params.Opto.Plan.Conditions(obj.Params.Opto.Plan.Index, 2);
                duration = obj.Params.Opto.Plan.Conditions(obj.Params.Opto.Plan.Index, 3);

                % Turn laser on
                if ~isgraphics(obj.Dialog)
                    obj.setLaser(iLaser, true, aout); % to be replaced with startLiveOpto
                else
                    obj.startPulsedOrContOpto();
                end
                obj.HasStimHappened = true;

                % Schedule laser to turn off after "Duration"    
                if ~isempty(obj.OptoTimer) && isvalid(obj.OptoTimer)
                    stop(obj.OptoTimer);
                    delete(obj.OptoTimer);
                end
                obj.OptoTimer = timer();
                obj.OptoTimer.StartDelay = duration;
                obj.OptoTimer.ExecutionMode = 'singleShot'; % fixedDelay, fixedSpacing
                if ~isgraphics(obj.Dialog)
                    obj.OptoTimer.TimerFcn = @(~, ~) obj.setLaser(iLaser, false);
                else
                    obj.OptoTimer.TimerFcn = @(~, ~) obj.stopPulsedOrContOpto();
                end
                start(obj.OptoTimer);


                currentTimeDisp = seconds(t);
                currentTimeDisp.Format = 'hh:mm:ss.SSS';
                if ~isgraphics(obj.Dialog)
                    fprintf("Stim:%s; P(Move)=%.1f%%, iCond=%i, iLaser=%i, AOut=%g, Duration=%gs\n", currentTimeDisp, pMove*100, obj.Params.Opto.Plan.Index, iLaser, aout, duration)
                else
                    fprintf("LiveOptoStim:%s; P(Move)=%.1f%%, iCond=%i, Duration=%gs\n", currentTimeDisp, pMove*100, obj.Params.Opto.Plan.Index, duration)
                end
            end
        end

        function fitModel(obj, varargin)
            p = inputParser();
            p.addParameter('Holdout', 0, @isnumeric)
            p.addParameter('ShowPlot', false, @islogical)
            p.parse(varargin{:})
            holdout = p.Results.Holdout;
            showPlot = p.Results.ShowPlot;

            nTrials = length(obj.Data.Train);
            if holdout > 0
                cvp = cvpartition(nTrials, Holdout=0.3);
                isTraining = cvp.training();
                isTest = cvp.test();
            else
                isTraining = true(nTrials, 1);
                isTest = false(nTrials, 1);
            end
            nTrain = nnz(isTraining);
            nTest = nnz(isTest);

            XTrain = [vertcat(obj.Data.Train(isTraining).XBaseline); vertcat(obj.Data.Train(isTraining).XMove)];
            XTrain = mean(XTrain, 2);
            yTrain = [zeros(nTrain, 1); ones(nTrain, 1)];
            
            mdl = fitglm(XTrain, yTrain, 'linear', Distribution='binomial', Link='logit');

            yHatTrainMove = mdl.predict(XTrain(yTrain==1, :)); % should cluster near 1
            yHatTrainBaseline = mdl.predict(XTrain(yTrain==0, :)); % should cluster near 0

            if nTest > 0
                XTest = [vertcat(obj.Data.Train(isTest).XBaseline); vertcat(obj.Data.Train(isTest).XMove)];
                XTest = mean(XTest, 2);
                yTest = [zeros(nTest, 1); ones(nTest, 1)];
                yHatTestMove = mdl.predict(XTest(yTest==1, :)); % should cluster near 1
                yHatTestBaseline = mdl.predict(XTest(yTest==0, :)); % should cluster near 0
            end

            if showPlot
                ax = axes(figure);
                hold(ax, 'on')
                histogram(ax, yHatTrainMove, -0.1:0.05:1.1, FaceColor='blue', FaceAlpha=0.2, EdgeAlpha=0, DisplayName='peri-move (train)')
                histogram(ax, yHatTrainBaseline, -0.1:0.05:1.1, FaceColor='red', FaceAlpha=0.2, EdgeAlpha=0, DisplayName='baseline (train)')

                if nTest > 0
                    histogram(ax, yHatTestMove, -0.1:0.05:1.1, FaceColor='blue', FaceAlpha=0.2, EdgeAlpha=1, DisplayName='peri-move (test)')
                    histogram(ax, yHatTestBaseline, -0.1:0.05:1.1, FaceColor='red', FaceAlpha=0.2, EdgeAlpha=1, DisplayName='baseline (test)')
                end

                xlabel('p(move)')
                ylabel('no. trials')
                legend(ax)
            end

            obj.Model.MDL = mdl;
        end

        function [p, t, X] = decodeNow(obj, binWidth)
            % p: decoded movement probability, [0, 1]
            % t: current time (ephys)
            % X: spikerate (averaged across channels) during [t-binWidth, t]
            t = obj.getTime();
            X = obj.SpikeTimeBuffer.getSpikeRates([t - binWidth, t]); % There's a more direct way of doing this without aliasing?
            x = mean(X, 2); % Average across neurons
            if isempty(obj.Model)
                p = NaN;
            else
                p = obj.Model.MDL.predict(x);
                obj.writeDecodedData(p, t, x); % Write decoded data to file.
            end
            if isempty(obj.ChannelMask)
                xMasked = x;
            else
                xMasked = mean(X(obj.ChannelMask));
            end
            obj.writeToBuffer(t, x, xMasked, p);
        end

        function initBuffer(obj, len)
            obj.Buffer.Length = len;
            obj.Buffer.CurrentIndex = 0;
            defaultData = NaN(1, len);
            obj.Buffer.Data = struct(t=defaultData, x=defaultData, xMasked=defaultData, p=defaultData);
        end

        function writeToBuffer(obj, t, x, xMasked, p)
            obj.Buffer.CurrentIndex = obj.Buffer.CurrentIndex + 1;
            if obj.Buffer.CurrentIndex > obj.Buffer.Length
                obj.Buffer.CurrentIndex = 1;
            end
            i = obj.Buffer.CurrentIndex;
            obj.Buffer.Data.t(i) = t;
            obj.Buffer.Data.x(i) = x;
            obj.Buffer.Data.xMasked(i) = xMasked;
            obj.Buffer.Data.p(i) = p;
        end

        function data = fetchBuffer(obj, len, fieldnames)
            if nargin < 3
                fieldnames = ["t", "x", "xMasked", "p"];
            end
            len = min(len, obj.Buffer.Length);
            indices = obj.Buffer.CurrentIndex-len+1 : obj.Buffer.CurrentIndex;
            indices(indices<=0) = indices(indices<=0) + obj.Buffer.Length;

            for fn = fieldnames
                data.(fn) = obj.Buffer.Data.(fn)(indices);
            end
        end

        function writeDecodedData(obj, p, t, x)
            i = uint32(obj.SpikeTimeBuffer.timestampToSampleIndex(t));
            x = uint16(x / 200 * 65535);
            p = uint8(p * 255);

            fid = obj.getOrCreateFile('DecodedData');
            fwrite(fid, i, 'uint32');
            fwrite(fid, x, 'uint16');
            fwrite(fid, p, 'uint8');
        end

        function closeDecoderData(obj)
            fid = obj.getOrCreateFile('DecodedData');
            fclose(fid);
        end

        function fid = getOrCreateFile(obj, name)
            fid = obj.Files.(name);
            % You're gonna be wanting to create it
            if isempty(fopen(fid)) % Returns empty for invalid fid (non-existent or closed)
                [path, ~, ~] = fileparts(obj.Arduino.ExperimentFileName);
                assert(isfolder(path));
                fid = fopen(fullfile(path, sprintf('%s.bin', name)), 'a');
                obj.Files.(name) = fid;
            end
        end

        function setLaser(obj, iLaser, turnOn, aout)
            if turnOn
                obj.IsLaserOn(iLaser) = true;
                obj.Arduino.SendMessage(sprintf('A %i %i', iLaser, aout));
                if obj.Debug
                    fprintf("##########  OPTO ON, aout=%i  ############\n", aout)
                end
            else
                obj.IsLaserOn(iLaser) = false;
                obj.Arduino.SendMessage(sprintf('A %i %i', iLaser, 0));
                if obj.Debug
                    fprintf("##########  OPTO OFF  ############\n")
                end
            end
        end

        function startPulsedOrContOpto(obj, iLaser)
            if nargin < 2
                obj.startPulsedOrContOpto(1);
                obj.startPulsedOrContOpto(2);
                return
            end
            obj.IsLaserOn(iLaser) = true;
            obj.Arduino.SendMessage(sprintf('J %i', iLaser));
            if obj.Debug
                fprintf("##########  LIVE OPTO ON %i  ############\n", iLaser)
            end
        end

        function stopPulsedOrContOpto(obj, iLaser)
            if nargin < 2
                obj.stopPulsedOrContOpto(1);
                obj.stopPulsedOrContOpto(2);
                return
            end
            obj.IsLaserOn(iLaser) = false;
            obj.Arduino.SendMessage(sprintf('K %i', iLaser));
            if obj.Debug
                fprintf("##########  LIVE OPTO OFF %i  ############\n", iLaser)
            end
        end

        function setPulsedOrContOptoParams(obj, iLaser, varargin)
            p = inputParser();
            p.addRequired('iLaser', @(x) x==1 || x==2)
            p.addParameter('aout', [], @(x) isnumeric(x) && isscalar(x) && x>=0)
            p.addParameter('pulseDuration', [], @(x) isnumeric(x) && isscalar(x) && x>=0)
            p.addParameter('pulseInterval', [], @(x) isnumeric(x) && isscalar(x) && x>=0)
            p.parse(iLaser, varargin{:});
            aout = p.Results.aout;
            pulseDuration = p.Results.pulseDuration;
            pulseInterval = p.Results.pulseInterval;
            switch iLaser
                case 1
                    if ~isempty(aout)
                        obj.Arduino.SetParam('OPTO_AOUT1_VALUE', aout)
                    end
                    if ~isempty(pulseDuration)
                        obj.Arduino.SetParam('OPTO_PULSE_DURATION', pulseDuration)
                    end
                    if ~isempty(pulseInterval)
                        obj.Arduino.SetParam('OPTO_PULSE_INTERVAL', pulseInterval)
                    end
                case 2
                    if ~isempty(aout)
                        obj.Arduino.SetParam('OPTO_AOUT2_VALUE', aout)
                    end
                    if ~isempty(pulseDuration)
                        obj.Arduino.SetParam('OPTO_PULSE_DURATION_2', pulseDuration)
                    end
                    if ~isempty(pulseInterval)
                        obj.Arduino.SetParam('OPTO_PULSE_INTERVAL_2', pulseInterval)
                    end
            end
        end

        % Listener callback for ArduinoConnection StateChanged events
        function onStateChanged(obj, src, ~)
            ac = obj.Arduino;
            obj.ArduinoState = string(ac.StateNames{ac.GetState()});
        end

        % Listener callback for ArduinoConnection EventMarkerReceived events
        function onEventMarkerReceived(obj, src, event)
            switch obj.Mode
                case "training"
                    switch event.Name
                        case 'TIMEOUT_START'
                            t = obj.addEventToBuffer(event);
                            obj.EventBuffer.HasMadeFirstMove = false;
                        case {'LICK', 'LEVER_PRESSED'}
                            if obj.EventBuffer.HasMadeFirstMove
                                return % Skip because not first move in a trial
                            end
                            t = obj.addEventToBuffer(event);
                            % Find the preceeding TIMEOUT_START
                            t0 = obj.EventBuffer.TIMEOUT_START(find(obj.EventBuffer.TIMEOUT_START < t, 1, 'last'));
                            if isempty(t0) || t - t0 < obj.Params.Train.MinTrialLength % Discard short trials, or movements before 1st ever timeout_start
                                return
                            end
                            baselineWindow = [max(t0, t+obj.Params.Train.BaselineWindow(1)), t+obj.Params.Train.BaselineWindow(2)];
                            moveWindow = [max(t0, t+obj.Params.Train.MoveWindow(1)), t+obj.Params.Train.MoveWindow(2)];
                            if baselineWindow(2) <= baselineWindow(1) || moveWindow(2) <= moveWindow(1)
                                return
                            end
                            XBaseline = obj.SpikeTimeBuffer.getSpikeRates(baselineWindow);
                            XMove = obj.SpikeTimeBuffer.getSpikeRates(moveWindow);
                            obj.Data.Train(length(obj.Data.Train) + 1) = struct(XBaseline=XBaseline, XMove=XMove, tBaseline=baselineWindow, tMove=moveWindow, trialLength=t-t0);
                            obj.EventBuffer.HasMadeFirstMove = true;
                    end

                case {"opto", "testing"}
                    switch event.Name
                        case 'TIMEOUT_START'
                            t = obj.addEventToBuffer(event);
                            obj.EventBuffer.HasMadeFirstMove = false;
                            obj.HasStimHappened = false;
                        case {'LICK', 'LEVER_PRESSED'}
                            if obj.EventBuffer.HasMadeFirstMove
                                return % Skip because not first move in a trial
                            end
                            fprintf("MOVED: pMove=%.1f%%\n", obj.PMove*100)
                            t = obj.addEventToBuffer(event);
                            obj.EventBuffer.HasMadeFirstMove = true;
                    end
                case "off"
            end
        end

        function t = addEventToBuffer(obj, event)
            % See class: EventMarkerData
            % if ismember(event.Name, {'LEVER_HELD', 'LICK_HELD', 'TIMEOUT_START', 'LEVER_DEPLOY_START', 'LEVER_DEPLOY_END', 'LEVER_RETRACT_START', 'LEVER_RETRACT_END'})
            if ismember(event.Name, {'LEVER_PRESSED', 'LICK', 'TIMEOUT_START'})
                t = obj.getTime();
                obj.EventBuffer.(event.Name) = [obj.EventBuffer.(event.Name), t];
            else
                t = [];
            end
        end

        function dt = getTimeSinceTimeoutStart(obj, currentTime)
            if isfield(obj.EventBuffer, 'TIMEOUT_START')
                dt = currentTime - obj.EventBuffer.TIMEOUT_START(end);
            else
                dt = Inf;
            end
        end

        % Return ephysTime ()
        function t = getTime(obj)
            t = obj.SpikeTimeBuffer.getTime();
        end

        function clearTrainingData(obj)
            obj.Data.Train = struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={});
        end

        function clearTestingData(obj)
            obj.Data.Test = struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={});
        end

        function clearEventBuffer(obj)
            obj.EventBuffer = struct(LEVER_PRESSED=[], LICK=[], TIMEOUT_START=[], HasMadeFirstMove=false);
        end

        % Gizmos and doodads for tinkering with dual color opto need to add a PID thingy to do spike rate clamp
        % The UI part is vibe coded because the grad student wants to go home for dinner. 
        function createDialog(obj)
            % Main figure window [left, bottom, width, height]
            fig = uifigure(Name="Opto Control", Position=[100, 100, 750, 380]);
            fig.GraphicsSmoothing = 'off'; % Performance tweak
            
            % --- PLOTS / DISPLAYS (Left Side Stacked Graphics) ---
            % Spike rate text header readout anchored on the top-left
            lblSpikeRate = uilabel(fig, Text="xxx.x sp/s", Position=[100, 330, 200, 22], FontWeight="bold", FontSize=16, VerticalAlignment='top');
        
            % Upper Plot: Spike Rate
            axSpikes = uiaxes(fig, Position=[50, 185, 465, 140]);
            ylabel(axSpikes, 'sp/s'); grid(axSpikes, 'on');
        
            % Lower Plot: Merged Blue & Orange Laser Light Stimulation
            axLight = uiaxes(fig, Position=[50, 35, 465, 140]);
            ylabel(axLight, 'mW'); grid(axLight, 'on');
        
            xlabel(axLight, 'sec')
            xlim([axSpikes, axLight], [-4, 0]);
        
            % Create low-overhead static plot line references for high-speed updates
            lineSpikes = plot(axSpikes, NaN, NaN, Color=[0.2, 0.2, 0.2], LineWidth=1.2);
        
            hold(axLight, 'on');
            lineBlue   = plot(axLight, NaN, NaN, Color=[0.0, 0.4, 0.8], LineWidth=1.2);
            lineOrng   = plot(axLight, NaN, NaN, Color=[0.9, 0.4, 0.0], LineWidth=1.2);
            hold(axLight, 'off');
        
            % --- TOP ROW BUTTONS ---
            % Master switch (on/off)
            uilabel(fig, Text="Master:", Position=[220, 350, 50, 22], FontWeight="bold");
            btnGrpMaster = uibuttongroup(fig, Position=[275, 325, 50, 50], BorderType="none", SelectionChangedFcn=@onMasterSwitchToggled);
            btnMasterOn  = uiradiobutton(btnGrpMaster, Text="On", Position=[2, 26, 45, 23]);
            btnMasterOff = uiradiobutton(btnGrpMaster, Text="Off", Position=[2, 1, 45, 23]);
            btnGrpMaster.SelectedObject = btnMasterOff; % Default to Off
            
            % Stim mode (manual/trigger based of pMove)
            uilabel(fig, Text="Mode:", Position=[330, 350, 45, 22], FontWeight="bold");
            btnGrpStimMode   = uibuttongroup(fig, Position=[375, 325, 60, 50], BorderType="none", SelectionChangedFcn=@onStimModeChanged);
            btnStimModeManual   = uiradiobutton(btnGrpStimMode, Text="Manual", Position=[2, 26, 60, 23]);
            btnStimModeTrigger  = uiradiobutton(btnGrpStimMode, Text="Trigger", Position=[2, 1, 60, 23]);
            btnGrpStimMode.SelectedObject = btnStimModeManual; % Default to Manual

            uilabel(fig, Text="t=", Position=[445, 350, 20, 22], FontWeight="bold");
            editStimDuration = uieditfield(fig, 'numeric', Value=1, Position=[465, 350, 30, 22], Limits=[0, 10]);

            uilabel(fig, Text="p>", Position=[445, 325, 20, 22], FontWeight="bold");
            editTriggerThreshold = uieditfield(fig, 'numeric', Value=0.5, Position=[465, 325, 30, 22], ValueChangedFcn=@onTriggerThresholdChanged, Limits=[0, 1]);

            % Top row (470nm)
            pnlBlue = uipanel(fig, Title="470nm (GtACR)", Position=[535, 205, 195, 145]);
            
            uilabel(pnlBlue, Text="Mode:", Position=[10, 95, 40, 22]);
            btnGrpBlue = uibuttongroup(pnlBlue, Position=[55, 95, 135, 25], BorderType="none", SelectionChangedFcn=@onLaserSettingsChanged_Mode);
            btnBlueModePulsed = uiradiobutton(btnGrpBlue, Text="Pulsed", Position=[1, 2, 60, 22]);
            btnBlueModeCont   = uiradiobutton(btnGrpBlue, Text="Cont.", Position=[65, 2, 65, 22]);
            btnGrpBlue.SelectedObject = btnBlueModeCont; 
            
            uilabel(pnlBlue, Text="Power (aout):", Position=[10, 65, 80, 22]);
            editBluePower = uieditfield(pnlBlue, 'numeric', Value=0, Position=[100, 65, 50, 22], ValueChangedFcn=@onLaserSettingsChanged_Numeric, Limits=[0, 4095]);
            
            uilabel(pnlBlue, Text="Freq (Hz):", Position=[10, 35, 80, 22]);
            editBlueFreq = uieditfield(pnlBlue, 'numeric', Value=10, Position=[100, 35, 50, 22], ValueChangedFcn=@onLaserSettingsChanged_Numeric, Limits=[0, 1000]);
            
            uilabel(pnlBlue, 'Text', 'Width (ms):', Position=[10, 5, 80, 22]);
            editBlueWidth = uieditfield(pnlBlue, 'numeric', Value=1, Position=[100, 5, 50, 22], ValueChangedFcn=@onLaserSettingsChanged_Numeric, Limits=[0, 1000]);
        
            % Bottom Row (593nm)
            pnlOrng = uipanel(fig, Title="593nm (ChrimsonR)", Position=[535, 50, 195, 145]);
            
            uilabel(pnlOrng, Text="Mode:", Position=[10, 95, 40, 22]);
            btnGrpOrng = uibuttongroup(pnlOrng, Position=[55, 95, 135, 25], BorderType="none", SelectionChangedFcn=@onLaserSettingsChanged_Mode);
            btnOrngModePulsed = uiradiobutton(btnGrpOrng, Text="Pulsed", Position=[1, 2, 60, 22]);
            btnOrngModeCont   = uiradiobutton(btnGrpOrng, Text="Cont.", Position=[65, 2, 65, 22]);
            btnGrpOrng.SelectedObject = btnOrngModePulsed; 
            
            uilabel(pnlOrng, Text="Power (aout):", Position=[10, 65, 80, 22]);
            editOrngPower = uieditfield(pnlOrng, 'numeric', Value=0, Position=[100, 65, 50, 22], ValueChangedFcn=@onLaserSettingsChanged_Numeric, Limits=[0, 4095]);
            
            uilabel(pnlOrng, Text="Freq (Hz):", Position=[10, 35, 80, 22]); 
            editOrngFreq = uieditfield(pnlOrng, 'numeric', Value=20, Position=[100, 35, 50, 22], ValueChangedFcn=@onLaserSettingsChanged_Numeric, Limits=[0, 1000]);
            
            uilabel(pnlOrng, Text="Width (ms):", Position=[10, 5, 80, 22]);
            editOrngWidth = uieditfield(pnlOrng, 'numeric', Value=1, Position=[100, 5, 50, 22], ValueChangedFcn=@onLaserSettingsChanged_Numeric, Limits=[0, 1000]);

            % Apply
            chkInstantApply = uicheckbox(fig, Text="Instant", Value=false, Position=[600, 15, 65, 22], ValueChangedFcn=@onInstantApplyChecked);
            btnApply = uibutton(fig, "push", Text="Apply", Position=[665, 15, 65, 24], ButtonPushedFcn=@onLaserSettingsApplied);

            % Used to define scroll wheel behavior on numeric text fields
            numericFields = { ...
                struct(Handle=editBluePower, Panel=pnlBlue,  InstantApply=chkInstantApply, IsArduinoParam=true, Min=0,   Max=4095, Step=1), ... Arduino
                struct(Handle=editBlueFreq,  Panel=pnlBlue,  InstantApply=chkInstantApply, IsArduinoParam=true, Min=0,   Max=1000, Step=1), ... Arduino
                struct(Handle=editBlueWidth, Panel=pnlBlue,  InstantApply=chkInstantApply, IsArduinoParam=true, Min=0,   Max=1000, Step=1), ... Arduino
                struct(Handle=editOrngPower, Panel=pnlOrng,  InstantApply=chkInstantApply, IsArduinoParam=true, Min=0,   Max=4095, Step=1), ... Arduino
                struct(Handle=editOrngFreq,  Panel=pnlOrng,  InstantApply=chkInstantApply, IsArduinoParam=true, Min=0,   Max=1000, Step=1), ... Arduino
                struct(Handle=editOrngWidth, Panel=pnlOrng,  InstantApply=chkInstantApply, IsArduinoParam=true, Min=0,   Max=1000, Step=1), ... Arduino
                struct(Handle=editTriggerThreshold, Panel=fig, InstantApply=false, IsArduinoParam=false, Min=0.0, Max=1.0, Step=0.1) ... MATLAB
                struct(Handle=editStimDuration, Panel=fig, InstantApply=false, IsArduinoParam=false, Min=0.0, Max=10.0, Step=0.5) ... MATLAB
                };
        
            fig.WindowScrollWheelFcn = @scrollWheelCallback;

            onLaserSettingsChanged_Mode();

            % Output handles for all the doodads
            uiHandles = struct(...
                fig=fig, lblSpikeRate=lblSpikeRate, axSpikes=axSpikes, axLight=axLight, ...
                lineSpikes=lineSpikes, lineBlue=lineBlue, lineOrng=lineOrng, ...
                btnGrpMaster=btnGrpMaster, btnGrpStimMode=btnGrpStimMode, ...
                editTriggerThreshold=editTriggerThreshold, editStimDuration=editStimDuration, ...
                btnGrpBlue=btnGrpBlue, editBluePower=editBluePower, editBlueFreq=editBlueFreq, editBlueWidth=editBlueWidth, ...
                btnGrpOrng=btnGrpOrng, editOrngPower=editOrngPower, editOrngFreq=editOrngFreq, editOrngWidth=editOrngWidth ...
            );

            obj.Dialog = fig;
            obj.UIHandles = uiHandles;
        
            % --- Scroll wheel to edit numeric fields (use shift/alt/shift+alt as speed modifiers) ---
            function scrollWheelCallback(~, event)
                mousePos = fig.CurrentPoint; mx = mousePos(1); my = mousePos(2);
                for i = 1:numel(numericFields)
                    field = numericFields{i}.Handle; 
                    panel = numericFields{i}.Panel; 
                    fPos = field.Position;
                    
                    if panel == fig
                        absX = fPos(1); absY = fPos(2);
                    else
                        pPos = panel.Position;
                        absX = pPos(1) + fPos(1); absY = pPos(2) + fPos(2);
                    end
                    
                    if (mx >= absX && mx <= (absX + fPos(3))) && (my >= absY && my <= (absY + fPos(4)))
                        activeModifiers = fig.CurrentModifier;
                        
                        baseStep = numericFields{i}.Step;
                        if ismember('shift', activeModifiers)
                            baseStep = baseStep*5;
                        elseif ismember('alt', activeModifiers)
                            baseStep = baseStep*10;
                        end
                        
                        newVal = field.Value + (-event.VerticalScrollCount * baseStep);
                        
                        if newVal >= numericFields{i}.Min && newVal <= numericFields{i}.Max
                            field.Value = newVal;
                            if numericFields{i}.IsArduinoParam && chkInstantApply.Value
                                onLaserSettingsApplied();
                            end
                        end
                        break;
                    end
                end
            end

            function onMasterSwitchToggled(~, ~)
                masterSwitch = btnGrpMaster.SelectedObject.Text;
                stimMode = btnGrpStimMode.SelectedObject.Text;
                switch masterSwitch
                    case "On"
                        % Turn that shit on
                        switch stimMode
                            case "Manual"
                                if ~isempty(obj.OptoTimer) && isvalid(obj.OptoTimer)
                                    stop(obj.OptoTimer);
                                    delete(obj.OptoTimer);
                                end
                                obj.OptoTimer = timer();
                                obj.OptoTimer.StartDelay = editStimDuration.Value;
                                obj.OptoTimer.ExecutionMode = 'singleShot'; % fixedDelay, fixedSpacing
                                obj.OptoTimer.TimerFcn = @(~, ~) obj.stopPulsedOrContOpto();
                                obj.startPulsedOrContOpto();
                                start(obj.OptoTimer);
                            case "Trigger"
                                obj.startAutoOpto();
                        end
                    case "Off"
                        % Turn off that stupid song
                        switch stimMode
                            case "Manual"
                                if ~isempty(obj.OptoTimer) && isvalid(obj.OptoTimer)
                                    stop(obj.OptoTimer);
                                    delete(obj.OptoTimer);
                                end
                                obj.stopPulsedOrContOpto();
                            case "Trigger"
                                obj.stopAutoOpto();
                        end
                end
            end

            function onStimModeChanged(~, ~)
                stimMode = btnGrpStimMode.SelectedObject.Text;
                switch stimMode
                    case "Manual"
                        if obj.Mode == "opto"
                            obj.stopAutoOpto();
                        end
                    case "Trigger"
                end
            end

            function onTriggerThresholdChanged(~, ~)
                triggerThreshold = editTriggerThreshold.Value;
                obj.Params.Opto.Threshold = triggerThreshold;
            end

            function onLaserSettingsChanged_Numeric(src, ~)
                for i = 1:numel(numericFields)
                    if numericFields{i}.Handle == src
                        if islogical(numericFields{i}.InstantApply) && numericFields{i}.InstantApply
                            onLaserSettingsChanged_Mode();
                        elseif numericFields{i}.InstantApply.Value
                            onLaserSettingsChanged_Mode();
                        end
                        break;
                    end
                end
            end
        
            % --- Laser setting update (Arduino) ---
            function onLaserSettingsChanged_Mode(~, ~)
                blueMode    = btnGrpBlue.SelectedObject.Text;
                orngMode    = btnGrpOrng.SelectedObject.Text;

                switch blueMode
                    case 'Pulsed'
                        editBlueFreq.Enable = 'on';
                        editBlueWidth.Enable = 'on';
                    case 'Cont.'
                        editBlueFreq.Enable = 'off';
                        editBlueWidth.Enable = 'off';
                end
                switch orngMode
                    case 'Pulsed'
                        editOrngFreq.Enable = 'on';
                        editOrngWidth.Enable = 'on';
                    case 'Cont.'
                        editOrngFreq.Enable = 'off';
                        editOrngWidth.Enable = 'off';
                end
                onLaserSettingsApplied();
            end

            function onInstantApplyChecked(src, ~)
                if src.Value
                    btnApply.Enable = 'off';
                    onLaserSettingsApplied();
                else
                    btnApply.Enable = 'on';
                end
            end

            function onLaserSettingsApplied(~, ~)
                masterSwitch = btnGrpMaster.SelectedObject.Text;
                stimMode = btnGrpStimMode.SelectedObject.Text;
                triggerThreshold = editTriggerThreshold.Value;

                blueMode    = btnGrpBlue.SelectedObject.Text;
                bluePower   = round(editBluePower.Value);
                blueFreq    = round(editBlueFreq.Value);
                blueWidth   = round(editBlueWidth.Value);

                orngMode    = btnGrpOrng.SelectedObject.Text;
                orngPower   = round(editOrngPower.Value);
                orngFreq    = round(editOrngFreq.Value);
                orngWidth   = round(editOrngWidth.Value);

                switch blueMode
                    case 'Pulsed'
                        blueIPI = round(1000/blueFreq - blueWidth);
                    case 'Cont.'
                        blueIPI = 0;
                end
                switch orngMode
                    case 'Pulsed'
                        orngIPI = round(1000/orngFreq - orngWidth);
                    case 'Cont.'
                        orngIPI = 0;
                end

                fprintf("%s - opto param update:\n", datetime('now', Format='HH:mm:ss.SSS'));
                fprintf('\tMaster=%s | Mode=%s | p>=%.2f\n', masterSwitch, stimMode, triggerThreshold);
                fprintf('\t470nm (GtACR): %s | AOut=%i | Freq=%iHz | PulseWidth=%ims | IPI=%ims\n', ...
                    blueMode, bluePower, blueFreq, blueWidth, blueIPI)
                fprintf('\t593nm (Chrimson): %s | AOut=%i | Freq=%iHz | PulseWidth=%ims | IPI=%ims\n', ...
                    orngMode, orngPower, orngFreq, orngWidth, orngIPI)

                if masterSwitch == "on"
                    obj.setPulsedOrContOptoParams(1, aout=bluePower, pulseDuration=blueWidth, pulseInterval=blueIPI);
                    obj.setPulsedOrContOptoParams(2, aout=orngPower, pulseDuration=orngWidth, pulseInterval=orngIPI);
                end
            end
        end


    end

    methods (Static)
        function map = getChannelMap(varargin)
            % Probe is mounted along ML, the flat bit is facing forward, the dovetail
            % is facing posterior of animal (if otherwise, map needs to be mirrored).
            % Looking from behind the animal is equivalent to SpikeGLX view
            % Map is looking from behind animal:
            %   shank 1 - 4 are left-to-right.
            %   col 1 - 2 are left-to-right, on same shank
            %   row 1 - n are bottom to top
            %   x is horizontal coord (um, 0 is center of all 4 shanks, negative is left)
            %   y is vertical coord (um, 0 is tip of shank, negative is down)
            %   ml, dv, ap: negative is left, down/ventral, back/posterior
            %   dv is zeroed relative to dura, make your own corrections
            % Try this to visualize things
            %   map=OnlineDecoder.getChannelMap(rotation=90); scatter3(map.ml, map.ap, map.dvFromDura); xlabel('ml'); ylabel('ap'); zlabel('dvFromDura'); text(map.ml, map.ap, map.dvFromDura, string(map.shank))
            p = inputParser();
            p.addParameter('ml', 1.300, @(x) isnumeric(x) && x>=0); % ML (left hemisphere is negative, we implant on the right mostly)
            p.addParameter('ap', -3.280, @isnumeric);
            p.addParameter('dvFromDura', -4.700, @isnumeric); % tip depth from dura (which is usually 200um below bregma for SNr)
            p.addParameter('rotation', 0, @isnumeric); % degress of CCW rotation along z axis looking from above (default is zero for the orientation described above)
            p.parse(varargin{:})
            ml = p.Results.ml;
            ap = p.Results.ap;
            dvFromDura = p.Results.dvFromDura;
            rotation = p.Results.rotation;
            tipLength = 175; % um
            shankPitch = 250;
            columnPitch = 15; % vertical distance between electrodes
            rowPitch = 32; % horizontal distance between electrodes

            if ~exist("E:\Data\tips_out.imro", 'file')
                file = "C:\SERVER\tips_out.imro";
            else
                file = "E:\Data\tips_out.imro";
            end
            mapStr = string(fileread(file));
            tokens = regexp(mapStr, '(?<=\()[^)]*(?=\))', 'match');
            assert(tokens(1) == "2013,384")
            tokens = tokens(2:end);
            defaultData = zeros(length(tokens), 1);
            map = struct(channel=defaultData, shank=defaultData, col=defaultData, row=defaultData, x=defaultData, y=defaultData);
            for i = 1:length(tokens)
                subtokens = strsplit(tokens(i), " ");
                map.channel(i) = str2double(subtokens(1)) + 1;
                assert(map.channel(i) == i)
                map.shank(i) = str2double(subtokens(2)) + 1; %
                idOnShank = str2double(subtokens(5));
                map.col(i) = 1 + (mod(idOnShank, 2) == 1);
                switch map.col(i)
                    case 1
                        map.row(i) = idOnShank/2 + 1;
                    case 2
                        map.row(i) = (idOnShank-1)/2 + 1;
                end
                map.x(i) = (map.shank(i)-1)*shankPitch - 1.5*shankPitch;
                switch map.col(i)
                    case 1
                        map.x(i) = map.x(i) - rowPitch/2;
                    case 2
                        map.x(i) = map.x(i) + rowPitch/2;
                end
                map.y(i) = tipLength + (map.row(i)-1)*columnPitch;
            end

            % convert um to mm
            map.x = map.x/1000;
            map.y = map.y/1000;

            % Create rotation matrix around z axis (clockwise from top
            % view)
            R = [ ...
                    cosd(rotation), -sind(rotation), 0; ... 
                    sind(rotation),  cosd(rotation), 0; ... 
                    0, 0, 1 ...
                ];

            coords = [map.x'; zeros(size(map.x))'; map.y']; % new order: x: left right, y: front back, z: height
            coords = R*coords; % rotate along z axis
            coords = coords';

            map.ml = ml + coords(:, 1);
            map.ap = ap + coords(:, 2);
            map.dvFromDura = dvFromDura + coords(:, 3);
        end
    end
end