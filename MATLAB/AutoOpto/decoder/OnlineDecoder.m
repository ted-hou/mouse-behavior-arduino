classdef OnlineDecoder < handle
    %ONLINEDECODER Gives movement probability based on spike

    properties
        SpikeTimeBuffer
        Arduino
        EventBuffer = struct(LEVER_HELD=[], LICK_HELD=[], TIMEOUT_START=[], HasMadeFirstMove=false)
        Params = struct(Train=[], Test=[])
        Data = struct(Train=struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={}), Test=struct(XBaseline={}, XMove={}, tBaseline={}, tMove={}, trialLength={}))
        Model
    end

    properties (Transient, SetAccess=protected)
        Mode = "off" % "off", "training", "testing", "opto"
    end

    properties (Transient)
        Timer
        Listeners
    end

    properties (Transient, Hidden)
        LineLength = 0
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

        function startTesting(obj)
            assert(obj.Mode == "off", "Current mode is %s, expected ""off"".", obj.Mode)
            obj.Mode = "testing";
        end

        function stopTesting(obj)
            assert(obj.Mode == "testing", "Current mode is %s, expected ""testing"".", obj.Mode)            
        end

        function startOptoClosedLoop(obj)
            assert(obj.Mode == "off", "Current mode is %s, expected ""off"".", obj.Mode)            
            obj.Mode = "opto";
            error("Not implemented: mode ""opto"".")
        end

        function stopOptoClosedLoop(obj)
            assert(obj.Mode == "opto", "Current mode is %s, expected ""opto"".", obj.Mode)            
        end

        % Listener callback for ArduinoConnection StateChanged events
        function onStateChanged(obj, src, ~)
        end

        % Listener callback for ArduinoConnection EventMarkerReceived events
        function onEventMarkerReceived(obj, src, event)
            % See class: EventMarkerData
            t = obj.addEventToBuffer(event);

            switch obj.Mode
                case "training"
                    switch event.Name
                        case 'TIMEOUT_START'
                            obj.EventBuffer.HasMadeFirstMove = false;
                        case {'LICK_HELD', 'LEVER_HELD'}
                            if obj.EventBuffer.HasMadeFirstMove
                                return % Skip because not first move in a trial
                            end
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
                case {"testing", "opto"}
                case "off"
            end
        end

        function t = addEventToBuffer(obj, event)
            t = obj.getTime();
            % See class: EventMarkerData
            % if ismember(event.Name, {'LEVER_HELD', 'LICK_HELD', 'TIMEOUT_START', 'LEVER_DEPLOY_START', 'LEVER_DEPLOY_END', 'LEVER_RETRACT_START', 'LEVER_RETRACT_END'})
            if ismember(event.Name, {'LEVER_HELD', 'LICK_HELD', 'TIMEOUT_START'})
                obj.EventBuffer.(event.Name) = [obj.EventBuffer.(event.Name), t];
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

        function startDecoding(obj, varargin)
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
            obj.Timer.TimerFcn = @(~, ~) obj.onDecoderUpdate();

            start(obj.Timer);
        end

        function onDecoderUpdate(obj)
            t = obj.getTime();
            X = obj.SpikeTimeBuffer.getSpikeRates([t - obj.Params.Test.BinWidth, t]); % There's a more direct way of doing this without aliasing?
            X = mean(X, 2);
            if isempty(obj.Model)
                return
            end
            yHat = obj.Model.MDL.predict(X);

            fprintf(repmat('\b', [1, obj.LineLength]));
            currentTimeDisp = seconds(t);
            currentTimeDisp.Format = 'hh:mm:ss.SSS';
            obj.LineLength = fprintf('CurrentTime = %s, X = %.1f sp/s, P(Move) = %.0f%%\n', currentTimeDisp, X, 100*yHat);
        end

        function stopDecoding(obj)
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = [];
        end
    end
end