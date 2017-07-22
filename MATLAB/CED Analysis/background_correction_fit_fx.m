function [correction_function, corrected_analog_data] = background_correction_fit_fx(analog_data)


%% Display the data:
h_plot = figure; 
plot(analog_data');
button = questdlg('Did you adjust the light intensity during the experiment?','Hey!','Yes','No','Yes');
answer = strcmp(button, 'Yes');

if answer ~= 1
	close(h_plot);
end

%% If light level was changed, allow user to select timepoint to split data on:
split_times = [];
split_values = []; 
num = 1;
keep_checking = answer;

while keep_checking == 1
	title('Select timepoint to split data by clicking');
	[split_times(num), split_values(num)] = ginput(1);
	
	button2 = questdlg(strcat('You selected sample #', num2str(split_times(num)), '. Are you happy with this selection?') ,'Hey!','Yes','No','Yes');
	answer2 = strcmp(button2, 'Yes');	
	if answer2 == 1
		button3 = questdlg(['Did you adjust the light at any other times?'] ,'Hey!','Yes','No','Yes');
		answer3 = strcmp(button3, 'Yes');	
		if answer3 == 1
			disp('checking again')
			num = num + 1;
		else
			disp('don''t check again')
			keep_checking = false;
			break
		end
    end
end
% Sort the user selections so the next step works right
split_times = sort(split_times);
split_values = sort(split_values);



%% Split the analog data into the regions to be fit:
split_analog_data_values = NaN(length(split_times)+1, length(analog_data)); %% each split gets its own row 
split_the_data = answer;

if split_the_data
	first_iter = true;

	for i_split = 1:(length(split_times)+1)
		if first_iter
			split_analog_data_values(i_split, 1:length(analog_data(1:split_times(i_split)))) = analog_data(1:split_times(i_split));
			first_iter = false;
		elseif i_split > length(split_times)
			split_analog_data_values(i_split, 1:length(analog_data(split_times(i_split-1):end))) = analog_data(split_times(i_split-1):end);
		else
			split_analog_data_values(i_split, 1:length(analog_data(split_times(i_split-1):(split_times(i_split))))) = analog_data(split_times(i_split-1):(split_times(i_split)));
		end
	end
else
	split_analog_data_values = analog_data;
end	

%% Now, for each row, make an exp fit for it:

% correction_array_x = [];
% correction_array_y = [];
number_of_fits = length(split_times)+1;
coefficient_array = NaN(number_of_fits, 2); 	% format: col1 = a, col2 = b; each row corresponds to the different breakpoints
figure
for i_row = 1:size(split_analog_data_values,1)
	% Make x and y and then transpose:
	x = size(split_analog_data_values, 2);
	x = x';
	y = split_analog_data_values(i_row, 7000:end-7000); %%%%% Note: I'm ommitting things close to the edge for a better fit
	y = y';
	% Eliminate NaNs then clip:
	x = find(y > -10000); % this eliminates NaN positions
	y = y(1:length(x));
	[fitobject{i_row},gof{i_row},output{i_row}] = fit(x,y,'exp1');
	h_plot = plot(fitobject{i_row});
	% correction_array_x(i_row, :) = get(h_plot,'XData')
	% correction_array_y(i_row, :) = get(h_plot,'YData')
	coefficient_array(i_row, :) = coeffvalues(fitobject{i_row});
	hold on
end


%% the exp fits work well! Now, use the coefficients piecewise to get the correction function
correction_function = NaN(1, length(analog_data));
split_times(length(split_times)+1) = length(analog_data); % this adds the last timepoint of analog_data to the split-point list to allow the last section to get fit

i_repeat = true;
position_counter = 1;
for i_fit = 1:number_of_fits
	%will go until counter reaches split_times(i_fit)
	a = coefficient_array(i_fit, 1);
	b = coefficient_array(i_fit, 2);
    i_repeat = true;
	while i_repeat == true
		% keep adding values until reach breakpoint, then switch to the other fit functions by breaking out of the loop
		if position_counter <= split_times(i_fit)
			% do stuff
			% use coeff of the current fit to generate a datapoint:
			correction_function(position_counter) = a*exp(b*position_counter);  % note if a = 0, then this will end up reading as NaN - basically if the end of the light function is not exp, this will give a meaningless exp fit
			position_counter = position_counter + 1;
		else
			i_repeat = false;
		end
	end
end



figure,
subplot(2,1,1)
title('Correction Function - not normalized')
plot(correction_function)

%% Normalize the correction function:

% correction_fx_max = max(correction_function);
% correction_function = correction_function./correction_fx_max;
% subplot(2,1,2)
% title('Correction Function - Normalized')
% plot(correction_function)


%% Finally, normalize the background of each analog data point:
%		@ timepoint t, multiply the analog value by 1/correction_function(t)
for i_times = 1:length(analog_data)
	corrected_analog_data(i_times) = (analog_data(i_times) - correction_function(i_times)) * 1/correction_function(i_times);
end

figure,
subplot(2,1,1)
title('Analog_data: No correction')
plot(analog_data)

subplot(2,1,2)
title('Analog_data: Corrected')
plot(corrected_analog_data)
    
    
end