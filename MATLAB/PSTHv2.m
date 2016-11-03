%% Peristimulus Time Histogram Plot

% takes obj.EventMarkers, parces it to set all the time stamps, then plots
% PSTH

% Note: in current version, pavlovian vs operant is not decided till
% response window. Thus, trials that are lost to early licks are not
% tallied in the divided up data...

%% Fetch Relevant Data From Exp Object:

% Fetch data from experiment obj
events = obj.EventMarkers;
numtrials = length(obj.Trials);
trial_data = obj.Trials;
result_codes = [obj.Trials.Code];

%% Find all Correct Trials (and other result codes):

correct_trial_numbers = find(result_codes == 1);
early_trial_numbers = find(result_codes == 2);
late_trial_numbers = find(result_codes == 3);
no_lick_trial_numbers = find(result_codes == 4);

%% Extract Event Markers With Timestamps:

% initialize variables for all trials
licks_by_trial = [];                       % each row is a different trial
cue_on_time_by_trial = NaN(numtrials, 1);  % each row is a different trial
pav_or_op_by_trial = NaN(numtrials, 1);    % each row is a trial, 0 for pavlovian, 1 for operant




% Decide which trials pav or operant based on new event markers (14 = pavlovian, 15 = operant)

% define indices
event_index = 1;
trial_index = 0;
pav_index = 0;
op_index = 0;

for ievent = 1:length(events)
    if events(ievent, 1) == 1              % If start new trial
        trial_index = trial_index + 1;
    end
    if events(ievent, 1) == 14             % 0 for pavlovian
%         disp('Pavlovian Trial Detected');
        pav_or_op_by_trial(trial_index) = 0;
    end
    if events(ievent, 1) == 15             % 1 for operant
%         disp('Operant Trial Detected');
        pav_or_op_by_trial(trial_index) = 1;
    end 
end



% Count # of Licks in each trial. Find the Cue-On time for each trial as
% well

% reinitialize indices
event_index = 1;
trial_index = 0;
pav_index = 0;
op_index = 0;

for ievent = 1:length(events)
    if events(ievent, 1) == 1             % if start new trial
        trial_index = trial_index + 1;
        start_time = events(ievent, 2); % reference time to trial start
        num_licks = 0;
    end
    if events(ievent, 1) == 3             % if cue on marker
        cue_on_time_by_trial(trial_index) = events(ievent, 2) - start_time; % defines cue on time relative to start time
        if pav_or_op_by_trial(trial_index) == 0   % for a pavlovian trial...
            pav_index = pav_index + 1;
            pav_cue_on_time_by_trial(pav_index, 1) = cue_on_time_by_trial(trial_index);
        end
        if pav_or_op_by_trial(trial_index) == 1   % for an operant trial...                                          % operant
            op_index = op_index + 1;
            op_cue_on_time_by_trial(op_index, 1) = cue_on_time_by_trial(trial_index);
        end
    end
    if events(ievent, 1) == 9             % if lick detected
        num_licks = num_licks + 1;
        licks_by_trial(trial_index, num_licks) = events(ievent, 2) - start_time; % add the lick time to the list of all trials
    end
    
end

% There may be zero licks in last trial. Thus, to make sure dimensions
% correct, add another row to licks_by_trial if size(licks_by_trial,
% 1)<numtrials:

if size(licks_by_trial,1) < numtrials
    licks_by_trial(numtrials, 1) = 0;
end



%% Get lick times wrt cue on: (for whole experiment, not parced by pav/op)

licks_by_trial_relative_to_cue = [];             % get lick time relative to cue on
start_trial_relative_to_cue = NaN(numtrials,1);  % get start trial time relative to cue

for itrial=1:numtrials
    for jlick = 1:size(licks_by_trial,2)
        if licks_by_trial(itrial, jlick) ~= 0
            licks_by_trial_relative_to_cue(itrial, jlick) = licks_by_trial(itrial, jlick) - cue_on_time_by_trial(itrial);
        else
            licks_by_trial_relative_to_cue(itrial, jlick) = NaN;
        end
    end
end

for i=1:numtrials
    start_trial_relative_to_cue(i) = - cue_on_time_by_trial(i);
end

%% Find licks by trial subdivided into Correct and other result code trials
% use licks_by_trial_relative_to_cue and pull out the relevant trials:

correct_trial_licks = NaN(length(correct_trial_numbers), size(licks_by_trial_relative_to_cue, 2));
early_trial_licks = NaN(length(early_trial_numbers), size(licks_by_trial_relative_to_cue, 2));
late_trial_licks = NaN(length(late_trial_numbers), size(licks_by_trial_relative_to_cue, 2));
no_lick_trial_licks = NaN(length(no_lick_trial_numbers), size(licks_by_trial_relative_to_cue, 2));


% Correct trials only:
correct_index = 1;
for icorrect = correct_trial_numbers
    correct_trial_licks(correct_index, :) = licks_by_trial_relative_to_cue(icorrect, :);
    correct_index = correct_index + 1;
end


% Early trials only:
early_index = 1;
for iearly = early_trial_numbers
    early_trial_licks(early_index, :) = licks_by_trial_relative_to_cue(iearly, :);
    early_index = early_index + 1;
end

% Late trials only:
late_index = 1;
for ilate = late_trial_numbers
    late_trial_licks(late_index, :) = licks_by_trial_relative_to_cue(ilate, :);
    late_index = late_index + 1;
end

% No lick trials only:
no_lick_index = 1;
for ino = no_lick_trial_numbers
    no_lick_trial_licks(no_lick_index, :) = licks_by_trial_relative_to_cue(ino, :);
    no_lick_index = no_lick_index + 1;
end



%% Put all the licks in one array (not parced for pav/op)

licks_hist = reshape(licks_by_trial_relative_to_cue,[1,numel(licks_by_trial_relative_to_cue)]);
correct_licks_hist = reshape(correct_trial_licks,[1,numel(correct_trial_licks)]);
early_licks_hist = reshape(early_trial_licks,[1,numel(early_trial_licks)]);
late_licks_hist = reshape(late_trial_licks,[1,numel(late_trial_licks)]);
no_licks_hist = reshape(no_lick_trial_licks,[1,numel(no_lick_trial_licks)]);

%% Separate trials by pavlovian or operant
%*********************NOTE! still need to separate out correct or incorrect
%here

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
end

for i=1:op_numtrials
    op_start_trial_relative_to_cue(i) = - op_cue_on_time_by_trial(i);
end

%% Put all the licks in one array (IS parced for pav/op)

% pavlovian
pav_licks_hist = reshape(pav_licks_by_trial_relative_to_cue,[1,numel(pav_licks_by_trial_relative_to_cue)]);

% operant
op_licks_hist = reshape(op_licks_by_trial_relative_to_cue,[1,numel(op_licks_by_trial_relative_to_cue)]);


%% Plot PSTH: All Trials

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


%% Plot PSTH: Pavlovian Trials Only

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

%% Plot PSTH: Operant Trials Only

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

%% Plot PSTH: Correct Trials Only

figure
histogram(correct_licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,30]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('Correct Trials');

%% Plot PSTH: Early Trials Only

figure
histogram(early_licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,30]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('Early Abort Trials');

%% Plot PSTH: Early Trials Only

figure
histogram(late_licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,30]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('Late Abort Trials');

%% Plot PSTH: No Lick Trials Only

figure
histogram(no_licks_hist, 1000);
hold on
plot([0,0], [0, 100], 'g-');

plot([1500,1500], [0, 100], 'r-');
plot([1250,1250], [0, 100], 'k--');
plot([2000,2000], [0, 100], 'k--');
ylim([0,30]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('No Licks Trials');