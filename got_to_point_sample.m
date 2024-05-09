v = VibrometerAPI("COM17");

% direct position control is independent of vibrometer definition. So it is
% done using channels, not yaw/pitch axes, because yaw/pitch axes may not
% be defined yet.

% reminder: Channel 0 is one cloaser to USB on pcb, Channel 1 is one
% further from USB, closer to the edge of pcb

% For both channels:
for channel=0:1
    disp(strcat("channel: ", num2str(channel)))

    % Get current position of channel motor
    point_st = v.get_position(channel);

    % Go to position 10 degree forward
    v.go_to_position(channel, point_st + 10);

    % Get new position
    point_end = v.get_position(channel);
    disp(strcat("Moved from ", num2str(point_st), " to ", num2str(point_end)))

    pause(0.5);

    % zero position. Set new positon as zero degrees
    v.zero_position(channel);
    point_zeroed = v.get_position(channel);
    disp(strcat("Position was set as zero degree: ", num2str(point_zeroed)))
end

%%
v.close();