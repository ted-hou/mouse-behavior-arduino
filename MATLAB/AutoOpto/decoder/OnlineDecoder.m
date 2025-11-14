classdef OnlineDecoder < handle
    %ONLINEDECODER Gives movement probability based on spike

    properties
        SpikeTimeBuffer
        Arduino
        EventBuffer
    end

    properties (Transient, SetAccess=protected)
        Mode = "off" % "off", "training", "test", "opto"
    end

    properties (Transient)
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
        function startTraining(obj)
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
            t = obj.getTime();
            % See class: EventMarkerData
            switch event.Name 
                case {'LEVER_HELD', 'LICK_HELD'}
                    obj.EventBuffer.(event.Name) = [obj.EventBuffer.(event.Name), t];
                case {'TIMEOUT_START'}
            end
        end

        function addEventToBuffer(obj, event)
            t = obj.getTime();
            % See class: EventMarkerData
            if ismember(event.Name, {'LEVER_HELD', 'LICK_HELD', 'TIMEOUT_START', 'LEVER_DEPLOY_START', 'LEVER_DEPLOY_END', 'LEVER_RETRACT_START', 'LEVER_RETRACT_END'})
                obj.EventBuffer.(event.Name) = [obj.EventBuffer.(event.Name), t];
            end
        end

        % Return ephysTime ()
        function t = getTime(obj)
            t = obj.SpikeTimeBuffer.getTime();
        end
    end
end