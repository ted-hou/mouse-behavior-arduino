classdef (ConstructOnLoad) EventMarkerData < event.EventData
    properties
        Code
        Timestamp
        AbsTime
        Name
    end

    methods
        function data = EventMarkerData(code, timestamp, absTime, name)
            data.Code = code;
            data.Timestamp = timestamp;
            data.AbsTime = absTime;
            data.Name = name;
        end
    end
end