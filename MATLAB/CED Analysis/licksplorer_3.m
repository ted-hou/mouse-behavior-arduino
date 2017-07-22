function licksplorer()
% LickSplorer v1.0 - A. Hamilos 4-27-17
% Last modified 4-27-17 by A. Hamilos
licksplorer_version = 'LickSplorer v1.0 - A. Hamilos';
font_size_big_button = 15;
font_size_small_button = 12;
button_width1 = 0.25;
button_height_big = 0.05;
button_height_small = 0.04;
load_left = 0.1;
exclude_left = 0.4;
include_left = 0.4;
df_f_left = 0.4;


column_2_left = 0.4;
excluded_text_left = .75;
column_3_left = 0.75;

% make numbers from greatest to least to get in correct positions
load_bottom =           0.9 -.01;
exclude_bottom =        0.9 -.01;
excluded_text_bottom =  0.9 -.02;
exclude_chunk_bottom =  0.9 -.025;
include_bottom =        0.9 -.03;
heatmap_bottom =        0.9 -.04;
df_f_bottom =           0.9 -.05;
averages_bottom =       0.9 -.06;
plot_button_bottom =    0.9 -.07;

plot_button_bottom =    0.9 -.08;
listbox_bottom =        0.9 -.09;
update_data_bottom =    0.9 -.10;
rename_data_bottom =    0.9 -.11;
change_defaults_bottom= 0.9 -.12;
print_figures_bottom =  0.9 -.13;




dF_F_style_DLS = 'Not Calculated Yet';
dF_F_style_SNc = 'Not Calculated Yet';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             Generate Figure + UI Controls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %------------------------------------------------------
   %         Create + Hide GUI Figure Window 
   %------------------------------------------------------
   f = figure('Visible','off',...
       'units', 'normalized',...
       'Position',[.5,.5,.4,.5]); 
   %------------------------------------------------------
   %          Create Load Data BUTTON 
   %------------------------------------------------------
   hload_data = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', font_size_big_button,...
          'String','Load Data',...
          'Position',[load_left,load_bottom,button_width1,button_height_big],...
          'Callback',{@load_data_Callback});
   %------------------------------------------------------
   %       Create Exclude Trials BUTTON 
   %------------------------------------------------------
   hexclude_trials = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Select Trials to Exclude',...
          'Position',[column_2_left,exclude_bottom,button_width1,button_height_small],...
          'Callback',{@exclude_trials_button_Callback});   
   %------------------------------------------------------
   %       Create Chunks of Trials BUTTON 
   %------------------------------------------------------
   hexclude_chunks_trials = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Select Chunks of Trials to Exclude',...
          'Position',[column_2_left,exclude_chunk_bottom,button_width1,button_height_small],...
          'Callback',{@exclude_chunks_trials_button_Callback});  

   %------------------------------------------------------
   %          Create "Excluded Trials DLS" Text 
   %------------------------------------------------------      
   htext_excluded_DLS = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String', ['Excluded DLS Trials: '],...
          'Position',[column_3_left,excluded_text_bottom,button_width1,button_height_small],...
          'Callback',{@htext_excluded_DLS_Callback});
   %------------------------------------------------------
   %          Create "Excluded Trials SNc" Text 
   %------------------------------------------------------      
   htext_excluded_SNc = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String', ['Excluded SNc Trials: '],...
          'Position',[column_3_left,excluded_text_bottom - 0.05,button_width1,button_height_small],...
          'Callback',{@htext_excluded_SNc_Callback});



   %------------------------------------------------------
   %       Create Exclude Trials BUTTON 
   %------------------------------------------------------
   hview_included_trials = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','View Included Trials',...
          'Position',[column_2_left,include_bottom,button_width1,button_height_small],...
          'Callback',{@view_included_trials_button_Callback});    
   %------------------------------------------------------
   %         Create Plot Heatmap BUTTON 
   %------------------------------------------------------   
   hplot_heatmap = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Plot Heatmap',...
          'Position',[column_2_left,heatmap_bottom,button_width1,button_height_small],...
          'Callback',{@plot_heatmap_Callback});  
   %------------------------------------------------------
   %        Create Calculate dF/F BUTTON 
   %------------------------------------------------------      
   hcalc_df_f = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Calculate dF/F',...
          'Position',[column_2_left,df_f_bottom,button_width1,button_height_small],...
          'Callback',{@calculate_df_f_Callback});
    
   %------------------------------------------------------
   %          Create "dF/F Style DLS" Text 
   %------------------------------------------------------      
   htext1 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String', ['dF/F Style DLS: ', dF_F_style_DLS],...
          'Position',[column_3_left,0.6,button_width1,button_height_small],...
          'Callback',{@htext1_Callback});
   
   %------------------------------------------------------
   %          Create "dF/F Style SNc" Text 
   %------------------------------------------------------      
   htext2 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String', ['dF/F Style SNc: ', dF_F_style_SNc],...
          'Position',[column_3_left,0.55,button_width1,button_height_small],...
          'Callback',{@htext2_Callback}); 
      
      
    %------------------------------------------------------
    %            Create Listbox 
    %------------------------------------------------------              
       hlistbox = uicontrol('Style','listbox',...
              'units', 'normalized',...
              'Fontsize', font_size_small_button,...
              'Position',[column_2_left,listbox_bottom,button_width1,.1],...
              'Callback',{@listbox_Callback},...
              'min', 0, ...
              'max', 2);    
    %------------------------------------------------------
    %         Create Update Listbox BUTTON 
    %------------------------------------------------------
       hlb_button = uicontrol('Style','pushbutton',...
              'units', 'normalized',...
              'String','Update Data Selection',...
              'Fontsize', font_size_small_button,...
              'Position',[column_2_left,update_data_bottom,button_width1,button_height_small],...
              'Callback',{@lb_button_Callback});
    %------------------------------------------------------
    %         Create Rename Data BUTTON 
    %------------------------------------------------------
       hrename_data_button = uicontrol('Style','pushbutton',...
              'units', 'normalized',...
              'String','Rename Datasets',...
              'Fontsize', font_size_small_button,...
              'Position',[column_2_left,rename_data_bottom,button_width1,button_height_small],...
              'Callback',{@rename_data_button_Callback}); 
    %------------------------------------------------------
    %         Create Change Default Parameters BUTTON 
    %------------------------------------------------------
       hchange_defaults_button = uicontrol('Style','pushbutton',...
              'units', 'normalized',...
              'String','Change Default Parameters...',...
              'Fontsize', font_size_small_button,...
              'Position',[column_2_left,change_defaults_bottom,button_width1,button_height_small],...
              'Callback',{@change_defaults_button_Callback}); 
      
      
   %------------------------------------------------------
   %         Create Print Figures BUTTON 
   %------------------------------------------------------
   hprintfigures = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'String','Print Figures',...
          'Fontsize', font_size_small_button,...
          'Position',[column_2_left,print_figures_bottom,button_width1,button_height_small],...
          'Callback',{@printfigures_button_Callback});     
      
      
   %------------------------------------------------------
   %         Compute Averages BUTTON 
   %------------------------------------------------------
   haverages = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'String','Compute Averages',...
          'Fontsize', font_size_small_button,...
          'Position',[column_2_left,averages_bottom,button_width1,button_height_small],...
          'Callback',{@averages_button_Callback});     
   %------------------------------------------------------
   %         Compute Averages BUTTON 
   %------------------------------------------------------
   hplot_button = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'String','Plot Averages',...
          'Fontsize', font_size_small_button,...
          'Position',[column_2_left,plot_button_bottom,button_width1,button_height_small],...
          'Callback',{@plot_button_Callback});     
   %------------------------------------------------------
   %             Create Left Top Axes (1) 
   %------------------------------------------------------   
   ha1 = axes('units', 'normalized',...
          'Position',[.05,.55,.4,.4]);
   %------------------------------------------------------
   %             Create Left Bottom Axes (2) 
   %------------------------------------------------------   
   ha2 = axes('units', 'normalized',...
          'Position',[.05,.05,.4,.4]);
   % %------------------------------------------------------
   % %             Create Right Top Axes (3) 
   % %------------------------------------------------------   
   % ha3 = axes('units', 'normalized',...
   %        'Position',[.425,.55,.3,.4]);
   % %------------------------------------------------------
   % %             Create Right Bottom Axes (4) 
   % %------------------------------------------------------   
   % ha4 = axes('units', 'normalized',...
   %        'Position',[.425,.05,.3,.4]);   
   %------------------------------------------------------
   %       Create Colorbar Modification Title Text (7)
   %------------------------------------------------------         
   htext7 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Colorbar Adjustment',...
          'Position',[0.65,0.1,.1,.02]);
   %------------------------------------------------------
   %             Create Min Colorbar Slider 
   %------------------------------------------------------      
   hMinSlider = uicontrol(...
                f,...
                'units', 'normalized',...
                'Style','slider',...
                'Min',-30,...
                'Max',30,...
                'Value',-10,...
                'SliderStep',[1/60 5/60],...
                'Position',[.675, .05, .01 .1],...
                'Callback',{@min_bar_Callback});
   %------------------------------------------------------
   %       Create "Min Colorbar" Title Text (3)
   %------------------------------------------------------         
   htext3 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Min',...
          'Position',[0.65,0.16,.03,.02]);
   %------------------------------------------------------
   %       Create "Min Colorbar" Value Text (5)
   %       Displays the position of Min Slider
   %------------------------------------------------------         
   htext5 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String', get(hMinSlider,'Value'),...
          'Position',[0.675,0.02,.03,.02]);
   %------------------------------------------------------
   %             Create Max Colorbar Slider 
   %------------------------------------------------------      
   hMaxSlider = uicontrol(...
                f,...
                'units', 'normalized',...
                'Style','slider',...
                'Min',-30,...
                'Max',30,...
                'Value',15,...
                'SliderStep',[1/60 5/60],...
                'Position',[.775, .05, .01 .1],...
                'Callback',{@max_bar_Callback});
   %------------------------------------------------------
   %       Create "Max Colorbar" Title Text (4)
   %------------------------------------------------------         
   htext4 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String','Max',...
          'Position',[0.775,0.16,.03,.02]);
   %------------------------------------------------------
   %       Create "Max Colorbar" Value Text (6)
   %       Displays Position of Max Slider
   %------------------------------------------------------         
   htext6 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', font_size_small_button,...
          'String', get(hMaxSlider,'Value'),...
          'Position',[0.775,0.02,.03,.02]);
   
   %------------------------------------------------------
   %               Align UI Controls 
   %------------------------------------------------------   
   align([hexclude_trials,...
       hexclude_chunks_trials,...
       hview_included_trials,...
       hcalc_df_f,...
       hplot_heatmap,...
       haverages,...
       hlistbox,...
       hlb_button,...
       hrename_data_button,...
       hchange_defaults_button,...
       hprintfigures,...
       htext7,...
       hplot_button],...
       'Center',...
       'Distribute');
   align([htext3,hMinSlider, htext5],...
       'Center',...
       'None');
   align([htext4,hMaxSlider, htext6],...
       'Center',...
       'None');


%%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 GUI Menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  f_menu = uimenu('Label','Workspace');
  uimenu(f_menu, 'Label', 'Save Workspace ...', 'Callback', {@save_menu_Callback});
  uimenu(f_menu, 'Label', 'Load Workspace ...', 'Callback', {@load_menu_Callback});
  %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  %    Save Current Variables in GUI CALLBACK
  %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function save_menu_Callback(source,eventdata)
        % save to a file
        [file, path] = uiputfile('*.mat','Save Workspace As');
        filename = [path, file];
        save(filename)
    end
  %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  %    Load Variables in GUI CALLBACK
  %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function load_menu_Callback(source,eventdata)
        % load a file
        [filename, filepath] = uigetfile('*.mat', 'Load previous experiment from file');
        % Exit if no file selected
        if ~(ischar(filename) && ischar(filepath))
          return
        end
        % Load file
        % p = load([filepath, filename]);
        load([filepath, filename]);


        % clear all
        % FileName = 'not selected';
        % PathName = 'not selected';
        % [FileName,PathName] = uigetfile('*.mat','Resume analysis: Select Saved Licksplorer Workspace');
        % if ~strcmp(FileName, 'not selected') & ~strcmp(PathName, 'not selected')
        %   filename = [PathName, FileName];
        %   load(filename);
        % end
    end


% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& I think maybe needs to be a structure and then extract all the vars from there to the workspace... So maybe make everything a structure...
% % Display errorMessage prompt if called for
      

%       [filename, filepath] = uigetfile('*.mat', 'Load previous experiment from file');
%       % Exit if no file selected
%       if ~(ischar(filename) && ischar(filepath))
%         return
%       end
%       % Load file
%       p = load([filepath, filename]);
%       % If loaded file does not contain experiment
%       if ~isfield(p, 'obj')
%         % Ask the Grad Student if he wants to select another file instead
%         obj.LoadExperiment('The file you selected was not loaded because it does not contain an ArduinoConnection object. Select another file instead?')
%       % If p.obj is not the correct class
%       elseif ~isa(p.obj, 'ArduinoConnection')
%         obj.LoadExperiment('The file you selected was not loaded because it does not contain an ArduinoConnection object. Select another file instead?')
%       else
%         % If all checks are good then do the deed
%         % Disable autosave first
%         obj.AutosaveEnabled = false;

%         % If we're doing this offline (w/o arduino), also load experiment setup
%         if ~obj.Connected
%           obj.StateNames = p.obj.StateNames;
%           obj.StateCanUpdateParams = p.obj.StateCanUpdateParams;
%           obj.ParamNames = p.obj.ParamNames;
%           obj.ParamValues = p.obj.ParamValues;
%           obj.ResultCodeNames = p.obj.ResultCodeNames;
%           obj.EventMarkerNames = p.obj.EventMarkerNames;
%           obj.StateNames = p.obj.StateNames;
%         end

%         % Load relevant experiment data
%         obj.EventMarkers      = p.obj.EventMarkers;
%         obj.EventMarkersUntrimmed   = p.obj.EventMarkersUntrimmed;
%         obj.Trials          = p.obj.Trials;
%         obj.TrialsCompleted     = p.obj.TrialsCompleted;

%         % Add all parameters to update queue
%         for iParam = 1:length(p.obj.ParamValues)
%           obj.UpdateParams_AddToQueue(iParam, p.obj.ParamValues(iParam))
%         end
%         % Attempt to execute update queue now, if current state does not allow param update, the queue will be executed when we enter an appropriate state
%         obj.UpdateParams_Execute()

%         % Store the save path
%         obj.ExperimentFileName = [filepath, filename];

%         % Re-enable autosave if online
%         if obj.Connected
%           obj.AutosaveEnabled = true;
%         end
% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

   
%%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             Initialize Global Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize Global Variables
workspace_variables = {};
h_datalabels = {};
current_data1 = [];
current_data2 = [];
cohort_values = [1,1];
cohort_name_1 = {'no name - error'};
cohort_name_2 = {'no name - error'};
% Licksplorer global vars:
DLS_struct = [];
SNc_struct = [];
DLS_values = [];
SNc_values = [];
DLS_times = [];
SNc_times = [];
trial_start_times = [];
cue_on_times = [];
juice_times = [];
lampOn_times = [];
lick_times = [];
trigger_times = [];
keyboard_times = [];
keyboard_codes = [];
num_trials = [];
lick_times_by_trial = [];
% these will exclude any excluded trial (the excluded trial is NaN):
DLS_values_by_trial = [];
SNc_values_by_trial = [];
DLS_times_by_trial = [];
SNc_times_by_trial = [];
DLS_excluded_trials = [];
SNc_excluded_trials = [];

% needed for average calculation: (excluded trials are NaN)
obj = [];
DLS_ave = [];
SNc_ave = [];
hybrid_trial_is_operant = [];
operant_trial_numbers = [];
hybrid_trial_is_not_operant = [];
NOToperant_trial_numbers = [];
SNc_sum_operant = [];
SNc_ave_operant = [];
DLS_sum_operant = [];
DLS_ave_operant = [];
SNc_sum_NOToperant = [];
SNc_ave_NOToperant = [];
DLS_sum_NOToperant = [];
DLS_ave_NOToperant = [];
SEM_SNc = [];
SEM_DLS = [];
std_SNc = [];
std_DLS = [];
% filtered data
f_SNc_ave = [];
f_DLS_ave = [];
f_SNc_ave_operant = [];
f_DLS_ave_operant = [];
f_SNc_ave_NOToperant = [];
f_DLS_ave_NOToperant = [];


% Initialize Workspace Variables and Names
import_workspace(); % returns workspace_variables
% name_variables(); % userinput of variable names

% Populate the listbox
% listbox_Callback(); % Populates listbox with user-defined data labels
% set(hlistbox,'Value',[]); % Makes no selections in box the default



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             Display Initial Plot on Loading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%Create initial plot in the axes - display Specsplorer logo.
axes(ha1)
% readme = imread(''); % loads file cdata
% imagesc(readme);
set(gca,'XTick',[],'YTick',[])

axes(ha2)
% logo = imread(''); % loads file cdata
% imagesc(logo);
set(gca,'XTick',[],'YTick',[])


   
   
   
%%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Initialize GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% GUI name - appears in the window title.
set(f,'Name',licksplorer_version)
% Move GUI to center of screen.
movegui(f,'center')
% Make GUI visible.
set(f,'Visible','on');
 


%%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Callbacks to LickSplorer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  These callbacks automatically have access to 
%  component handles and initialized data 
%  because they are nested at a lower level.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    Variable Manipulation and Listbox Functions
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   %    Import Workspace Variables Function
   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function import_workspace(source,eventdata)
        % Imports the names of variables in the workspace
        workspace_variables = evalin('base','who');
    end
   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   %    Rename Data Function
   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function name_variables(source, eventdata)
        % Generates prompt user to rename workspace variables
        a = msgbox(sprintf('Name the spectral datasets from your workspace. \n\nLeave blank any unwanted variables'));    
        uiwait(a);
        prompt = workspace_variables;
        dlg_title = 'Name the datasets imported into Specsplorer';
        num_lines = 1;
        defaultans = workspace_variables;
        options.Resize='on';
        h_datalabels = inputdlg(prompt, dlg_title, num_lines, defaultans, options);
    end
   %------------------------------------------------------
   %    Rename Data BUTTON Callback
   %------------------------------------------------------
    function rename_data_button_Callback(source, eventdata)
        name_variables(source, eventdata)
        listbox_Callback()
        set(hlistbox,'Value',[]);
    end
   %------------------------------------------------------
   %    Listbox Callback
   %------------------------------------------------------
    function listbox_Callback(source,eventdata)
    % Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from listbox1
    % Updates the listbox to match the current workspace
        set(hlistbox,'String',h_datalabels);
    end
   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   %    Get Selected Data in Listbox Function
   %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function [var1,var2] = get_var_names(source, eventdata)
    % Returns the names of the two variables to plot
    index_selected = get(hlistbox,'Value');
    var1 = [];
    var2 = [];
        if length(index_selected) ~= 2
            errordlg('You must select two variables','Incorrect Selection','modal')
        else
            var1 = workspace_variables{index_selected(1)};
            var2 = workspace_variables{index_selected(2)};
        end 
    end
   %------------------------------------------------------
   %    Update Selected Data BUTTON Callback
   %------------------------------------------------------
    
    function lb_button_Callback(source,eventdata)
        % Button to Update Selected Data
        %-- When Update button is pressed, the selected data will be analyzed.

        [current_data1, current_data2] = get_var_names();
        disp(current_data1)
        disp(current_data2)
    end
   %------------------------------------------------------
   %    Change Default Parameters BUTTON Callback
   %------------------------------------------------------
    
    function change_defaults_button_Callback(source,eventdata)
        % Generates popup to allow user to change default parameters
        prompt = {'Sampling Frequency',...
                    'Frequency Min',...
                    'Frequency Max',...
                    'Tapers - TW',...
                    'Tapers - K',...
                    'Window Size (s)',...
                    'Window Step (s)',...
                    'Number of Bootstraps',...
                    }; 
        dlg_title = 'Set Default Parameters';
        num_lines = 1;
        

        str_Fs = mat2str(params.Fs);
        str_fpass_min = mat2str(params.fpass(1));
        str_fpass_max = mat2str(params.fpass(2));
        str_tapers_TW = mat2str(params.tapers(1));
        str_tapers_K = mat2str(params.tapers(2));
        str_movingwin_size = mat2str(movingwin(1));
        str_movingwin_step = mat2str(movingwin(2));
        str_num_bootstraps = mat2str(num_bootstraps);
                       
        defaultans = {str_Fs,...
                        str_fpass_min,...
                        str_fpass_max,...
                        str_tapers_TW,...
                        str_tapers_K,...
                        str_movingwin_step,...
                        str_movingwin_size,...
                        str_num_bootstraps,...
                        };
        options.Resize='on';
        h_defaults = inputdlg(prompt, dlg_title, num_lines, defaultans, options);
        
        params.Fs = str2double(h_defaults(1));
        params.fpass = [str2double(h_defaults(2)), str2double(h_defaults(3))];
        params.tapers = [str2double(h_defaults(4)), str2double(h_defaults(5))];
        movingwin = [str2double(h_defaults(6)), str2double(h_defaults(7))];
        num_bootstraps = str2double(h_defaults(8));
    end




 
   
  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%              PUSH-BUTTON callbacks. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Push button callbacks. 
   %------------------------------------------------------
   %              LOAD DATA BUTTON 
   %------------------------------------------------------
   function load_data_Callback(source,eventdata) 
   % Load up the data and extract all the variables and lick data
      h = msgbox('Loading data, please wait...')
        try
        % Extract data from the workspace:
        % current_array_1 = evalin('base',current_data1);        
        % % Get user-defined name (string) for plot title:
        % cohort_values = get(hlistbox, 'Value');
        % cohort_name_1 = h_datalabels(cohort_values(1));

        %% Open file:
        response = inputdlg('Enter CED filename (don''t include *_lick, etc)');
        filename = response{1};
        %-----------------------------------------------------------------------------------------
        %% Extract variables from file

        % Extract the HSOM object
        try
          obj = evalin('base', ['obj']);
        catch ex
          errordlg(sprintf('HSOM data not in workspace - can''t use averaging functions unless you reload data'), 'modal');
        end

        % Extract the lamp_off structure and timepoints
        lamp_off_struct = evalin('base', [filename, '_Lamp_OFF']);
        trial_start_times = lamp_off_struct.times;

        % Extract the cue_on structure and timepoints
        cue_on_struct = evalin('base', [filename, '_Start_Cu']);
        cue_on_times = cue_on_struct.times;

        % Extract the Juice structure and timepoints
        juice_struct = evalin('base', [filename, '_Juice']);
        juice_times = juice_struct.times;

        % Extract the LampON structure and timepoints
        lampOn_struct = evalin('base', [filename, '_LampON']);
        lampOn_times = lampOn_struct.times;

        % Extract the Lick structure and timepoints
        lick_struct = evalin('base', [filename, '_Lick']);
        lick_times = lick_struct.times;

        % Extract the Trigger structure and timepoints
        trigger_struct = evalin('base', [filename, '_Trigger']);
        trigger_times = trigger_struct.times;

        % Extract the Keyboard structure and timepoints and codes
        keyboard_struct = evalin('base', [filename, '_Keyboard']);
        keyboard_times = keyboard_struct.times;
        keyboard_codes = keyboard_struct.codes;

        % Number of trials:
        num_trials_plus_1 = length(trial_start_times);
        num_trials = num_trials_plus_1 - 1; %(doesn't include the last incomplete trial)

        % Extract the DLS signal structure, timepoints and analog values
        DLS_struct = evalin('base', [filename, '_DLS']);
        DLS_values = DLS_struct.values;
        DLS_times = DLS_struct.times;
        % Extract the SNc signal structure, timepoints and analog values
        SNc_struct = evalin('base', [filename, '_SNc']);
        SNc_values = SNc_struct.values;
        SNc_times = SNc_struct.times;
         

        %% Divide all data into trials by cue on:
        [DLS_times_by_trial, DLS_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(DLS_times, DLS_values, trial_start_times, cue_on_times);
        [SNc_times_by_trial, SNc_values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(SNc_times, SNc_values, trial_start_times, cue_on_times);

        %% Calculate Lick Times By Trial:
        lick_times_by_trial = lick_times_by_trial_fx(lick_times, cue_on_times, 17, num_trials); % note: 17 = time from cue on till end of trial in sec
        
        % %% Calculate first lick data
        [f_lick_rxn,...
         f_lick_train_abort,...
         f_lick_operant_no_rew,...
         f_lick_operant_rew,...
         f_lick_pavlovian,...
         f_lick_ITI,...
         trials_with_rxn,...
         trials_with_train,...
         trials_with_pav,...
         trials_with_ITI] = first_lick_grabber(lick_times_by_trial, num_trials);


        catch ex
            errordlg(sprintf('There was a problem, debug @ load_data_Callback.'), 'modal');
        end
        close(h);
   end
   %------------------------------------------------------
   %              Exclude Trials BUTTON 
   %------------------------------------------------------
   function exclude_trials_button_Callback(source,eventdata)
   % Displays globally-normalized heatmap and allows user to select trials to exclude from further analysis
           
      try
        %% Choose DLS or SNc:
        button_1 = questdlg('Exclude trials for DLS or SNc?','Hey!','DLS','SNc', 'DLS');
        if strcmp(button_1, 'DLS')
          current_data = DLS_values_by_trial;
        elseif strcmp(button_1, 'SNc')
          current_data = SNc_values_by_trial;
        else
          current_data = [];
        end

        %% Plot as heatmap...
        [h_heatmap_global_no_exclusions, heat_by_trial_global_no_exclusions] = heatmap_3_fx(current_data, [], false);
        title('Globally-normalized heatmap of df/f')

        % Allow user to select trials they want to ignore from consideration:
        button_2 = questdlg('Exclude Trials?','Hey!','Yes','No','Yes');
        answer = strcmp(button_2, 'Yes');
        if answer ~= 1
          close(h_heatmap_global_no_exclusions);
        end

        %% Allow user to select trial to ignore:
        split_times = [];
        split_trials = []; 
        num = 1;
        keep_checking = answer;
        while keep_checking == 1
          title('Select trials to split data by clicking (choose in order small->large)');
          [split_times(num), split_trials(num)] = ginput(1);
          
          button_3 = questdlg(['You selected trial #', num2str(floor(split_trials(num)))],'Hey!','Continue','Redo', 'Select More Trials', 'Continue');
          if strcmp(button_3, 'Select More Trials');
            disp('checking again')
            num = num + 1;
            keep_checking = 1;  
          elseif strcmp(button_3, 'Continue');
            disp('don''t check again')
            keep_checking = false;
            break
          elseif strcmp(button_3, 'Redo');
            disp('Pick again...')
            num = num;
            keep_checking = 1;
            end
        end
        % Take the floor of the trial # so it is a whole #:
        split_trials = floor(split_trials);

        ignore_split_trials = current_data;
        for i = split_trials
          ignore_split_trials(i, :) = NaN;
        end

        if strcmp(button_1, 'DLS')
          DLS_values_by_trial = ignore_split_trials;
          DLS_excluded_trials = split_trials;
          htext_excluded_DLS_Callback();
        elseif strcmp(button_1, 'SNc')
          SNc_values_by_trial = ignore_split_trials;
          SNc_excluded_trials = split_trials;
          htext_excluded_SNc_Callback();
        end

        %% 3. Check heatmap now...
        [h_heatmap_global_with_exclusions, heat_by_trial_with_exlcusions] = heatmap_3_fx(ignore_split_trials, [], false);
        title('Globally-normalized heatmap without excluded trials')
             
      catch ex
            errordlg(sprintf('There was a problem, debug @ exclude_trials_button_Callback.'), 'modal');
      end

   end


   %------------------------------------------------------
   %              Exclude CHUNKS Trials BUTTON 
   %------------------------------------------------------
   function exclude_chunks_trials_button_Callback(source,eventdata)
   % Displays globally-normalized heatmap and allows user to select trials to exclude from further analysis
           
      % try
        %% Choose DLS or SNc:
        button_1 = questdlg('Exclude trials for DLS or SNc?','Hey!','DLS','SNc', 'DLS');
        if strcmp(button_1, 'DLS')
          current_data = DLS_values_by_trial;
        elseif strcmp(button_1, 'SNc')
          current_data = SNc_values_by_trial;
        else
          current_data = [];
        end

        %% Plot as heatmap...
        [h_heatmap_global_no_exclusions, heat_by_trial_global_no_exclusions] = heatmap_3_fx(current_data, [], false);
        title('Globally-normalized heatmap of df/f')

        % Allow user to select trials they want to ignore from consideration:
        button_2 = questdlg('Exclude Trials?','Hey!','Yes','No','Yes');
        answer = strcmp(button_2, 'Yes');
        if answer ~= 1
          close(h_heatmap_global_no_exclusions);
        end

        %% Allow user to select trial to ignore:
        split_times = [];
        split_trials = []; 
        num = 1;
        keep_checking = answer;
        while keep_checking == 1
          title('Click on 2 points and press enter. Any points between them will be eliminated');
          ok = 0;
          while ok == 0
            try 
              [split_times(num, 1:2), split_trials(num, 1:2)] = getpts(gca);
              ok = 1;
            catch ex
              errordlg('Pick TWO points, no more, no less, then press enter!');
            end
          end
          
          button_3 = questdlg(['You eliminated all trials between ', num2str(floor(split_trials(num, 1))), ' and ', num2str(floor(split_trials(num, 2)))],'Hey!','Continue','Redo', 'Select More Trials', 'Continue');
          if strcmp(button_3, 'Select More Trials');
            disp('checking again')
            num = num + 1;
            keep_checking = 1;  
          elseif strcmp(button_3, 'Continue');
            disp('don''t check again')
            keep_checking = false;
            break
          elseif strcmp(button_3, 'Redo');
            disp('Pick again...')
            num = num;
            keep_checking = 1;
            end
        end
        % Take the floor of the trial # so it is a whole #:
        split_trials = floor(split_trials);

        % in case you select more trials than there really are...
        toohigh = find(split_trials > num_trials);
        split_trials(toohigh) = num_trials;

        ignore_split_trials = current_data;
        excluded_trials = [];
        for i = 1:num
          ignore_split_trials(split_trials(i, 1):split_trials(i, 2), :) = NaN;
          number_excluded = split_trials(i, 2) - split_trials(i, 1);
          for n = 1:number_excluded
            excluded_trials(end+1) = split_trials(i, 1) + n-1;
          end
        end

        if strcmp(button_1, 'DLS')
          DLS_values_by_trial = ignore_split_trials;
          DLS_excluded_trials = excluded_trials; % split_trials;
          htext_excluded_DLS_Callback();    % right now, this won't show chunks of missing trials, but this would be good to add later
        elseif strcmp(button_1, 'SNc')
          SNc_values_by_trial = ignore_split_trials;
          SNc_excluded_trials = excluded_trials; % split_trials;
          htext_excluded_SNc_Callback();
        end

        %% 3. Check heatmap now...
        [h_heatmap_global_with_exclusions, heat_by_trial_with_exlcusions] = heatmap_3_fx(ignore_split_trials, [], false);
        title('Globally-normalized heatmap without excluded trials')
             
      % catch ex
      %       errordlg(sprintf('There was a problem, debug @ exclude_trials_button_Callback.'), 'modal');
      % end

   end






   %------------------------------------------------------
   %              View Included Trials BUTTON 
   %------------------------------------------------------
   function view_included_trials_button_Callback(source,eventdata) 
     %% 3. Check heatmap now...
        heatmap_3_fx(DLS_values_by_trial, [], false);
        title(['DLS - Excluded trials: ', num2str(DLS_excluded_trials)])
        heatmap_3_fx(SNc_values_by_trial, [], false);
        title(['SNc - Excluded trials: ', num2str(SNc_excluded_trials)])
   end




%%
   %------------------------------------------------------
   %        CALCULATE DF/F BUTTON CALLBACK
   %------------------------------------------------------
   function calculate_df_f_Callback(source,eventdata) 
   % Allows user to select how to calculate df/f and calculates for the dataset
   
        % try
          %% Choose DLS or SNc:
          button = questdlg('Calculate dF/F for DLS or SNc?','Hey!','DLS','SNc', 'DLS');
          if strcmp(button, 'DLS')
            current_data = DLS_values_by_trial;
            times_by_trial = DLS_times_by_trial;
            analog_times = DLS_times;
            analog_values = DLS_values;
            split_trials = DLS_excluded_trials;
            channel = 'DLS';
          elseif strcmp(button, 'SNc')
            current_data = SNc_values_by_trial;
            times_by_trial = SNc_times_by_trial;
            split_trials = SNc_excluded_trials;
            analog_times = SNc_times;
            analog_values = SNc_values;
            channel = 'SNc';
          else
            current_data = [];
          end

          button2 = questdlg('How do you want to calculate dF/F?','Hey!','Local 3 Sec ITI','Global Exp', 'Local 3 Sec ITI');
          if strcmp(button2, 'Local 3 Sec ITI')
            %% Find the ave of last 3 sec in each trial and subtract that from every datapoint in that trial:
            df_f_values = NaN(size(current_data));
            for i_trial = 1:num_trials
              % take ave of last 3 sec:
              ave_last_3 = nanmean(current_data(i_trial, end-3000:end));
              % subtract this from every datapoint in the trial:
              df_f_values(i_trial, :) = current_data(i_trial, :) - ave_last_3;
            end

            %% 3. Check heatmap now...
            [h_heatmap_df_f, heat_by_trial_df_f] = heatmap_3_fx(df_f_values, [], false);
            title([channel, ' Globally-normalized heatmap of dF/F now in use'])

            if strcmp(button, 'DLS')
              dF_F_style_DLS = 'Local';
             elseif strcmp(button, 'SNc')
              dF_F_style_SNc = 'Local';
            end
            % End Local----------------------------------------------------------------

        

          elseif strcmp(button2, 'Global Exp')
     %------------------------------------------------------------------------------------------
        %% 1. Divide all data into trials by cue on:
        [times_by_trial, values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(analog_times, analog_values, trial_start_times, cue_on_times);

        %% 2. Plot as heatmap...
        [h_heatmap, heat_by_trial] = heatmap_3_fx(values_by_trial, [], false);

        % Allow user to select trials they want to ignore from consideration:

        button_a = questdlg('Did the light intensity change during the experiment?','Hey!','Yes','No','Yes');
        answer = strcmp(button_a, 'Yes');

        if answer ~= 1
          close(h_heatmap);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% put in part where response NO is valid*************************************************

        %% If light level was changed, allow user to select timepoint to split data on:
        split_times = [];
        split_trials = []; 
        num = 1;
        keep_checking = answer;

        while keep_checking == 1
          title('Select trials to split data by clicking (choose in order small->large)');
          [split_times(num), split_trials(num)] = ginput(1);
          
          button2 = questdlg(strcat('You selected trial #', num2str(floor(split_trials(num))) ,'Hey!','Continue','Redo', 'Select More Trials', 'Continue'));
          if strcmp(button2, 'Select More Trials');
            disp('checking again')
            num = num + 1;
            keep_checking = 1;  
          elseif strcmp(button2, 'Continue');
            disp('don''t check again')
            keep_checking = false;
            break
          elseif strcmp(button2, 'Redo');
            disp('Pick again...')
            num = num;
            keep_checking = 1;
            end
        end

        % Take the floor of the trial # so it is a whole #:
        split_trials = floor(split_trials);


        % Now get the timepoints for the splits from the times_by_trial array:
        position_1st_timestamp = min(find(times_by_trial(1,:)>-10000))
        start_time = times_by_trial(1,position_1st_timestamp);
        end_time = times_by_trial(end,end-1);
        times_to_break = []; % this is a nx2 array. col1 = end of prev split, col2 = begin next split

        for i_splits = 1:length(split_trials)
          % find the first timestamp in the trial
          position_1st_timestamp = min(find(times_by_trial(split_trials(i_splits),:)>-10000))
          times_to_break(i_splits,1) = times_by_trial(split_trials(i_splits), position_1st_timestamp);
          times_to_break(i_splits,2) = times_by_trial(split_trials(i_splits), end-1);
        end


        % make a cell array to hold all the split things:
          splitting_times_final = []; % a nx2 array, col 1 = start, col2 = end
          split_time_begin = start_time;
          splitting_times_final(1,1) = split_time_begin;
          belly = {};   % belly will hold all these split up 1xn arrays
          for i_split = 1:length(split_trials)
            split_time_end = times_to_break(i_split, 1);
            splitting_times_final(i_split, 2) = split_time_end;
            %find values position where the split times are:
            val_pos_1 = min(find(analog_times <= split_time_begin + 0.001 & analog_times >= split_time_begin - 0.001));
            val_pos_2 = min(find(analog_times <= split_time_end + 0.001 & analog_times >= split_time_end - 0.001));

            belly{i_split} = analog_values(val_pos_1:val_pos_2);

            split_time_begin = times_to_break(i_split, 2); % for next trial
            splitting_times_final(i_split+1, 1) = split_time_begin;
          end
          % Now do the final split:
          split_time_end = end_time;
          splitting_times_final(end, 2) = split_time_end;
          %find values position where the split times are:
          val_pos_1 = min(find(analog_times <= split_time_begin + 0.001 & analog_times >= split_time_begin - 0.001));
          val_pos_2 = min(find(analog_times <= split_time_end + 0.001 & analog_times >= split_time_end - 0.001));
          belly{end+1} = analog_values(val_pos_1:val_pos_2);


        %% Now fit each belly with exp:
          fitobject = {}; % saves each fit
          gof = {};   % saves goodness of fit stats for each fit
          output = {};  % saves output for each fit
          coefficient_array = []; % saves the coeffs as rows = fit, col = a,b
          split_time_begin = start_time;
          for i_fit = 1:length(belly)
            % Make x and y and then transpose:
            x = (1:length(belly{i_fit}));
            x = x';
            y = belly{i_fit};
            [fitobject{i_fit},gof{i_fit},output{i_fit}] = fit(x,y,'exp2');
            figure, hold on, plot(belly{i_fit}), plot(fitobject{i_fit});
            coefficient_array(i_fit, :) = coeffvalues(fitobject{i_fit});
          end



        %% Now, use the coefficients to get a correction function for each fit
          correction_functions = {}; % each cell has a 1xn array of multipliers based on the exp fit
          for i_fit = 1:(length(belly))
            a = coefficient_array(i_fit, 1);
            b = coefficient_array(i_fit, 2);
            for i_timestamp = 1:length(belly{i_fit})+18501
              correction_functions{i_fit}(i_timestamp) = a*exp(b*i_timestamp);  % note if a = 0, then this will end up reading as NaN - basically if the end of the light function is not exp, this will give a meaningless exp fit
            end
          end



        % Now correct each datapoint:
          df_f_values = NaN(size(values_by_trial));
          start_trial = 1;
          for i_fit = 1:length(belly)-1
            end_trial = split_trials(i_fit);
            expcount = 1;

            for i_trial = start_trial:end_trial
              for i_col = 1:size(values_by_trial,2)
                % for each timestamp, check if not NaN. Remember to increment the exp counter
                if values_by_trial(i_trial, i_col) > -10000
                  df_f_values(i_trial, i_col) = values_by_trial(i_trial, i_col) ./ correction_functions{i_fit}(expcount);
                  expcount = expcount + 1;
                end
              end
            end

            start_trial = end_trial + 1
          end
          % now do the final fit:
          end_trial = size(values_by_trial,1);
          expcount = 1;
          for i_trial = start_trial:end_trial
            for i_col = 1:size(values_by_trial,2)
              % for each timestamp, check if not NaN. Remember to increment the exp counter
              if values_by_trial(i_trial, i_col) > -10000
                df_f_values(i_trial, i_col) = values_by_trial(i_trial, i_col) ./ correction_functions{i_fit}(expcount);
                expcount = expcount + 1;
              end
            end
          end


            %% Check heatmap now...
            [h_heatmap_df_f, heat_by_trial_df_f] = heatmap_3_fx(df_f_values, [], false);
            title([channel, ' Globally-normalized heatmap of dF/F now in use'])

            if strcmp(button, 'DLS')
              dF_F_style_DLS = 'Global';
             elseif strcmp(button, 'SNc')
              dF_F_style_SNc = 'Global';
            end

          end %Global end------------------------------------------

          if strcmp(button, 'DLS')
            DLS_df_f = df_f_values;
            htext1_Callback();
           elseif strcmp(button, 'SNc')
            SNc_df_f = df_f_values;
            htext2_Callback();
          end

        % catch ex
        %     errordlg(sprintf('There was a problem. Debug @ calculate_df_f_Callback.'), 'modal');
        % end            
   end
%%
   %------------------------------------------------------
   %             PLOT HEATMAP BUTTON CALLBACK
   %------------------------------------------------------
   function plot_heatmap_Callback(source,eventdata) 
   % Allow user to select which channel, heatmap type, and with or without licks to plot
        
        %% Choose DLS or SNc:
        button = questdlg('Heatmap for DLS or SNc?','Hey!','DLS','SNc', 'DLS');
        if strcmp(button, 'DLS')
          current_data = DLS_values_by_trial;
          channel = 'DLS';
        elseif strcmp(button, 'SNc')
          current_data = SNc_values_by_trial;
          channel = 'SNc';
        else
          current_data = [];
        end

        button2 = questdlg('Select Heatmap Type:','Hey!','Global','Local','Local');
        button3 = questdlg('Include Lick Raster?','Hey!','Yes','No','No');
        if strcmp(button2, 'Global') & strcmp(button3, 'Yes')
          [h_heatmap_global_licks, heat_by_trial_global] = heatmap_3_fx(current_data, lick_times_by_trial, true);
          title([channel, ' Globally-normalized heatmap'])
        elseif strcmp(button2, 'Global') & strcmp(button3, 'No')
          [h_heatmap_global_no_licks, heat_by_trial_global] = heatmap_3_fx(current_data, [], false);
          title([channel, ' Globally-normalized heatmap'])
        elseif strcmp(button2, 'Local') & strcmp(button3, 'Yes')
          [h_heatmap_local_licks, heat_by_trial_local] = heatmap_fx(current_data, lick_times_by_trial, true);
          title([channel, ' Locally-normalized heatmap'])
        elseif strcmp(button2, 'Local') & strcmp(button3, 'No')
          [h_heatmap_local_no_licks, heat_by_trial_local] = heatmap_fx(current_data, [], false);
          title([channel, ' Locally-normalized heatmap'])
        end
   end 
%%
   %------------------------------------------------------
   %        Compute AVERAGES BUTTON Callback
   %------------------------------------------------------
   function averages_button_Callback(source,eventdata) 
      % Alert user that averages are being calculated:
      h = msgbox(['Calculating Averages for DLS and SNc (ignoring excluded trials), please wait...']);
      
      %% Average the trials together:
      SNc_sum = nansum(SNc_values_by_trial,1);
      SNc_ave = SNc_sum/(num_trials-length(SNc_excluded_trials));
      % SNc_ave = nanmean(SNc_values_by_trial,1);

      DLS_sum = nansum(DLS_values_by_trial,1);
      DLS_ave = DLS_sum/(num_trials-length(DLS_excluded_trials));
      % DLS_ave = nanmean(DLS_values_by_trial,1);

      %% Determine if trial is operant (defined as a trial in which mouse licked between no-lick and target and scored as first lick on PSTH)
      hybrid_trial_is_operant = hybrid_trial_is_operant_fx(obj);
      operant_trial_numbers = find(hybrid_trial_is_operant == 1);

      hybrid_trial_is_not_operant = hybrid_trial_is_NOT_operant_fx(obj);
      NOToperant_trial_numbers = find(hybrid_trial_is_not_operant == 1);

      % Determine number of excluded operant and not operant trials:
      num_operant_excluded_SNc = 0;
      num_not_operant_excluded_SNc = 0;
      num_operant_excluded_DLS = 0;
      num_not_operant_excluded_DLS = 0;

      for i_exc = 1:length(SNc_excluded_trials)
        if any(operant_trial_numbers == i_exc)
          % there's an excluded operant trial
          disp(['Operant trial excluded at trial #', num2str(SNc_excluded_trials(i_exc))])
          num_operant_excluded_SNc = num_operant_excluded_SNc + 1;
        elseif any(NOToperant_trial_numbers == i_exc)
          disp(['Non-op trial excluded at trial #', num2str(SNc_excluded_trials(i_exc))])
          num_not_operant_excluded_SNc = num_not_operant_excluded_SNc + 1;
        end
      end
      for i_exc = 1:length(DLS_excluded_trials)
        if any(operant_trial_numbers == i_exc)
          % there's an excluded operant trial
          disp(['Operant trial excluded at trial #', num2str(DLS_excluded_trials(i_exc))])
          num_operant_excluded_DLS = num_operant_excluded_DLS + 1;
        elseif any(NOToperant_trial_numbers == i_exc)
          disp(['Non-op trial excluded at trial #', num2str(DLS_excluded_trials(i_exc))])
          num_not_operant_excluded_DLS = num_not_operant_excluded_DLS + 1;
        end
      end

      disp(['total operant excluded SNc ', num2str(num_operant_excluded_SNc)])
      disp(['total Non-op excluded SNc ', num2str(num_not_operant_excluded_SNc)])
      disp(['total operant excluded DLS ', num2str(num_operant_excluded_DLS)])
      disp(['total Non-op excluded DLS ', num2str(num_not_operant_excluded_DLS)])

      % Average trials based on pav vs operant:
      SNc_sum_operant = nansum(SNc_values_by_trial(operant_trial_numbers,:),1);
      SNc_ave_operant = SNc_sum_operant/(length(operant_trial_numbers) - num_operant_excluded_SNc);

      DLS_sum_operant = nansum(DLS_values_by_trial(operant_trial_numbers,:),1);
      DLS_ave_operant = DLS_sum_operant/(length(operant_trial_numbers) - num_operant_excluded_DLS);

      SNc_sum_NOToperant = nansum(SNc_values_by_trial(NOToperant_trial_numbers(1:end-1),:),1);
      SNc_ave_NOToperant = SNc_sum_NOToperant/(length(NOToperant_trial_numbers(1:end-1)) - num_not_operant_excluded_SNc);

      DLS_sum_NOToperant = nansum(DLS_values_by_trial(NOToperant_trial_numbers(1:end-1),:),1);
      DLS_ave_NOToperant = DLS_sum_NOToperant/(length(NOToperant_trial_numbers(1:end-1)) - num_not_operant_excluded_DLS);

      % Calculate SEM:
      % SEM will also be a 1xn vector, where the SEM is calc'd for each timepoint
      SEM_SNc = [];
      SEM_DLS = [];

      std_SNc = std(SNc_values_by_trial);
      std_DLS = std(DLS_values_by_trial);

      SEM_SNc = std_SNc ./ sqrt(num_trials);
      SEM_DLS = std_DLS ./ sqrt(num_trials);

      % Filter data
      f_SNc_ave = smooth(SNc_ave, 50, 'moving');
      f_DLS_ave = smooth(DLS_ave, 50, 'moving');
      f_SNc_ave_operant = smooth(SNc_ave_operant, 50, 'moving');
      f_DLS_ave_operant = smooth(DLS_ave_operant, 50, 'moving');
      f_SNc_ave_NOToperant = smooth(SNc_ave_NOToperant, 50, 'moving');
      f_DLS_ave_NOToperant = smooth(DLS_ave_NOToperant, 50, 'moving');

      close(h);

   end 


   %------------------------------------------------------
   %        Compute AVERAGES BUTTON Callback
   %------------------------------------------------------
   function plot_button_Callback(source,eventdata) 
      button = questdlg('What type of average?','Hey!','Aligned to Cue','Aligned to Movement', 'Aligned to Cue');
      if strcmp(button, 'Aligned to Cue')
        % Averaged trial plots: SNc
        % try
           % Averaged trial plots: SNc
            % figure, plot(f_SNc_ave, 'linewidth', 3)


            figure,
            subplot(2,1,1)
            plot(f_SNc_ave, 'linewidth', 3)
            hold on
            plot([1500, 1500], [min(f_SNc_ave(2000:end-2000))-.01,max(f_SNc_ave(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            hold on
            plot([6500, 6500], [min(f_SNc_ave(2000:end-2000))-.01,max(f_SNc_ave(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            ylim([min(f_SNc_ave(2000:end-2000))-.001,max(f_SNc_ave(2000:end-2000))+.001])
            xlim([0,18500])
            xlabel('Time (ms)', 'fontsize', 20)
            ylabel('\DeltaF/F', 'fontsize', 20)
            title('SNc Average Across Trials', 'fontsize', 20)
            set(gca, 'fontsize', 20)

            % Averaged trial plots: DLS
            subplot(2,1,2)
            plot(f_DLS_ave, 'linewidth', 3)
            hold on
            plot([1500, 1500], [min(f_DLS_ave(2000:end-2000))-.01,max(f_DLS_ave(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            hold on
            plot([6500, 6500], [min(f_DLS_ave(2000:end-2000))-.01,max(f_DLS_ave(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            xlim([0,18500])
            ylim([min(f_DLS_ave(2000:end-2000))-.001,max(f_DLS_ave(2000:end-2000))+.001])
            ylabel('\DeltaF/F', 'fontsize', 20)
            xlabel('Time (ms)', 'fontsize', 20)
            title('Striatal Average Across Trials', 'fontsize', 20)
            set(gca, 'fontsize', 20)

            % Separate averaged trial plots into pav and op trials:-------------------
            figure,
            subplot(2,2,1)
            plot(f_SNc_ave_operant, 'linewidth', 3)
            hold on
            plot([1500, 1500], [min(f_SNc_ave_operant(2000:end-2000))-.01,max(f_SNc_ave_operant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            hold on
            plot([6500, 6500], [min(f_SNc_ave_operant(2000:end-2000))-.01,max(f_SNc_ave_operant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            xlim([0,18500])
            ylim([min(f_SNc_ave_operant(2000:end-2000))-.001,max(f_SNc_ave_operant(2000:end-2000))+.001])
            title('SNc OPERANT Average Across Trials', 'fontsize', 20)
            ylabel('\DeltaF/F', 'fontsize', 20)
            xlabel('Time (ms)', 'fontsize', 20)
            set(gca, 'fontsize', 20)

            subplot(2,2,2)
            plot(f_SNc_ave_NOToperant, 'linewidth', 3)
            hold on
            plot([1500, 1500], [min(f_SNc_ave_NOToperant(2000:end-2000))-.01,max(f_SNc_ave_NOToperant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            hold on
            plot([6500, 6500], [min(f_SNc_ave_NOToperant(2000:end-2000))-.01,max(f_SNc_ave_NOToperant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            xlim([0,18500])
            ylim([min(f_SNc_ave_NOToperant(2000:end-2000))-.001,max(f_SNc_ave_NOToperant(2000:end-2000))+.001])
            title('SNc Pavlovian Average Across Trials', 'fontsize', 20)
            ylabel('\DeltaF/F', 'fontsize', 20)
            xlabel('Time (ms)', 'fontsize', 20)
            set(gca, 'fontsize', 20)

            subplot(2,2,3)
            plot(f_DLS_ave_operant, 'linewidth', 3)
            hold on
            plot([1500, 1500], [min(f_DLS_ave_operant(2000:end-2000))-.01,max(f_DLS_ave_operant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            hold on
            plot([6500, 6500], [min(f_DLS_ave_operant(2000:end-2000))-.01,max(f_DLS_ave_operant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            xlim([0,18500])
            ylim([min(f_DLS_ave_operant(2000:end-2000))-.001,max(f_DLS_ave_operant(2000:end-2000))+.001])
            title('Striatal OPERANT Average Across Trials', 'fontsize', 20)
            ylabel('\DeltaF/F', 'fontsize', 20)
            xlabel('Time (ms)', 'fontsize', 20)
            set(gca, 'fontsize', 20)

            subplot(2,2,4)
            plot(f_DLS_ave_NOToperant, 'linewidth', 3)
            hold on
            plot([1500, 1500], [min(f_DLS_ave_NOToperant(2000:end-2000))-.01,max(f_DLS_ave_NOToperant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            hold on
            plot([6500, 6500], [min(f_DLS_ave_NOToperant(2000:end-2000))-.01,max(f_DLS_ave_NOToperant(2000:end-2000))+.01], 'r-', 'linewidth', 3)
            xlim([0,18500])
            ylim([min(f_DLS_ave_NOToperant(2000:end-2000))-.001,max(f_DLS_ave_NOToperant(2000:end-2000))+.001])
            title('Striatal Pavlovian Average Across Trials', 'fontsize', 20)
            ylabel('\DeltaF/F', 'fontsize', 20)
            xlabel('Time (ms)', 'fontsize', 20)
            set(gca, 'fontsize', 20)

        % catch ex
            % errordlg('You must calculate averages before plotting in this way', 'modal');
        % end





      elseif strcmp(button, 'Aligned to Movement')




      else
        msgbox('Error with selection');
      end    
   end 










  

















%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%              COLORBAR SLIDER callbacks. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %------------------------------------------------------
   %           Colorbar Min SLIDER Callback 
   %------------------------------------------------------
    % --- Executes on slider movement.
    function min_bar_Callback(source, eventdata)
            set(htext5,'string',ceil(get(hMinSlider,'Value')));
            set(hMinSlider, 'Value', ceil(get(hMinSlider,'Value')));
    end
   %------------------------------------------------------
   %           Colorbar Max SLIDER Callback 
   %------------------------------------------------------
    % --- Executes on slider movement.
    function max_bar_Callback(source, eventdata)
            set(htext6,'string',ceil(get(hMaxSlider,'Value')));
            set(hMaxSlider, 'Value', ceil(get(hMaxSlider,'Value')));
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%              TEXT Feedback callbacks. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %------------------------------------------------------
   %           dF/F Style DLS Callback 
   %------------------------------------------------------
    % --- Executes on slider movement.
    function htext1_Callback(source, eventdata)
            set(htext1,'string',['dF/F Style DLS: ', dF_F_style_DLS]);
    end
   %------------------------------------------------------
   %           dF/F Style SNc Callback 
   %------------------------------------------------------
    % --- Executes on slider movement.
    function htext2_Callback(source, eventdata)
            set(htext2,'string',['dF/F Style SNc: ', dF_F_style_SNc]);
    end

   %------------------------------------------------------
   %           dF/F Style DLS Callback 
   %------------------------------------------------------
    % --- Executes on slider movement.
    function htext_excluded_DLS_Callback(source, eventdata)
            % convert the nx2 array into a string
            % newtext = [];
            % for i = 1:length

            set(htext_excluded_DLS,'string',['Excluded DLS Trials: ', num2str(DLS_excluded_trials)]);
    end
   %------------------------------------------------------
   %           dF/F Style SNc Callback 
   %------------------------------------------------------
    % --- Executes on slider movement.
    function htext_excluded_SNc_Callback(source, eventdata)
            set(htext_excluded_SNc,'string',['Excluded SNc Trials: ', num2str(SNc_excluded_trials)]);
    end








%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%              PRINT FIGURES callbacks. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



   %------------------------------------------------------
   %    Print Figures BUTTON Callback
   %------------------------------------------------------
    function printfigures_button_Callback(source, eventdata)
        try
        % Extract data from the workspace:
        current_array_1 = evalin('base',current_data1);
        current_array_2 = evalin('base',current_data2);

        % Get user-defined name (string) for plot title:
            cohort_values = get(hlistbox, 'Value');
            cohort_name_1 = h_datalabels(cohort_values(1));
            cohort_name_2 = h_datalabels(cohort_values(2));
        
        % Generate the figures
%-------Spectrogram #1-------------------------                        
            h_spect1 = figure('color','w','units','normalized','position',[0.3 0.3 0.4 0.5]);
                
                try
                % Estimate spectrogram #1 w/ mutitaper spectral estimation
                [spect_1, stimes, sfreqs]=mtspecgramc(current_array_1, movingwin, params);
                % Take median(spectrogram #1) across subjects
                med_spectrogram_1 = median(spect_1,3);


               % Plot median spectrogram:
              
                    imagesc(stimes, sfreqs, pow2db(med_spectrogram_1(:,:)'));
                title(cohort_name_1, 'fontsize', 15);
                axis xy; 
                ylabel('Frequency (Hz) ', 'fontsize', 15);
                xlabel('Time (s) ', 'fontsize', 15);
                xlim([0, 60])
                ylim(params.fpass)
                set(gca,'XTick',[0, 10, 20, 30, 40, 50, 60])
                set(gca,'YTick',[0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50])
                c = colorbar;
                set(gca,'clim',[get(hMinSlider, 'value'), get(hMaxSlider, 'value')], 'fontsize', 15)
                colormap('jet');
                ylabel(c,'Power (dB) ', 'fontsize', 13.5);        
                set(c, 'YTick', [-30, -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25, 30])
            catch ex
                errordlg('Problem plotting spectrograms. You must select data before printing figures. Be sure to press "Update Data" to save selections.', 'modal')
            end
 
%-------Spectrogram #2-------------------------
            h_spect2 = figure('color','w','units','normalized','position',[0.3 0.3 0.4 0.5]);

            % Estimate spectrogram #1 w/ mutitaper spectral estimation
            [spect_2, stimes, sfreqs]=mtspecgramc(current_array_2, movingwin, params);

            % Take median(spectrogram #1) across subjects
            med_spectrogram_2 = median(spect_2,3);

            % Plot median spectrogram:
            imagesc(stimes, sfreqs, pow2db(med_spectrogram_2(:,:)'));
            axis xy; 
            ylabel('Frequency (Hz) ', 'fontsize', 15);
            xlabel('Time (s) ', 'fontsize', 15);
            xlim([0, 60])
            ylim(params.fpass)
            set(gca,'XTick',[0, 10, 20, 30, 40, 50, 60])
            set(gca,'YTick',[0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50])
            c = colorbar;
            set(gca,'clim',[get(hMinSlider, 'value'), get(hMaxSlider, 'value')], 'fontsize', 15);
            ylabel(c,'Power (dB) ', 'fontsize', 13.5);        
            set(c, 'YTick', [-30, -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25, 30])
            title(cohort_name_2, 'fontsize', 15);
            
%-------Bootstrapped Spectra-------------------------                                     
            h_bsspectra = figure('color','w','units','normalized','position',[0.3 0.3 0.4 0.5]);
            % Use try command to ensure bootstraps completed already:                   
            try
   
                % CI for group 1:
                e1 = prctile(medianGroup1, 50*alpha, 2); % takes <freqs x subjects array> values = power
                yy = prctile(medianGroup1, 50, 2);
                e2 = prctile(medianGroup1, 100-50*alpha, 2);
                ee = [yy-e1 e2-yy];

                Ax(1) = shadedErrorBar(sfreqs,yy, ee', 'k',0.5);

                hold on

                % CI for group 2:
                Oe1 = prctile(medianGroup2, 50*alpha, 2); 
                Oyy = prctile(medianGroup2, 50, 2);
                Oe2 = prctile(medianGroup2, 100-50*alpha, 2);
                Oee = [Oyy-Oe1 Oe2-Oyy];

                Ax(2) = shadedErrorBar(sfreqs, Oyy, Oee','r',0.05);
    
                ylim([get(hMinSlider, 'value'), get(hMaxSlider, 'value')])
                ylabel('Power ', 'FontSize',15)
                xlabel('Frequency (Hz) ', 'FontSize', 15)
                xlim(params.fpass)
                set(gca,'fontsize', 15, 'TickDir','out');
                set(gca,'XTick',[0 10 20 30 40 50]);
                set(gca,'XMinorTick','on','YMinorTick','on');  
                legend([Ax(1).mainLine, Ax(2).mainLine], char(cohort_name_1), char(cohort_name_2));
                colormap('jet');
                box off;
                legend boxoff;
                title('Bootstrapped Spectra ', 'fontsize', 13.5);
                hold on
                plot([0, 100], [-30, -30], 'k-', 'linewidth', 1.5')
                plot([0, 0], [-100, 100], 'k-', 'linewidth', 1.5')
                set(gca,'XTick',[0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50])
                set(gca,'YTick',[-30, -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25, 30]) 
            catch ex
                errordlg('Error generating bootstrapped spectra plot. You must select data before printing figures. Be sure to press "Update Data" to save selections.', 'modal')
            end
        
%-----------Spectral Difference-----------------                
            h_difference = figure('color','w','units','normalized','position',[0.3 0.3 0.4 0.5]);
        % Use try command to ensure bootstraps completed already:
         
        
            try
                       
            plot(sfreqs(:),BootstrapCI(2,:),'r','linewidth',1)
            hold on
            plot(sfreqs(:),BootstrapCI(1,:),'b','linewidth',1)
            hold on
            if size(significantPoints) > 0
                fx_plot_piecewise_CI(significantPoints,-10) % calls a piecewise function written to write CIs, plots at -0.35
                hold on
            end
            line([0, max(sfreqs(:))],[0, 0],'Color',[0 0 0],'LineWidth',1.7) % this is the x-axis
            ylim([-15 15])
            xlim(params.fpass)
            set(gca,'fontsize', 15)
            set(gca,'XTick',[0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50])
            set(gca,'YTick',[-15, -10, -5, 0, 5, 10, 15])
            xlabel('Frequency (Hz) ', 'fontsize', 15);
            ylabel('Power Difference (dB) ', 'fontsize', 15);
            set(gca,'TickDir','out');
            box off;
            if size(significantPoints) > 0
                legend(['Upper boundary (', num2str(upperCIboundPercent), '%)'], ['Lower boundary (',num2str(lowerCIboundPercent),'%)'], 'Significant Frequencies')
            else
                legend(['Upper boundary (', num2str(upperCIboundPercent), '%)'], ['Lower boundary (',num2str(lowerCIboundPercent),'%)'])
            end
            legend boxoff  % Hides the legend's axes (legend border and background)
            str_title = sprintf('Spectral Difference: %s - %s', char(cohort_name_1), char(cohort_name_2)); 
            title(str_title, 'fontsize', 13.5)
            catch ex
                errordlg('You must select data before printing figures. Be sure to press "Update Data" to save selections.', 'modal')
            end

        
        
        
        h_save = questdlg('Save figures?','Save','yes','no','yes');
        switch h_save
            case 'yes'
            
                % Allow user to select folder to save to:
                folder_name = uigetdir('', sprintf('Select folder to save figures. This will save .fig and .eps files to this directory.'));
                cd(folder_name);

                % Choose filenames for figures:
                prompt = sprintf('Type desired filename base here.\n\nFiles will be saved as:\t\n\nfilenamebase_spect1 \t\nfilenamebase_spect2 \t\nfilenamebase_bscoherence \t\nfilenamebase_diff\n\nin .eps format.\n');
                dlg_title = 'Filename';
                num_lines = 1;
                defaultans = {'filenamebase'};
                options.Resize='on';
                h_filenamebase = inputdlg(prompt, dlg_title, num_lines, defaultans, options);

                spect1 = sprintf('%s_spect1', char(h_filenamebase));
                spect2 = sprintf('%s_spect2', char(h_filenamebase));
                bsspectra = sprintf('%s_bsspectra', char(h_filenamebase));
                diff = sprintf('%s_diff', char(h_filenamebase));


                % Now save figures
                try
    %             savefig(h_coh1,coh1)
    %             savefig(h_coh2,coh2)
    %             savefig(h_bscoherence,bscoherence)
    %             savefig(h_difference,diff)

                print(h_spect1, '-depsc2', spect1);
                print(h_spect2, '-depsc2', spect2);
                print(h_bsspectra, '-depsc2', bsspectra);
                print(h_difference, '-depsc2', diff);
                catch ex
                    errordlg('Problem saving files')
                end
        end
%                 h_close = questdlg(sprintf('Close printed figures?\n\nYour boy Fetty always saves figure files (.fig) before closing.','yes','no','yes'));
%                 switch h_close
%                     case 'yes'
%                         close(h_spect1)
%                         close(h_spect2)
%                         close(h_bsspectra)
%                         close(h_difference)
%                         h=msgbox('Fetty says, "Peace out!"');
%                     case 'no'
%                         h=msgbox('Fetty says, "Saving is a good idea." Figures will be left open.');
%                 end
        
        dlgclose = sprintf('Close printed figures without saving?\n\nYour boy Fetty always saves figure files (.fig) before closing.');
        h_close = questdlg(dlgclose,'Close','yes','no','yes');

        switch h_close
            case 'yes'
                close(h_spect1)
                close(h_spect2)
                close(h_bsspectra)
                close(h_difference)
                h=msgbox('Fetty says, "I hope you''ve got this sewed up"');
            case 'no'
                h=msgbox('Fetty says, "Saving is a good idea." Figures will be left open.');
        end
        
        
        
        
        
   end
        
        
        
    end
end





  