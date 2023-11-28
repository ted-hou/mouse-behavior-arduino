%%
hLaser = MouseBehaviorInterface('COM5'); % This is the laser control arduino
hMotor = MouseBehaviorInterface('COM7'); % This is the stepping motor arduino (for moving mirror)
hLaser.Arduino.DebugMode = false;
hMotor.Arduino.DebugMode = false;

%%
[file, path] = uiputfile('*.mat');

%%
% Initial condition: turn everything off

while ~strcmpi('IDLE', hLaser.Arduino.StateNames{hLaser.Arduino.State})
    pause(0.01);
end

while ~strcmpi('AT_TARGET', hMotor.Arduino.StateNames{hMotor.Arduino.State})
    pause(0.01);
end
hLaser.Arduino.SendMessage(sprintf('A %i %i', 1, 0));
hLaser.Arduino.SendMessage(sprintf('A %i %i', 2, 0));

%
interTrainInterval = 10;
waitForConfirmationBetweenTrains = true;

nPulses = 10;
pulseWidth = 0.01;
ipi = 0.5;
preTrainDelay = 8;
postTrainDelay = 1;

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
conditions = conditions(randperm(16), :);
disp(conditions)

% log = struct('params', [], 'wavelength', [], 'targetPower', [], 'calibrationPower', [], 'validationPower', [], 'mirrorPos', [], 'analogOutValue', [], 'mirrorStartTime', [], 'mirrorStopTime', [], 'laserOnTime', [], 'trainStartTime', [], 'trainStopTime', [], 'laserOffTime', []);
% clear log trainlog
if ~exist('log', 'var')
    log = struct([]);
else
    answer = questdlg(sprintf('Variable ''log'' already exists (length=%i), do you want to:', length(log)), ...
	    'Warning', ...
	    'Append','Overwrite','Cancel','Cancel');
    % Handle response
    switch answer
        case 'Append'
            fprintf('Appending to existing log...\n');
        case 'Overwrite'
            log = struct([]);
        case 'Cancel'
            error('User cancelled script execution.')
    end    
end

% Run through all conditions
for iCond = 1:length(conditions)
    iMirrorPos = conditions(iCond, 1);
    iPower = conditions(iCond, 2);
    iLaser = conditions(iCond, 3);

    fprintf('Running condition %i of %i, mirror=%i, power=%.2fmW (%.2fmW), wavelength=%.1fnm:\n', iCond, length(conditions), p.mirrorPositions(iMirrorPos), p.targetPowers(iPower)*1e3, result.powersValidation(iPower, iMirrorPos, iLaser)*1e3, p.wavelengths(iLaser))

    trainlog = runStimTrain(hMotor, hLaser, p, result, iMirrorPos, iPower, iLaser, ...
        nPulses=nPulses, pulseWidth=pulseWidth, ipi=ipi, ...
        preTrainDelay=preTrainDelay, postTrainDelay=postTrainDelay);
    if isempty(log)
        log = trainlog;
    else
        log(length(log) + 1) = trainlog;
    end
    save([path, file], 'log', 'hLaser', 'hMotor', 'p', 'result');

    if waitForConfirmationBetweenTrains
        if iCond < length(conditions)
            t = timer('StartDelay', 10, ...
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

    pause(interTrainInterval);

end

clear iCond iMirrorPos iPower iLaser
