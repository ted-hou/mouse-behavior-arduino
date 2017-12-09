%% backfill_handler_roadmap1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-5-17: Got rid of fill-ins that aren't saved - no need to take up space with this
%% ------------------------------------------------------------------------------------------- (section validated 12/5/17)


if dls_on
    [~,~,~, DLS_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(DLS_values_by_trial, DLS_ex_values_by_trial, num_trials);
    % [DLS_values_by_trial_fi, DLS_ex_values_by_trial_fi,DLS_values_by_trial_fi_trim, DLS_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(DLS_values_by_trial, DLS_ex_values_by_trial, num_trials);
else
    % DLS_values_by_trial_fi = [];
    % DLS_ex_values_by_trial_fi = [];
    % DLS_values_by_trial_fi_trim = [];
    DLS_ex_values_by_trial_fi_trim = [];
end


if snc_on
	[~,~,~, SNc_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(SNc_values_by_trial, SNc_ex_values_by_trial, num_trials);
else
    % SNc_values_by_trial_fi = [];
    % SNc_ex_values_by_trial_fi = [];
    % SNc_values_by_trial_fi_trim = [];
    SNc_ex_values_by_trial_fi_trim = [];
end


if vta_on
	[~,~,~, VTA_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(VTA_values_by_trial, VTA_ex_values_by_trial, num_trials);
else
    % VTA_values_by_trial_fi = [];
    % VTA_ex_values_by_trial_fi = [];
    % VTA_values_by_trial_fi_trim = [];
    VTA_ex_values_by_trial_fi_trim = [];
end


if dlsred_on
    [~,~,~, DLSred_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(DLSred_values_by_trial, DLSred_ex_values_by_trial, num_trials);
else
    % DLSred_values_by_trial_fi = [];
    % DLSred_ex_values_by_trial_fi = [];
    % DLSred_values_by_trial_fi_trim = [];
    DLSred_ex_values_by_trial_fi_trim = [];
end


if sncred_on
    [~, ~,~, SNcred_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(SNcred_values_by_trial, SNcred_ex_values_by_trial, num_trials);
else
    % SNcred_values_by_trial_fi = [];
    % SNcred_ex_values_by_trial_fi = [];
    % SNcred_values_by_trial_fi_trim = [];
    SNcred_ex_values_by_trial_fi_trim = [];
end


if vtared_on
    [~, ~,~, VTAred_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(VTAred_values_by_trial, VTAred_ex_values_by_trial, num_trials);
else
    % VTAred_values_by_trial_fi = [];
    % VTAred_ex_values_by_trial_fi = [];
    % VTAred_values_by_trial_fi_trim = [];
    VTAred_ex_values_by_trial_fi_trim = [];
end


if x_on && y_on && z_on
	[~,~,~, X_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(X_values_by_trial, X_ex_values_by_trial, num_trials);
    [~,~,~, Y_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(Y_values_by_trial, Y_ex_values_by_trial, num_trials);
    [~,~,~, Z_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(Z_values_by_trial, Z_ex_values_by_trial, num_trials);
else
    % X_values_by_trial_fi = [];
    % X_ex_values_by_trial_fi = [];
    % X_values_by_trial_fi_trim = [];
    X_ex_values_by_trial_fi_trim = [];
    
    % Y_values_by_trial_fi = [];
    % Y_ex_values_by_trial_fi = [];
    % Y_values_by_trial_fi_trim = [];
    Y_ex_values_by_trial_fi_trim = [];
    
    % Z_values_by_trial_fi = [];
    % Z_ex_values_by_trial_fi = [];
    % Z_values_by_trial_fi_trim = [];
    Z_ex_values_by_trial_fi_trim = [];
end
    
if emg_on
	[~, ~,~, EMG_ex_values_by_trial_fi_trim] = fill_in_nans_from_back_fx(EMG_values_by_trial, EMG_ex_values_by_trial, num_trials);
else
    % EMG_values_by_trial_fi = [];
    % EMG_ex_values_by_trial_fi = [];
    % EMG_values_by_trial_fi_trim = [];
    EMG_ex_values_by_trial_fi_trim = [];
end

