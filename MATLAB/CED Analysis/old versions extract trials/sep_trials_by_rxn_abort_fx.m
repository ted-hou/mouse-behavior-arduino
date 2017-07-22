function [] = sep_trials_by_rxn_abort_fx(f_lick_rxn, f_lick_train_abort, analog_data)
%  Created 4/21/17  - ahamilos
%  Modified 4/21/17 - ahamilos
% 
%   5/19/17 OBSOLETE - sep_trials_by_success_fail_fx already does this!!!!
%

%  Like sep_trial_by_rxn_to_cue_fx, but now also splits wrt if the rxn caused a trial failure
% 
%  Dependency:
% 	first_lick_grabber.m (f_lick_rxn, f_lick_train_abort)

	% defaults: 
	f_lick_rxn = f_lick_rxn;
	f_lick_train_abort = f_lick_train_abort;
	analog_data = SNc_values_by_trial;


	num_trials = length(f_lick_rxn);


	% find trials with rxn lick and without rxn lick:
	trials_with_rxn_lick = zeros(size(f_lick_rxn));
	trials_with_rxn_lick(f_lick_rxn~=0)=1;
	trials_with_rxn_abort = zeros(size(f_lick_train_abort));
	trials_with_rxn_abort(f_lick_train_abort~=0)=1;


	% Now break apart the analog data into two sets:
	rxn_ok_lick_trial_data = NaN(size(analog_data));
	rxn_abort_lick_trial_data = NaN(size(analog_data));
	no_rxn_lick_trial_data = NaN(size(analog_data));

	for i_trial = 1:num_trials
		% Rxn happened, but didn't cause abort:
		if trials_with_rxn_lick(i_trial) && ~trials_with_rxn_abort(i_trial)% assign the data to the slot in the rxn ok set
			rxn_ok_lick_trial_data(i_trial, :) = analog_data(i_trial, :);

		% Rxn train resulted in trial abort!
		elseif trials_with_rxn_lick(i_trial) && trials_with_rxn_abort(i_trial)
			rxn_abort_lick_trial_data(i_trial, :) = analog_data(i_trial, :);

		% No rxn
		elseif ~trials_with_rxn_lick(i_trial) % assign data to slot in -rxn set
			no_rxn_lick_trial_data(i_trial, :) = analog_data(i_trial, :);
		else
			disp('error')
		end
	end	


	% Now average the two sets and smooth them:
	rxn_ok_lick_ave = nanmean(rxn_ok_lick_trial_data,1);
	rxn_abort_lick_ave = nanmean(rxn_abort_lick_trial_data,1);
	no_rxn_lick_ave = nanmean(no_rxn_lick_trial_data,1);

	smooth_rxn_ok_lick_ave = smooth(rxn_ok_lick_ave, 50, 'gauss');
	smooth_rxn_abort_lick_ave = smooth(rxn_abort_lick_ave, 50, 'gauss');
	smooth_no_rxn_lick_ave = smooth(no_rxn_lick_ave, 50, 'gauss');


figure,
subplot(3,1,1)
plot(smooth_rxn_ok_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_rxn_ok_lick_ave)-.01,max(smooth_rxn_ok_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_rxn_ok_lick_ave)-.01,max(smooth_rxn_ok_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_rxn_ok_lick_ave)-.01,max(smooth_rxn_ok_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_rxn_ok_lick_ave)-.01,max(smooth_rxn_ok_lick_ave)+.01], 'b-', 'linewidth', 3)
ylim([min(smooth_rxn_ok_lick_ave)-.001,max(smooth_rxn_ok_lick_ave)+.001])
xlim([0,18500])
xlabel('Time (ms)', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
title('Ave of trials with Rxn OK Licks', 'fontsize', 20)
set(gca, 'fontsize', 20)


subplot(3,1,2)
plot(smooth_rxn_abort_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'b-', 'linewidth', 3)
ylim([min(smooth_rxn_abort_lick_ave)-.001,max(smooth_rxn_abort_lick_ave)+.001])
xlim([0,18500])
xlabel('Time (ms)', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
title('Ave of trials with Rxn Licks -- Train Abort', 'fontsize', 20)
set(gca, 'fontsize', 20)



subplot(3,1,3)
plot(smooth_no_rxn_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_no_rxn_lick_ave)-.01,max(smooth_no_rxn_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_no_rxn_lick_ave)-.01,max(smooth_no_rxn_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_no_rxn_lick_ave)-.01,max(smooth_no_rxn_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_no_rxn_lick_ave)-.01,max(smooth_no_rxn_lick_ave)+.01], 'b-', 'linewidth', 3)
xlim([0,18500])
ylim([min(smooth_no_rxn_lick_ave)-.001,max(smooth_no_rxn_lick_ave)+.001])
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
title('Ave of trials without Rxn Licks', 'fontsize', 20)
set(gca, 'fontsize', 20)