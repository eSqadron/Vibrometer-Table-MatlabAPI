v = VibrometerAPI("COM17");
%%
v.define_scanner(1, 10, 30, 5, ...
                 0, 10, 30, 5, ...
                 100);

v.start_scan()

while(v.get_status() ~= "5")
    pause(0.1);
    while(v.get_status() == "2")
        pause(0.1);
    end

    status = v.get_status();

    if(status == "6")
        break
    end
    
    assert(status == "3", status);
    v.get_point()
    
    % Here goes measurement

    v.next_point()
end

%%
v.close()
