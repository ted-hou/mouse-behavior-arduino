function licksplorer()
% LickSplorer v1.0 - A. Hamilos 4-27-17
% Last modified 4-27-17 by A. Hamilos
licksplorer_version = 'LickSplorer v1.0 - A. Hamilos';
button_width1 = 0.4;
button_height1 = 0.05;


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
          'Fontsize', 15,...
          'String','Load Data',...
          'Position',[.55,.95,button_width1,button_height1],...
          'Callback',{@load_data_Callback});
   %------------------------------------------------------
   %       Create Exclude Trials BUTTON 
   %------------------------------------------------------
   hexclude_trials = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', 15,...
          'String','Select Trials to Exclude',...
          'Position',[.55,.85,button_width1,button_height1],...
          'Callback',{@exclude_trials_button_Callback});      
   %------------------------------------------------------
   %        Create Calculate dF/F BUTTON 
   %------------------------------------------------------      
   hcalc_df_f = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', 15,...
          'String','Calculate dF/F',...
          'Position',[.55,.75,button_width1,button_height1],...
          'Callback',{@calculate_df_f_Callback});
   %------------------------------------------------------
   %         Create Plot Heatmap BUTTON 
   %------------------------------------------------------   
   hplot_heatmap = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'Fontsize', 15,...
          'String','Plot Heatmap',...
          'Position',[.55,.65,button_width1,button_height1],...
          'Callback',{@plot_heatmap_Callback});      
   %------------------------------------------------------
   %          Create "Select Data" Text 
   %------------------------------------------------------      
   htext1 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', 15,...
          'String','Select Data',...
          'Position',[0.55,0.6,button_width1,button_height1]);
   
      
      
      
    %------------------------------------------------------
    %            Create Listbox 
    %------------------------------------------------------              
       hlistbox = uicontrol('Style','listbox',...
              'units', 'normalized',...
              'Fontsize', 15,...
              'Position',[0.55,0.45,button_width1,.15],...
              'Callback',{@listbox_Callback},...
              'min', 0, ...
              'max', 2);    
    %------------------------------------------------------
    %         Create Update Listbox BUTTON 
    %------------------------------------------------------
       hlb_button = uicontrol('Style','pushbutton',...
              'units', 'normalized',...
              'String','Update Data Selection',...
              'Fontsize', 15,...
              'Position',[.55,.42,button_width1,button_height1],...
              'Callback',{@lb_button_Callback});
    %------------------------------------------------------
    %         Create Rename Data BUTTON 
    %------------------------------------------------------
       hrename_data_button = uicontrol('Style','pushbutton',...
              'units', 'normalized',...
              'String','Rename Datasets',...
              'Fontsize', 15,...
              'Position',[.55,.39,button_width1,button_height1],...
              'Callback',{@rename_data_button_Callback}); 
    %------------------------------------------------------
    %         Create Change Default Parameters BUTTON 
    %------------------------------------------------------
       hchange_defaults_button = uicontrol('Style','pushbutton',...
              'units', 'normalized',...
              'String','Change Default Parameters...',...
              'Fontsize', 15,...
              'Position',[.55,.35,button_width1,button_height1],...
              'Callback',{@change_defaults_button_Callback}); 
      
      
   %------------------------------------------------------
   %         Create Print Figures BUTTON 
   %------------------------------------------------------
   hprintfigures = uicontrol('Style','pushbutton',...
          'units', 'normalized',...
          'String','Print Figures',...
          'Fontsize', 15,...
          'Position',[.55,.3,button_width1,button_height1],...
          'Callback',{@printfigures_button_Callback});     
      
      
   % %------------------------------------------------------
   % %         Create Compute Bootstraps BUTTON 
   % %------------------------------------------------------
   % hbootstraps = uicontrol('Style','pushbutton',...
   %        'units', 'normalized',...
   %        'String','Compute Bootstraps',...
   %        'Fontsize', 15,...
   %        'Position',[.55,.25,0.2,0.05],...
   %        'Callback',{@bootstraps_button_Callback});     
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
          'Fontsize', 15,...
          'String','Colorbar Adjustment',...
          'Position',[0.65,0.2,.1,.02]);
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
          'Fontsize', 15,...
          'String','Min',...
          'Position',[0.65,0.16,.03,.02]);
   %------------------------------------------------------
   %       Create "Min Colorbar" Value Text (5)
   %       Displays the position of Min Slider
   %------------------------------------------------------         
   htext5 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', 15,...
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
          'Fontsize', 15,...
          'String','Max',...
          'Position',[0.775,0.16,.03,.02]);
   %------------------------------------------------------
   %       Create "Max Colorbar" Value Text (6)
   %       Displays Position of Max Slider
   %------------------------------------------------------         
   htext6 = uicontrol('Style','text',...
          'units', 'normalized',...
          'Fontsize', 15,...
          'String', get(hMaxSlider,'Value'),...
          'Position',[0.775,0.02,.03,.02]);
   
   %------------------------------------------------------
   %               Align UI Controls 
   %------------------------------------------------------   
   align([hload_data,...
       hexclude_trials,...
       hcalc_df_f,...
       hplot_heatmap,...
       htext1,...
       hlistbox,...
       hlb_button,...
       hrename_data_button,...
       hchange_defaults_button,...
       hprintfigures,...
       htext7],...
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
DLS_values_by_trial = [];
SNc_values_by_trial = [];
DLS_times_by_trial = [];
SNc_times_by_trial = [];
DLS_excluded_trials = [];
SNc_excluded_trials = [];
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
%               Callbacks to Specsplorer
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
   end
   %------------------------------------------------------
   %              SPECTROGRAM #2 BUTTON 
   %------------------------------------------------------
   function exclude_trials_button_Callback(source,eventdata)
   % Displays globally-normalized heatmap and allows user to select trials to exclude from further analysis
           
      try
        %% Choose DLS or SNc:
        button = questdlg('Exclude trials for DLS or SNc?','Hey!','DLS','SNc', 'DLS');
        if strcmp(button, 'DLS')
          current_data = DLS_values_by_trial;
        elseif strcmp(button, 'SNc')
          current_data = SNc_values_by_trial;
        else
          current_data = [];
        end

        %% Plot as heatmap...
        [h_heatmap_global_no_exclusions, heat_by_trial_global_no_exclusions] = heatmap_3_fx(current_data, [], false);
        title('Globally-normalized heatmap of df/f')

        % Allow user to select trials they want to ignore from consideration:
        button = questdlg('Exclude Trials?','Hey!','Yes','No','Yes');
        answer = strcmp(button, 'Yes');
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
          
          button2 = questdlg(['You selected trial #', num2str(floor(split_trials(num)))],'Hey!','Continue','Redo', 'Select More Trials', 'Continue');
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

        ignore_split_trials = current_data;
        for i = split_trials
          ignore_split_trials(i, :) = NaN;
        end

        if strcmp(button, 'DLS')
          DLS_values_by_trial = ignore_split_trials;
          DLS_excluded_trials = split_trials;
        elseif strcmp(button, 'SNc')
          SNc_values_by_trial = ignore_split_trials;
          SNc_excluded_trials = split_trials;
        end

        %% 3. Check heatmap now...
        [h_heatmap_global_with_exclusions, heat_by_trial_with_exlcusions] = heatmap_3_fx(ignore_split_trials, [], false);
        title('Globally-normalized heatmap without excluded trials')
             
      catch ex
            errordlg(sprintf('There was a problem, debug @ exclude_trials_button_Callback.'), 'modal');
      end

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
            current_times = DLS_times;
            current_values = DLS_values;
            split_trials = DLS_excluded_trials;
            channel = 'DLS';
          elseif strcmp(button, 'SNc')
            current_data = SNc_values_by_trial;
            times_by_trial = SNc_times_by_trial;
            split_trials = SNc_excluded_trials;
            current_times = SNc_times;
            current_values = SNc_values;
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
         



          elseif strcmp(button2, 'Global Exp')

                      %% 1. Divide all data into trials by cue on:
                      [times_by_trial, values_by_trial] = put_data_into_trials_aligned_to_cue_on_fx(current_times, current_values, trial_start_times, cue_on_times);
                      
                      %% 2. Plot as heatmap...
                      [h_heatmap, heat_by_trial] = heatmap_3_fx(values_by_trial, [], false);

                      % Allow user to select trials they want to ignore from consideration:

                      button = questdlg('Did the light intensity change during the experiment?','Hey!','Yes','No','Yes');
                      answer = strcmp(button, 'Yes');

                      if answer ~= 1
                        close(h_heatmap);
                      end

                      %% If light level was changed, allow user to select timepoint to split data on:
                      split_times = [];
                      split_trials = []; 
                      num = 1;
                      keep_checking = answer;

                      while keep_checking == 1
                        title('Select trials to split data by clicking (choose in order small->large)');
                        [split_times(num), split_trials(num)] = ginput(1);
                        
                        button2 = questdlg(strcat('You selected trial #', num2str(floor(split_trials(num)))) ,'Hey!','Continue','Redo', 'Select More Trials', 'Continue');
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









            % Get the timepoints for the splits from the times_by_trial array:
            position_1st_timestamp = min(find(times_by_trial(1,:)>-10000));
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
              val_pos_1 = min(find(times_by_trial <= split_time_begin + 0.001 & times_by_trial >= split_time_begin - 0.001));
              val_pos_2 = min(find(times_by_trial <= split_time_end + 0.001 & times_by_trial >= split_time_end - 0.001));

              belly{i_split} = current_data(val_pos_1:val_pos_2);

              split_time_begin = times_to_break(i_split, 2); % for next trial
              splitting_times_final(i_split+1, 1) = split_time_begin;
            end
            % Now do the final split:
            split_time_end = end_time;
            splitting_times_final(end, 2) = split_time_end;
            %find values position where the split times are:
            val_pos_1 = min(find(times_by_trial <= split_time_begin + 0.001 & times_by_trial >= split_time_begin - 0.001));
            val_pos_2 = min(find(times_by_trial <= split_time_end + 0.001 & times_by_trial >= split_time_end - 0.001));
            belly{end+1} = current_data(val_pos_1:val_pos_2);


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
              y=y';
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
          end

          if strcmp(button, 'DLS')
            DLS_df_f = df_f_values;
          elseif strcmp(button, 'SNc')
            SNc_df_f = df_f_values;
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
   %        Compute BOOTSTRAPS BUTTON Callback
   %------------------------------------------------------
   function bootstraps_button_Callback(source,eventdata) 
            cla(ha3,'reset') % clears bootstrapped spectral axis to prep for new Bootstrap
            cla(ha4,'reset') % clears bootstrap spectral difference axis to prep for new Bootstrap            
            
            % Alert user that Bootstraps are being computed
            h=msgbox(['Calculating Bootstraps, please wait...']);
            
            try       
%-----------% Estimate Spectrogram #1
            % Extract data from the workspace:
            current_array_1 = evalin('base',current_data1);
            % Get user-defined name (string) for plot title:
            cohort_values = get(hlistbox, 'Value');
            cohort_name_1 = h_datalabels(cohort_values(1));
            % Estimate spectrogram #1 w/ mutitaper spectral estimation
            [spect_1, ~, sfreqs]=mtspecgramc(current_array_1, movingwin, params);
                      
%-----------% Estimate Spectrogram #2
            % Extract data from the workspace:
            current_array_2 = evalin('base',current_data2);        
            % Get user-defined name (string) for plot title:
            cohort_values = get(hlistbox, 'Value');
            cohort_name_2 = h_datalabels(cohort_values(2));
            % Estimate spectrogram #2 using mutitaper spectral estimation
            [spect_2, ~, sfreqs]=mtspecgramc(current_array_2, movingwin, params);
            % spect = <times x frequencies x subjects>, value = power
          
%-----------% BOOTSTRAP: 
            % Compute bootstrap confidence intervals                                              
            [BootstrapCI,...
                significantPoints,...
                ~,...
                medianGroup1,...
                medianGroup2]...
                =bootstrap_median_AH(...
                    pow2db(spect_1),...
                    pow2db(spect_2),...
                    num_bootstraps,... % User must input # of bootstraps here!!!!**************
                    params.tapers,...
                    movingwin,...
                    sfreqs,...
                    alpha);                                                       
            catch ex
                errordlg(sprintf('You must select data 1 and data 2 before proceeding. Please select and try again. \n\nOccasionally with small bootstrap numbers the program encounters errors. If you think there''s been a mistake, press ''Compute Bootstraps'' and try again.','modal'));
            end
            close(h); 
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





  