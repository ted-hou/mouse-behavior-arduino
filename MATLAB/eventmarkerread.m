%% Draft for LF State Machine Interface Raster Plot

% a = ans.Arduino.EventMarkers;
a = b.Arduino.EventMarkers;
dimensions = size(a);

eventMarkers = a(1:dimensions(1), 1);
timeStamps = a(1:dimensions(1), 2);

resolution = 5000; % Number of ms per trial


nTrials = 1;

for n = 2:dimensions(1)
    if timeStamps(n) == 0 && timeStamps(n-1) ~= 0
        nTrials = nTrials + 1;
    end
end




timesByTrial = cell(nTrials,1);

currentTrialNumber = 0;

% Divide up the trials
for x = 1:length(eventMarkers)
    if x == 1 && eventMarkers(x) == 1
        currentTrialNumber = 1;
        currentTrialData = [];
        currentIndex = 1;
        
    elseif eventMarkers(x) == 1
        timesByTrial{currentTrialNumber} = currentTrialData;
        currentTrialNumber = currentTrialNumber + 1;
        currentTrialData = [];
        currentIndex = 1;    
    elseif eventMarkers(x) == 9
        currentTrialData(currentIndex) = timeStamps(x);
        currentIndex = currentIndex + 1;
    else
        disp('Error')
    end
    
end


%     
%     if eventMarkers(x) == 0
%         if currentTrialNumber > 0
%             timesByTrial{currentTrialNumber} = currentTrialData;
%         end
%         currentTrialNumber = currentTrialNumber + 1;
%         currentTrialData = [];
%         currentIndex = 1;
%     elseif eventData(x) == 254
%         % ignore
%     else
%         uncompressedData = (eventData(x)*resolution)/256;
%         currentTrialData(currentIndex) = uncompressedData;
%         currentIndex = currentIndex + 1;
%     end
% end
% 
logicalByTrial = zeros(nTrials, 7000);
% start time will always be at 2000, so you can get the random delay before
% start. so, add 2000 to all times. Then change axis after

for x = 1:nTrials % for each trial
    % extract the array from the cell array
    currentTrialTimes = timesByTrial{x};
    for y = 1:length(currentTrialTimes)
        logicalByTrial(x, currentTrialTimes(y)+2000) = 1;
    end
end

logicalByTrial = logical(logicalByTrial);

MarkerFormat = struct();
MarkerFormat.Color = [0 0 0];
MarkerFormat.MarkerSize = 10;
MarkerFormat.MarkerEdgeColor = [0 .5 .5];
MarkerFormat.MarkerFaceColor = [0 .7 .7];
MarkerFormat.LineWidth = 1.5;


figure
plotSpikeRaster(logicalByTrial,'PlotType','scatter', 'MarkerFormat', MarkerFormat);
xlabel('Time (ms)');
ylabel('Trial #');
ax = gca;
ax.XTick = 0:500:10000;
ax.XTickLabel = -2000:500:8000;
hold on
plot([3500, 3500], [0,nTrials], 'r-');
ylim([0, nTrials]);
plot([3250, 3250], [0,nTrials], 'k-');
plot([3750, 3750], [0,nTrials], 'k-');
plot([5000, 5000], [0,nTrials], 'k-');



disp('Number of Trials: ')
disp(nTrials);

% 
% 
% % possibleTimeSlots = zeros(1, 6000);
% % logicalByTrial = cell(nTrials, 1);
% % 
% % for x = 1:nTrials % for each trial
% %     extract the array from the cell array
% %     currentTrialTimes = timesByTrial{x};
% %     for y = 1:length(currentTrialTimes)
% %         possibleTimeSlots(round(currentTrialTimes(y))) = 1;
% %     end
% %     logicalByTrial{x} = possibleTimeSlots;
% %     possibleTimeSlots = zeros(1, 6000);
% % end
% % 
% % 
% % plotSpikeRaster(logicalByTrial,'PlotType','scatter');