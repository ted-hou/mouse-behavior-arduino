%% handler_save_gfits_to_header.m-------------------------------------------------------------------
% 
% 	Created 	12-8-17 ahamilos (roadmap v1_3)
% 	Modified 	12-8-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-8-17: Tired of program crashing and losing the most critical part
%% -------------------------------------------------------------------------------------------

	gfit_struct_name = genvarname(['d', daynum_, '_gfit_struct']);
    eval([gfit_struct_name '.gfit_SNc = gfit_SNc;']);
    eval([gfit_struct_name '.gfit_VTA = gfit_VTA;']);
    eval([gfit_struct_name '.gfit_DLS = gfit_DLS;']);
    eval([gfit_struct_name '.gfit_SNcred = gfit_SNcred;']);
    eval([gfit_struct_name '.gfit_VTAred = gfit_VTAred;']);
    eval([gfit_struct_name '.gfit_DLSred = gfit_DLSred;']);
    eval([gfit_struct_name '.X_values = X_values;']);
    eval([gfit_struct_name '.Y_values = Y_values;']);
    eval([gfit_struct_name '.Z_values = Z_values;']);
    eval([gfit_struct_name '.EMG_values = EMG_values;']);

    eval([gfit_struct_name '.SNc_values_by_trial = SNc_values_by_trial;']);
    eval([gfit_struct_name '.DLS_values_by_trial = DLS_values_by_trial;']);
    eval([gfit_struct_name '.VTA_values_by_trial = VTA_values_by_trial;']);
    eval([gfit_struct_name '.SNcred_values_by_trial = SNcred_values_by_trial;']);
    eval([gfit_struct_name '.DLSred_values_by_trial = DLSred_values_by_trial;']);
    eval([gfit_struct_name '.VTAred_values_by_trial = VTAred_values_by_trial;']);
    eval([gfit_struct_name '.X_values_by_trial = X_values_by_trial;']);
    eval([gfit_struct_name '.Y_values_by_trial = Y_values_by_trial;']);
    eval([gfit_struct_name '.Z_values_by_trial = Z_values_by_trial;']);
    eval([gfit_struct_name '.EMG_values_by_trial = EMG_values_by_trial;']);
	gfit_filename = ['gfits_', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(gfit_filename, gfit_struct_name, '-v7.3');