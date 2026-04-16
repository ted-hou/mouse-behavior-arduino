classdef OnlineDecoder < handle
    %ONLINEDECODER Gives movement probability based on spike

    properties
        SpikeTimeBuffer
        Arduino
        EventBuffer = struct(LEVER_HELD=[], LICK_HELD=[], TIMEOUT_START=[], HasMadeFirstMove=false)
        Params = struct(Train=[], Test=[], Opto=[])
        Data = struct(Train=struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={}), Test=struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={}))
        Model
        Debug = false
    end

    properties (Transient, SetAccess=protected)
        Mode = "off" % "off", "training", "testing", "opto"
        PMove = NaN
        IsLaserOn = false
        HasStimHappened = false
        ArduinoState = ""
        Files = struct(DecodedData=-1, Events=-1);
    end

    properties (Transient)
        Timer
        OptoPulseTimer
        Listeners
    end

    methods
        function obj = OnlineDecoder(stb, ac)
            obj.SpikeTimeBuffer = stb;
            obj.Arduino = ac;
            obj.Mode = "off";
            obj.Listeners.StateChanged = addlistener(obj.Arduino, 'StateChanged', @obj.onStateChanged);
            obj.Listeners.EventMarkerReceived = addlistener(obj.Arduino, 'EventMarkerReceived', @obj.onEventMarkerReceived);
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

        function startAutoOpto(obj, varargin)
            assert(obj.Mode == "off", "Current mode is %s, expected ""off"".", obj.Mode)            
            obj.Mode = "opto";

            p = inputParser();
            p.addParameter('UpdateInterval', 0.02, @isnumeric)
            p.addParameter('BinWidth', 0.1, @isnumeric)
            p.addParameter('Threshold', 0.5, @(x) isnumeric(x) && x<=1 && x>=0)
            p.addParameter('Duration', 0.5, @(x) isnumeric(x) && x>=0)
            p.addParameter('AOutValue', 4095, @isnumeric)
            p.parse(varargin{:})
            updateInterval = p.Results.UpdateInterval;
            binWidth = p.Results.BinWidth;

            obj.Params.Opto.UpdateInterval = updateInterval;
            obj.Params.Opto.BinWidth = binWidth;
            obj.Params.Opto.Threshold = p.Results.Threshold;
            obj.Params.Opto.Duration = p.Results.Duration;
            obj.Params.Opto.AOutValue = p.Results.AOutValue;

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
            if ~isempty(obj.OptoPulseTimer) && isvalid(obj.OptoPulseTimer)
                stop(obj.OptoPulseTimer);
                delete(obj.OptoPulseTimer);
            end
            obj.OptoPulseTimer = [];
            if obj.IsLaserOn
                obj.setLaser(false);
            end
            obj.Mode = "off";
        end

        function onAutoOptoUpdate(obj)
            [pMove, t, X] = obj.decodeNow(obj.Params.Opto.BinWidth);
            obj.PMove = pMove;

            % In TIMEOUT/WAITFORTOUCH, start opto if pMove exceeds threshold
            if pMove > obj.Params.Opto.Threshold && ~obj.IsLaserOn && ismember(obj.ArduinoState, ["WAITFORTOUCH"]) && ~obj.HasStimHappened
                % Turn laser on
                obj.setLaser(true, obj.Params.Opto.AOutValue);
                obj.HasStimHappened = true;

                % Schedule laser to turn off after "Duration"    
                if ~isempty(obj.OptoPulseTimer) && isvalid(obj.OptoPulseTimer)
                    stop(obj.OptoPulseTimer);
                    delete(obj.OptoPulseTimer);
                end
                obj.OptoPulseTimer = timer();
                obj.OptoPulseTimer.StartDelay = obj.Params.Opto.Duration;
                obj.OptoPulseTimer.ExecutionMode = 'singleShot'; % fixedDelay, fixedSpacing
                obj.OptoPulseTimer.TimerFcn = @(~, ~) obj.setLaser(false);
                start(obj.OptoPulseTimer);

                fprintf("pMove=%.1f%%\n", pMove*100)
            end

            if obj.Debug
                currentTimeDisp = seconds(t);
                currentTimeDisp.Format = 'hh:mm:ss.SSS';
                fprintf('CurrentTime = %s, X = %.1f sp/s, P(Move) = %.0f%%\n', currentTimeDisp, X, 100*pMove);
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
            X = mean(X, 2); % Average across neurons
            if isempty(obj.Model)
                p = NaN;
                return
            end
            p = obj.Model.MDL.predict(X);
            obj.writeDecodedData(p, t, X); % Write decoded data to file.
        end

        function writeDecodedData(obj, p, t, X)
            i = uint32(obj.SpikeTimeBuffer.timestampToSampleIndex(t));
            X = uint16(X / 200 * 65535);
            p = uint8(p * 255);

            fid = obj.getOrCreateFile('DecodedData');
            fwrite(fid, i, 'uint32');
            fwrite(fid, X, 'uint16');
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

        function setLaser(obj, turnOn, aout)
            if turnOn
                obj.IsLaserOn = true;
                obj.Arduino.SendMessage(sprintf('A %i %i', 1, aout));
                if obj.Debug
                    fprintf("##########  OPTO ON, aout=%i  ############\n", aout)
                end
            else
                obj.IsLaserOn = false;
                obj.Arduino.SendMessage(sprintf('A %i %i', 1, 0));
                if obj.Debug
                    fprintf("##########  OPTO OFF  ############\n")
                end
            end
        end

        % Listener callback for ArduinoConnection StateChanged events
        function onStateChanged(obj, src, ~)
            ac = obj.Arduino;
            obj.ArduinoState = string(ac.StateNames{ac.GetState()});
            if obj.ArduinoState == "TIMEOUT"
                obj.HasStimHappened = false;
            end
        end

        % Listener callback for ArduinoConnection EventMarkerReceived events
        function onEventMarkerReceived(obj, src, event)

            switch obj.Mode
                case "training"
                    switch event.Name
                        case 'TIMEOUT_START'
                            t = obj.addEventToBuffer(event);
                            obj.EventBuffer.HasMadeFirstMove = false;
                        case {'LICK_HELD', 'LEVER_HELD'}
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
                        case 'TIMEOUT_START'
                            t = obj.addEventToBuffer(event);
                            obj.EventBuffer.HasMadeFirstMove = false;
                        case {'LICK_HELD', 'LEVER_HELD'}
                            fprintf("MOVED: pMove=%.1f%%\n", obj.PMove*100)
                            if obj.EventBuffer.HasMadeFirstMove
                                return % Skip because not first move in a trial
                            end
                            t = obj.addEventToBuffer(event);
                            obj.EventBuffer.HasMadeFirstMove = true;
                case "off"
            end
        end

        function t = addEventToBuffer(obj, event)
            % See class: EventMarkerData
            % if ismember(event.Name, {'LEVER_HELD', 'LICK_HELD', 'TIMEOUT_START', 'LEVER_DEPLOY_START', 'LEVER_DEPLOY_END', 'LEVER_RETRACT_START', 'LEVER_RETRACT_END'})
            if ismember(event.Name, {'LEVER_HELD', 'LICK_HELD', 'TIMEOUT_START'})
                t = obj.getTime();
                obj.EventBuffer.(event.Name) = [obj.EventBuffer.(event.Name), t];
            else
                t = [];
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
            obj.EventBuffer = struct(LEVER_HELD=[], LICK_HELD=[], TIMEOUT_START=[], HasMadeFirstMove=false);
        end

    end
end