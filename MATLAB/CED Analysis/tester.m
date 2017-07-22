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
          % htext_excluded_DLS_Callback();    % right now, this won't show chunks of missing trials, but this would be good to add later
        elseif strcmp(button_1, 'SNc')
          SNc_values_by_trial = ignore_split_trials;
          SNc_excluded_trials = excluded_trials; % split_trials;
          % htext_excluded_SNc_Callback();
        end

        %% 3. Check heatmap now...
        [h_heatmap_global_with_exclusions, heat_by_trial_with_exlcusions] = heatmap_3_fx(ignore_split_trials, [], false);
        title('Globally-normalized heatmap without excluded trials')