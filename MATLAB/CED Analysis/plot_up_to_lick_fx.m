function [] = plot_up_to_lick_fx(DLS_values_up_to_lick, SNc_values_up_to_lick, f_lick_type_left_plot, f_lick_type_right_plot, window_left, window_right)
% 
% 	*** Note: input window wrt cue on in ms
% 
% 		Copy and paste to run: 
% 				plot_up_to_lick_fx(DLS_values_up_to_lick, SNc_values_up_to_lick, f_lick_operant_rew, f_lick_operant_no_rew, [4800,5200], [2800,3200]);
% 
% 	Created			5-24-17 ahamilos
% 	Last Modified	5-24-17 ahamilos
% 
% 	Dependencies:
% 		extract_trials_operant_v1
% 		lick_times_by_trial_fx	    
% 		first_lick_grabber_operant   (f_lick... for lick_type)
% 		extract_values_up_to_lick_fx (DLS_values_up_to_lick, SNc_values_up_to_lick)
% 		varname.m (gets string of the input variables)
% 
%.........................................................................................
%% Defaults:
    % window_left  = [4800,5200];
    % window_right = [2800,3200];


%% Convert window into abs time wrt trial start in sec (add 1500, div by 1000):
	window_left  = window_left/1000  + 1.5;
	window_right = window_right/1000 + 1.5;

% Find trials fitting window for left plot:
	left_trials  = find(f_lick_type_left_plot  >= window_left(1)  & f_lick_type_left_plot  <= window_left(2));
	right_trials = find(f_lick_type_right_plot >= window_right(1) & f_lick_type_right_plot <= window_right(2));
	disp(['Left Trials: ',  num2str(left_trials)]);
	disp(['Right Trials: ', num2str(right_trials)]);

% Plot trials within the windows:
	figure 
	subplot(2,2,1) % top plot left: SNc
	for i_trial_left = left_trials
		plot(smooth(SNc_values_up_to_lick(i_trial_left,:), 500, 'moving'))
		hold on
	end
	names = strread(num2str(left_trials),'%s');
	legend(names);
	title(['SNc ', varname(f_lick_type_left_plot)])
	xlabel('time (ms) [1500=cue on]')
	ylabel('signal')


	subplot(2,2,2) % top plot right: SNc
	for i_trial_right = right_trials
		plot(smooth(SNc_values_up_to_lick(i_trial_right,:), 500, 'moving'))
		hold on
	end
	names = strread(num2str(right_trials),'%s');
	legend(names);
	title(['SNc ', varname(f_lick_type_right_plot)])
	xlabel('time (ms) [1500=cue on]')
	ylabel('signal')

% -------------------------------bottom plots: DLS
	subplot(2,2,3) % bottom plot left: DLS
	for i_trial_left = left_trials
		plot(smooth(DLS_values_up_to_lick(i_trial_left,:), 500, 'moving'))
		hold on
	end
	names = strread(num2str(left_trials),'%s');
	legend(names);
	title(['DLS ', varname(f_lick_type_left_plot)])
	xlabel('time (ms) [1500=cue on]')
	ylabel('signal')


	subplot(2,2,4) % top plot right: SNc
	for i_trial_right = right_trials
		plot(smooth(DLS_values_up_to_lick(i_trial_right,:), 500, 'moving'))
		hold on
	end
	names = strread(num2str(right_trials),'%s');
	legend(names);
	title(['DLS ', varname(f_lick_type_right_plot)])
	xlabel('time (ms) [1500=cue on]')
	ylabel('signal')
	

