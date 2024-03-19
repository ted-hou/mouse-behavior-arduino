function trainlog = runStimTrain(hMotor, hLaser, p, result, iMirrorPos, iPower, iLaser, varargin)
    parser = inputParser();
    parser.addRequired('hMotor', @(x) isa(x, 'MouseBehaviorInterface'))
    parser.addRequired('hLaser', @(x) isa(x, 'MouseBehaviorInterface'))
    parser.addRequired('p', @isstruct)
    parser.addRequired('results', @isstruct)
    parser.addRequired('iMirrorPos', @isnumeric)
    parser.addRequired('iPower', @isnumeric)
    parser.addRequired('iLaser', @isnumeric)
    parser.addParameter('nPulses', 10, @(x) isnumeric(x) && mod(x, 1)==0)
    parser.addParameter('pulseWidth', 0.01, @isnumeric)
    parser.addParameter('ipi', 0.5, @isnumeric) % Inter-pulse-interval, in seconds
    parser.addParameter('preTrainDelay', 8, @isnumeric)
    parser.addParameter('postTrainDelay', 1, @isnumeric)

    parser.parse(hMotor, hLaser, p, result, iMirrorPos, iPower, iLaser, varargin{:})

    r = parser.Results;
    p = r.p;
    result = r.results;
    iMirrorPos = r.iMirrorPos;
    iPower = r.iPower;
    iLaser = r.iLaser;

    DEBUG = true;
    trainlog.params = parser.Results;
    trainlog.wavelength = p.wavelengths(iLaser);
    trainlog.targetPower = p.targetPowers(iPower);
    trainlog.calibrationPower = result.powers(iPower, iMirrorPos, iLaser);
    trainlog.validationPower = result.powersValidation(iPower, iMirrorPos, iLaser);
    trainlog.mirrorPos = p.mirrorPositions(iMirrorPos);
    trainlog.analogOutValue = result.aoutValues(iPower, iMirrorPos, iLaser);
    trainlog.mirrorStartTime = 0;
    trainlog.mirrorStopTime = 0;
    trainlog.laserOnTime = 0;
    trainlog.trainOnTime = 0;
    trainlog.trainOffTime = 0;
    trainlog.laserOffTime = 0;
    % parser.Results
    % When did mirror start moving
    % When did mirro stop
    % When did laser turn on
    % Laser power
    % Laser wavelength
    % When did laser turn off

    % Step 1: Set mirror
    hMotor.Arduino.SetParam(find(strcmpi(hMotor.Arduino.ParamNames, 'TARGET_1')), p.mirrorPositions(iMirrorPos));
    trainlog.mirrorStartTime = datetime();
    if DEBUG
        fprintf('\t%s: move mirror.\n', datetime())
    end
    pause(0.1);
    while ~strcmpi('AT_TARGET', hMotor.Arduino.StateNames{hMotor.Arduino.State})
        pause(0.01);
    end
    trainlog.mirrorStopTime = datetime();
    if DEBUG
        fprintf('\t%s: mirror at target.\n', datetime())
    end

    % Step 2: Turn on laser and wait
    trainlog.laserOnTime = datetime();
    hLaser.Arduino.SendMessage(sprintf('A %i %i', iLaser, result.aoutValues(iPower, iMirrorPos, iLaser)));
    if DEBUG
        fprintf('\t%s: laser on.\n', datetime())
    end
    pause(r.preTrainDelay);

    % Step 3: Do pulses
    hLaser.Arduino.SetParam(find(strcmpi(hLaser.Arduino.ParamNames, 'OPTO_ENABLED')), 1);
    hLaser.Arduino.SetParam(find(strcmpi(hLaser.Arduino.ParamNames, 'OPTO_PULSE_DURATION')), round(r.pulseWidth*1e3));
    hLaser.Arduino.SetParam(find(strcmpi(hLaser.Arduino.ParamNames, 'OPTO_PULSE_INTERVAL')), round(r.ipi*1e3));
    hLaser.Arduino.SetParam(find(strcmpi(hLaser.Arduino.ParamNames, 'OPTO_NUM_PULSES')), r.nPulses);
    hLaser.Arduino.SetParam(find(strcmpi(hLaser.Arduino.ParamNames, 'OPTO_SELECTION')), 1); % Deprecated feature
    pause(0.1);
    if DEBUG
        fprintf('\t%s: starting stim train.\n', datetime())
    end
    trainlog.trainOnTime = datetime();
    success = hLaser.Arduino.OptogenStim();
    assert(success)
    pause(0.1);
    while ~strcmpi('IDLE', hLaser.Arduino.StateNames{hLaser.Arduino.State})
        pause(0.01);
    end
    trainlog.trainOffTime = datetime();
    if DEBUG
        fprintf('\t%s: stim train complete.\n', datetime())
    end

    % Step 4: Wait and turn off laser
    pause(r.postTrainDelay);
    hLaser.Arduino.SendMessage(sprintf('A %i %i', iLaser, 0));
    trainlog.laserOffTime = datetime();
    if DEBUG
        fprintf('\t%s: laser off.\n', datetime())
    end
end