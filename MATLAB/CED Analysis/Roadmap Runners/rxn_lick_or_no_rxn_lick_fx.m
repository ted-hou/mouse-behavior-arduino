function [f_licks_with_rxn, f_licks_no_rxn] = rxn_lick_or_no_rxn_lick_fx(all_first_licks, f_lick_rxn)

%% Separate first licks by trials with rxn and trials without rxn
% 
%  Created  8-11-17
%  Modified 8-15-17
% 
% 
%	Update 8-15-17: fixed key error in f_licks_with_rxn, now is the correct size and will plot correctly
% -------------------------------------------------------------------------


trials_with_rxn_lick = find(f_lick_rxn);

f_licks_no_rxn = all_first_licks;
f_licks_no_rxn(trials_with_rxn_lick) = 0;

f_licks_with_rxn = zeros(1,length(all_first_licks));
f_licks_with_rxn(trials_with_rxn_lick) = all_first_licks(trials_with_rxn_lick);

