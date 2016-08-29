
function interpretArduinoMessage(messageString)

messageString = strtrim(messageString);

command = messageString(1);
if length(messageString) > 1
    value = str2num(messageString(2:end));
end

switch command
    case 'S'
        % Arduino started up
        % do nothing more
    case 'P'
        % Arduino sent a message to be printed 
        fprintf('From arduino: %i\n', value)
    case 'L'
        % New active LED
        fprintf('LED %i now active!\n', value)
    otherwise
        % unknown input
        fprintf('Received unknown command type: %s\n',command)
end
