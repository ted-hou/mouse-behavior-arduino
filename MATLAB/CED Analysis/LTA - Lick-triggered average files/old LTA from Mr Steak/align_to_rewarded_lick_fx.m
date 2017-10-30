function []...
    = align_to_rewarded_lick_fx(analog_times_by_trial,...
                                analog_values_by_trial,...
                                f_lick_operant_no_rew,...
                                f_lick_operant_rew,...
                                f_lick_pavlovian,...
                                num_trials,...
                                signal)
% 
% Plot lick-triggered averages, seperated by trial outcome (early, operant, pavlovian)
% 
% 
%  HYBRID VERSION - OK to use with any HYBRID experiment, regardless of rxn window
%     *note: beta version written, may work with allop too (7/19/17)
% 
%  Created:  ahamilos 4/21/17
%  Modified: ahamilos 7/19/17
%
%  HYBRID Premades:
% 
% For DLS, no exclusions 
%  align_to_rewarded_lick_fx(d3_DLS_times_by_trial, d3_DLS_values_by_trial, d3_f_lick_operant_no_rew, d3_f_lick_operant_rew, d3_f_lick_pavlovian, num_trials, 'DLS')
% For SNc, no exclusions 
%  align_to_rewarded_lick_fx(d3_SNc_times_by_trial, d3_SNc_values_by_trial, d3_f_lick_operant_no_rew, d3_f_lick_operant_rew, d3_f_lick_pavlovian, num_trials, 'SNc')
% 
% For DLS, exclusions:
%  align_to_rewarded_lick_fx(d3_DLS_times_by_trial, d3_DLS_values_by_trial, d3_f_ex1_lick_operant_no_rew, d3_f_ex1_lick_operant_rew, d3_f_ex1_lick_pavlovian, num_trials, 'DLS')
% For SNc, exclusions 
%  align_to_rewarded_lick_fx(d3_SNc_times_by_trial, d3_SNc_values_by_trial, d3_f_ex1_lick_operant_no_rew, d3_f_ex1_lick_operant_rew, d3_f_ex1_lick_pavlovian, num_trials, 'SNc')
%
% 
%  OPERANT Premades: Instead of Pavlovian, do the rxn train
% For DLS, no exclusions 
%  align_to_rewarded_lick_fx(d3_DLS_times_by_trial, d3_DLS_values_by_trial, d3_f_lick_operant_no_rew, d3_f_lick_operant_rew, [0], num_trials, 'DLS')
% For SNc, no exclusions 
%  align_to_rewarded_lick_fx(d3_SNc_times_by_trial, d3_SNc_values_by_trial, d3_f_lick_operant_no_rew, d3_f_lick_operant_rew, [0], num_trials, 'SNc')
% 
% For DLS, exclusions:
%  align_to_rewarded_lick_fx(d3_DLS_times_by_trial, d3_DLS_values_by_trial, d3_f_ex1_lick_operant_no_rew, d3_f_ex1_lick_operant_rew, d22_f_ex1_lick_train_abort, num_trials, 'DLS')
% For SNc, exclusions 
%  align_to_rewarded_lick_fx(d3_SNc_times_by_trial, d3_SNc_values_by_trial, d3_f_ex1_lick_operant_no_rew, d3_f_ex1_lick_operant_rew, d22_f_ex1_lick_train_abort, num_trials, 'SNc')
% 
%---------------------------------------------- 
% Update Log:
%     original: use with Mr. Steak hybrid
%     7/19/17:  part of analysis roadmap, create defaults for copy-paste to analyze the Super-6 (hybrid data)
% 
% 
% ---------------------------------------------------------------------------

if f_lick_pavlovian == 0
  % assume operant situation
  f_lick_pavlovian = zeros(size(f_lick_operant_rew));
end

rewarded_f_licks = f_lick_operant_rew + f_lick_pavlovian;
unrequited_f_licks = f_lick_operant_no_rew;

% Find the alignments for rewarded first licks
[ave_f_lick_times_rew,...
          ave_f_lick_values_rew,...
          scored_lick_aligned_times_rew,...
          smoothed_scored_lick_aligned_values_rew,...
          normalized_smoothed_scored_lick_aligned_values_rew]...
             = align_to_lick_fx(analog_times_by_trial,...
                                analog_values_by_trial,...
                                rewarded_f_licks,... 
                                num_trials);
                            
                            
% Find the alignments for unrequited first licks
[ave_f_lick_times_no_rew,...
          ave_f_lick_values_no_rew,...
          scored_lick_aligned_times_no_rew,...
          smoothed_scored_lick_aligned_values_no_rew,...
          normalized_smoothed_scored_lick_aligned_values_no_rew]...
             = align_to_lick_fx(analog_times_by_trial,...
                                analog_values_by_trial,...
                                unrequited_f_licks,... 
                                num_trials);
                            
                            
% Find the alignments for Pavlovian first licks
[ave_f_lick_times_pav,...
          ave_f_lick_values_pav,...
          scored_lick_aligned_times_pav,...
          smoothed_scored_lick_aligned_values_pav,...
          normalized_smoothed_scored_lick_aligned_values_pav]...
             = align_to_lick_fx(analog_times_by_trial,...
                                analog_values_by_trial,...
                                f_lick_pavlovian,... 
                                num_trials);
                            
% Find the alignments for Operant-Rewarded first licks
[ave_f_lick_times_rew_op,...
          ave_f_lick_values_rew_op,...
          scored_lick_aligned_times_rew_op,...
          smoothed_scored_lick_aligned_values_rew_op,...
          normalized_smoothed_scored_lick_aligned_values_rew_op]...
             = align_to_lick_fx(analog_times_by_trial,...
                                analog_values_by_trial,...
                                f_lick_operant_rew,... 
                                num_trials);           
                            
                            
%% Smooth all the averages:

ave_f_lick_values_rew = smooth(ave_f_lick_values_rew, 50, 'gauss');
ave_f_lick_values_no_rew = smooth(ave_f_lick_values_no_rew, 50, 'gauss');
ave_f_lick_values_pav = smooth(ave_f_lick_values_pav, 50, 'gauss');
ave_f_lick_values_rew_op = smooth(ave_f_lick_values_rew_op, 50, 'gauss');



%% Plotting:

% 1. Averages:
figure, 
subplot(2,1,1)
plot(ave_f_lick_times_rew, ave_f_lick_values_rew, 'linewidth', 3)
hold on
plot([0,0], [min(ave_f_lick_values_rew)-.001, max(ave_f_lick_values_rew)+.001], 'r-', 'linewidth', 3)
title(['All Rewarded First Licks ', signal], 'fontsize', 15)
ylim([min(ave_f_lick_values_rew)-.001,max(ave_f_lick_values_rew)+.001])
ylabel('\DeltaF/F', 'fontsize', 15)
xlabel('Time (ms)', 'fontsize', 15)
xlim([-2,2])
set(gca, 'fontsize', 15)

subplot(2,1,2)
plot(ave_f_lick_times_no_rew, ave_f_lick_values_no_rew, 'linewidth', 3)
hold on
plot([0,0], [min(ave_f_lick_values_no_rew)-.001, max(ave_f_lick_values_no_rew)+.001], 'r-', 'linewidth', 3)
title(['All Unrequited First Licks ', signal], 'fontsize', 15)
ylabel('\DeltaF/F', 'fontsize', 15)
xlabel('Time (ms)', 'fontsize', 15)
ylim([min(ave_f_lick_values_no_rew)-.001,max(ave_f_lick_values_no_rew)+.001])
xlim([-2,2])
set(gca, 'fontsize', 15)


figure, 
subplot(3,1,1)
plot(ave_f_lick_times_no_rew, ave_f_lick_values_no_rew, 'linewidth', 3)
hold on
plot([0,0], [min(ave_f_lick_values_no_rew)-.001, max(ave_f_lick_values_no_rew)+.001], 'r-', 'linewidth', 3)
title(['All Unrequited First Operant Licks ', signal], 'fontsize', 15)
ylabel('\DeltaF/F', 'fontsize', 15)
xlabel('Time (ms)', 'fontsize', 15)
ylim([min(ave_f_lick_values_no_rew)-.001,max(ave_f_lick_values_no_rew)+.001])
xlim([-2,2])
set(gca, 'fontsize', 15)

subplot(3,1,2)
plot(ave_f_lick_times_rew_op, ave_f_lick_values_rew_op, 'linewidth', 3)
hold on
plot([0,0], [min(ave_f_lick_values_rew_op)-.001, max(ave_f_lick_values_rew_op)+.001], 'r-', 'linewidth', 3)
title(['All Rewarded First Operant Licks ', signal], 'fontsize', 15)
ylabel('\DeltaF/F', 'fontsize', 15)
xlabel('Time (ms)', 'fontsize', 15)
ylim([min(ave_f_lick_values_rew_op)-.001,max(ave_f_lick_values_rew_op)+.001])
xlim([-2,2])
set(gca, 'fontsize', 15)

subplot(3,1,3)
plot(ave_f_lick_times_pav, ave_f_lick_values_pav, 'linewidth', 3)
hold on
plot([0,0], [min(ave_f_lick_values_pav)-.001, max(ave_f_lick_values_pav)+.001], 'r-', 'linewidth', 3)
title(['All First Pavlovian Licks ', signal], 'fontsize', 15)
ylabel('\DeltaF/F', 'fontsize', 15)
xlabel('Time (ms)', 'fontsize', 15)
ylim([min(ave_f_lick_values_pav)-.001,max(ave_f_lick_values_pav)+.001])
xlim([-2,2])
set(gca, 'fontsize', 15)







                            
                            % figure,
% for i_trial = 1:num_trials
%     plot(scored_lick_aligned_times(i_trial,:), normalized_smoothed_scored_lick_aligned_values(i_trial, :))
%     hold on
% end
% hold on
% plot([0,0], [min(ave_f_lick_values), max(ave_f_lick_values)], 'r-', 'linewidth', 3)
                            
                    