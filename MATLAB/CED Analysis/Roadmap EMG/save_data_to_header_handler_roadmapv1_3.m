%% save_data_to_header_handler_roadmapv1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-6-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-6-17: Updated for split up datasets by signal type
%% -------------------------------------------------------------------------------------------

answ = questdlg(['Warning - about to create header file called:                                        ',...
					 mousename_,...
					 ' Day ', daynum_,...
					 ' Header ', headernum_,...
					 ' roadmapv1_3 ',...
					 todaysdate2,'.txt                                       and                                     ',...
					 mousename_,...
					 '_day', daynum_,...
					 '_header', headernum_,...
					 '_roadmapv1_3_', todaysdate,...
					 '.mat                                              Check if exists - ok to overwrite?'],'Ready to Save?', 'No');
if strcmp(answ, 'Yes')
	disp('proceeding!')
else
	error('Figure out header you want and proceed from line 249')
end

if snc_on
	SNcsavefilename = ['SNc', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(SNcsavefilename, SNc_datastruct_name, '-v7.3');
	disp('SNc files saved')
end

if dls_on
	DLSsavefilename = ['DLS', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(DLSsavefilename, DLS_datastruct_name, '-v7.3');
	disp('DLS files saved')
end

if vta_on
	VTAsavefilename = ['VTA', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(VTAsavefilename, VTA_datastruct_name, '-v7.3');
	disp('VTA files saved')
end

if sncred_on
	SNcredsavefilename = ['SNcred', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(SNcredsavefilename, SNcred_datastruct_name, '-v7.3');
	disp('SNcred files saved')
end

if dlsred_on
	DLSredsavefilename = ['DLSred', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(DLSredsavefilename, DLSred_datastruct_name, '-v7.3');
	disp('DLSred files saved')
end


if vtared_on
	VTAredsavefilename = ['VTAred', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(VTAredsavefilename, VTAred_datastruct_name, '-v7.3');
	disp('VTAred files saved')
end


if emg_on
	EMGsavefilename = ['EMG', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(EMGsavefilename, EMG_datastruct_name, '-v7.3');
	disp('EMG files saved')
end

if x_on
	Xsavefilename = ['X', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(Xsavefilename, X_datastruct_name, '-v7.3');
	disp('X files saved')
end

if y_on
	Ysavefilename = ['Y', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(Ysavefilename, Y_datastruct_name, '-v7.3');
	disp('Y files saved')
end

if z_on
	Zsavefilename = ['Z', mousename_, '_day', daynum_, '_header', headernum_, '_roadmapv1_3_', todaysdate];
	save(Zsavefilename, Z_datastruct_name, '-v7.3');
	disp('Z files saved')
end