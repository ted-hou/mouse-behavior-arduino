hLaser = MouseBehaviorInterface('COM5'); % This is the laser control arduino
hMotor = MouseBehaviorInterface('COM7'); % This is the stepping motor arduino (for moving mirror)

%%
try
    meter.disconnect;                                      % Disconnect and release
end

clear p result
p.mirrorPositions = [-300, 0];
p.targetPowers = [0.5, 2, 6] .* 1e-3;
p.wavelengths = [473, 593];
p.stepDelays = [0.5, 4];
p.aoutMin = 0;
p.aoutMax = 4095;
p.tolerancePercentage = 2.5e-2;
p.maxIters = 100;
p.maxStationaryIters = 5;
% p.stepSizeMultiplier = 100000; % Step size = -multiplier * (read wattage - target wattage)
p.stepSizeMultiplier = 10000; % Step size = -multiplier * (read wattage - target wattage)
p.readThreshold = 60e-6; % Watts, values below this are considered zero.
% p.subthresholdStepSize = 500; % 
p.subthresholdStepSize = 250; % 

result.aoutValues = zeros(length(p.targetPowers), length(p.mirrorPositions), 2);
result.targetReached = false(length(p.targetPowers), length(p.mirrorPositions), 2);
result.powers = zeros(length(p.targetPowers), length(p.mirrorPositions), 2);

meterList=ThorlabsPowerMeter;                              % Initiate the meter_list
DeviceDescription=meterList.listdevices;               	% List available device(s)
meter=meterList.connect(DeviceDescription);           % Connect single/the first devices


for iMirrorPos = 1:length(p.mirrorPositions)
    hMotor.Arduino.SetParam(find(strcmpi(hMotor.Arduino.ParamNames, 'TARGET_1')), p.mirrorPositions(iMirrorPos));
    while ~strcmpi('AT_TARGET', hMotor.Arduino.StateNames{hMotor.Arduino.State})
        pause(0.5);
    end
    for iLaser = 1:2
        for iPower = 1:length(p.targetPowers)
            meter.setWaveLength(p.wavelengths(iLaser));            % Set sensor wavelength
            meter.setDispBrightness(0.3);                          % Set display brightness
            meter.setAttenuation(0);                               % Set Attenuation
            meter.sensorInfo;                                      % Retrive the sensor info
            meter.setPowerAutoRange(1);                            % Set Autorange
            pause(5)                                                    % Pause the program a bit to allow the power meter to autoadjust
            meter.setAverageTime(0.01);                            % Set average time for the measurement
            meter.setTimeout(1000);                                % Set timeout value 
            
            hLaser.Arduino.SendMessage(sprintf('A %i %i', 1, 0));
            hLaser.Arduino.SendMessage(sprintf('A %i %i', 2, 0));
            
            aoutValue = 0;
            aoutValueOld = 0;
            targetPwr = p.targetPowers(iPower);
            i = 0;
            nStationaryIters = 0;
            
            while true
                if i > p.maxIters || nStationaryIters > p.maxStationaryIters
                    warning('Failed to reach target after %i iterations. Target = %g, Value = %g', i, targetPwr, targetPwr + dPwr)
                    break
                end

                pause(p.stepDelays(iLaser));
                meter.updateReading(0);                          % Update the power reading(with interal period of 0.5s)
                assert(meter.meterPowerUnit == 'W', 'Power meter unit is "%s" instead of "W"', meter.meterPowerUnit);
            
                i = i + 1;
                dPwr = meter.meterPowerReading - targetPwr;
                aoutValueOld = aoutValue;                
                if meter.meterPowerReading < p.readThreshold
                    thisStepSize = p.subthresholdStepSize;
                else
                    thisStepSize = - ceil(p.stepSizeMultiplier * abs(dPwr)) * sign(dPwr);
                end
                if abs(dPwr) > p.tolerancePercentage * targetPwr

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
                    result.targetReached(iPower, iMirrorPos, iLaser) = true;
                    break
                end
                hLaser.Arduino.SendMessage(sprintf('A %i %i', iLaser, aoutValue));
                fprintf('%gnm, i=%i, tgt=%.1fmW, df=%.3fmW, step=%i, AOUT(%i)=%i\n', p.wavelengths(iLaser), i, targetPwr*1e3, dPwr*1e3, thisStepSize, iLaser, aoutValue)
            
        %         fprintf('%.10f%c\r',test_meter.meterPowerReading,test_meter.meterPowerUnit);
            end
        
            meter.updateReading(p.stepDelays(iLaser));
            result.aoutValues(iPower, iMirrorPos, iLaser) = aoutValue;
            result.powers(iPower, iMirrorPos, iLaser) = meter.meterPowerReading;
        end
    end
end

% Turn lasers off
hLaser.Arduino.SendMessage(sprintf('A %i %i', 1, 0));
hLaser.Arduino.SendMessage(sprintf('A %i %i', 2, 0));

meter.disconnect;                                      % Disconnect and release

clearvars -except hLaser hMotor p result