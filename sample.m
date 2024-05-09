% Connnect to Vibrometer on appropriate port
v = VibrometerAPI("COM17");

%%

% Get status. If vibrometer was just turned on, it should be equal to
% "Uninitialised". Hovewer if any other operations were performed it can
% have different statuses.
status = v.get_status()

% if we are running this script after succesfull finish of scanning, that
% lets prepare vibrometer again by dumping points
if(status == "Finished")
    v.dump_points();
end

%%

% if we are in the middle of scan
% (status scanning or WaitingForContinuation)
status = v.get_status();
if(status == "Scanning" || status == "WaitingForContinuation")
    % then let's first stop previous scan:
    v.stop_scan();
    pause(0.1);
    % Vibrometer table may take a while to stop the scan
    while(v.get_status() == "Stopping")
        pause(0.1);
    end
    
    % Assert that after succesfull stop, vibrometer is in Finished status.
    % If not, then something wen't wrong on vibrometer side.
    status = v.get_status();
    assert(status == "Finished", status);
    
    % after succesfull finish, move vibrometer back to ready status, by
    % dumping points from previous measurement
    v.dump_points();
end

% Just to be sure, let's assert that vibrometer is in one of the statuses:
% Ready - previous scanning was succssfully finished
% Uninitialised - Vibrometer table was just turned on
status = v.get_status();
assert(status == "Ready" || status == "Uninitialised", status);

% Now, that we are sure that we are in correct status, lets define new
% vibrometer.
% Define scanner takes 8 arguments, 4 for yaw, 4 for pitch
% They go as follows: 
% Channel (0 or 1, harware dependant)
% Starting position in degrees
% End position in degrees
% delta between next measurement positions in degrees
v.define_scanner(0, 10, 30, 5, ...
                 1, 10, 30, 5);
% Start scan, go to start position for yaw and pitch
v.start_scan()

%%

% iterate over all of the points:
while(1)
    pause(0.1);
    % status scanning means that table is trying to reach next point, so we
    % are waiting for table to do so.
    while(v.get_status() == "Scanning")
        pause(0.1);
    end
    
    % After vibrometer reaches point, get it's status
    status = v.get_status();
    
    % Finished means that it was the last point, so perform the final
    % measurment and break the loop
    if(status == "Finished")

        [yaw, pitch] = v.get_point()
        % Here goes final measurement

        break;
    end
    
    % assume that if we are not finished, than vibrometer is waiting for
    % our input to go to the next point.
    % If vibrometer is in different status, than something went terribly
    % wrong!
    assert(status == "WaitingForContinuation", status);

    % get actual point in degrees
    [yaw, pitch] = v.get_point()
    
    %perform measurement eith vibrometer:

    % Here goes measurement
    
    % Go to next point:
    v.next_point()
end

% Finalize whole measurement by dumping all of the points
v.dump_points();
%%

% Close connection with the vibrometer.
% WARNING! if connection won't be closed, for example some assert fails,
% than it is impossible to open another connection. Also, if connection via
% putty or HostApp is opened, these connections must be closed for matlab
% connection to be opened!
v.close();
