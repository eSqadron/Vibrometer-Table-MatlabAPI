classdef VibrometerAPI
    %VIBROMETERAPI Class that controls table for vibrometer positioning
    %using serial port communication
    
    properties (Hidden=true)
        device
    end
    properties
        prec_mod = 100 % TODO - read these from driver!
        point_accuracy = 0.5;
    end
    
    methods
        function obj = VibrometerAPI(SerialPort)
            %VIBROMETERAPI Construct an instance of this class and connect 
            % to specified serial port
            % WARNING! In order to opne serial port, there can be no other
            % instances of that port open! Every other instance needs to be
            % closed.
            try
                obj.device = serialport(SerialPort, 9600);
            catch
                % TODO - make closing and opening work!
                obj.close()
                pause(0.5);
                obj.device = serialport(SerialPort, 9600);
            end

            configureTerminator(obj.device,"CR");
            pause(0.5);
            flush(obj.device);
        end
        
        function define_scanner(obj, yaw_channel, yaw_start, yaw_end, yaw_delta, pitch_channel, pitch_start, pitch_end, pitch_delta)
            % define scanner matrix of points. First yaw axis, then pitch.
            % Arguments go as follows:
            % Channel (0 or 1, harware dependant)
            % Starting position in degrees
            % End position in degrees
            % delta between next measurement positions in degrees

            % TODO - get status

            ret = obj.writeline_and_get_response(sprintf('scan define yaw %d %d %d %d', yaw_channel, yaw_start*obj.prec_mod, yaw_end*obj.prec_mod, yaw_delta*obj.prec_mod));
            assert(ret == "New scanner Yaw axis defined succesfully!", ret);

            ret = obj.writeline_and_get_response(sprintf('scan define pitch %d %d %d %d', pitch_channel, pitch_start*obj.prec_mod, pitch_end*obj.prec_mod, pitch_delta*obj.prec_mod));
            assert(ret == "New scanner Pitch axis defined succesfully!", ret);

            ret = obj.writeline_and_get_response('scan ready');
            assert(ret == "Sucessfully defined scanner!", ret);
        end
        
        function actual_position = get_position(obj, channel)
            % Get position of single motor on specified channel
            ret = obj.writeline_and_get_response(strcat("channel ", num2str(channel)));
            assert(ret == strcat("channel set to: ", num2str(channel)), ret);

            ret = obj.writeline_and_get_response("pos");

            actual_position = extractAfter(ret,"Position: ");
            actual_position = str2double(actual_position)/obj.prec_mod;
        end

        function go_to_position(obj, channel, point_degree)
            % Turn one motor on specific channel to specified position

            % TODO - check if scanning isn't being performed!
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
            % set current position on specified channel to zero degrees.

            % TODO - check if scanning isn't being performed!

            ret = obj.writeline_and_get_response(strcat("channel ", num2str(channel)));
            assert(ret == strcat("channel set to: ", num2str(channel)), ret);

            ret = obj.writeline_and_get_response("pos zero");
            assert(ret == "Position reset succesfull", ret);
        end
        
        function start_scan(obj)
            % Start scan, go to position (yaw_start; pitch_start)

            %TODO - check if state ready

            ret = obj.writeline_and_get_response('scan start');
            assert(ret == "Sucessfully started scan!", ret);
        end

        function stop_scan(obj)
            % Break scan prematurely
            
            % TODO - check if scan is being currently performed

            ret = obj.writeline_and_get_response('scan stop');
            assert(ret == "Succesfully stopped scanner!", ret);
        end

        function status = get_status(obj)
            % Get status of current scan

            status = obj.writeline_and_get_response('scan status');
            status = extractAfter(status,"status: ");
        end

        function [yaw, pitch] = get_point(obj)
            % get point at which table currently is as a [yaw; pitch] pair.
             

            % TODO - check if scanner is defined

            point_str = obj.writeline_and_get_response('scan get_point');
            yaw =  extractBetween(point_str,"Yaw: ",", Pitch: ");
            pitch = extractAfter(point_str,", Pitch: ");
            yaw = str2double(yaw)/100;
            pitch = str2double(pitch)/100;
        end

        function next_point(obj)
            % If scanner is waiting for user interaction, 
            % move to next point in mesh of points
            
            % TODO - check status

            ret = obj.writeline_and_get_response('scan next_point');
            assert(ret == "Succesfully started movement to next point!", ret);
        end
        
        function full_response = dump_points(obj)
            % dump all of the points at which scanner was since last dump
            % or beggining of the measurement. Also, if in status finished,
            % move to status ready

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
            % Close serial port

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

