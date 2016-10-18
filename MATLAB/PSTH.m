%% Peristimulus Time Histogram Plot

% takes obj.EventMarkers, parces it to set all the time stamps, then plots
% PSTH

%% Parcing:

% Fetch data from experiment obj
events = obj.EventMarkers;
numtrials = length(obj.Trials);
parced = cell(numtrials,1);
trial_data = obj.Trials;


% initialize variables for all trials
licks_by_trial = [];        % each row is a different trial
cue_on_time_by_trial = NaN(numtrials, 1);  % each row is a different trial
pav_or_op_by_trial = NaN(numtrials, 1);    % 0 for pavlovian, 1 for operant



% Decide which trials pav or operant:
for itrial=1:numtrials
    pav_or_op_by_trial(itrial) = trial_data(itrial).Parameters(3);
end


% define indices
event_index = 1;
trial_index = 0;
pav_index = 0;
op_index = 0;

% this loop separates out the event markers. Counts number of trials in exp
% and number of licks in each trial
for ievent = 1:length(events)
    if events(event_index, 1) == 1                                                      % if start new trial
%         disp('New trial at');
%         disp(num2str(event_index));
        trial_index = trial_index + 1;
        start_time = events(event_index, 2); % reference time to trial start
        num_licks = 0;
    end
    if events(event_index, 1) == 3                                                      % if cue on
        cue_on_time_by_trial(trial_index) = events(event_index, 2) - start_time;
        if pav_or_op_by_trial(trial_index) == 0                                             % pavlovian
            pav_index = pav_index + 1;
            pav_cue_on_time_by_trial(pav_index, 1) = events(event_index, 2) - start_time;
        end
        if pav_or_op_by_trial(trial_index) == 1                                             % operant
            op_index = op_index + 1;
            op_cue_on_time_by_trial(op_index, 1) = events(event_index, 2) - start_time;
        end
    end
    if events(event_index, 1) == 9                                                      % if lick detected
        num_licks = num_licks + 1;
        licks_by_trial(trial_index, num_licks) = events(event_index, 2) - start_time;
    end
    
    event_index = event_index + 1; % go to next event marker
end



%% Get lick times wrt cue on: (for whole experiment, not parced by pav/op

licks_by_trial_relative_to_cue = [];
start_trial_relative_to_cue = NaN(numtrials,1);

for itrial=1:numtrials
    for jlick = 1:size(licks_by_trial,2)
        if licks_by_trial(itrial, jlick) ~= 0
            licks_by_trial_relative_to_cue(itrial, jlick) = licks_by_trial(itrial, jlick) - cue_on_time_by_trial(itrial);
        else
            licks_by_trial_relative_to_cue(itrial, jlick) = NaN;
        end
    end
%     pav_or_op_by_trial(itrial) = trial_data(itrial).Parameters(3);   %
%     delete - already have above^^^
end

for i=1:numtrials
    start_trial_relative_to_cue(i) = - cue_on_time_by_trial(i);
end

%% Put all the licks in one array (not parced for pav/op)

licks_hist = reshape(licks_by_trial_relative_to_cue,[1,numel(licks_by_trial_relative_to_cue)]);

%% Separate trials by pavlovian or operant



licks_by_pavlovian = [];  % each row diff trial - no longer numbered corresponding to absolute trial #
licks_by_operant = [];

pavlovian_index = 0;
operant_index = 0;

for itrials = 1:numtrials
    if pav_or_op_by_trial(itrials) == 0 % pavlovian
        pavlovian_index = pavlovian_index + 1;
        licks_by_pavlovian(pavlovian_index, :) = licks_by_trial(itrials, :);
    end
    if pav_or_op_by_trial(itrials) == 1 % operant
        operant_index = operant_index + 1;
        licks_by_operant(operant_index, :) = licks_by_trial(itrials, :);
    end
end

%% Get lick times wrt cue on for pav/op parced data:

% number of trials in each:
pav_numtrials = size(licks_by_pavlovian, 1);
op_numtrials  = size(licks_by_operant, 1);

pav_licks_by_trial_relative_to_cue = [];
pav_start_trial_relative_to_cue    = NaN(pav_numtrials,1);

op_licks_by_trial_relative_to_cue = [];
op_start_trial_relative_to_cue = NaN(op_numtrials,1);

pav_index = 0;
op_index = 0;


% pavlovian loop
for itrial=1:pav_numtrials
    for jlick = 1:size(licks_by_pavlovian,2)
        if licks_by_pavlovian(itrial, jlick) ~= 0
            pav_licks_by_trial_relative_to_cue(itrial, jlick) = licks_by_pavlovian(itrial, jlick) - pav_cue_on_time_by_trial(itrial);
        else
            pav_licks_by_trial_relative_to_cue(itrial, jlick) = NaN;
        end
    end
%     pav_or_op_by_trial(itrial) = trial_data(itrial).Parameters(3);
end

for i=1:pav_numtrials
    pav_start_trial_relative_to_cue(i) = - pav_cue_on_time_by_trial(i);
end

% operant loop
for itrial=1:op_numtrials
    for jlick = 1:size(licks_by_operant,2)
        if licks_by_operant(itrial, jlick) ~= 0
            op_licks_by_trial_relative_to_cue(itrial, jlick) = licks_by_operant(itrial, jlick) - op_cue_on_time_by_trial(itrial);
        else
            op_licks_by_trial_relative_to_cue(itrial, jlick) = NaN;
        end
    end
%     pav_or_op_by_trial(itrial) = trial_data(itrial).Parameters(3);
end

for i=1:op_numtrials
    op_start_trial_relative_to_cue(i) = - op_cue_on_time_by_trial(i);
end

%% Put all the licks in one array (IS parced for pav/op)

% pavlovian
pav_licks_hist = reshape(pav_licks_by_trial_relative_to_cue,[1,numel(pav_licks_by_trial_relative_to_cue)]);

% operant
op_licks_hist = reshape(op_licks_by_trial_relative_to_cue,[1,numel(op_licks_by_trial_relative_to_cue)]);


%% Plot PSTH:

figure
histogram(licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,30]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');


%% Plot PSTH:

figure
histogram(pav_licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,10]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('Pavlovian Trials');

%% Plot PSTH:

figure
histogram(op_licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,30]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('Operant Trials');