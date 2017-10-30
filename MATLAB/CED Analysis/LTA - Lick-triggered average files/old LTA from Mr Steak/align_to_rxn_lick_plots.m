%  This file let's you align analog data to the first reaction lick in the trial

%  Next steps:
%     Divide by whether rxn train abort or no
%     Put side by side with aligned to the cue onset +/- first licks




% Defaults 
analog_times_by_trial = SNc_times_by_trial;
analog_values_by_trial = SNc_values_by_trial;
f_lick_rxn = f_lick_rxn;
num_trials = num_trials;
signal = 'SNc'


% Find the alignments for rxn licks:
[ave_rxn_lick_times,...
          ave_rxn_lick_values,...
          rxn_lick_aligned_times,...
          smoothed_rxn_lick_aligned_values,...
          normalized_smoothed_rxn_lick_aligned_values]...
             = align_to_lick_fx(analog_times_by_trial,...
                                analog_values_by_trial,...
                                f_lick_rxn,... 
                                num_trials);
                                  
                            
                            
%% Smooth all the averages:
ave_rxn_lick_values = smooth(ave_rxn_lick_values, 50, 'gauss');


%% Plotting:

% 1. Averages:
figure, 
plot(ave_rxn_lick_times, ave_rxn_lick_values, 'linewidth', 3)
hold on
plot([0,0], [min(ave_rxn_lick_values)-.001, max(ave_rxn_lick_values)+.001], 'r-', 'linewidth', 3)
title(['Aligned to Reaction Licks to the Cue: ', signal], 'fontsize', 15)
ylim([min(ave_rxn_lick_values)-.001,max(ave_rxn_lick_values)+.001])
ylabel('\DeltaF/F', 'fontsize', 15)
xlabel('Time (ms)', 'fontsize', 15)
xlim([-1,2])
set(gca, 'fontsize', 15)