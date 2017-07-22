% function [] = sep_trials_by_rxn_to_cue_abort_fx(f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI, analog_data)
%  Created 4/21/17  - ahamilos
%  Modified 4/21/17 - ahamilos
% 
%  Like sep_trial_by_rxn_to_cue_fx, but now also splits wrt if the rxn caused a trial 
% 	failure AND whether a trial was successful or not (ie any reward)
% 
%  Now also will raster plot the points where animal licked on those trials
% 
% 
%  Dependency:
% 	first_lick_grabber.m (f_lick_rxn, f_lick_train_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI)

	% defaults: 
	f_lick_rxn = f_lick_rxn;
	f_lick_train_abort = f_lick_train_abort;
	f_lick_operant_no_rew = f_lick_operant_no_rew;
	analog_data = DLS_values_by_trial;
	plot_rast = true;


	num_trials = length(f_lick_rxn);


	% find trials with rxn lick and without rxn lick:
	trials_with_rxn_lick = zeros(size(f_lick_rxn));
	trials_with_rxn_lick(f_lick_rxn~=0)=1;
	trials_with_rxn_abort = zeros(size(f_lick_train_abort));
	trials_with_rxn_abort(f_lick_train_abort~=0)=1;

	% find trials with early lick aborts:
	trials_op_abort = zeros(size(f_lick_operant_no_rew));
	trials_op_abort(f_lick_operant_no_rew~=0)=1;


	% Now break apart the analog data into two sets:
	rxn_ok_success_lick_trial_data = NaN(size(analog_data));
	rxn_ok_fail_lick_trial_data = NaN(size(analog_data));
	no_rxn_success_lick_trial_data = NaN(size(analog_data));
	no_rxn_fail_lick_trial_data = NaN(size(analog_data));
	rxn_abort_lick_trial_data = NaN(size(analog_data));

	% keep track of the number of each kind of trial outcome:
	num_rxn_ok_success = 0;
	num_rxn_ok_fail    = 0;
	num_rxn_abort      = 0;
	num_no_rxn_success = 0;
	num_no_rxn_fail    = 0;

	% keep track of first lick times for raster on the overlay - a 1xn vector this time because I just want this for plotting the raster
	rast_rxn_ok_success = []; % include the rxn raster and successful lick
	rast_rxn_ok_fail    = [];
	rast_rxn_abort      = [];
	rast_no_rxn_success = [];
	rast_no_rxn_fail    = [];
	

	for i_trial = 1:num_trials
		% Rxn happened, but didn't cause abort:
		if trials_with_rxn_lick(i_trial) && ~trials_with_rxn_abort(i_trial)% assign the data to the slot in the rxn ok set
			% successful
			if ~trials_op_abort(i_trial)
				rxn_ok_success_lick_trial_data(i_trial, :) = analog_data(i_trial, :);
				num_rxn_ok_success = num_rxn_ok_success + 1;
				% add times to the raster. 1. time of rxn lick, then 2. time of successful lick
				rast_rxn_ok_success(end+1) = f_lick_rxn(i_trial);
				if f_lick_operant_rew(i_trial) > 0
					rast_rxn_ok_success(end+1) = f_lick_operant_rew(i_trial);
				elseif f_lick_pavlovian(i_trial) > 0
					rast_rxn_ok_success(end+1) = f_lick_pavlovian(i_trial);
				elseif f_lick_ITI(i_trial) > 0
					rast_rxn_ok_success(end+1) = f_lick_ITI(i_trial);
				else
					disp(['No lick @ trial: ', num2str(i_trial), '+rxn success'])
				end
					
				

			% failure
			elseif trials_op_abort(i_trial)
				rxn_ok_fail_lick_trial_data(i_trial, :) = analog_data(i_trial, :);
				num_rxn_ok_fail = num_rxn_ok_fail + 1;
				% add times to raster:
				rast_rxn_ok_fail(end+1) = f_lick_rxn(i_trial);
				if f_lick_operant_no_rew(i_trial) > 0
					rast_rxn_ok_fail(end+1) = f_lick_operant_no_rew(i_trial);
				else 
					disp(['No lick @ trial: ', num2str(i_trial), '+rxn, failure'])
				end
			else
				disp('error at rxn ok')
					% No rxn
			end

		% NO REACTION!
		elseif ~trials_with_rxn_lick(i_trial) % assign data to slot in -rxn set
			% successful
			if ~trials_op_abort(i_trial)
				no_rxn_success_lick_trial_data(i_trial, :) = analog_data(i_trial, :);
				num_no_rxn_success = num_no_rxn_success + 1;
				% add times to the raster. time of successful lick
				if f_lick_operant_rew(i_trial) > 0
					rast_no_rxn_success(end+1) = f_lick_operant_rew(i_trial);
				elseif f_lick_pavlovian(i_trial) > 0
					rast_no_rxn_success(end+1) = f_lick_pavlovian(i_trial);
				elseif f_lick_ITI(i_trial) > 0
					rast_no_rxn_success(end+1) = f_lick_ITI(i_trial);
				else
					disp(['No lick @ trial: ', num2str(i_trial), '-rxn, Sucess'])
				end


			% failure
			elseif trials_op_abort(i_trial)
				no_rxn_fail_lick_trial_data(i_trial, :) = analog_data(i_trial, :);
				num_no_rxn_fail = num_no_rxn_fail + 1;
				% add times to the raster. time of successful lick
				if f_lick_operant_no_rew(i_trial) > 0
					rast_no_rxn_fail(end+1) = f_lick_operant_no_rew(i_trial);
				else
					disp(['No lick @ trial: ', num2str(i_trial), '-rxn, Fail'])
				end
			else
				disp('error at no rxn')
			end

		% Rxn train resulted in trial abort!
		elseif trials_with_rxn_lick(i_trial) && trials_with_rxn_abort(i_trial)
			rxn_abort_lick_trial_data(i_trial, :) = analog_data(i_trial, :);
			num_rxn_abort = num_rxn_abort + 1;
			% add times to the raster. time of successful lick
			rast_rxn_abort(end+1) = f_lick_rxn(i_trial);
			if f_lick_train_abort(i_trial) > 0
				rast_rxn_abort(end+1) = f_lick_train_abort(i_trial);
			else
				disp(['No lick @ trial: ', num2str(i_trial), '+rxn, train abort'])
			end

		else
			disp('error')
		end
	end	

	trials_total = 	num_rxn_ok_success+num_rxn_ok_fail+num_rxn_abort+num_no_rxn_success+num_no_rxn_fail;
	if trials_total ~= num_trials
		disp(['WARNING!!! Trials Counted: ', num2str(trials_total), ' but there should be ', num2str(num_trials)])
	end


	% Now average the two sets and smooth them:
	rxn_ok_success_lick_ave = nanmean(rxn_ok_success_lick_trial_data,1);
	rxn_ok_fail_lick_ave = nanmean(rxn_ok_fail_lick_trial_data,1);
	no_rxn_success_lick_ave = nanmean(no_rxn_success_lick_trial_data,1);
	no_rxn_fail_lick_ave = nanmean(no_rxn_fail_lick_trial_data,1);
	rxn_abort_lick_ave = nanmean(rxn_abort_lick_trial_data,1);
	

	smooth_rxn_ok_success_lick_ave = smooth(rxn_ok_success_lick_ave, 50, 'gauss');
	smooth_rxn_ok_fail_lick_ave = smooth(rxn_ok_fail_lick_ave, 50, 'gauss');
	smooth_no_rxn_success_lick_ave = smooth(no_rxn_success_lick_ave, 50, 'gauss');
	smooth_no_rxn_fail_lick_ave = smooth(no_rxn_fail_lick_ave, 50, 'gauss');
	smooth_rxn_abort_lick_ave = smooth(rxn_abort_lick_ave, 50, 'gauss');
	


figure,
subplot(3,2,1)
plot(smooth_rxn_ok_success_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_rxn_ok_success_lick_ave)-.01,max(smooth_rxn_ok_success_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_rxn_ok_success_lick_ave)-.01,max(smooth_rxn_ok_success_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_rxn_ok_success_lick_ave)-.01,max(smooth_rxn_ok_success_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_rxn_ok_success_lick_ave)-.01,max(smooth_rxn_ok_success_lick_ave)+.01], 'b-', 'linewidth', 3)
if plot_rast
	plot(rast_rxn_ok_success*1000, (nanmedian(smooth_rxn_ok_success_lick_ave(1500:end-1500))-.005)*ones(length(rast_rxn_ok_success)), '.',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', 'black',...
				'MarkerFaceColor', 'black',...
				'LineWidth', 1.5)
end
ylim([min(smooth_rxn_ok_success_lick_ave)-.001,max(smooth_rxn_ok_success_lick_ave)+.001])
xlim([0,18500])
xlabel('Time (ms)', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
title(['Ave of trials with Rxn OK Licks - Success. n=', num2str(num_rxn_ok_success)], 'fontsize', 20)
set(gca, 'fontsize', 20)

subplot(3,2,2)
plot(smooth_rxn_ok_fail_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_rxn_ok_fail_lick_ave)-.01,max(smooth_rxn_ok_fail_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_rxn_ok_fail_lick_ave)-.01,max(smooth_rxn_ok_fail_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_rxn_ok_fail_lick_ave)-.01,max(smooth_rxn_ok_fail_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_rxn_ok_fail_lick_ave)-.01,max(smooth_rxn_ok_fail_lick_ave)+.01], 'b-', 'linewidth', 3)
if plot_rast
	plot(rast_rxn_ok_fail*1000, (nanmedian(smooth_rxn_ok_fail_lick_ave(1500:end-1500))-.005)*ones(length(rast_rxn_ok_fail)), '.',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', 'black',...
				'MarkerFaceColor', 'black',...
				'LineWidth', 1.5)
end
ylim([min(smooth_rxn_ok_fail_lick_ave)-.001,max(smooth_rxn_ok_fail_lick_ave)+.001])
xlim([0,18500])
xlabel('Time (ms)', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
title(['Ave of trials with Rxn OK Licks - Fail. n=', num2str(num_rxn_ok_fail)], 'fontsize', 20)
set(gca, 'fontsize', 20)


subplot(3,2,3)
plot(smooth_rxn_abort_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_rxn_abort_lick_ave)-.01,max(smooth_rxn_abort_lick_ave)+.01], 'b-', 'linewidth', 3)
if plot_rast
	plot(rast_rxn_abort*1000, (nanmedian(smooth_rxn_abort_lick_ave(1500:end-1500))-.005)*ones(length(rast_rxn_abort)), '.',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', 'black',...
				'MarkerFaceColor', 'black',...
				'LineWidth', 1.5)
end
ylim([min(smooth_rxn_abort_lick_ave)-.001,max(smooth_rxn_abort_lick_ave)+.001])
xlim([0,18500])
xlabel('Time (ms)', 'fontsize', 20)
ylabel('\DeltaF/F', 'fontsize', 20)
title(['Ave of trials with Rxn Licks -- Train Abort. n=', num2str(num_rxn_abort)], 'fontsize', 20)
set(gca, 'fontsize', 20)



subplot(3,2,5)
plot(smooth_no_rxn_success_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_no_rxn_success_lick_ave)-.01,max(smooth_no_rxn_success_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_no_rxn_success_lick_ave)-.01,max(smooth_no_rxn_success_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_no_rxn_success_lick_ave)-.01,max(smooth_no_rxn_success_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_no_rxn_success_lick_ave)-.01,max(smooth_no_rxn_success_lick_ave)+.01], 'b-', 'linewidth', 3)
if plot_rast
	plot(rast_no_rxn_success*1000, (nanmedian(smooth_no_rxn_success_lick_ave(1500:end-1500))-.005)*ones(length(rast_no_rxn_success)), '.',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', 'black',...
				'MarkerFaceColor', 'black',...
				'LineWidth', 1.5)
end
xlim([0,18500])
ylim([min(smooth_no_rxn_success_lick_ave)-.001,max(smooth_no_rxn_success_lick_ave)+.001])
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
title(['Ave of trials without Rxn Licks - Success. n=', num2str(num_no_rxn_success)], 'fontsize', 20)
set(gca, 'fontsize', 20)

subplot(3,2,6)
plot(smooth_no_rxn_fail_lick_ave, 'linewidth', 3)
hold on
plot([1500, 1500], [min(smooth_no_rxn_fail_lick_ave)-.01,max(smooth_no_rxn_fail_lick_ave)+.01], 'b-', 'linewidth', 3)
hold on
plot([2000, 2000], [min(smooth_no_rxn_fail_lick_ave)-.01,max(smooth_no_rxn_fail_lick_ave)+.01], 'r-', 'linewidth', 3)
plot([3333, 3333], [min(smooth_no_rxn_fail_lick_ave)-.01,max(smooth_no_rxn_fail_lick_ave)+.01], 'g-', 'linewidth', 3)
plot([6500, 6500], [min(smooth_no_rxn_fail_lick_ave)-.01,max(smooth_no_rxn_fail_lick_ave)+.01], 'b-', 'linewidth', 3)
if plot_rast
	plot(rast_no_rxn_fail*1000, (nanmedian(smooth_no_rxn_fail_lick_ave(1500:end-1500))-.005)*ones(length(rast_no_rxn_fail)), '.',...
				'MarkerSize', 10,...
				'MarkerEdgeColor', 'black',...
				'MarkerFaceColor', 'black',...
				'LineWidth', 1.5)
end
xlim([0,18500])
ylim([min(smooth_no_rxn_fail_lick_ave)-.001,max(smooth_no_rxn_fail_lick_ave)+.001])
ylabel('\DeltaF/F', 'fontsize', 20)
xlabel('Time (ms)', 'fontsize', 20)
title(['Ave of trials without Rxn Licks - Fail. n=', num2str(num_no_rxn_fail)], 'fontsize', 20)
set(gca, 'fontsize', 20)