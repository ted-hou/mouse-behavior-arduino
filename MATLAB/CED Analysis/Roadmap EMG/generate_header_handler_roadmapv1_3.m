%% generate_header_handler_roadmapv1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-5-17: 
%% -------------------------------------------------------------------------------------------

excluded_trials_ = Excluded_Trials;

prompt2 = {'Enter header file text:', 'Generation Codes', 'Exp Description', 'Excluded Trials:', 'Notes - don''t make any carriage returns!'};
dlg_title = 'Header file text';
num_lines = 5;
defaultans = {[mousename_, ' Day ',daynum_, ' Header #', headernum_, '-------------------------------'], ['Data generated on ', todaysdate2,...
			 ' using roadmapv1_3 - version 12-6-17 - new saving paradign - set of functions, which includes Z-scored data (plot-to-lick and backfilled) and is for movement and photometry.'],...
			  ['Today was processed as ', exptype_, ' with rxn window = ', num2str(rxnwin_), 'ms.'], ['Excluded trials: ', num2str(excluded_trials_)], 'Notes:'};
answer = inputdlg(prompt2,dlg_title,num_lines,defaultans);



fid = fopen([mousename_, ' Day ',daynum_,' Header ', headernum_,' roadmapv1_3 ', todaysdate2,'.txt'], 'wt' );
fprintf(fid, '%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s\n\r\n\r%s', answer{1}, answer{2}, answer{3}, answer{4}, answer{5});
fclose(fid);