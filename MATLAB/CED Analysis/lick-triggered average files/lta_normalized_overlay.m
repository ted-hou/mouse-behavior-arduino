%% Overlay the different types of licks - normalized - from -4000, 1000
% 
% Created  7-25-17
% Modified 7-26-17
% 
% Validated with dummy_data test set (7-26-17)
% 
% Instructions: run the lick_triggered_ave program for each case, and save the data by copy pasting from here
% Once all done with that, get normalized versions

%% This section now completed in lick_triggered_ave_fx.m
	% %% Step 1: run this:
	% range_ = [-4000,1000];
	% %debug range:
	% 	% range_ = [-20,20];
	% 	% 
	% 	% 

	% %% Step 2: do these individually-----------------------------------------------------------------
	% rxn_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
	% rxn_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;

	% early_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
	% early_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;

	% rew_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
	% rew_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;

	% pav_DLS_lick_triggered_ave_ignore_NaN = DLS_lick_triggered_ave_ignore_NaN;
	% pav_SNc_lick_triggered_ave_ignore_NaN = SNc_lick_triggered_ave_ignore_NaN;

%% Step 3: run this set-------------------------------------------------------------------------
pos1 = find(time_array==range_(1));
pos2 = find(time_array==range_(2));
zeropos = find(time_array==0);

N_rxn_DLS = rxn_DLS_lick_triggered_ave_ignore_NaN%(pos1:pos2)%/max(rxn_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
N_rxn_SNc = rxn_SNc_lick_triggered_ave_ignore_NaN%(pos1:pos2)%/max(rxn_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));

N_early_DLS = early_DLS_lick_triggered_ave_ignore_NaN%(pos1:pos2)%/max(early_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
N_early_SNc = early_SNc_lick_triggered_ave_ignore_NaN%(pos1:pos2)%/max(early_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));

N_rew_DLS = rew_DLS_lick_triggered_ave_ignore_NaN%(pos1:pos2)%/max(rew_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
N_rew_SNc = rew_SNc_lick_triggered_ave_ignore_NaN%(pos1:pos2)%/max(rew_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));

% N_pav_DLS = pav_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2)/max(pav_DLS_lick_triggered_ave_ignore_NaN(pos1:pos2));
% N_pav_SNc = pav_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2)/max(pav_SNc_lick_triggered_ave_ignore_NaN(pos1:pos2));


% Plot the overlays:

figure
ax1 = subplot(1,2,1) % DLS
plot(time_array(pos1:pos2),N_rxn_DLS(pos1:pos2), 'linewidth', 3)
hold on
plot(time_array(pos1:pos2),N_early_DLS(pos1:pos2), 'linewidth', 3)
plot(time_array(pos1:pos2),N_rew_DLS(pos1:pos2), 'linewidth', 3)
% plot(time_array(pos1:pos2),N_pav_DLS, 'linewidth', 3)
names = {'rxn', 'early', 'rew'};
% names = {'rxn', 'early', 'rew', 'pav'};
legend(names)
xlim(range_)
plot([0,0], [0,1], 'g-', 'linewidth', 2)

ax2 = subplot(1,2,2) % SNc
plot(time_array(pos1:pos2),N_rxn_SNc(pos1:pos2), 'linewidth', 3)
hold on
plot(time_array(pos1:pos2),N_early_SNc(pos1:pos2), 'linewidth', 3)
plot(time_array(pos1:pos2),N_rew_SNc(pos1:pos2), 'linewidth', 3)
% plot(time_array(pos1:pos2),N_pav_SNc, 'linewidth', 3)
legend(names)
xlim(range_)
plot([0,0], [0,1], 'g-', 'linewidth', 2)

% Plot the overlays:

figure
ax3 = subplot(1,2,1) % DLS
plot(time_array(pos1:pos2),smooth(N_rxn_DLS(pos1:pos2),50,'gauss'), 'linewidth', 3)
hold on
plot(time_array(pos1:pos2),smooth(N_early_DLS(pos1:pos2),50,'gauss'), 'linewidth', 3)
plot(time_array(pos1:pos2),smooth(N_rew_DLS(pos1:pos2),50,'gauss'), 'linewidth', 3)
% plot(time_array(pos1:pos2),smooth(N_pav_DLS,50,'gauss'), 'linewidth', 3)
names = {'rxn', 'early', 'rew'};
% names = {'rxn', 'early', 'rew', 'pav'};
legend(names)
xlim(range_)
plot([0,0], [0,1], 'g-', 'linewidth', 2)

ax4 = subplot(1,2,2) % SNc
plot(time_array(pos1:pos2),smooth(N_rxn_SNc(pos1:pos2),50,'gauss'), 'linewidth', 3)
hold on
plot(time_array(pos1:pos2),smooth(N_early_SNc(pos1:pos2),50,'gauss'), 'linewidth', 3)
plot(time_array(pos1:pos2),smooth(N_rew_SNc(pos1:pos2),50,'gauss'), 'linewidth', 3)
% plot(time_array(pos1:pos2),smooth(N_pav_SNc,50,'gauss'), 'linewidth', 3)
legend(names)
xlim(range_)
plot([0,0], [0,1], 'g-', 'linewidth', 2)

linkaxes([ax1, ax2, ax3, ax4],'xy')
% turn off with linkaxes([ax1, ax2, ax3, ax4],'off')
