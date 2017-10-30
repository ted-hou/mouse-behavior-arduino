%% Plot histogram for COMBO days
% 
%  Make histograms based on trial type for combined days
% 
% 	Created  8-11-17
% 	Modified 8-14-17
% 
%  (hxgram_single_roadmapv1)
% 
% ------------------------------------------

% combined_data_struct

% 1. Plot Hxgram of first licks for whole day
all_licks = all_ex_first_licks + f_ex_lick_rxn;
nanswitch = find(all_licks == 0);
all_licks(nanswitch) = NaN;
all_licks = all_licks - 1.5;

figure, histogram(all_licks, 200)
ylabel('# of licks/bin')
xlabel('time (sec)')
title('All First Licks')
xlim([0,18])




% 2. Plot Hxgram of rxns
rxn_licks = f_ex_lick_rxn;
nanswitch = find(rxn_licks == 0);
rxn_licks(nanswitch) = NaN;
rxn_licks = rxn_licks - 1.5;

figure, histogram(rxn_licks, 30)
ylabel('# of licks/bin')
xlabel('time (sec)')
title('Rxn')


% 3. Plot Hxgram of all operants
op_licks = f_ex_lick_operant_no_rew + f_ex_lick_operant_rew;
nanswitch = find(op_licks == 0);
op_licks(nanswitch) = NaN;
op_licks = op_licks - 1.5;

figure, histogram(op_licks, 40)
ylabel('# of licks/bin')
xlabel('time (sec)')
title('All Operant')
xlim([0,18])


[f_ex_licks_with_rxn, f_ex_licks_no_rxn] = rxn_lick_or_no_rxn_lick_fx(all_ex_first_licks, f_ex_lick_rxn)

% Plot Hxgram of trials with a rxn lick:
plus_rxn_licks = f_ex_licks_with_rxn;
nanswitch = find(plus_rxn_licks == 0);
plus_rxn_licks(nanswitch) = NaN;
plus_rxn_licks = plus_rxn_licks - 1.5;

figure, histogram(plus_rxn_licks, 40)
ylabel('# of licks/bin')
xlabel('time (sec)')
xlim([0,18])
% title('Trials with Rxn Lick')

% Plot Hxgram of trials with NO rxn lick:
no_rxn_licks = f_ex_licks_no_rxn;
nanswitch = find(no_rxn_licks == 0);
no_rxn_licks(nanswitch) = NaN;
no_rxn_licks = no_rxn_licks - 1.5;

hold on, histogram(no_rxn_licks, 40)
xlim([0,18])
ylabel('# of licks/bin')
xlabel('time (sec)')
title('Trials with and without Rxn Lick')
legend({'Trials With Rxn', 'Trials Without Rxn'})