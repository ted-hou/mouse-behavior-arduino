%% paired_baseline_comparisons
% 
% 	Created: 	9-4-17	ahamilos
% 	Modified: 	9-4-17	ahamilos
% 
% 
% 
% 
% 
%  --------------------------------------
% For unrewarded = early and rewarded = late case
% early_boundary_left = (1500+700)/1000; % edge of rxn bound in sec - for use with f_lick_vars
% early_boundary_right = (1500+3333)/1000; % I choose to include all unrewarded early trials in same category
% late_boundary_right = (1500+7000)/1000; % end of reward window

% For early-unrew vs late-unrew
early_boundary_left = (1500+700)/1000; % edge of rxn bound in sec - for use with f_lick_vars
early_boundary_right = (1500+1316.5)/1000; % I choose to include all unrewarded early trials in same category
late_boundary_right = (1500+3333)/1000; % end of reward window

baseline_window = [17500, 18500];


all_ex_first_licks = all_ex_first_licks;
num_trials = num_trials;
SNc_values_by_trial = SNc_values_by_trial;
DLS_values_by_trial = DLS_values_by_trial;

%  The goal is to find the median fluorescence during last 1 sec of ITI in prior trial for each trial. Then, without dF/F, find all paired early and late trials
% 	Dependent on:
% 		- roadmap_v1_1_no_dF_F - extract DLS and SNc values without corrections
% 		- lick_times_by_trial
% 		- first_lick_grabber (exclusions apply)
% 		- 

%  Determine if a trial is early vs late
% all_ex_first_licks does not include rxns, but we also want to pad the boundary to 700. 
%  Technically we already know all the f_licks for early and rew, but by calc here we make generalizable to other cut off windows
%  Include the right edge of the boundary!!!!!!! -- consistent with trial_binner_fxs
trials_with_early = find(all_ex_first_licks > early_boundary_left & all_ex_first_licks < early_boundary_right);
trials_with_late = find(all_ex_first_licks > early_boundary_right & all_ex_first_licks < late_boundary_right);

% Find the pre-trial baseline for each trial (have to exclude trial #1 because don't know the pretrial baseline for that one.)
pre_trial_baselines_SNc = NaN(num_trials,1);
pre_trial_baselines_DLS = NaN(num_trials,1);

for i_trial = 2:num_trials
	SNc_baseline_before = nanmean(SNc_values_by_trial((i_trial-1), (baseline_window(1):baseline_window(2))));
	pre_trial_baselines_SNc(i_trial) = SNc_baseline_before; 

	DLS_baseline_before = nanmean(DLS_values_by_trial((i_trial-1), (baseline_window(1):baseline_window(2))));
	pre_trial_baselines_DLS(i_trial) = DLS_baseline_before;
end


% EARLY - LATE PAIRS ===================================================================================================================
	pos1 = trials_with_early;
	pos2 = trials_with_late;
	pairs = 1;
	pos1_positions = [];
	pos2_positions = [];

	for i_early = 1:length(trials_with_early)
	    if find(trials_with_late==trials_with_early(i_early)+1)
	%         pos2_pair_positions = find(trials_with_late==trials_with_early(i_early)+1); % an array that looks like [0,0,0,2,0,6] where 0 indicates that pos1 is first, ~=0 is the position in pos2 that comes next
	        pos1_positions(pairs) = pos1(i_early); % an array that looks like [4,6] - it's the trials where pos1 comes first. This is all we need. The trials where pos2 comes second are pos1_pair_positions + 1
	        pos2_positions(pairs) = pos1(i_early) + 1;
	        pairs = pairs + 1;
	    end
	end

	% now we want the pairs to be paired for t-tests. Do in 2 (npairs, 1) vectors
	pos1_baselines_SNc = nan(length(pos1_positions),1);
	pos2_baselines_SNc = nan(length(pos2_positions),1);

	pos1_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos1_positions);
	pos2_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos2_positions);



	pos1_baselines_DLS = nan(length(pos1_positions),1);
	pos2_baselines_DLS = nan(length(pos2_positions),1);

	pos1_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos1_positions);
	pos2_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos2_positions);

	colorpallet = {'bo', 'ro'}
	earlycolor = 1;
	latecolor = 2;

	figure,
	ax1 = subplot(1, 2, 1);
	plot(pos1_positions, pos1_baselines_DLS,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_DLS,colorpallet{latecolor})
	title('DLS')

	ax2 = subplot(1, 2, 2);
	plot(pos1_positions, pos1_baselines_SNc,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_SNc,colorpallet{latecolor})
	title('SNc')

	SNc_del = pos1_baselines_SNc - pos2_baselines_SNc;
	DLS_del = pos1_baselines_DLS - pos2_baselines_DLS;

	figure,
	ax3 = subplot(1, 2, 1);
	plot(pos1_positions, DLS_del,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [0,0], 'k-', 'linewidth', 3)
	title('DLS del (centered on pos1')
	ylabel('Early Baseline - Late Baseline')
	xlabel('Trial #')
	ylim([-.012, .012])

	ax4 = subplot(1, 2, 2);
	plot(pos1_positions, SNc_del,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [0,0], 'k-', 'linewidth', 3)
	title('SNc del')
	ylabel('Early Baseline - Late Baseline')
	xlabel('Trial #')
	ylim([-.1, .1])


	figure,
	ax5 = subplot(1, 2, 1);
	plot(zeros(size(DLS_del)), DLS_del,colorpallet{earlycolor})
	hold on
	plot([-1,1], [0,0], 'k-', 'linewidth', 3)
	title('DLS del (centered on 0')
	ylabel('Early Baseline - Late Baseline')

	ax6 = subplot(1, 2, 2);
	plot(zeros(size(SNc_del)), SNc_del,colorpallet{earlycolor})
	hold on
	plot([-1,1], [0,0], 'k-', 'linewidth', 3)
	title('SNc del')
	ylabel('Early Baseline - Late Baseline')

	linkaxes([ax3, ax5], 'y')
	linkaxes([ax4, ax6], 'y')



	early1_late2_ttest_DLS = {};
	early1_late2_ttest_SNc = {};
	[early1_late2_ttest_DLS.h,early1_late2_ttest_DLS.p,early1_late2_ttest_DLS.ci,early1_late2_ttest_DLS.stats] = ttest(pos1_baselines_DLS,pos2_baselines_DLS);
	[early1_late2_ttest_SNc.h,early1_late2_ttest_SNc.p,early1_late2_ttest_SNc.ci,early1_late2_ttest_SNc.stats] = ttest(pos1_baselines_SNc,pos2_baselines_SNc);






% LATE - EARLY PAIRS =================================================================================================================== 
	pos1 = trials_with_late;
	pos2 = trials_with_early;
	pairs = 1;
	pos1_positions = [];
	pos2_positions = [];

	for i_early = 1:length(pos1)
	    if find(pos2==pos1(i_early)+1)
	%         pos2_pair_positions = find(pos2==pos1(i_early)+1); % an array that looks like [0,0,0,2,0,6] where 0 indicates that pos1 is first, ~=0 is the position in pos2 that comes next
	        pos1_positions(pairs) = pos1(i_early); % an array that looks like [4,6] - it's the trials where pos1 comes first. This is all we need. The trials where pos2 comes second are pos1_pair_positions + 1
	        pos2_positions(pairs) = pos1(i_early) + 1;
	        pairs = pairs + 1;
	    end
	end

	% now we want the pairs to be paired for t-tests. Do in 2 (npairs, 1) vectors
	pos1_baselines_SNc = nan(length(pos1_positions),1);
	pos2_baselines_SNc = nan(length(pos2_positions),1);

	pos1_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos1_positions);
	pos2_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos2_positions);



	pos1_baselines_DLS = nan(length(pos1_positions),1);
	pos2_baselines_DLS = nan(length(pos2_positions),1);

	pos1_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos1_positions);
	pos2_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos2_positions);


	figure,
	ax7 = subplot(1, 2, 1);
	plot(pos1_positions, pos1_baselines_DLS,colorpallet{latecolor})
	hold on
	plot(pos2_positions, pos2_baselines_DLS,colorpallet{earlycolor})
	title('DLS')

	ax8 = subplot(1, 2, 2);
	plot(pos1_positions, pos1_baselines_SNc,colorpallet{latecolor})
	hold on
	plot(pos2_positions, pos2_baselines_SNc,colorpallet{earlycolor})
	title('SNc')

	SNc_del = pos1_baselines_SNc - pos2_baselines_SNc;
	DLS_del = pos1_baselines_DLS - pos2_baselines_DLS;

	figure,
	ax9 = subplot(1, 2, 1);
	plot(pos1_positions, DLS_del,colorpallet{latecolor})
	hold on
	plot([0,num_trials], [0,0], 'k-', 'linewidth', 3)
	title('DLS del (centered on pos1')
	ylabel('LATE Baseline - EARLY Baseline')
	xlabel('Trial #')
	% ylim([-.012, .012])

	ax10 = subplot(1, 2, 2);
	plot(pos1_positions, SNc_del,colorpallet{latecolor})
	hold on
	plot([0,num_trials], [0,0], 'k-', 'linewidth', 3)
	title('SNc del')
	ylabel('LATE Baseline - EARLY Baseline')
	xlabel('Trial #')
	% ylim([-.1, .1])


	figure,
	ax11 = subplot(1, 2, 1);
	plot(zeros(size(DLS_del)), DLS_del,colorpallet{latecolor})
	hold on
	plot([-1,1], [0,0], 'k-', 'linewidth', 3)
	title('DLS del (centered on 0')
	ylabel('LATE Baseline - EARLY Baseline')

	ax12 = subplot(1, 2, 2);
	plot(zeros(size(SNc_del)), SNc_del,colorpallet{latecolor})
	hold on
	plot([-1,1], [0,0], 'k-', 'linewidth', 3)
	title('SNc del')
	ylabel('LATE Baseline - EARLY Baseline')

	linkaxes([ax9, ax11], 'y')
	linkaxes([ax10, ax12], 'y')


	late1_early2_ttest_DLS = {};
	late1_early2_ttest_SNc = {};
	[late1_early2_ttest_DLS.h,late1_early2_ttest_DLS.p,late1_early2_ttest_DLS.ci,late1_early2_ttest_DLS.stats] = ttest(pos1_baselines_DLS,pos2_baselines_DLS);
	[late1_early2_ttest_SNc.h,late1_early2_ttest_SNc.p,late1_early2_ttest_SNc.ci,late1_early2_ttest_SNc.stats] = ttest(pos1_baselines_SNc,pos2_baselines_SNc);




% EARLY / LATE PAIRS ===================================================================================================================
	pos1 = trials_with_early;
	pos2 = trials_with_late;
	pairs = 1;
	pos1_positions = [];
	pos2_positions = [];

	for i_early = 1:length(trials_with_early)
	    if find(trials_with_late==trials_with_early(i_early)+1)
	%         pos2_pair_positions = find(trials_with_late==trials_with_early(i_early)+1); % an array that looks like [0,0,0,2,0,6] where 0 indicates that pos1 is first, ~=0 is the position in pos2 that comes next
	        pos1_positions(pairs) = pos1(i_early); % an array that looks like [4,6] - it's the trials where pos1 comes first. This is all we need. The trials where pos2 comes second are pos1_pair_positions + 1
	        pos2_positions(pairs) = pos1(i_early) + 1;
	        pairs = pairs + 1;
	    end
	end

	% now we want the pairs to be paired for t-tests. Do in 2 (npairs, 1) vectors
	pos1_baselines_SNc = nan(length(pos1_positions),1);
	pos2_baselines_SNc = nan(length(pos2_positions),1);

	pos1_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos1_positions);
	pos2_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos2_positions);



	pos1_baselines_DLS = nan(length(pos1_positions),1);
	pos2_baselines_DLS = nan(length(pos2_positions),1);

	pos1_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos1_positions);
	pos2_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos2_positions);

	colorpallet = {'bo', 'ro'}
	earlycolor = 1;
	latecolor = 2;

	figure,
	ax1 = subplot(1, 2, 1);
	plot(pos1_positions, pos1_baselines_DLS,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_DLS,colorpallet{latecolor})
	title('DLS')

	ax2 = subplot(1, 2, 2);
	plot(pos1_positions, pos1_baselines_SNc,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_SNc,colorpallet{latecolor})
	title('SNc')

	SNc_div = pos1_baselines_SNc ./ pos2_baselines_SNc;
	DLS_div = pos1_baselines_DLS ./ pos2_baselines_DLS;

	figure,
	ax3 = subplot(1, 2, 1);
	plot(pos1_positions, DLS_div,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [1,1], 'k-', 'linewidth', 3)
	title('DLS div (centered on pos1')
	ylabel('Early Baseline / Late Baseline')
	xlabel('Trial #')

	ax4 = subplot(1, 2, 2);
	plot(pos1_positions, SNc_div,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [1,1], 'k-', 'linewidth', 3)
	title('SNc div')
	ylabel('Early Baseline / Late Baseline')
	xlabel('Trial #')


	figure,
	ax5 = subplot(1, 2, 1);
	plot(zeros(size(DLS_div)), DLS_div,colorpallet{earlycolor})
	hold on
	plot([-1,1], [1,1], 'k-', 'linewidth', 3)
	title('DLS div (centered on 0')
	ylabel('Early Baseline / Late Baseline')

	ax6 = subplot(1, 2, 2);
	plot(zeros(size(SNc_div)), SNc_div,colorpallet{earlycolor})
	hold on
	plot([-1,1], [1,1], 'k-', 'linewidth', 3)
	title('SNc div')
	ylabel('Early Baseline / Late Baseline')

	linkaxes([ax3, ax5], 'y')
	linkaxes([ax4, ax6], 'y')



	div_early1_late2_ttest_DLS = {};
	div_early1_late2_ttest_SNc = {};
	[div_early1_late2_ttest_DLS.h,div_early1_late2_ttest_DLS.p,div_early1_late2_ttest_DLS.ci,div_early1_late2_ttest_DLS.stats] = ttest(pos1_baselines_DLS,pos2_baselines_DLS);
	[div_early1_late2_ttest_SNc.h,div_early1_late2_ttest_SNc.p,div_early1_late2_ttest_SNc.ci,div_early1_late2_ttest_SNc.stats] = ttest(pos1_baselines_SNc,pos2_baselines_SNc);






% LATE / EARLY PAIRS =================================================================================================================== 
	pos1 = trials_with_late;
	pos2 = trials_with_early;
	pairs = 1;
	pos1_positions = [];
	pos2_positions = [];

	for i_early = 1:length(pos1)
	    if find(pos2==pos1(i_early)+1)
	%         pos2_pair_positions = find(pos2==pos1(i_early)+1); % an array that looks like [0,0,0,2,0,6] where 0 indicates that pos1 is first, ~=0 is the position in pos2 that comes next
	        pos1_positions(pairs) = pos1(i_early); % an array that looks like [4,6] - it's the trials where pos1 comes first. This is all we need. The trials where pos2 comes second are pos1_pair_positions + 1
	        pos2_positions(pairs) = pos1(i_early) + 1;
	        pairs = pairs + 1;
	    end
	end

	% now we want the pairs to be paired for t-tests. Do in 2 (npairs, 1) vectors
	pos1_baselines_SNc = nan(length(pos1_positions),1);
	pos2_baselines_SNc = nan(length(pos2_positions),1);

	pos1_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos1_positions);
	pos2_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos2_positions);



	pos1_baselines_DLS = nan(length(pos1_positions),1);
	pos2_baselines_DLS = nan(length(pos2_positions),1);

	pos1_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos1_positions);
	pos2_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos2_positions);


	figure,
	ax7 = subplot(1, 2, 1);
	plot(pos1_positions, pos1_baselines_DLS,colorpallet{latecolor})
	hold on
	plot(pos2_positions, pos2_baselines_DLS,colorpallet{earlycolor})
	title('DLS')

	ax8 = subplot(1, 2, 2);
	plot(pos1_positions, pos1_baselines_SNc,colorpallet{latecolor})
	hold on
	plot(pos2_positions, pos2_baselines_SNc,colorpallet{earlycolor})
	title('SNc')

	SNc_div = pos1_baselines_SNc ./ pos2_baselines_SNc;
	DLS_div = pos1_baselines_DLS ./ pos2_baselines_DLS;

	figure,
	ax9 = subplot(1, 2, 1);
	plot(pos1_positions, DLS_div,colorpallet{latecolor})
	hold on
	plot([0,num_trials], [1,1], 'k-', 'linewidth', 3)
	title('DLS div (centered on pos1')
	ylabel('LATE Baseline / EARLY Baseline')
	xlabel('Trial #')
	% ylim([-.012, .012])

	ax10 = subplot(1, 2, 2);
	plot(pos1_positions, SNc_div,colorpallet{latecolor})
	hold on
	plot([0,num_trials], [1,1], 'k-', 'linewidth', 3)
	title('SNc div')
	ylabel('LATE Baseline / EARLY Baseline')
	xlabel('Trial #')
	% ylim([-.1, .1])


	figure,
	ax11 = subplot(1, 2, 1);
	plot(zeros(size(DLS_div)), DLS_div,colorpallet{latecolor})
	hold on
	plot([-1,1], [1,1], 'k-', 'linewidth', 3)
	title('DLS div (centered on 0')
	ylabel('LATE Baseline / EARLY Baseline')

	ax12 = subplot(1, 2, 2);
	plot(zeros(size(SNc_div)), SNc_div,colorpallet{latecolor})
	hold on
	plot([-1,1], [1,1], 'k-', 'linewidth', 3)
	title('SNc div')
	ylabel('LATE Baseline / EARLY Baseline')

	linkaxes([ax9, ax11], 'y')
	linkaxes([ax10, ax12], 'y')


	div_late1_early2_ttest_DLS = {};
	div_late1_early2_ttest_SNc = {};
	[div_late1_early2_ttest_DLS.h,div_late1_early2_ttest_DLS.p,div_late1_early2_ttest_DLS.ci,div_late1_early2_ttest_DLS.stats] = ttest(pos1_baselines_DLS,pos2_baselines_DLS);
	[div_late1_early2_ttest_SNc.h,div_late1_early2_ttest_SNc.p,div_late1_early2_ttest_SNc.ci,div_late1_early2_ttest_SNc.stats] = ttest(pos1_baselines_SNc,pos2_baselines_SNc);






%%%%%%% For Late-Late comparisons:

% LATE - LATE PAIRS ===================================================================================================================
	pos1 = trials_with_late;
	pos2 = trials_with_late;
	pairs = 1;
	pos1_positions = [];
	pos2_positions = [];

	for i_early = 1:length(pos1)
	    if find(pos2==pos1(i_early)+1)
	%         pos2_pair_positions = find(pos2==pos1(i_early)+1); % an array that looks like [0,0,0,2,0,6] where 0 indicates that pos1 is first, ~=0 is the position in pos2 that comes next
	        pos1_positions(pairs) = pos1(i_early); % an array that looks like [4,6] - it's the trials where pos1 comes first. This is all we need. The trials where pos2 comes second are pos1_pair_positions + 1
	        pos2_positions(pairs) = pos1(i_early) + 1;
	        pairs = pairs + 1;
	    end
	end

	% now we want the pairs to be paired for t-tests. Do in 2 (npairs, 1) vectors
	pos1_baselines_SNc = nan(length(pos1_positions),1);
	pos2_baselines_SNc = nan(length(pos2_positions),1);

	pos1_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos1_positions);
	pos2_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos2_positions);



	pos1_baselines_DLS = nan(length(pos1_positions),1);
	pos2_baselines_DLS = nan(length(pos2_positions),1);

	pos1_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos1_positions);
	pos2_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos2_positions);

	colorpallet = {'r.', 'ro'}
	earlycolor = 1;
	latecolor = 2;

	figure,
	ax1 = subplot(1, 2, 1);
	plot(pos1_positions, pos1_baselines_DLS,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_DLS,colorpallet{latecolor})
	title('DLS late-late')

	ax2 = subplot(1, 2, 2);
	plot(pos1_positions, pos1_baselines_SNc,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_SNc,colorpallet{latecolor})
	title('SNc late-late')

	SNc_del = pos1_baselines_SNc - pos2_baselines_SNc;
	DLS_del = pos1_baselines_DLS - pos2_baselines_DLS;

	figure,
	ax3 = subplot(1, 2, 1);
	plot(pos1_positions, DLS_del,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [0,0], 'k-', 'linewidth', 3)
	title('DLS del (centered on pos1')
	ylabel('Late Baseline - Late Baseline')
	xlabel('Trial #')
	ylim([-.012, .012])

	ax4 = subplot(1, 2, 2);
	plot(pos1_positions, SNc_del,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [0,0], 'k-', 'linewidth', 3)
	title('SNc del')
	ylabel('Late Baseline - Late Baseline')
	xlabel('Trial #')
	ylim([-.1, .1])


	figure,
	ax5 = subplot(1, 2, 1);
	plot(zeros(size(DLS_del)), DLS_del,colorpallet{earlycolor})
	hold on
	plot([-1,1], [0,0], 'k-', 'linewidth', 3)
	title('DLS del (centered on 0')
	ylabel('Late Baseline - Late Baseline')

	ax6 = subplot(1, 2, 2);
	plot(zeros(size(SNc_del)), SNc_del,colorpallet{earlycolor})
	hold on
	plot([-1,1], [0,0], 'k-', 'linewidth', 3)
	title('SNc del')
	ylabel('Late Baseline - Late Baseline')

	linkaxes([ax3, ax5], 'y')
	linkaxes([ax4, ax6], 'y')



	del_late1_late2_ttest_DLS = {};
	del_late1_late2_ttest_SNc = {};
	[del_late1_late2_ttest_DLS.h,del_late1_late2_ttest_DLS.p,del_late1_late2_ttest_DLS.ci,del_late1_late2_ttest_DLS.stats] = ttest(pos1_baselines_DLS,pos2_baselines_DLS);
	[del_late1_late2_ttest_SNc.h,del_late1_late2_ttest_SNc.p,del_late1_late2_ttest_SNc.ci,del_late1_late2_ttest_SNc.stats] = ttest(pos1_baselines_SNc,pos2_baselines_SNc);







% LATE / LATE PAIRS ===================================================================================================================
	pos1 = trials_with_late;
	pos2 = trials_with_late;
	pairs = 1;
	pos1_positions = [];
	pos2_positions = [];

	for i_early = 1:length(pos1)
	    if find(pos2==pos1(i_early)+1)
	%         pos2_pair_positions = find(pos2==pos1(i_early)+1); % an array that looks like [0,0,0,2,0,6] where 0 indicates that pos1 is first, ~=0 is the position in pos2 that comes next
	        pos1_positions(pairs) = pos1(i_early); % an array that looks like [4,6] - it's the trials where pos1 comes first. This is all we need. The trials where pos2 comes second are pos1_pair_positions + 1
	        pos2_positions(pairs) = pos1(i_early) + 1;
	        pairs = pairs + 1;
	    end
	end

	% now we want the pairs to be paired for t-tests. Do in 2 (npairs, 1) vectors
	pos1_baselines_SNc = nan(length(pos1_positions),1);
	pos2_baselines_SNc = nan(length(pos2_positions),1);

	pos1_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos1_positions);
	pos2_baselines_SNc(:,1) = pre_trial_baselines_SNc(pos2_positions);



	pos1_baselines_DLS = nan(length(pos1_positions),1);
	pos2_baselines_DLS = nan(length(pos2_positions),1);

	pos1_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos1_positions);
	pos2_baselines_DLS(:,1) = pre_trial_baselines_DLS(pos2_positions);

	colorpallet = {'r.', 'ro'}
	earlycolor = 1;
	latecolor = 2;

	figure,
	ax1 = subplot(1, 2, 1);
	plot(pos1_positions, pos1_baselines_DLS,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_DLS,colorpallet{latecolor})
	title('DLS late/late')

	ax2 = subplot(1, 2, 2);
	plot(pos1_positions, pos1_baselines_SNc,colorpallet{earlycolor})
	hold on
	plot(pos2_positions, pos2_baselines_SNc,colorpallet{latecolor})
	title('SNc late/late')

	SNc_div = pos1_baselines_SNc ./ pos2_baselines_SNc;
	DLS_div = pos1_baselines_DLS ./ pos2_baselines_DLS;

	figure,
	ax3 = subplot(1, 2, 1);
	plot(pos1_positions, DLS_div,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [1,1], 'k-', 'linewidth', 3)
	title('DLS div (centered on pos1')
	ylabel('Late Baseline / Late Baseline')
	xlabel('Trial #')

	ax4 = subplot(1, 2, 2);
	plot(pos1_positions, SNc_div,colorpallet{earlycolor})
	hold on
	plot([0,num_trials], [1,1], 'k-', 'linewidth', 3)
	title('SNc div')
	ylabel('Late Baseline / Late Baseline')
	xlabel('Trial #')


	figure,
	ax5 = subplot(1, 2, 1);
	plot(zeros(size(DLS_div)), DLS_div,colorpallet{earlycolor})
	hold on
	plot([-1,1], [1,1], 'k-', 'linewidth', 3)
	title('DLS div (centered on 0')
	ylabel('Late Baseline / Late Baseline')

	ax6 = subplot(1, 2, 2);
	plot(zeros(size(SNc_div)), SNc_div,colorpallet{earlycolor})
	hold on
	plot([-1,1], [1,1], 'k-', 'linewidth', 3)
	title('SNc div')
	ylabel('Late Baseline / Late Baseline')

	linkaxes([ax3, ax5], 'y')
	linkaxes([ax4, ax6], 'y')



	div_late1_late2_ttest_DLS = {};
	div_late1_late2_ttest_SNc = {};
	[div_late1_late2_ttest_DLS.h,div_late1_late2_ttest_DLS.p,div_late1_late2_ttest_DLS.ci,div_late1_late2_ttest_DLS.stats] = ttest(pos1_baselines_DLS,pos2_baselines_DLS);
	[div_late1_late2_ttest_SNc.h,div_late1_late2_ttest_SNc.p,div_late1_late2_ttest_SNc.ci,div_late1_late2_ttest_SNc.stats] = ttest(pos1_baselines_SNc,pos2_baselines_SNc);





