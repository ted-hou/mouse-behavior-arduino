function [DLS_values_up_to_lick, SNc_values_up_to_lick] = extract_values_up_to_lick_fx(all_first_licks, DLS_values_by_trial, SNc_values_by_trial)
% 
% 	Created 		5-24-17 ahamilos
% 	Last Modified 	5-24-17 ahamilos
% 
% Note that all_first_licks in sec wrt trial start (cue_on + 1.5s)
% 
% 	For use with plot_up_to_lick_fx.m
% .........................................................


DLS_values_up_to_lick = nan(size(DLS_values_by_trial));
SNc_values_up_to_lick = nan(size(SNc_values_by_trial));

% actually dont need DLS_times_by_trial bc all_first_licks is wrt cue on
% +1.5 in sec, so do *1000

for i_trial = 1:length(all_first_licks)
	if all_first_licks(i_trial) == 0
		% skip this one bc is rxn train abort, so all_first_licks == 0
	else		
		cutoff = floor((all_first_licks(i_trial)*1000));
		DLS_values_up_to_lick(i_trial,1:cutoff) = DLS_values_by_trial(i_trial, 1:cutoff);
		SNc_values_up_to_lick(i_trial,1:cutoff) = SNc_values_by_trial(i_trial, 1:cutoff);
	end
end