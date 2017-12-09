%% collect_UI_handler_roadmapv1_3.m-------------------------------------------------------------------
% 
% 	Created 	12-5-17 ahamilos (roadmap v1_3)
% 	Modified 	12-5-17 ahamilos
% 
% Note: is a script to make roadmap more compact!
% 
% UPDATE LOG:
% 		- 12-5-17: 
%% -------------------------------------------------------------------------------------------



todaysdate = datestr(datetime('now'), 'mm_dd_yy');
todaysdate2 = datestr(datetime('now'), 'mm-dd-yy');


prompt = {'Day # prefix:','CED filename_ (don''t include *_lick, etc):', 'Header number:', 'Type of exp (hyb, op)', 'Rxn window (0, 300, 500)', 'Trial Duration (ms)', 'Target (ms)', 'Exclusion Criteria Version', 'Animal Name', 'Excluded Trials', 'Photometry Hz', 'Movement Hz'};
dlg_title = 'Inputs';
num_lines = 1;
defaultans = {'11','b6_day11_hybop','2allrew', 'op', '0', '17000', '5000', '1', 'B6', '###', '1000', '2000'};
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