%% Test cases for first lick grabber - use for code validation and debugging
% 
%  Created   7-24-17 ahamilos
%  Modified  7-24-17 ahamilos
% 
% Validation History:
% 
% 	7-24-17: Validated first_lick_grabber_hyb
% 					   first_lick_grabber_operant_fx
% 					   first_lick_grabber_operant_fx_300msv
% 					   first_lick_grabber_operant_fx_0msv
% 


%% Dummy test code:
dummy_lick_times_by_trial = [0.100, 0.110,0.115,0.130,4.000,4.200,    0,0,0, 0;...
							     0,     0,    0,    0,    0,    0,    0,0,0, 0;...
							 0.490, 0.500,0.550,2.100,5.200,8.100,    0,0,0, 0;...
							 2.510, 2.520,2.530,2.540,6.100,    0,    0,0,0, 0;...
							 0.120, 3.334,3.308,3.330,6.100,6.200,7.510,8,9,10;...
							 0.250, 10.51,10.53,10.56,11.50,17.11,    0,0,0, 0;...
							 5.610, 5.630,5.660,5.690,6.120,6.200,6.220,8,0, 0;...
							 0.290, 0.300,0.301,2.500,5.100,    0,    0,0,0, 0] + 1.5;
	 % All lick_times_by_trial are lick time wrt cue + 1.5 sec



% Hybrid Test Case, 500 ms:
[f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_pavlovian, f_lick_ITI,...
trials_with_rxn, trials_with_rxn_fail, trials_with_pav, trials_with_ITI, all_first_licks] = first_lick_grabber_hyb(dummy_lick_times_by_trial, 7)
% Correct interpretations-------------------------------------------------
% Hybrid, 500ms rxn:
% Rxn 			= 1,3,5,6		   [1.6, 0, 1.99,   0, 1.62, 1.75,    0]
% Rxn trainabort= 3 (train abort)  [  0, 0, 2.05,   0,    0,    0,    0]  % note that 500ms is included in rxn ok, it's >500 that is not
% Op, no rew 	= 4                [  0, 0,    0,4.01,    0,    0,    0]  % note that 3333ms is not rewarded, 5100 is not pav. it's included in the prior range
% Op, rew 		= 1,5              [5.5, 0,    0,   0,4.834,    0,    0]
% Pav           = 7                [  0, 0,    0,   0,    0,    0, 7.11]
% ITI 			= 6 			   [  0, 0,    0,   0,    0,12.01,    0]
% 
% Validated 7-24-17



% Operant Test Case, 500 ms:
[f_lick_rxn, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_train, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx(dummy_lick_times_by_trial, 7);
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



% Operant Test Case, 300 ms:
[f_lick_rxn, f_lick_rxn_fail, f_lick_rxn_abort, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_train, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx_300msv(dummy_lick_times_by_trial, 8);
% Correct interpretations-------------------------------------------------
% Hybrid, 500ms rxn:
% Rxn 			= 1,3,5,6		   [1.6, 0, 1.99,   0, 1.62, 1.75,    0, 1.790]
% Rxn fail 		= 3 (fail)         [  0, 0, 1.99,   0,    0,    0,    0,     0]
% Rxn trainabort= 8 (train)        [  0, 0,    0,   0,    0,    0,    0, 1.801]
% Op, no rew 	= 4                [  0, 0,    0,4.01,    0,    0,    0,     0]
% Op, rew 		= 1,5,7            [5.5, 0,    0,   0,4.834,    0, 7.11,     0]
% Pav           = n/a              [                                          ]
% ITI 			= 6                [  0, 0,    0,   0,    0,12.01,    0,     0]
% 
% Validated 7-24-17



% Operant Test Case, 0 ms:
[f_lick_rxn, f_lick_operant_no_rew, f_lick_operant_rew, f_lick_ITI, trials_with_rxn, trials_with_ITI, all_first_licks] = first_lick_grabber_operant_fx_0msv(dummy_lick_times_by_trial, 8);
% Correct interpretations-------------------------------------------------
% Hybrid, 500ms rxn:
% Rxn(fail)     = 1,3,5,6		   [1.6, 0, 1.99,   0, 1.62, 1.75,    0, 1.790]
% Op, no rew 	= 4                [  0, 0,    0,4.01,    0,    0,    0,     0]
% Op, rew 		= 1,5,7            [  0, 0,    0,   0,    0,    0, 7.11,     0]
% Pav           = n/a              [                                          ]
% ITI 			= 6                [  0, 0,    0,   0,    0,    0,    0,     0]
% 
% Validated 7-24-17