%% Peristimulus Time Histogram Plot



% editable plot params:
all_trials_max = 45;
pav_max = 45;
op_max = 30;

% takes obj.EventMarkers, parces it to set all the time stamps, then plots
% PSTH

% Note: This version compatible with hybrid and mixed pav-op
% Note: Now ignores first licks in abort window within first 200 ms that were preceeded by a lick in the post-cue allowed window
%   In test file, found 0 instances of first 200 ms licks not being preceeded by a lick train in the pre-abort window

%% Fetch Relevant Data From Exp Object:

% Fetch data from experiment obj
events = obj.EventMarkers;
numtrials = length(obj.Trials);
trial_data = obj.Trials;
result_codes = [obj.Trials.Code];


% Find majority of times for salient events in trial (ie mode)
num_parameters = length(obj.Trials(1).Parameters); % 25 for this file
all_trials_parameters = [obj.Trials.Parameters]; % 1xn vector with all the parameters
all_trials_parameters = reshape(all_trials_parameters, num_parameters, numtrials)'; % rows = trials, cols = params

    % find target time:
    time_target = mode(all_trials_parameters(:,8));
    % find min interval:
    time_min_interval = mode(all_trials_parameters(:,6));
    % find max interval:
    time_max_interval = mode(all_trials_parameters(:,7));
    % find trial duration:
    time_trial_duration = mode(all_trials_parameters(:,9));
    % find abort min:
    time_abort_min = mode(all_trials_parameters(:,23));
    % find abort max:
    time_abort_max = mode(all_trials_parameters(:,24));

    % We also want to keep track of first licks in each interval:
        % First lick after the cue:
        times_1st_post_cue_lick = [];
        pav_times_1st_post_cue_lick = [];
        op_times_1st_post_cue_lick = [];
        hybrid_times_1st_post_cue_lick = [];
        % First lick in the no lick period:
        times_1st_lick_no_lick_period = [];
        pav_times_1st_lick_no_lick_period = [];
        op_times_1st_lick_no_lick_period = [];
        hybrid_times_1st_lick_no_lick_period = [];
        % First lick in the pre-reward interval (if reached it):
        pre_times_1st_lick_reward = [];
        pre_pav_times_1st_lick_reward = [];
        pre_op_times_1st_lick_reward = [];
        pre_hybrid_times_1st_lick_reward = [];
        % First lick in the reward interval (if reached it):
        times_1st_lick_reward = [];
        pav_times_1st_lick_reward = [];
        op_times_1st_lick_reward = [];
        hybrid_times_1st_lick_reward = [];
        % First lick in post-window (if reached it):
        times_1st_late_lick = [];
        pav_times_1st_late_lick = [];
        op_times_1st_late_lick = [];
        hybrid_times_1st_late_lick = [];

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
hybrid_by_trial = NaN(numtrials, 1);       % 1 for hybrid, 0 for non-hybrid



% Decide which trials pav or operant based on new event markers (14 = pavlovian, 15 = operant)

% define indices
event_index = 1;
trial_index = 1;
pav_index = 0;
op_index = 0;
hybrid = 0;

for ievent = 1:length(events)
    if events(ievent, 1) == 1              % If start new trial
    end
    if events(ievent, 1) == 14             % 0 for pavlovian
        pav_or_op_by_trial(trial_index) = 0;
        trial_index = trial_index + 1;
    end
    if events(ievent, 1) == 15             % 1 for operant
        pav_or_op_by_trial(trial_index) = 1;
        trial_index = trial_index + 1;
    end
    if events(ievent, 1) == 16             % 1 for hybrid
        hybrid_by_trial(trial_index) = 1;
        trial_index = trial_index + 1;
    end 
end



% Count # of Licks in each trial. Find the Cue-On time for each trial as
% well

% reinitialize indices
event_index = 1;
trial_index = 0;
pav_index = 0;
op_index = 0;
hybrid_index = 0;

allfirstlicks = []; % tracks all aborted and rewarded first licks discounting pavlovian and early train first licks
rewarded_no_pav_firstlicks = []; % tracks all rewarded first licks discounting pavlovian trials
abortedfirstlicks = []; % tracks aborted first licks, discounting early train first licks

for ievent = 1:length(events)
    if events(ievent, 1) == 1             % if start new trial
        trial_index = trial_index + 1;
        start_time = events(ievent, 2); % reference time to trial start
        num_licks = 0;
        first_post_cue_lick = false;
        first_abort_window_lick = false;
        first_reward_lick = false;
        first_post_window_lick = false;
        pre_first_reward_lick = false;

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
        if hybrid_by_trial(trial_index) == 1      % for an operant trial...                                          % operant
            hybrid_index = hybrid_index + 1;
            hybrid_cue_on_time_by_trial(hybrid_index, 1) = cue_on_time_by_trial(trial_index);
        end
    end
    if events(ievent, 1) == 9             % if lick detected
        num_licks = num_licks + 1;
        licks_by_trial(trial_index, num_licks) = events(ievent, 2) - start_time; % add the lick time to the list of all trials
        % check for first post-cue lick:
        if first_post_cue_lick == false && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time > 0 && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time < time_abort_min
            times_1st_post_cue_lick(length(times_1st_post_cue_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            first_post_cue_lick = true;
            if pav_or_op_by_trial(trial_index) == 0   % for a pavlovian trial...
                pav_times_1st_post_cue_lick(length(pav_times_1st_post_cue_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if pav_or_op_by_trial(trial_index) == 1   % for an operant trial...
                op_times_1st_post_cue_lick(length(op_times_1st_post_cue_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if hybrid_by_trial(trial_index) == 1   % for hybrid trial...
                hybrid_times_1st_post_cue_lick(length(hybrid_times_1st_post_cue_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
        end
        % check for first abort window lick:
        if first_abort_window_lick == false && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time > time_abort_min && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time < time_abort_max
            if events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time < time_abort_min + 200 && first_post_cue_lick == true, % If the lick occurred within the first 200 ms of the abort window AND a post-cue lick was detected...
                disp(['train of licks to abort window @ trial ', num2str(trial_index), '. Not including in first licks!']);
            else
                times_1st_lick_no_lick_period(length(times_1st_lick_no_lick_period)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                first_abort_window_lick = true;
                if events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time - time_abort_min > 200
                    allfirstlicks(length(allfirstlicks)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                    abortedfirstlicks(length(abortedfirstlicks)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                end
                if pav_or_op_by_trial(trial_index) == 0   % for a pavlovian trial...
                    pav_times_1st_lick_no_lick_period(length(times_1st_lick_no_lick_period)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                end
                if pav_or_op_by_trial(trial_index) == 1   % for an operant trial...
                    op_times_1st_lick_no_lick_period(length(op_times_1st_lick_no_lick_period)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                end
                if hybrid_by_trial(trial_index) == 1      % for hybrid trial...
                    hybrid_times_1st_lick_no_lick_period(length(hybrid_times_1st_lick_no_lick_period)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                end
            end
        end
        % check for pre-reward window lick if trial not aborted:
        if pre_first_reward_lick == false && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time > time_abort_max && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time < time_min_interval && first_abort_window_lick == false;
            pre_times_1st_lick_reward(length(pre_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            pre_first_reward_lick = true;
            allfirstlicks(length(allfirstlicks)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            if pav_or_op_by_trial(trial_index) == 0   % for a pavlovian trial...
                pre_pav_times_1st_lick_reward(length(pre_pav_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if pav_or_op_by_trial(trial_index) == 1   % for an operant trial...
                pre_op_times_1st_lick_reward(length(pre_op_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if hybrid_by_trial(trial_index) == 1      % for hybrid trial...
                pre_hyrbid_times_1st_lick_reward(length(pre_hybrid_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
        end
        % check for first reward window lick if trial not aborted:
        if first_reward_lick == false && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time > time_min_interval && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time < time_max_interval && first_abort_window_lick == false;
            times_1st_lick_reward(length(times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            first_reward_lick = true;
            if events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time - time_target < 100 || events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time - time_target < 600, 
                allfirstlicks(length(allfirstlicks)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
                rewarded_no_pav_firstlicks(length(rewarded_no_pav_firstlicks)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if pav_or_op_by_trial(trial_index) == 0   % for a pavlovian trial...
                pav_times_1st_lick_reward(length(pav_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if pav_or_op_by_trial(trial_index) == 1   % for an operant trial...
                op_times_1st_lick_reward(length(op_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if hybrid_by_trial(trial_index) == 1      % for hybrid trial...
                hybrid_times_1st_lick_reward(length(hybrid_times_1st_lick_reward)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
        end
        % check for first post window lick if trial not aborted or rewarded:
        if first_post_cue_lick == false && events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time > time_max_interval && first_abort_window_lick == false && first_reward_lick == false;
            times_1st_late_lick(length(times_1st_late_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            first_post_window_lickrs = true;
            allfirstlicks(length(allfirstlicks)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            if pav_or_op_by_trial(trial_index) == 0   % for a pavlovian trial...
                pav_times_1st_late_lick(length(pav_times_1st_late_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if pav_or_op_by_trial(trial_index) == 1   % for an operant trial...
                op_times_1st_late_lick(length(op_times_1st_late_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
            if hybrid_by_trial(trial_index) == 1      % for hybrid trial...
                hybrid_times_1st_late_lick(length(hybrid_times_1st_late_lick)+1) = events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time;
            end
        end
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

%% Separate trials by pavlovian or operant or hybrid

licks_by_pavlovian = [];  % each row diff trial - no longer numbered corresponding to absolute trial #
licks_by_operant = [];
licks_by_hybrid = [];
pav_correct_trial_licks = [];
pav_early_trial_licks = [];
pav_late_trial_licks = [];
pav_no_lick_trial_licks = [];
op_correct_trial_licks = [];
op_early_trial_licks = [];
op_late_trial_licks = [];
op_no_lick_trial_licks = [];
hybrid_correct_trial_licks = [];
hybrid_early_trial_licks = [];
hybrid_late_trial_licks = [];
hybrid_no_lick_trial_licks = [];

pavlovian_index = 0;
operant_index = 0;
hybrid_index = 0;

pav_correct_index = 1;
pav_early_index = 1;
pav_late_index = 1;
pav_no_lick_index = 1;

op_correct_index = 1;
op_early_index = 1;
op_late_index = 1;
op_no_lick_index = 1;

hybrid_correct_index = 1;
hybrid_early_index = 1;
hybrid_late_index = 1;
hybrid_no_lick_index = 1;

for itrials = 1:numtrials
    if pav_or_op_by_trial(itrials) == 0 % pavlovian
        pavlovian_index = pavlovian_index + 1;
        licks_by_pavlovian(pavlovian_index, :) = licks_by_trial_relative_to_cue(itrials, :);

        % Pavlovian Correct trials only:
        if ~isempty(find(correct_trial_numbers == itrials))
            pav_correct_trial_licks(pav_correct_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            pav_correct_index = pav_correct_index + 1;
        end

        % Pavlovian Early trials only:
        if ~isempty(find(early_trial_numbers == itrials))
            pav_early_trial_licks(pav_early_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            pav_early_index = pav_early_index + 1;
        end

        % Pavlovian Late trials only:
        if ~isempty(find(late_trial_numbers == itrials))
            pav_late_trial_licks(pav_late_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            pav_late_index = pav_late_index + 1;
        end

        % Pavlovian No lick trials only:
        if ~isempty(find(no_lick_trial_numbers == itrials))
            pav_no_lick_trial_licks(pav_no_lick_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            pav_no_lick_index = pav_no_lick_index + 1;
        end
    end
    if pav_or_op_by_trial(itrials) == 1 % operant
        operant_index = operant_index + 1;
        licks_by_operant(operant_index, :) = licks_by_trial_relative_to_cue(itrials, :);

        % Operant Correct trials only:
        if ~isempty(find(correct_trial_numbers == itrials))
            op_correct_trial_licks(op_correct_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            op_correct_index = op_correct_index + 1;
        end

        % Operant Early trials only:
        if ~isempty(find(early_trial_numbers == itrials))
            op_early_trial_licks(op_early_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            op_early_index = op_early_index + 1;
        end

        % Operant Late trials only:
        if ~isempty(find(late_trial_numbers == itrials))
            op_late_trial_licks(op_late_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            op_late_index = op_late_index + 1;
        end

        % Operant No lick trials only:
        if ~isempty(find(no_lick_trial_numbers == itrials))
            op_no_lick_trial_licks(op_no_lick_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            op_no_lick_index = op_no_lick_index + 1;
        end
    end
    if hybrid_by_trial(itrials) == 1     % hyrbid
        hybrid_index = hybrid_index + 1;
        licks_by_hybrid(hybrid_index, :) = licks_by_trial_relative_to_cue(itrials, :);

        % Hybrid Correct trials only:
        if ~isempty(find(correct_trial_numbers == itrials))
            hybrid_correct_trial_licks(hybrid_correct_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            hybrid_correct_index = hybrid_correct_index + 1;
        end

        % Hybrid Early trials only:
        if ~isempty(find(early_trial_numbers == itrials))
            hybrid_early_trial_licks(hybrid_early_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            hybrid_early_index = hybrid_early_index + 1;
        end

        % Hybrid Late trials only:
        if ~isempty(find(late_trial_numbers == itrials))
            hybrid_late_trial_licks(hybrid_late_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            hybrid_late_index = hybrid_late_index + 1;
        end

        % Hybrid No lick trials only:
        if ~isempty(find(no_lick_trial_numbers == itrials))
            hybrid_no_lick_trial_licks(hybrid_no_lick_index, :) = licks_by_trial_relative_to_cue(itrials, :);
            hybrid_no_lick_index = hybrid_no_lick_index + 1;
        end
    end
end

%% Get lick times wrt cue on for pav/op parced data: (redundant, may remove next version!)

% number of trials in each:
pav_numtrials = size(licks_by_pavlovian, 1);
op_numtrials  = size(licks_by_operant, 1);
hybrid_numtrials  = size(licks_by_hybrid, 1);

pav_licks_by_trial_relative_to_cue = [];
pav_start_trial_relative_to_cue    = NaN(pav_numtrials,1);

op_licks_by_trial_relative_to_cue = [];
op_start_trial_relative_to_cue = NaN(op_numtrials,1);

hybrid_licks_by_trial_relative_to_cue = [];
hybrid_start_trial_relative_to_cue = NaN(hybrid_numtrials,1);

pav_index = 0;
op_index = 0;
hybrid_index = 0;




for i=1:pav_numtrials
    pav_start_trial_relative_to_cue(i) = - pav_cue_on_time_by_trial(i);
end



for i=1:op_numtrials
    op_start_trial_relative_to_cue(i) = - op_cue_on_time_by_trial(i);
end

for i=1:hybrid_numtrials
    hybrid_start_trial_relative_to_cue(i) = - hybrid_cue_on_time_by_trial(i);
end

%% Put all the licks in one array (IS parced for pav/op)

% pavlovian
pav_licks_hist = reshape(licks_by_pavlovian,[1,numel(licks_by_pavlovian)]);
pav_correct_licks_hist = reshape(pav_correct_trial_licks,[1,numel(pav_correct_trial_licks)]);
pav_early_licks_hist = reshape(pav_early_trial_licks,[1,numel(pav_early_trial_licks)]);
pav_late_licks_hist = reshape(pav_late_trial_licks,[1,numel(pav_late_trial_licks)]);
pav_no_licks_hist = reshape(pav_no_lick_trial_licks,[1,numel(pav_no_lick_trial_licks)]);

% operant
op_licks_hist = reshape(licks_by_operant,[1,numel(licks_by_operant)]);
op_correct_licks_hist = reshape(op_correct_trial_licks,[1,numel(op_correct_trial_licks)]);
op_early_licks_hist = reshape(op_early_trial_licks,[1,numel(op_early_trial_licks)]);
op_late_licks_hist = reshape(op_late_trial_licks,[1,numel(op_late_trial_licks)]);
op_no_licks_hist = reshape(op_no_lick_trial_licks,[1,numel(op_no_lick_trial_licks)]);

% hybrid
hybrid_licks_hist = reshape(licks_by_hybrid,[1,numel(licks_by_hybrid)]);
hybrid_correct_licks_hist = reshape(hybrid_correct_trial_licks,[1,numel(hybrid_correct_trial_licks)]);
hybrid_early_licks_hist = reshape(hybrid_early_trial_licks,[1,numel(hybrid_early_trial_licks)]);
hybrid_late_licks_hist = reshape(hybrid_late_trial_licks,[1,numel(hybrid_late_trial_licks)]);
hybrid_no_licks_hist = reshape(hybrid_no_lick_trial_licks,[1,numel(hybrid_no_lick_trial_licks)]);


% %% Plot PSTH: All Trials
% 
% figure
% subplot(4,1,1);
% histogram(licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,all_trials_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('All Trials');
% 
% 
% %% Plot PSTH: Pavlovian Trials Only
% 
% % figure
% subplot(4,1,2);
% histogram(pav_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,pav_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Pavlovian Trials');
% 
% %% Plot PSTH: Operant Trials Only
% 
% % figure
% subplot(4,1,3);
% histogram(op_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,op_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Operant Trials');
% 
% %% Plot PSTH: Hybrid Trials Only
% 
% % figure
% subplot(4,1,4);
% histogram(hybrid_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,op_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hyrbid Trials');
% 
% %% Plot PSTH: Correct Trials Only
% 
% figure
% subplot(4,1,1);
% histogram(correct_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,all_trials_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Correct Trials');
% 
% %% Plot PSTH: Early Trials Only
% 
% % figure
% subplot(4,1,2);
% histogram(early_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,all_trials_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Early Abort Trials');
% 
% %% Plot PSTH: Late Trials Only
% 
% % figure
% subplot(4,1,3);
% histogram(late_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,all_trials_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Late Abort Trials');
% 
% %% Plot PSTH: No Lick Trials Only
% 
% % figure
% subplot(4,1,4);
% histogram(no_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('No Licks Trials');
% 
% 
% 
% 
% % %% Pavlovian only plots:
% % figure
% % subplot(4,1,1);
% % histogram(pav_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,pav_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Pavlovian Trials');
% % 
% % %% Plot PSTH: Pav Correct Trials Only
% % % figure
% % subplot(4,1,2);
% % histogram(pav_correct_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,pav_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Pavlovian Correct Trials');
% % 
% % %% Plot PSTH: Pav Early Trials Only
% % % figure
% % subplot(4,1,3);
% % histogram(pav_early_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,pav_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Pavlovian Early Abort Trials');
% % 
% % %% Plot PSTH: Pav No Lick Trials Only
% % 
% % % figure
% % subplot(4,1,4);
% % histogram(pav_no_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,10]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Pavlovian No Licks Trials');
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % 
% % %% Operant only plots:
% % figure
% % subplot(5,1,1);
% % histogram(op_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,op_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Operant Trials');
% % 
% % %% Plot PSTH: Op Correct Trials Only
% % % figure
% % subplot(5,1,2);
% % histogram(op_correct_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,op_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Operant Correct Trials');
% % 
% % %% Plot PSTH: Op Early Trials Only
% % % figure
% % subplot(5,1,3);
% % histogram(op_early_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,op_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Operant Early Abort Trials');
% % 
% % %% Plot PSTH: Op Late Trials Only
% % % figure
% % subplot(5,1,4);
% % histogram(op_late_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,op_max]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Operant Late Abort Trials');
% % 
% % %% Plot PSTH: Op No Lick Trials Only
% % % figure
% % subplot(5,1,5);
% % histogram(op_no_licks_hist, 1000);
% % hold on
% % plot([0,0], [0, 100], 'g-');
% % 
% % plot([time_target,time_target], [0, 100], 'r-');
% % plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% % plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% % plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% % plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% % plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% % ylim([0,10]);
% % xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% % ylabel('number of licks');
% % xlabel('time relative to cue on (ms)');
% % title('Operant No Licks Trials');
% 
% 
% 
% 
% 
% 
% 
% %% Hybrid only plots
% figure
% subplot(3,1,1);
% histogram(hybrid_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,op_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hyrbid Trials');
% 
% %% Plot PSTH: Hyrbid Correct Trials Only
% % figure
% subplot(3,1,2);
% histogram(hybrid_correct_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,op_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hyrbid Correct Trials');
% 
% %% Plot PSTH: Hybrid Early Trials Only
% % figure
% subplot(3,1,3);
% histogram(hybrid_early_licks_hist, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,op_max]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hybrid Early Abort Trials');








%% Summary Stats:

disp(['~~~~~~~~~~~~~~~Summary Statistics~~~~~~~~~~~~~~~~~'])
disp([' '])
disp(['Trials Total: ', num2str(numtrials)])
disp(['# Correct: ', num2str(correct_index - 1), ' | ', num2str(round(100*(correct_index - 1)/numtrials)), '%'])
disp(['# Early: ', num2str(early_index - 1), ' | ', num2str(round(100*(early_index - 1)/numtrials)), '%'])
disp(['# Late: ', num2str(late_index - 1), ' | ', num2str(round(100*(late_index - 1)/numtrials)), '%'])
disp(['# No Lick: ', num2str(no_lick_index - 1), ' | ', num2str(round(100*(no_lick_index - 1)/numtrials)), '%'])
disp([' '])
disp(['# Pavlovian Total: ', num2str(pavlovian_index - 1)])
disp(['# Pavlovian Correct: ', num2str(pav_correct_index - 1), ' | ', num2str(round(100*(pav_correct_index - 1)/pavlovian_index)), '%'])
disp(['# Pavlovian Early: ', num2str(pav_early_index - 1), ' | ', num2str(round(100*(pav_early_index - 1)/pavlovian_index)), '%'])
disp(['# Pavlovian Late: ', num2str(pav_late_index - 1), ' | ', num2str(round(100*(pav_late_index - 1)/pavlovian_index)), '%'])
disp(['# Pavlovian No Lick: ', num2str(pav_no_lick_index - 1), ' | ', num2str(round(100*(pav_no_lick_index - 1)/pavlovian_index)), '%'])
disp([' '])
disp(['# Operant Total: ', num2str(operant_index - 1)])
disp(['# Operant Correct: ', num2str(op_correct_index - 1), ' | ', num2str(round(100*(op_correct_index - 1)/operant_index)), '%'])
disp(['# Operant Early: ', num2str(op_early_index - 1), ' | ', num2str(round(100*(op_early_index - 1)/operant_index)), '%'])
disp(['# Operant Late: ', num2str(op_late_index - 1), ' | ', num2str(round(100*(op_late_index - 1)/operant_index)), '%'])
disp(['# Operant No Lick: ', num2str(op_no_lick_index - 1), ' | ', num2str(round(100*(op_no_lick_index - 1)/operant_index)), '%'])
disp([' '])
disp(['# Hybrid Total: ', num2str(hybrid_correct_index - 1 + hybrid_early_index - 1)])
disp(['# Hybrid Correct: ', num2str(hybrid_correct_index - 1), ' | ', num2str(round(100*(hybrid_correct_index - 1)/(hybrid_correct_index - 1 + hybrid_early_index - 1))), '%'])
disp(['# Hybrid Early: ', num2str(hybrid_early_index - 1), ' | ', num2str(round(100*(hybrid_early_index - 1)/(hybrid_correct_index - 1 + hybrid_early_index - 1))), '%'])

% %--------------------------------------------------------------------------------------------------------------------------
% %% Plot Hx of First Licks for each Interval
% % First lick post cue
% figure
% subplot(4,1,1);
% histogram(times_1st_post_cue_lick, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('First lick after cue');
% 
% 
% %% Abort window licks:
% subplot(4,1,2);
% histogram(times_1st_lick_no_lick_period, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('First lick in abort window');
% 
% 
% %% Reward window first lick:
% subplot(4,1,3);
% histogram(times_1st_lick_reward, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('First lick in REWARD window');
% 
% 
% %% Abort window licks:
% subplot(4,1,4);
% histogram(times_1st_late_lick, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('First lick in post-reward window');


% %--------------------------------------------------------------------------------------------------------------------------
% % Pavlovian First Licks
% 
% figure
% subplot(4,1,1);
% histogram(pav_times_1st_post_cue_lick, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Pavlovian First lick after cue');
% 
% 
% %% Abort window licks:
% subplot(4,1,2);
% histogram(pav_times_1st_lick_no_lick_period, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Pavlovian First lick in abort window');
% 
% 
% %% Reward window first lick:
% subplot(4,1,3);
% histogram(pav_times_1st_lick_reward, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Pavlovian First lick in REWARD window');
% 
% 
% %% Abort window licks:
% subplot(4,1,4);
% histogram(pav_times_1st_late_lick, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Pavlovian First lick in post-reward window');
% 
% 
% %--------------------------------------------------------------------------------------------------------------------------
% % Operant First Licks
% 
% figure
% subplot(5,1,1);
% histogram(op_times_1st_post_cue_lick, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Operant First lick after cue');
% 
% 
% %% Abort window licks:
% subplot(5,1,2);
% histogram(op_times_1st_lick_no_lick_period, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Operant First lick in abort window');
% 
% 
% %% Reward window first lick:
% subplot(5,1,3);
% histogram(op_times_1st_lick_reward, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Operant First lick in REWARD window');
% 
% 
% %% Abort window licks:
% subplot(5,1,4);
% histogram(op_times_1st_late_lick, 100);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Operant First lick in post-reward window');
% 
% 
% %% All op 1st licks:
% subplot(5,1,5);
% histogram([op_times_1st_post_cue_lick, op_times_1st_lick_no_lick_period, pre_op_times_1st_lick_reward, op_times_1st_lick_reward, op_times_1st_late_lick], 100);
% hold on
% plot([0,0], [0, 100], 'g-'); 
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Operant Combined First licks');

% 
% 
% %--------------------------------------------------------------------------------------------------------------------------
% % Hybrid First Licks
% 
% figure
% subplot(5,1,1);
% histogram(hybrid_times_1st_post_cue_lick, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hybrid First lick after cue');
% 
% 
% %% Early lick Abort window licks:
% subplot(5,1,2);
% histogram(hybrid_times_1st_lick_no_lick_period, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hyrbid First lick in abort window');
% 
% 
% %% Reward window first lick:
% subplot(5,1,3);
% histogram(hybrid_times_1st_lick_reward, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hybrid First lick in REWARD window');
% 
% 
% %% Late window licks:
% subplot(5,1,4);
% histogram(hybrid_times_1st_late_lick, 1000);
% hold on
% plot([0,0], [0, 100], 'g-');
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hybrid First lick in post-reward window');
% 
% 
% %% All hybrid 1st licks:
% subplot(5,1,5);
% histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
%     100);
% hold on
% histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
%     200);
% histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
%     500);
% histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
%     500);
% histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
%     500);
% hold on
% plot([0,0], [0, 100], 'g-'); 
% 
% plot([time_target,time_target], [0, 100], 'r-');
% plot([time_abort_min,time_abort_min], [0, 100], 'b--');
% plot([time_abort_max,time_abort_max], [0, 100], 'b--');
% plot([time_min_interval,time_min_interval], [0, 100], 'g--');
% plot([time_max_interval,time_max_interval], [0, 100], 'g--');
% plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
% ylim([0,10]);
% xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
% ylabel('number of licks');
% xlabel('time relative to cue on (ms)');
% title('Hybrid Combined First licks');
% 




%% Single combined hybrid 1st licks fig

figure 
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    20);
hold on
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    50);
hold on
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    100);
hold on
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    200);
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    500);
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    500);
histogram([hybrid_times_1st_post_cue_lick, hybrid_times_1st_lick_no_lick_period, pre_hybrid_times_1st_lick_reward, hybrid_times_1st_lick_reward, hybrid_times_1st_late_lick],...
    500);
hold on
plot([0,0], [0, 100], 'g-'); 

plot([time_target,time_target], [0, 100], 'r-');
plot([time_abort_min,time_abort_min], [0, 100], 'b--');
plot([time_abort_max,time_abort_max], [0, 100], 'b--');
plot([time_min_interval,time_min_interval], [0, 100], 'g--');
plot([time_max_interval,time_max_interval], [0, 100], 'g--');
plot([time_trial_duration,time_trial_duration], [0, 100], 'c--');
ylim([0,10]);
xlim([min(min(licks_by_trial_relative_to_cue)) - 500, max(max(licks_by_trial_relative_to_cue)) + 500]);
ylabel('number of licks');
xlabel('time relative to cue on (ms)');
title('Hybrid Combined First licks');





%% Bar plots:
figure
subplot(4, 1, 1);
bar([1:length(allfirstlicks)], allfirstlicks);
title('all first lick times (by trial)');
% excludes first part of abort window and pavlovian part of reward window. Check later that this is calc right

subplot(4,1,2);
bar([1:length(rewarded_no_pav_firstlicks)], rewarded_no_pav_firstlicks);
title('NO PAV rewarded first lick times (by trial)')
ylim([time_min_interval, time_max_interval]);
% excludes pavlovian part of reward window. Check later that this is calc right

xi = randperm(length(rewarded_no_pav_firstlicks));
mixedrewarded = rewarded_no_pav_firstlicks(xi);
subplot(4,1,3);
bar([1:length(mixedrewarded)], mixedrewarded);
title('SHUFFLED - NO PAV rewarded first lick times')
ylim([time_min_interval, time_max_interval]);


subplot(4,1,4);
bar([1:length(abortedfirstlicks)], abortedfirstlicks);
title('Aborted only first lick times')
ylim([time_abort_min, time_abort_max]);
% excludes first part of abort window. Check later that this is calc right