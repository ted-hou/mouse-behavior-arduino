%% collect_UI_handler_roadmapv1_3_subrun_diff_rew_levels.m-------------------------------------------------------------------
% 
% 	Created 	12-6-17 ahamilos (from base 1_3 handler version)
% 	Modified 	12-6-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-6-17: 
%% -------------------------------------------------------------------------------------------



todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');


prompt = {'Day # prefix:','CED filename_ (don''t include *_lick, etc):', 'Header number: Including Reward Level', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Trial Duration (ms)', 'Target (ms)', 'Exclusion Criteria Version', 'Animal Name', 'Excluded Trials', 'Photometry Hz', 'Movement Hz'};
dlg_title = 'Inputs';
num_lines = 1;
defaultans = {daynum_,filename_,'2####rewlevel', exptype_, num2str(rxnwin_), num2str(trial_duration_), num2str(target_), exclusion_criteria_version_, mousename_, excludedtrials_, p_Hz_, m_Hz_};
answer_ = inputdlg(prompt,dlg_title,num_lines,defaultans);
daynum_ = answer_{1};
filename_ = answer_{2};
headernum_ = answer_{3};
exptype_ = answer_{4};
rxnwin_ = str2double(answer_{5});
trial_duration_ = str2double(answer_{6});
target_ = str2double(answer_{7});
exclusion_criteria_version_ = answer_{8};
mousename_ = answer_{9};
excludedtrials_ = answer_{10};
p_Hz_ = answer_{11};
m_Hz_ = answer_{12};
    
% Modifiable trial structure vars:
total_trial_duration_in_sec = trial_duration_/1000;


waiter = questdlg('WARNING: Need to close all figures before proceeding - ok?','Ready to plot?', 'No');
if strcmp(waiter, 'Yes')
	close all
	disp('proceeding!')
else
	error('Close everything, then proceed from line 34')
end