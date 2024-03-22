classdef TwoColorExperiment < handle
    properties
        Path = ''
        LaserArduino % Also behavior
        MotorArduino
        Params % Calibration Params
        Results % Calibration Results
        Log % Stimulation Log
        Plan
    end

    properties (Transient, Hidden)
        LaserInterface
        MotorInterface
        PowerMeter
        Listeners
    end

    methods
        function obj = TwoColorExperiment(varargin)
            p = inputParser();
            p.addParameter('offline', false, @islogical)
            p.addParameter('laserCOM', 'COM5', @ischar)
            p.addParameter('motorCOM', 'COM7', @ischar)
            p.parse(varargin{:})
            r = p.Results;

            if r.offline
                return
            end

            % Connect to arduinos
            obj.connect(r.laserCOM, r.motorCOM, true);

            % Choose save path
            [file, path] = uiputfile(sprintf('expname_%s.mat', datestr(now, 'yyyymmdd')), 'Choose autosave path:');
            if file == 0
                return
            end
            obj.Path = [path, file];
        end

        function connect(obj, laserCOM, motorCOM, debug)
            if nargin < 4
                debug = false;
            end
            obj.LaserInterface = MouseBehaviorInterface(laserCOM); % This is the laser control arduino
            obj.MotorInterface = MouseBehaviorInterface(motorCOM); % This is the stepping motor arduino (for moving mirror)
            obj.LaserArduino = obj.LaserInterface.Arduino;
            obj.MotorArduino = obj.MotorInterface.Arduino;
            obj.LaserArduino.DebugMode = debug;
            obj.MotorArduino.DebugMode = debug;
        end

        function conditions = planStim(obj, varargin)
            parser = inputParser();
            parser.addParameter('nPulses', 10, @(x) isnumeric(x) && mod(x, 1)==0)
            parser.addParameter('pulseWidth', 0.01, @isnumeric)
            parser.addParameter('ipi', 0.5, @isnumeric) % Inter-pulse-interval, in seconds
            parser.addParameter('preTrainDelay', 8, @isnumeric)
            parser.addParameter('postTrainDelay', 1, @isnumeric)
            parser.parse(varargin{:})
            
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
            obj.Plan.stim = struct('length', [], 'index', 0, 'completed', false, 'conditions', [], 'nPulses', [], 'pulseWidth', [], 'ipi', [], 'preTrainDelay', [], 'postTrainDelay', []);
            obj.Plan.stim.length            = size(conditions, 1);
            obj.Plan.stim.index             = 0;
            obj.Plan.stim.completed         = false;
            obj.Plan.stim.conditions        = conditions; % (iCond, [iMirrorPos, iPower, iLaser])
            obj.Plan.stim.nPulses           = parser.Results.nPulses;
            obj.Plan.stim.pulseWidth        = parser.Results.pulseWidth;
            obj.Plan.stim.ipi               = parser.Results.ipi;
            obj.Plan.stim.preTrainDelay     = parser.Results.preTrainDelay;
            obj.Plan.stim.postTrainDelay    = parser.Results.postTrainDelay;

            if ~isfield(obj.LaserArduino.Listeners, 'TCE_OptoRequested') || ~isvalid(obj.LaserArduino.Listeners.TCE_OptoRequested)
                obj.LaserArduino.Listeners.TCE_OptoRequested = addlistener(obj.LaserArduino, 'OptoRequested', @obj.OnOptoRequested);
            end
        end

        function positions = planLever(obj, varargin)
            p = inputParser();
            p.addParameter('nBlocksPerPosition', 3, @isnumeric);
            p.addParameter('nPositions', 4, @isnumeric)
            p.addParameter('randomize', true, @islogical)
            p.parse(varargin{:})
            nBlocksPerPosition = p.Results.nBlocksPerPosition;
            nPositions = p.Results.nPositions;
            randomize = p.Results.randomize;

            positions = repmat(1:nPositions, 1, nBlocksPerPosition);
            if randomize
                positions = positions(randperm(nBlocksPerPosition*nPositions));
            end

            obj.Plan.lever = struct('length', [], 'index', 0, 'completed', false, 'positions', [], 'isRandom', []);
            obj.Plan.lever.length       = nBlocksPerPosition*nPositions;
            obj.Plan.lever.index        = 0;
            obj.Plan.lever.completed    = false;
            obj.Plan.lever.positions    = positions;
            obj.Plan.lever.isRandom     = randomize;

            if ~isfield(obj.LaserArduino.Listeners, 'TCE_MoveLeverRequested') || ~isvalid(obj.LaserArduino.Listeners.TCE_MoveLeverRequested)
                obj.LaserArduino.Listeners.TCE_MoveLeverRequested = addlistener(obj.LaserArduino, 'MoveLeverRequested', @obj.OnMoveLeverRequested);
            end

            obj.save();
        end

        function OnOptoRequested(obj, ~, ~)
            if isempty(obj.Plan) || ~isfield(obj.Plan, 'stim') || isempty(obj.Plan.stim) || ~isfield(obj.Plan.stim, 'conditions') || isempty(obj.Plan.stim.conditions)
                warning('Stim plan is empty/not initialized, sending back "; 0" to skip opto.')
                obj.LaserArduino.SendMessage('; 0');
                return
            end

            index = obj.Plan.stim.index + 1;
            if index > obj.Plan.stim.length
                index = 1;
                obj.Plan.stim.completed = true;
            end

            conditions = obj.Plan.stim.conditions;
            iMirrorPos = conditions(index, 1);
            iPower = conditions(index, 2);
            iLaser = conditions(index, 3);
        
            p = obj.Params;
            results = obj.Results;
            fprintf('Running condition %i of %i, mirror=%i, power=%.2fmW (%.2fmW), wavelength=%.1fnm:\n', index, length(conditions), p.mirrorPositions(iMirrorPos), p.targetPowers(iPower)*1e3, results.powersValidation(iPower, iMirrorPos, iLaser)*1e3, p.wavelengths(iLaser))
        
            obj.Plan.stim.index = index;

            obj.runStimTrainPlanned(iMirrorPos, iPower, iLaser, ...
                nPulses=obj.Plan.stim.nPulses, pulseWidth=obj.Plan.stim.pulseWidth, ipi=obj.Plan.stim.ipi, ...
                preTrainDelay=obj.Plan.stim.preTrainDelay);

            obj.save();

        end

        function runStimSessionPlanned(obj, varargin)
            parser = inputParser();
            parser.addParameter('residual', true, @islogical); % True to only run the residual part of the plan that hasn't been (by arduino request) played yet.
            parser.addParameter('ignoreCompletion', false, @islogical); % True to run the plan even if (obj.Plan.stim.complete == true).
            parser.addParameter('iti', 10, @isnumeric);
            parser.parse(varargin{:})
            residual = parser.Results.residual;
            ignoreCompletion = parser.Results.ignoreCompletion;
            iti = parser.Results.iti;

            p = obj.Params;
            results = obj.Results;

            if ~ignoreCompletion && obj.Plan.stim.completed
                warning('runStimSessionPlanned will not run becasue stim plan has been completed once. Try calling runStimSessionPlanned(ignoreCompletion=false) if you want to run stim anyway.')
                return
            end

            if residual
                startIndex = obj.Plan.stim.index + 1;
            else
                startIndex = 1;
            end

            for index = startIndex:obj.Plan.stim.length
                conditions = obj.Plan.stim.conditions;
                iMirrorPos = conditions(index, 1);
                iPower = conditions(index, 2);
                iLaser = conditions(index, 3);
    
                fprintf('Running condition %i of %i, mirror=%i, power=%.2fmW (%.2fmW), wavelength=%.1fnm:\n', index, length(conditions), p.mirrorPositions(iMirrorPos), p.targetPowers(iPower)*1e3, results.powersValidation(iPower, iMirrorPos, iLaser)*1e3, p.wavelengths(iLaser))
            
                % Run stim train
                obj.runStimTrain(iMirrorPos, iPower, iLaser, ...
                    nPulses=obj.Plan.stim.nPulses, pulseWidth=obj.Plan.stim.pulseWidth, ipi=obj.Plan.stim.ipi, ...
                    preTrainDelay=obj.Plan.stim.preTrainDelay, postTrainDelay=obj.Plan.stim.postTrainDelay);
                
                % Register completion
                obj.Plan.stim.index = index;
                if index == obj.Plan.stim.length
                    obj.Plan.stim.completed = true;
                end
                obj.save();
            
                % Give user a change to cancel
                if index < obj.Plan.stim.length
                    t = timer('StartDelay', iti, ...
                        'TimerFcn', @(~,~)delete(findall(groot,'WindowStyle','modal')));
                    start(t)
                    answer = questdlg('Do you want to run next train?', ...
                        'Continue', ...
                        'Yes','No','Yes');
                    stop(t)
                    % Handle response
                    switch answer
                        case 'No'
                            break
                        otherwise
                            continue
                    end
                end
            end
        end

        function OnMoveLeverRequested(obj, ~, ~)
            if isempty(obj.Plan) || ~isfield(obj.Plan, 'lever') || isempty(obj.Plan.lever) || ~isfield(obj.Plan.lever, 'positions') || isempty(obj.Plan.lever.positions)
                warning('Lever plan is empty/not initialized, sending back "^ 1" so lever goes to position 1.')
                obj.LaserArduino.SendMessage('^ 1');
                return
            end


            index = obj.Plan.lever.index + 1;
            if index > obj.Plan.lever.length
                index = 1;
                obj.Plan.lever.completed = true;
            end
            pos = obj.Plan.lever.positions(index);
            obj.LaserArduino.SendMessage(sprintf('^ %i', pos));
            obj.Plan.lever.index = index;

            if obj.LaserArduino.DebugMode
                fprintf('\t\tMOVE_LEVER: request processed, sending motor 1 to position %i (%i/%i).\n', pos, index, obj.Plan.lever.length)
            end
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
            obj.setParam('motor', 'MOTOR2_TARGET', 0);
            if any(strcmpi('IDLE', obj.getStateName('motor')))
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
                obj.setParam('motor', 'MOTOR2_TARGET', p.mirrorPositions(iMirrorPos));
                while ~strcmpi('AT_TARGET', obj.getStateName('motor', 2))
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
            obj.setParam('motor', 'MOTOR2_TARGET', 0);
            if any(strcmpi('IDLE', obj.getStateName('motor')))
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
                obj.setParam('motor', 'MOTOR2_TARGET', p.mirrorPositions(iMirrorPos));
                while ~strcmpi('AT_TARGET', obj.getStateName('motor', 2))
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

        % Stim train on arduino request
        function log = runStimTrainPlanned(obj, iMirrorPos, iPower, iLaser, varargin)
            parser = inputParser();
            parser.addRequired('iMirrorPos', @isnumeric)
            parser.addRequired('iPower', @isnumeric)
            parser.addRequired('iLaser', @isnumeric)
            parser.addParameter('nPulses', 10, @(x) isnumeric(x) && mod(x, 1)==0)
            parser.addParameter('pulseWidth', 0.01, @isnumeric)
            parser.addParameter('ipi', 0.5, @isnumeric) % Inter-pulse-interval, in seconds
            parser.addParameter('preTrainDelay', 8, @isnumeric)
        
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
            obj.setParam('motor', 'MOTOR2_TARGET', p.mirrorPositions(iMirrorPos));
            log.mirrorStartTime = datetime();
            if DEBUG
                fprintf('\t%s: move mirror.\n', datetime())
            end
            % Step 2: Turn on laser and wait
            log.laserOnTime = datetime();
            obj.analogWrite(iLaser, results.aoutValues(iPower, iMirrorPos, iLaser));

            % Step 3: Do pulses
            obj.setParam('laser', 'OPTO_ENABLED', 1);
            obj.setParam('laser', 'OPTO_PULSE_DURATION', round(r.pulseWidth*1e3));
            obj.setParam('laser', 'OPTO_PULSE_INTERVAL', round(r.ipi*1e3));
            obj.setParam('laser', 'OPTO_NUM_PULSES', r.nPulses);
            obj.setParam('laser', 'OPTO_WARMUP_TIME', round(r.preTrainDelay*1e3));
            if DEBUG
                fprintf('\t%s: starting stim train.\n', datetime())
            end
            obj.LaserArduino.SendMessage('; 1'); % Tell arduino laser/mirror is ready, goto opto.
  
            obj.addLogEntry(log);
        end

        % Manual stim train
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
            obj.setParam('motor', 'MOTOR2_TARGET', p.mirrorPositions(iMirrorPos));
            if any(strcmpi('IDLE', obj.getStateName('motor')))
                obj.MotorArduino.Start();
            end
            log.mirrorStartTime = datetime();
            if DEBUG
                fprintf('\t%s: move mirror.\n', datetime())
            end
            pause(0.1);
            while ~strcmpi('AT_TARGET', obj.getStateName('motor', 2))
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
%             obj.setParam('laser', 'OPTO_SELECTION', 1); % Deprecated feature, keep at 1
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

        % Manual stim session (iterate through all stim conditions)
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
            parser.addParameter('planned', true, @islogical)
            parser.addParameter('onlyRemaining', true, @islogical)
            parser.parse(varargin{:})
            nPulses                     = parser.Results.nPulses;
            pulseWidth                  = parser.Results.pulseWidth;
            ipi                         = parser.Results.ipi;
            preTrainDelay               = parser.Results.preTrainDelay;
            postTrainDelay              = parser.Results.postTrainDelay;
            iti                         = parser.Results.iti;
            waitForUserBetweenTrains    = parser.Results.waitForUserBetweenTrains;
            waitForUserTimeout          = parser.Results.waitForUserTimeout;
            
            p                           = obj.Params;
            results                     = obj.Results;

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
                obj.LaserArduino.SendMessage('T 1');
            else
                obj.LaserArduino.SendMessage('T 0');
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

        function state = getStateName(obj, arduinoName, motorIndex)
            switch lower(arduinoName)
                case 'laser'
                    arduino = obj.LaserArduino;
                case 'motor'
                    arduino = obj.MotorArduino;
                otherwise
                    error('ArduinoName must be "laser" or "motor"')
            end
            if nargin < 3
                if length(arduino.State) == 1
                    state = arduino.StateNames{arduino.State};
                else
                    state = arduino.StateNames(arduino.State); % Return cell array of state names
                end
            else
                state = arduino.StateNames{arduino.GetState(motorIndex)};
            end
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

            obj.setParam('motor', 'MOTOR1_TARGET_1', 0);
            obj.setParam('motor', 'MOTOR1_TARGET_2', 0);
            obj.setParam('motor', 'MOTOR1_TARGET_3', 0);
            obj.setParam('motor', 'MOTOR1_TARGET_4', 0);
            obj.setParam('motor', 'MOTOR2_TARGET', 0);
            pause(0.1);
            while ~all(strcmpi('AT_TARGET', obj.getStateName('motor')))
                pause(0.1);
            end
            obj.MotorArduino.Stop();
            obj.MotorInterface.ArduinoClose([], [], true);
        end
    end
end