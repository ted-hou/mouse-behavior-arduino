classdef (ConstructOnLoad) EventMarkerData < event.EventData
    properties
        Code
        Timestamp
        DateNum
        Name
    end

    methods
        function data = EventMarkerData(code, timestamp, datenum, name)
            data.Code = code;
            data.Timestamp = timestamp;
            data.DateNum = datenum;
            data.Name = name;
        end
    end
end