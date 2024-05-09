classdef VibrometerAPI
    %VIBROMETERAPI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Hidden=true)
        device
        isDefined
    end
    properties
        prec_mod = 100 % TODO - read these from driver!
        point_accuracy = 0.5;
    end
    
    methods
        function obj = VibrometerAPI(SerialPort)
            %VIBROMETERAPI Construct an instance of this class
            %   Detailed explanation goes here
            try
                obj.device = serialport(SerialPort,9600);
            catch ME
                obj.close()
                pause(0.5);
                obj.device = serialport(SerialPort,9600);
            end

            configureTerminator(obj.device,"CR");
            pause(0.5);
            flush(obj.device);

            obj.isDefined = 0;
        end
        
        function define_scanner(obj, yaw_channel, yaw_start, yaw_end, yaw_delta, pitch_channel, pitch_start, pitch_end, pitch_delta)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            ret = obj.writeline_and_get_response(sprintf('scan define yaw %d %d %d %d', yaw_channel, yaw_start*obj.prec_mod, yaw_end*obj.prec_mod, yaw_delta*obj.prec_mod));
            assert(ret == "New scanner Yaw axis defined succesfully!", ret);

            ret = obj.writeline_and_get_response(sprintf('scan define pitch %d %d %d %d', pitch_channel, pitch_start*obj.prec_mod, pitch_end*obj.prec_mod, pitch_delta*obj.prec_mod));
            assert(ret == "New scanner Pitch axis defined succesfully!", ret);

            ret = obj.writeline_and_get_response('scan ready');
            assert(ret == "Sucessfully defined scanner!", ret);

            obj.isDefined = 1;
        end
        
        function actual_point = get_position(obj, channel)
            ret = obj.writeline_and_get_response(strcat("channel ", num2str(channel)));
            assert(ret == strcat("channel set to: ", num2str(channel)), ret);

            ret = obj.writeline_and_get_response("pos");

            actual_point = extractAfter(ret,"Position: ");
            actual_point = str2double(actual_point)/obj.prec_mod;
        end

        function go_to_position(obj, channel, point_degree)
            point_degree = point_degree * obj.prec_mod;
            ret = obj.writeline_and_get_response("mode pos");
            assert(ret == "mode set to: pos", ret);

            ret = obj.writeline_and_get_response('motor start');
            assert(ret == strcat("Motor started forward successfully on channel ", num2str(channel),"!"), ret);

            ret = obj.writeline_and_get_response(strcat("channel " + num2str(channel)));
            assert(ret == strcat("channel set to: ", num2str(channel)), ret);

            ret = obj.writeline_and_get_response(strcat("pos ", num2str(point_degree)));
            assert(ret == strcat("Position set to: ", num2str(point_degree)), ret);
            
            
            pause(0.7);
            ret = obj.writeline_and_get_response('actual_direction');
            while(~contains(ret, "Motor is stationary!"))
                pause(0.1);
                ret = obj.writeline_and_get_response('actual_direction');
            end

            ret = obj.writeline_and_get_response('motor stop');
            assert(ret == strcat("Motor stopped successfully on channel ", num2str(channel),"!"), ret);

        end

        function zero_position(obj, channel)
            ret = obj.writeline_and_get_response(strcat("channel ", num2str(channel)));
            assert(ret == strcat("channel set to: ", num2str(channel)), ret);

            ret = obj.writeline_and_get_response("pos zero");
            assert(ret == "Position reset succesfull", ret);
        end
        
        function start_scan(obj)
            ret = obj.writeline_and_get_response('scan start');
            assert(ret == "Sucessfully started scan!", ret);
        end

        function stop_scan(obj)
            ret = obj.writeline_and_get_response('scan stop');
            assert(ret == "Succesfully stopped scanner!", ret);
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
        
        function full_response = dump_points(obj)
            writeline(obj.device, 'scan dump');
            readline(obj.device);
            first_line = strtrim(readline(obj.device));
            point_count = extractBetween(first_line,"Dumping last "," points!");
            point_count = str2double(point_count);

            full_response = first_line + newline;

            for line = 1:point_count
                full_response = full_response + strtrim(readline(obj.device)) + newline;
            end
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

