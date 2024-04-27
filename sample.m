v = VibrometerAPI("COM17");
%%
v.define_scanner(1, 10, 30, 5, ...
                 0, 10, 30, 5, ...
                 100);

v.start_scan()

while(v.get_status() ~= "Finished")
    pause(0.1);
    while(v.get_status() == "Scanning")
        pause(0.1);
    end

    status = v.get_status();

    if(status == "Finished")
        break;
    end
    
    assert(status == "WaitingForContinuation", status);
    [yaw, pitch] = v.get_point()
    
    % Here goes measurement

    v.next_point()
end

%%
v.close()
