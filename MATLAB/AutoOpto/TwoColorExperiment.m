classdef TwoColorExperiment < handle
    properties
        Path = ''
        LaserArduino
        MotorArduino
        Params % Calibration Params
        Results % Calibration Results
        Log % Stimulation Log
    end

    properties (Transient, Hidden)
        LaserInterface
        MotorInterface
        PowerMeter
    end

    methods
        function obj = TwoColorExperiment(varargin)
            p = inputParser();
            p.addParameter('offline', false, @islogical)
            p.parse(varargin{:})
            r = p.Results;

            if r.offline
                return
            end

            % Connect to arduinos
            obj.connect();

            % Choose save path
            [file, path] = uiputfile(sprintf('expname_%s.mat', datestr(now, 'yyyymmdd')), 'Choose autosave path:');
            if file == 0
                return
            end
            obj.Path = [path, file];
        end

        function connect(obj)
            obj.LaserInterface = MouseBehaviorInterface('COM5'); % This is the laser control arduino
            obj.MotorInterface = MouseBehaviorInterface('COM7'); % This is the stepping motor arduino (for moving mirror)
            obj.LaserArduino = obj.LaserInterface.Arduino;
            obj.MotorArduino = obj.MotorInterface.Arduino;
            obj.LaserArduino.DebugMode = false;
            obj.MotorArduino.DebugMode = false;
        end

        function results = calibrate(obj, varargin)
            p = inputParser();
            p.addParameter('mirrorPositions', [-300, 0], @isnumeric)
            p.addParameter('targetPowers', [0.5, 2, 4, 10].*1e-3, @isnumeric)
            p.addParameter('wavelengths', [473, 593], @(x) isnumeric(x) && length(x) == 2)
            p.addParameter('stepDelays', [0.5, 8], @(x) isnumeric(x) && length(x) == 2)
            p.addParameter('aoutMin', 500, @isnumeric)
            p.addParameter('aoutMax', 4095, @isnumeric)
            p.addParameter('tolerance', 2.5e-2, @isnumeric) % Fraction (0-1)
            p.addParameter('maxIters', 100, @isnumeric);
            p.addParameter('maxStationaryIters', 5, @isnumeric);
            p.addParameter('stepSizeMultiplierDist', 50000, @isnumeric); % Step size = -multiplier * (read wattage - target wattage)
            p.addParameter('stepSizeMultiplierGrad', 0.25, @isnumeric); % Step size = multiplier * (targetWattage - currentWattage) ./ (dWattage./dAout)
            p.addParameter('stepSizeConst', 250);
            p.addParameter('powerMeterThreshold', 50e-6);

            p.parse(varargin{:})
            p = p.Results;
            obj.Params = p;

            results.aoutValues = zeros(length(p.targetPowers), length(p.mirrorPositions), 2);
            results.targetReached = false(length(p.targetPowers), length(p.mirrorPositions), 2);
            results.powers = zeros(length(p.targetPowers), length(p.mirrorPositions), 2);

            % Init motor
            obj.setParam('motor', 'TARGET_1', 0);
            if strcmpi('IDLE', obj.getStateName('motor'))
                obj.MotorArduino.Start();
            end            

            obj.openShutter();

            % Init power meter
            if ~isempty(obj.PowerMeter)
                try
                    obj.PowerMeter.disconnect();
                end
            end

            meterList = ThorlabsPowerMeter;                              % Initiate the meter_list
            deviceDescription = meterList.listdevices;               	% List available device(s)
            meter = meterList.connect(deviceDescription);           % Connect single/the first devices
            obj.PowerMeter = meter;
            meter.setDispBrightness(0.3);                          % Set display brightness
            meter.setAttenuation(0);                               % Set Attenuation
            meter.setAverageTime(0.01);                            % Set average time for the measurement
            meter.setTimeout(1000);                                % Set timeout value 

            
            for iMirrorPos = 1:length(p.mirrorPositions)
                obj.setParam('motor', 'TARGET_1', p.mirrorPositions(iMirrorPos));
                while ~strcmpi('AT_TARGET', obj.getStateName('motor'))
                    pause(0.5);
                end
                for iLaser = 1:2
                    meter.setWaveLength(p.wavelengths(iLaser));            % Set sensor wavelength
                    meter.sensorInfo;                                      % Retrive the sensor info
                    meter.setPowerAutoRange(1);                            % Set Autorange
                    pause(5)                                                    % Pause the program a bit to allow the power meter to autoadjust
                        
                    for iPower = 1:length(p.targetPowers)
                        obj.analogWrite(1, 0);
                        obj.analogWrite(2, 0);
                        
                        aoutValue = 0;
                        aoutValueOld = 0;
                        pwr = NaN;
                        pwrOld = NaN;
                        targetPwr = p.targetPowers(iPower);
                        i = 0;
                        nStationaryIters = 0;
                        
                        while true
                            if i > p.maxIters || nStationaryIters > p.maxStationaryIters
                                warning('Failed to reach target after %i iterations. Target = %g, Value = %g', i, targetPwr, targetPwr + dist)
                                break
                            end
            
                            pause(p.stepDelays(iLaser));
                            meter.updateReading(0);                          % Update the power reading(with interal period of 0.5s)
                            assert(meter.meterPowerUnit == 'W', 'Power meter unit is "%s" instead of "W"', meter.meterPowerUnit);
            
                            if meter.meterPowerReading < p.powerMeterThreshold
                                pwrOld = NaN;
                                pwr = NaN;
                            else
                                pwrOld = pwr;
                                pwr = meter.meterPowerReading;
                            end
            
                            i = i + 1;
                            dist = meter.meterPowerReading - targetPwr;
                            aoutValueOld = aoutValue;
                            dPwr = pwr - pwrOld;
                            if meter.meterPowerReading < p.powerMeterThreshold
                                thisStepSize = p.stepSizeConst;
                                stepType = 'constStep';
                            elseif isnan(dPwr)
                                thisStepSize = -sign(dist)*max(1, ceil(p.stepSizeMultiplierDist * abs(dist)));
                                stepType = 'distStep';
                            else
                                thisStepSize = -sign(dist)*max(1, ceil(abs(p.stepSizeMultiplierGrad*dist./(dPwr./dAout))));
                                stepType = 'gradStep';
                            end
                            if abs(dist) > p.tolerance * targetPwr
                                aoutValue = aoutValue + thisStepSize;
                                aoutValue = min(aoutValue, p.aoutMax);
                                aoutValue = max(aoutValue, p.aoutMin);
                                dAout = aoutValue - aoutValueOld;
                                if dAout == 0
                                    nStationaryIters = nStationaryIters + 1;
                                else
                                    nStationaryIters = 0;
                                end
                            else
                                fprintf('Target reached in %i iterations.\n', i)
                                results.targetReached(iPower, iMirrorPos, iLaser) = true;
                                break
                            end
                            obj.analogWrite(iLaser, aoutValue);
                            fprintf('%gnm, i=%i, tgt=%.1fmW, df=%.3fmW, %s=%i, AOUT(%i)=%i\n', p.wavelengths(iLaser), i, targetPwr*1e3, dist*1e3, stepType, thisStepSize, iLaser, aoutValue)
                        
                    %         fprintf('%.10f%c\r',test_meter.meterPowerReading,test_meter.meterPowerUnit);
                        end
                    
                        pause(p.stepDelays(iLaser));
                        meter.updateReading(0);
                        results.aoutValues(iPower, iMirrorPos, iLaser) = aoutValue;
                        results.powers(iPower, iMirrorPos, iLaser) = meter.meterPowerReading;
                    end
                end
            end
            
            % Turn lasers off
            obj.analogWrite(1, 0);
            obj.analogWrite(2, 0);
            obj.closeShutter();
            
            meter.disconnect;                                      % Disconnect and release
            obj.PowerMeter = [];

            obj.Results = results;
        end

        function results = validate(obj, varargin)
            p = inputParser();
            p.addParameter('validationDelay', [4, 15], @(x) isnumeric(x) && length(x) == 2)
            p.parse(varargin{:})
            obj.Params.validationDelay = p.Results.validationDelay;
            p = obj.Params;
            results = obj.Results;

            assert(~isempty(results))

            obj.openShutter();

            % Init motor
            obj.setParam('motor', 'TARGET_1', 0);
            if strcmpi('IDLE', obj.getStateName('motor'))
                obj.MotorArduino.Start();
            end

            % Init power meter
            if ~isempty(obj.PowerMeter)
                try
                    obj.PowerMeter.disconnect();
                end
            end

            meterList = ThorlabsPowerMeter;                              % Initiate the meter_list
            deviceDescription = meterList.listdevices;               	% List available device(s)
            meter = meterList.connect(deviceDescription);           % Connect single/the first devices
            obj.PowerMeter = meter;
            meter.setDispBrightness(0.3);                          % Set display brightness
            meter.setAttenuation(0);                               % Set Attenuation
            meter.setAverageTime(0.01);                            % Set average time for the measurement
            meter.setTimeout(1000);                                % Set timeout value 
                        
            results.powersValidation = zeros(size(results.powers));
            for iMirrorPos = 1:length(p.mirrorPositions)
                obj.setParam('motor', 'TARGET_1', p.mirrorPositions(iMirrorPos));
                while ~strcmpi('AT_TARGET', obj.getStateName('motor'))
                    pause(0.5);
                end
                for iLaser = 1:2
                    obj.analogWrite(1, 0);
                    obj.analogWrite(2, 0);
            
                    meter.setWaveLength(p.wavelengths(iLaser));            % Set sensor wavelength
                    meter.sensorInfo;                                      % Retrive the sensor info
                    meter.setPowerAutoRange(1);                            % Set Autorange
                    pause(5);
            
                    for iPower = 1:length(p.targetPowers)
                        % Playback
                        obj.analogWrite(iLaser, results.aoutValues(iPower, iMirrorPos, iLaser));
                        pause(p.validationDelay(iLaser))                               % Pause the program a bit to allow the power meter to autoadjust
            
                        meter.updateReading(0);
                        results.powersValidation(iPower, iMirrorPos, iLaser) = meter.meterPowerReading;
            
                        fprintf('%inm, mirror=%i, Tgt=%.1fmW, Cal=%.3fmW, Val=%.3fmW\n', p.wavelengths(iLaser), p.mirrorPositions(iMirrorPos), p.targetPowers(iPower)*1e3, results.powers(iPower, iMirrorPos, iLaser)*1e3, meter.meterPowerReading*1e3);
                    end
                end
            end
            
            % Turn lasers off
            obj.analogWrite(1, 0);
            obj.analogWrite(2, 0);
            obj.closeShutter();
            
            meter.disconnect;                                      % Disconnect and release
            obj.PowerMeter = [];

            obj.Results = results;
        end

        function log = runStimTrain(obj, iMirrorPos, iPower, iLaser, varargin)
            parser = inputParser();
            parser.addRequired('iMirrorPos', @isnumeric)
            parser.addRequired('iPower', @isnumeric)
            parser.addRequired('iLaser', @isnumeric)
            parser.addParameter('nPulses', 10, @(x) isnumeric(x) && mod(x, 1)==0)
            parser.addParameter('pulseWidth', 0.01, @isnumeric)
            parser.addParameter('ipi', 0.5, @isnumeric) % Inter-pulse-interval, in seconds
            parser.addParameter('preTrainDelay', 8, @isnumeric)
            parser.addParameter('postTrainDelay', 1, @isnumeric)
        
            parser.parse(iMirrorPos, iPower, iLaser, varargin{:})
       
            p = obj.Params;
            results = obj.Results;

            r = parser.Results;
            iMirrorPos = r.iMirrorPos;
            iPower = r.iPower;
            iLaser = r.iLaser;
        
            DEBUG = true;
            log.params = parser.Results;
            log.wavelength = p.wavelengths(iLaser);
            log.targetPower = p.targetPowers(iPower);
            log.calibrationPower = results.powers(iPower, iMirrorPos, iLaser);
            log.validationPower = results.powersValidation(iPower, iMirrorPos, iLaser);
            log.mirrorPos = p.mirrorPositions(iMirrorPos);
            log.analogOutValue = results.aoutValues(iPower, iMirrorPos, iLaser);
            log.mirrorStartTime = 0;
            log.mirrorStopTime = 0;
            log.laserOnTime = 0;
            log.trainOnTime = 0;
            log.trainOffTime = 0;
            log.laserOffTime = 0;
            % parser.Results
            % When did mirror start moving
            % When did mirro stop
            % When did laser turn on
            % Laser power
            % Laser wavelength
            % When did laser turn off
        
            % Step 1: Set mirror
            obj.setParam('motor', 'TARGET_1', p.mirrorPositions(iMirrorPos));
            if strcmpi('IDLE', obj.getStateName('motor'))
                obj.MotorArduino.Start();
            end
            log.mirrorStartTime = datetime();
            if DEBUG
                fprintf('\t%s: move mirror.\n', datetime())
            end
            pause(0.1);
            while ~strcmpi('AT_TARGET', obj.getStateName('motor'))
                pause(0.01);
            end
            log.mirrorStopTime = datetime();
            if DEBUG
                fprintf('\t%s: mirror at target.\n', datetime())
            end

            % Step 2: Turn on laser and wait
            log.laserOnTime = datetime();
            obj.analogWrite(iLaser, results.aoutValues(iPower, iMirrorPos, iLaser));
            if DEBUG
                fprintf('\t%s: laser on.\n', datetime())
            end
            pause(r.preTrainDelay);

            % Step 3: Do pulses
            obj.setParam('laser', 'OPTO_ENABLED', 1);
            obj.setParam('laser', 'OPTO_PULSE_DURATION', round(r.pulseWidth*1e3));
            obj.setParam('laser', 'OPTO_PULSE_INTERVAL', round(r.ipi*1e3));
            obj.setParam('laser', 'OPTO_NUM_PULSES', r.nPulses);
            obj.setParam('laser', 'OPTO_SELECTION', 1); % Deprecated feature, keep at 1
            pause(0.1);
            if DEBUG
                fprintf('\t%s: starting stim train.\n', datetime())
            end
            log.trainOnTime = datetime();
            success = obj.LaserArduino.OptogenStim();
            assert(success)
            pause(0.1);
            while ~strcmpi('IDLE', obj.getStateName('laser'))
                pause(0.01);
            end
            log.trainOffTime = datetime();
            if DEBUG
                fprintf('\t%s: stim train complete.\n', datetime())
            end

            % Step 4: Wait and turn off laser
            pause(r.postTrainDelay);
            obj.analogWrite(iLaser, 0);
            log.laserOffTime = datetime();
            if DEBUG
                fprintf('\t%s: laser off.\n', datetime())
            end
            obj.addLogEntry(log);
        end

        function runStimSession(obj, varargin)
            parser = inputParser();
            parser.addParameter('nPulses', 10, @(x) isnumeric(x) && mod(x, 1)==0)
            parser.addParameter('pulseWidth', 0.01, @isnumeric)
            parser.addParameter('ipi', 0.5, @isnumeric) % Inter-pulse-interval, in seconds
            parser.addParameter('preTrainDelay', 8, @isnumeric)
            parser.addParameter('postTrainDelay', 1, @isnumeric)
            parser.addParameter('iti', 1, @isnumeric) % Inter-train-interval, in seconds
            parser.addParameter('waitForUserBetweenTrains', true, @islogical) % Ask before continuing to next train
            parser.addParameter('waitForUserTimeout', 10, @isnumeric) % If no response, auto continue
            parser.parse(varargin{:})
            nPulses = parser.Results.nPulses;
            pulseWidth = parser.Results.pulseWidth;
            ipi = parser.Results.ipi;
            preTrainDelay = parser.Results.preTrainDelay;
            postTrainDelay = parser.Results.postTrainDelay;
            iti = parser.Results.iti;
            waitForUserBetweenTrains = parser.Results.waitForUserBetweenTrains;
            waitForUserTimeout = parser.Results.waitForUserTimeout;
            
            p = obj.Params;
            results = obj.Results;

            conditions = zeros(length(p.mirrorPositions)*length(p.targetPowers)*length(p.wavelengths), 3);
            
            iCond = 0;
            for iMirrorPos = 1:length(p.mirrorPositions)
                for iPower = 1:length(p.targetPowers)
                    for iLaser = 1:length(p.wavelengths)
                        iCond = iCond + 1;
                        conditions(iCond, 1:3) = [iMirrorPos, iPower, iLaser];
                    end
                end
            end
            
            % Randomize conditions
            conditions = conditions(randperm(size(conditions, 1)), :);
            disp(conditions)
            
            % Run through all conditions
            for iCond = 1:length(conditions)
                iMirrorPos = conditions(iCond, 1);
                iPower = conditions(iCond, 2);
                iLaser = conditions(iCond, 3);
            
                fprintf('Running condition %i of %i, mirror=%i, power=%.2fmW (%.2fmW), wavelength=%.1fnm:\n', iCond, length(conditions), p.mirrorPositions(iMirrorPos), p.targetPowers(iPower)*1e3, results.powersValidation(iPower, iMirrorPos, iLaser)*1e3, p.wavelengths(iLaser))
            
                obj.runStimTrain(iMirrorPos, iPower, iLaser, ...
                    nPulses=nPulses, pulseWidth=pulseWidth, ipi=ipi, ...
                    preTrainDelay=preTrainDelay, postTrainDelay=postTrainDelay);
                obj.save();
            
                if iCond < length(conditions) 
                    if waitForUserBetweenTrains
                        if iCond < length(conditions)
                            t = timer('StartDelay', waitForUserTimeout, ...
                                'TimerFcn', @(~,~)delete(findall(groot,'WindowStyle','modal')));
                            start(t)
                            answer = questdlg('Do you want to run next train?', ...
	                            'Continue', ...
	                            'Yes','No','Yes');
                            % Handle response
                            switch answer
                                case 'No'
                                    break
                                otherwise
                                    continue
                            end
                        end
                    end
                    pause(iti);
                end
            end

        end

        function openShutter(obj, state)
            if nargin < 2
                state = true;
            end
            if state
                obj.LaserArduino.SendMessage('T 1 1');
            else
                obj.LaserArduino.SendMessage('T 1 0');
            end
        end

        function closeShutter(obj)
            obj.openShutter(false);
        end

        function analogWrite(obj, channel, value)
            assert(ismember(channel, [1, 2]), 'channel must be 1 or 2')
            assert(isnumeric(value) && length(value)==1 && mod(value, 1) == 0, 'value must be an integer')
            obj.LaserArduino.SendMessage(sprintf('A %i %i', channel, value));
        end

        function setParam(obj, arduinoName, paramName, value)
            switch lower(arduinoName)
                case 'laser'
                    arduino = obj.LaserArduino;
                case 'motor'
                    arduino = obj.MotorArduino;
                otherwise
                    error('ArduinoName must be "laser" or "motor"')
            end
            paramIndex = find(strcmpi(arduino.ParamNames, paramName));
            assert(~isempty(paramIndex), 'Could not find Arduino parameter with name: "%s".', paramName)
            assert(mod(value, 1)==0, 'Param value must be an interger instead of %g.', value)
            arduino.SetParam(paramIndex, value);
        end

        function state = getStateName(obj, arduinoName)
            switch lower(arduinoName)
                case 'laser'
                    arduino = obj.LaserArduino;
                case 'motor'
                    arduino = obj.MotorArduino;
                otherwise
                    error('ArduinoName must be "laser" or "motor"')
            end
            state = arduino.StateNames{arduino.State};
        end

        function save(obj)
            save(obj.Path, 'obj');
        end

        function addLogEntry(obj, trainLog)
            log = obj.Log;
            if isempty(log)
                log = trainLog;
            else
                log(length(log) + 1) = trainLog;
            end
            obj.Log = log;
        end

        function close(obj)
            obj.LaserInterface.ArduinoClose([], [], true);

            obj.setParam('motor', 'TARGET_1', 0);
            pause(0.1);
            while ~strcmpi('AT_TARGET', obj.getStateName('motor'))
                pause(0.1);
            end
            obj.MotorArduino.Stop();
            obj.MotorInterface.ArduinoClose([], [], true);
        end
    end
end