classdef VibrometerAPI
    %VIBROMETERAPI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Hidden=true)
        device
    end
    properties
        prec_mod = 100
    end
    
    methods
        function obj = VibrometerAPI(SerialPort)
            %VIBROMETERAPI Construct an instance of this class
            %   Detailed explanation goes here
            obj.device = serialport(SerialPort,9600);
            configureTerminator(obj.device,"CR");
            pause(0.5);
            flush(obj.device);
        end
        
        function define_scanner(obj, yaw_channel, yaw_start, yaw_end, yaw_delta, pitch_channel, pitch_start, pitch_end, pitch_delta, time_delta)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            ret = obj.writeline_and_get_response(sprintf('scan define yaw %d %d %d %d', yaw_channel, yaw_start*obj.prec_mod, yaw_end*obj.prec_mod, yaw_delta*obj.prec_mod));
            assert(ret == "New scanner Yaw axis defined succesfully!", ret);

            ret = obj.writeline_and_get_response(sprintf('scan define pitch %d %d %d %d', pitch_channel, pitch_start*obj.prec_mod, pitch_end*obj.prec_mod, pitch_delta*obj.prec_mod));
            assert(ret == "New scanner Pitch axis defined succesfully!", ret);

            ret = obj.writeline_and_get_response(sprintf('scan define time %d', time_delta));
            assert(ret == "New scanner wait ime between points specified to 100!", ret);

            ret = obj.writeline_and_get_response('scan ready');
            assert(ret == "Sucessfully defined scanner!", ret);
        end

        function start_scan(obj)
            ret = obj.writeline_and_get_response('scan start');
            assert(ret == "Sucessfully started scan!", ret);
        end

        function status = get_status(obj)
            status = obj.writeline_and_get_response('scan status');
            status = extractAfter(status,"status: ");
        end

        function [yaw, pitch] = get_point(obj)
            point_str = obj.writeline_and_get_response('scan get_point');
            yaw =  extractBetween(point_str,"Yaw: ",", Pitch: ");
            pitch = extractAfter(point_str,", Pitch: ");
            yaw = str2double(yaw)/100;
            pitch = str2double(pitch)/100;
        end

        function next_point(obj)
            ret = obj.writeline_and_get_response('scan next_point');
            assert(ret == "Succesfully started movement to next point!", ret);
        end
        
        function close(obj)
            delete(obj.device)
        end
    end
    methods (Hidden=true)
        function response = writeline_and_get_response(obj, write_string)
            writeline(obj.device, write_string);
            readline(obj.device);
            response = strtrim(readline(obj.device));
        end

    end
end

