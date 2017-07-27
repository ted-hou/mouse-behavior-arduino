%% Test cases for time_binner_fx - use for code validation and debugging
% 
%  Created   7-24-17 ahamilos
%  Modified  7-25-17 ahamilos
% 
% Validation History:
% 
% 	7-24-17: full check-through of sorting and binning for time_binner_fx_500ms (operant)
% 			 also did time_binner_fx_300ms (operant)
% 			 also did time_binner_fx_0ms (operant)
% 
% 	7-25-17: also did time_binner_fx_hyb
% 


%% Dummy test code:
dummy_lick_times_by_trial = [0.100, 0.110,0.115,0.130,4.000,4.200,    0,0,0, 0;...   % 1  rxnok(130) + operant
							     0,     0,    0,    0,    0,    0,    0,0,0, 0;...   % 2  no lick
							 0.490, 0.500,0.550,2.100,5.200,8.100,    0,0,0, 0;...   % 3  rxn train abort (500) + early + pav + ITI
							 2.510, 2.520,2.530,2.540,6.100,    0,    0,0,0, 0;...   % 4  early + pav
							 0.120, 3.334,3.308,3.330,6.100,6.200,7.510,8,9,10;...   % 5  rxnok(120) + op + pav + ITI
							 0.250, 10.51,10.53,10.56,11.50,17.11,    0,0,0, 0;...   % 6  rxnok(250) + ITI
							 5.610, 5.630,5.660,5.690,6.120,6.200,6.220,8,0, 0;...   % 7  pav + ITI
							 0.290, 0.300,0.301,2.500,5.100,    0,    0,0,0, 0;...   % 8  rxnok(290) + early + op
							 3.334, 3.354,3.368,3.370,6.100,6.200,7.510,8,9,10;...   % 9  op + pav + ITI
							 2.981, 2.990,3.000,10.56,11.50,17.11,    0,0,0, 0;...   % 10 early + ITI
							 1.991, 2.500,3.000,5.690,6.120,6.200,6.220,8,0, 0;...   % 11 early + pav + ITI
							 2.200, 2.300,2.400,2.500,5.100,    0,    0,0,0, 0;...   % 12 early + op
							 2.555, 2.600,2.710,3.330,6.100,6.200,7.510,8,9,10;...   % 13 early + pav + ITI
							 2.799, 4.000,10.53,10.56,11.50,17.11,    0,0,0, 0;...   % 14 early + op + ITI
							 4.111, 4.300,5.660,5.690,6.120,6.200,6.220,8,0, 0;...   % 15 op + pav + ITI
							 6.500, 7.300,7.301,8.500,9.100,    0,    0,0,0, 0] + 1.5; % 16 pav + ITI
	 % All lick_times_by_trial are lick time wrt cue + 1.5 sec

	 DLS_values_by_trial = [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1];
	 SNc_values_by_trial = [1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1];

% 16 trials:

%% Operant Test Case, 500 ms:-----------------------------------------------------------------------------------
	[f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_train, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx(dummy_lick_times_by_trial, 16);
	% now run time_binner_fx_500op

	% Operant Rewarded Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	 0	 0   0	 0	 0	4.834	4.834	5.5	 5.611	7.11	 8];
	trial_positions = [2	3	4	6	8	10	11	12	13	14	    5	    9	  1	    15	   7	16];
	% all this is correct
	total_time_across_bins = 3.6670 %(should be 7000-3333 - verified 3667)
	time_in_ea_bin = 0.7334 %(verified 733.4)
	% thus, the bin edges are 3333, 4066.4, 4799.8, 5533.2, 6266.6, 7000 + 1500
	% bin 1: 4.83 - 5.57: good  
	% bin 2: 5.57 - 6.30: good
	% bin 3: 6.30 - 7.03: good
	% bin 4: 7.03 - 7.77: good
	% bin 5: 7.77 - 8.50: good!
	DLS_binned_trial_positions = {[5,9,1]	15	[]	7	16}



	% Operant No Reward Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	0	0	0	 0	 0	3.491	 3.7	4	4.01	4.055	4.299	4.481];
		trial_positions = [1	2	3	5	6	7	9	15	16	   11	  12	8	   4	   13	   14	   10];
		% all this is correct
		total_time_across_bins = 2.6330 %(should be 3333-700 - verified 2633)
		time_in_ea_bin = 0.5266 %(verified 526.6)
		% thus, the bin edges are 700, 1226.6, 1753.2, 2279.8, 2806.4, 3333 + 1500
		% bin 1:  2.2 - 2.73:  likely ok
		% bin 2: 2.73 - 3.25:  likely ok
		% bin 3: 3.25 - 3.78:  good
		% bin 4: 3.78 - 4.31:  good
		% bin 5: 4.31 - 4.83:  good!
		SNc_binned_trial_positions = []	[]	[11,12]	[8,4,13,14]	10
		% binning looks appropriate. 

		% note that to match the designations from first_lick_grabber, the ranges should be (min, max] - Updated code to reflect this edge case (7-24-17, all 4 files)



		% Rxn Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	 0	 0	 0	 0	 0	 0	 0	1.6	  1.62	1.75	1.79	1.99];
		trial_positions = [2	4	7	9	10	11	12	13	14	15	16	  1	     5	   6	   8	   3];
		% all this is correct


		% Rxn Train Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	0	0	0	0	 0	 0	 0	 0	 0	 0	 0	2.05];
		trial_positions = [1	2	4	5	6	7	8	9	10	11	12	13	14	15	16	   3];
		% all this is correct


		% ITI Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	0	0	0	0	 0	 0	 0	 0	 0	 0	 0	12.01];
		trial_positions = [1	2	3	4	5	7	8	9	10	11	12	13	14	15	16	    6];
		% all this is correct


		% Test Case, 500 ms:

		% Correct interpretations-------------------------------------------------
		% Hybrid, 500ms rxn:
		% Rxn 			= 1,3,5,6		   [1.6, 0, 1.99,   0, 1.62, 1.75,    0]
		% Rxn trainabort= 3 (train abort)  [  0, 0, 2.05,   0,    0,    0,    0]
		% Op, no rew 	= 4                [  0, 0,    0,4.01,    0,    0,    0]
		% Op, rew 		= 1,5,7            [5.5, 0,    0,   0,4.834,    0, 7.11]
		% Pav           = n/a              [                                   ]
		% ITI 			= 6                [  0, 0,    0,   0,    0,12.01,    0]
		% 
		% Validated 7-24-17

%% Operant Test Case, 300 ms:-----------------------------------------------------------------------------------
	[f_lick_rxn, f_lick_rxn_fail, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, ~, ~, ~, all_first_licks] = first_lick_grabber_operant_fx_300msv(dummy_lick_times_by_trial, 16);
	% now run time_binner_fx_300op

	% Operant Rewarded Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	4.834	4.834	5.5		5.611	7.11	 8];
	trial_positions = [2	3	4	6	8	10	11	12	13	14		5	    9	  1	   	   15	   7	16];
	% all this is correct, same as 500msv
	total_time_across_bins = 3.6670 %(should be 7000-3333 - verified 3667)
	time_in_ea_bin = 0.7334 %(verified 733.4)
	% thus, the bin edges are 3333, 4066.4, 4799.8, 5533.2, 6266.6, 7000 + 1500
	% bin 1: 4.83 - 5.57: good  
	% bin 2: 5.57 - 6.30: good
	% bin 3: 6.30 - 7.03: good
	% bin 4: 7.03 - 7.77: good
	% bin 5: 7.77 - 8.50: good
	DLS_binned_trial_positions = {[5,9,1]	15	[]	7	16} % correct



	% Operant No Reward Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	3.491	3.7	  4.01	4.055	4.299	4.481];
	trial_positions = [1	2	3	5	6	7	8	9	15	16	   11	 12      4	   13	   14	   10];
	% all this is correct. only trial 8 is newly excluded
	% total_time_across_bins = 2.8330 %(should be 3333-500 - verified 2833)
	% time_in_ea_bin = 0.5666 %(verified 566.6)
	% thus, the bin edges are 500, 1066.6, 1633.2, 2199.8, 2766.4, 3333 + 1500
	% bin 1:     2  - 2.57: good
	% bin 2:  2.57  - 3.13: good
	% bin 3:  3.13  - 3.669: yes - 12 is close to bound is over
	% bin 4:  3.669 - 4.2664: good
	% bin 5: 4.2664 - 4.83: yes!
	% SNc_binned_trial_positions = {[]	[]	11	[12,4,13]	[14,10]}  % only difference is 8 now excluded, correct
	% % binning looks appropriate. - rechecked 7-25-17




	% Rxn Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	 0	 0	 0	 0	 0	 0	 0	1.6	  1.62	1.75	1.79	1.99]; % same as 500msv
	trial_positions = [2	4	7	9	10	11	12	13	14	15	16	  1	     5	   6	   8	   3]; % same as 500msv
	% all this is correct


	% Rxn Train Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1.801]; %indeed this is the first run over into 300ms
	trial_positions = [1	2	3	4	5	6	7	9	10	11	12	13	14	15	16	    8]; %correctly different. now 8 is the train, 3 is not a train, it's just not included because is too close to cue - is rxn range trial with failure
	% all this is correct


	% ITI Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	 0	 0	 0	 0	 0	 0	 0	12.01]; % same as 500msv
	trial_positions = [1	2	3	4	5	7	8	9	10	11	12	13	14	15	16	    6]; % good
	% all this is correct


	% Operant Test Case, 300 ms:

	% Correct interpretations-------------------------------------------------
	% Operant, 300ms rxn:
	% Rxn 			= 1,3,5,6		   [1.6, 0, 1.99,   0, 1.62, 1.75,    0, 1.790]
	% Rxn fail 		= 3 (fail)         [  0, 0, 1.99,   0,    0,    0,    0,     0]
	% Rxn trainabort= 8 (train)        [  0, 0,    0,   0,    0,    0,    0, 1.801]
	% Op, no rew 	= 4                [  0, 0,    0,4.01,    0,    0,    0,     0]
	% Op, rew 		= 1,5,7            [5.5, 0,    0,   0,4.834,    0, 7.11,     0]
	% Pav           = n/a              [                                          ]
	% ITI 			= 6                [  0, 0,    0,   0,    0,12.01,    0,     0]
	% 
	% Validated 7-24-1

%% Operant Test Case, 0 ms:-------------------------------------------------------------------------------------
	[f_lick_rxn, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx_0msv(dummy_lick_times_by_trial, 16);
	% now run time_binner_fx_0op

	% Operant Rewarded Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	4.834	4.834	5.5		5.611	7.11	 8]; % correctly excludes any trials with rxns
	trial_positions = [1	2	3	4	5	6	8	10	11	12	   13	   14	  9	       15	   7	16];
	% all this is correct
	total_time_across_bins = 3.6670 %(should be 7000-3333 - verified 3667)
	time_in_ea_bin = 0.7334 %(verified 733.4)
	% thus, the bin edges are 3333, 4066.4, 4799.8, 5533.2, 6266.6, 7000 + 1500
	% bin 1: 4.83 - 5.57: good  
	% bin 2: 5.57 - 6.30: good
	% bin 3: 6.30 - 7.03: good
	% bin 4: 7.03 - 7.77: good
	% bin 5: 7.77 - 8.50: good
	DLS_binned_trial_positions = {9	 15	[]	7	16} % correct



	% Operant No Reward Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	3.491	3.7	  4.01	4.055	4.299	4.481]; % same as 300ms case - any rxn aborts dont go in this category anyway
	trial_positions = [1	2	3	5	6	7	8	9	15	16	   11	 12      4	   13	   14	   10];
	% all this is correct. only trial 8 is newly excluded
	total_time_across_bins = 2.8330 %(should be 500-3333 - verified 2833) - it's different from the 500 case
	time_in_ea_bin = 0.5666 %(verified 566.6)
	% thus, the bin edges are 500, 1066.6, 1633.2, 2199.8, 2766.4, 3333 + 1500
	% bin 1:     2  - 2.57: good
	% bin 2:  2.57  - 3.13: good
	% bin 3:  3.13  - 3.669: yes - 12 is close to bound is over
	% bin 4:  3.669 - 4.2664: good
	% bin 5: 4.2664 - 4.83: yes!
	SNc_binned_trial_positions = {[]	[]	11	[12,4,13]	[14,10]}  
	% binning looks appropriate. 




	% Rxn Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	 0	 0	 0	 0	 0	 0	 0	1.6	  1.62	1.75	1.79	1.99]; % same as 500msv
	trial_positions = [2	4	7	9	10	11	12	13	14	15	16	  1	     5	   6	   8	   3]; % same as 500msv
	% all this is correct for 0msv


	% Rxn Train Case: none for 0msv



	% ITI Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	 0	 0	 0	 0	 0	 0	 0	 0]; % correct - no ITI in this dataset
	trial_positions = [1	2	3	4	5	6	7	8	9	10	11	12	13	14	15	16]; % good
	% all this is correct for 0msv


	% Operant Test Case, 0 ms:

	% Correct interpretations-------------------------------------------------
	% Operant, 0ms rxn:
	% Rxn(fail)     = 1,3,5,6		   [1.6, 0, 1.99,   0, 1.62, 1.75,    0, 1.790]
	% Op, no rew 	= 4                [  0, 0,    0,4.01,    0,    0,    0,     0]
	% Op, rew 		= 1,5,7            [  0, 0,    0,   0,    0,    0, 7.11,     0]
	% Pav           = n/a              [                                          ]
	% ITI 			= 6                [  0, 0,    0,   0,    0,    0,    0,     0]
	% 
	% Validated 7-24-1

%--------!also check op 300 for ranges for no rew
%% Hybrid Test Case, 500 ms:-------------------------------------------------------------------------------------
	[f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,~,~,~,~, all_first_licks] = first_lick_grabber_hyb(dummy_lick_times_by_trial, 16)
	% now run time_binner_fx_hyb

	% Pavlovian Case:
	figure
	plot(sorted_times,trial_positions)
	
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	0	0	0	0	7.110	8]
	trial_positions = [1	2	3	4	5	6	8	9	10	11	12	13	14	15	7	   16]
	% all this is correct
	total_time_across_bins = 1.900 % (verified 7-25-17)
	time_in_ea_bin = 0.3800 % (0.3800 verified 7-25-17)
	% thus, the bin edges are 5100, 5480, 5860, 6240, 6620, 7000 + 1500
	% bin 1: 6.60 - 6.98  % ok?
	% bin 2: 6.98 - 7.36  % good
	% bin 3: 7.36 - 7.74  % ok?
	% bin 4: 7.74 - 8.12  % good
	% bin 5: 8.12 - 8.5   % ok!
	DLS_binned_trial_positions = {[]	7	[]	16	[]}
	% Found bug! 0.1 for pavlovian should be 100 because time in ms in the entry area. Fixed 7-25-17





	% Operant Rewarded Case:
	figure
	plot(sorted_times,trial_positions)
	% The times are indeed monotonically increasing. Also viewed to verify:
	sorted_times    = [0	0	0	0	0	0	0	0	0	0	0	0	4.834	4.834	5.5	  5.611];
	trial_positions = [2	3	4	6	7	8	10	11	12	13	14	16	5	    9	    1	     15];
	% all this is correct
	total_time_across_bins = 1.767 %(should be 3333-5100, 1767)
	time_in_ea_bin = 0.3534 %(should be 353.4)
	% thus, the bin edges are 3333, 3686.4, 4039.8, 4393.2, 4746.6, 5100 + 1500
	% bin 1: 4.80 - 5.19  % good
	% bin 2: 5.19 - 5.54  % good
	% bin 3: 5.54 - 5.90  % good
	% bin 4: 5.90 - 6.25  % ok
	% bin 5: 6.25 - 6.60  % ok
	DLS_binned_trial_positions = {[5,9]	1	15	[]	[]}
	% verified for hyb v



	% Operant No Reward Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	0	0	0	 0	 0	3.491	 3.7	4	4.01	4.055	4.299	4.481];
		trial_positions = [1	2	3	5	6	7	9	15	16	   11	  12	8	   4	   13	   14	   10];
		% all this is correct
		total_time_across_bins = 2.6330 %(should be 3333-700 - verified 2633)
		time_in_ea_bin = 0.5266 %(verified 526.6)
		% thus, the bin edges are 700, 1226.6, 1753.2, 2279.8, 2806.4, 3333 + 1500
		% bin 1:  2.2 - 2.73:  likely ok
		% bin 2: 2.73 - 3.25:  likely ok
		% bin 3: 3.25 - 3.78:  good
		% bin 4: 3.78 - 4.31:  good
		% bin 5: 4.31 - 4.83:  good!
		SNc_binned_trial_positions = []	[]	[11,12]	[8,4,13,14]	10
		% binning looks appropriate - verified for hyb version

		% note that to match the designations from first_lick_grabber, the ranges should be (min, max] - Updated code to reflect this edge case (7-24-17, all 4 files)



		% Rxn Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	 0	 0	 0	 0	 0	 0	 0	1.6	  1.62	1.75	1.79	1.99];
		trial_positions = [2	4	7	9	10	11	12	13	14	15	16	  1	     5	   6	   8	   3];
		% all this is correct for hyb


		% Rxn Train Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	0	0	0	0	 0	 0	 0	 0	 0	 0	 0	2.05];
		trial_positions = [1	2	4	5	6	7	8	9	10	11	12	13	14	15	16	   3];
		% all this is correct for hyb


		% ITI Case:
		figure
		plot(sorted_times,trial_positions)
		% The times are indeed monotonically increasing. Also viewed to verify:
		sorted_times    = [0	0	0	0	0	0	0	0	 0	 0	 0	 0	 0	 0	 0	12.01];
		trial_positions = [1	2	3	4	5	7	8	9	10	11	12	13	14	15	16	    6];
		% all this is correct for hyb


		% Whole set verified 7-25-17


