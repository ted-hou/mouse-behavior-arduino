hLaser = MouseBehaviorInterface('COM5'); % This is the laser control arduino
hMotor = MouseBehaviorInterface('COM7'); % This is the stepping motor arduino (for moving mirror)

%%
clear p result
p.mirrorPositions = [-300, 0];
p.targetPowers = [0.1, 0.5] .* 1e-3;
p.wavelengths = [473, 593];
p.stepDelays = [0.5, 1];
p.aoutMin = 0;
p.aoutMax = 4095;
p.tolerancePercentage = 1e-2;
p.maxIters = 100;
p.stepSizeMultiplier = 200000; % Step size = -multiplier * (read wattage - target wattage)
p.readThreshold = 60e-6; % Watts, values below this are considered zero.
p.subthresholdStepSize = 500; % 

result.aoutValues = zeros(length(p.targetPowers), length(p.mirrorPositions), 2);
result.targetReached = false(length(p.targetPowers), length(p.mirrorPositions), 2);
result.powers = zeros(length(p.targetPowers), length(p.mirrorPositions), 2);

meter_list=ThorlabsPowerMeter;                              % Initiate the meter_list
DeviceDescription=meter_list.listdevices;               	% List available device(s)
test_meter=meter_list.connect(DeviceDescription);           % Connect single/the first devices


for iMirrorPos = 1:length(p.mirrorPositions)
    hMotor.Arduino.SetParam(find(strcmpi(hMotor.Arduino.ParamNames, 'TARGET_1')), p.mirrorPositions(iMirrorPos));
    while ~strcmpi('AT_TARGET', hMotor.Arduino.StateNames{hMotor.Arduino.State})
        pause(0.5);
    end
    for iLaser = 1:2
        for iPower = 1:length(p.targetPowers)
            test_meter.setWaveLength(p.wavelengths(iLaser));            % Set sensor wavelength
            test_meter.setDispBrightness(0.3);                          % Set display brightness
            test_meter.setAttenuation(0);                               % Set Attenuation
            test_meter.sensorInfo;                                      % Retrive the sensor info
            test_meter.setPowerAutoRange(1);                            % Set Autorange
            pause(5)                                                    % Pause the program a bit to allow the power meter to autoadjust
            test_meter.setAverageTime(0.01);                            % Set average time for the measurement
            test_meter.setTimeout(1000);                                % Set timeout value 
            
            hLaser.Arduino.SendMessage(sprintf('A %i %i', 1, 0));
            hLaser.Arduino.SendMessage(sprintf('A %i %i', 2, 0));
            
            aoutValue = 0;
            targetPwr = p.targetPowers(iPower);
            i = 0;
            
            while true
                if i > p.maxIters
                    warning('Failed to reach target after %i iterations. Target = %g, Value = %g', i, targetPwr, targetPwr + df)
                    break
                end
            
                test_meter.updateReading(p.stepDelays(iLaser));                          % Update the power reading(with interal period of 0.5s)
                assert(test_meter.meterPowerUnit == 'W', 'Power meter unit is "%s" instead of "W"', test_meter.meterPowerUnit);
            
                i = i + 1;
                df = test_meter.meterPowerReading - targetPwr;
                if test_meter.meterPowerReading < p.readThreshold
                    this_step_size = p.subthresholdStepSize;
                else
                    this_step_size = - ceil(p.stepSizeMultiplier * abs(df)) * sign(df);
                end
                if abs(df) > p.tolerancePercentage * targetPwr
                    aoutValue = aoutValue + this_step_size;
                    aoutValue = min(aoutValue, p.aoutMax);
                    aoutValue = max(aoutValue, p.aoutMin);
                else
                    fprintf('Target reached in %i iterations.\n', i)
                    result.targetReached(iLaser, iPower, iMirrorPos) = true;
                    break
                end
                hLaser.Arduino.SendMessage(sprintf('A %i %i', iLaser, aoutValue));
                fprintf('df = %.3fmW, Setting AOUT %i to %i\n', df*1e3, iLaser, aoutValue)
            
        %         fprintf('%.10f%c\r',test_meter.meterPowerReading,test_meter.meterPowerUnit);
            end
        
            test_meter.updateReading(p.stepDelays(iLaser));
            result.aoutValues(iPower, iMirrorPos, iLaser) = aoutValue;
            result.powers(iPower, iMirrorPos, iLaser) = test_meter.meterPowerReading;
        end
    end
end

% Turn lasers off
hLaser.Arduino.SendMessage(sprintf('A %i %i', 1, 0));
hLaser.Arduino.SendMessage(sprintf('A %i %i', 2, 0));

test_meter.disconnect;                                      % Disconnect and release

clearvars -except hLaser hMotor p result