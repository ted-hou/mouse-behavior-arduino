function [hybrid_trial_is_not_operant] = hybrid_trial_is_NOT_operant_fx(obj)

%       Keeps track of which trials were operant vs pavlovian licks in the hybrid trials
%       NOT operant by definition also includes trials that aren't pavlovian specifically, but could be very early licks or very late licks

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

% For HYBRID trials - have to decide if pav or op based on first lick. Therefore, find if first lick in Hybrid trials is before target
hybrid_trial_is_not_operant = [];



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
                % disp(['train of licks to abort window @ trial ', num2str(trial_index), '. Not including in first licks!']);
                hybrid_trial_is_not_operant(trial_index) = 1;
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
                    hybrid_trial_is_not_operant(trial_index) = 0;
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
                hybrid_trial_is_not_operant(trial_index) = 0;     
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
                if (events(ievent, 2) - cue_on_time_by_trial(trial_index) - start_time) < time_target;
                    % disp(time_target);
                    hybrid_trial_is_not_operant(trial_index) = 0;
                else
                    hybrid_trial_is_not_operant(trial_index) = 1;
                end
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
                hybrid_trial_is_not_operant(trial_index) = 1;
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



