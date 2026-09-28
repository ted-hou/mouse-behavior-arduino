classdef VideoAssistantReferee
    %VIDEOASSISTANTREFEREE
    %   to make sure mouse does not lick during reach trials, and vice versa

    properties
        Camera = struct(left=[], right=[])
        Arduino
        Params
        Buffer = struct(idx=[], t=[], pose=[])
        BufferLength = 30*10; % 300 frames ~= 10s
    end

    methods
        function obj = VideoAssistantReferee(arduino, varargin)
            p = inputParser();
            p.addRequired('Arduino', @(x) isa(x, 'ArduinoConnection'))
            p.addParameter('CamId', 3) % Use left camera as default

        end
    end
end