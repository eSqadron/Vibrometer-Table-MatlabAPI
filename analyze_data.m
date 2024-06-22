load('steel_plate_measurement.mat')

octFiltBank = octaveFilterBank('1/3 octave', s.Fs);
octFiltBank.FrequencyRange(1) = 22;
octFiltBank.FrequencyRange(2) = 4000;

octaves_count = size(octFiltBank(s.measurements(1).data), 2);

analyzed_measurements = zeros(s.meas_counter, octaves_count);
yaws = zeros(s.meas_counter, 1);
pitches = zeros(s.meas_counter, 1);

for i = 1:s.meas_counter
    audio_in_octaves = octFiltBank(s.measurements(i).data);
    energy_in_octaves = rms(audio_in_octaves);
    energy_vectored = energy_in_octaves * ...
                      cos(deg2rad(s.measurements(i).yaw + s.yaw_offset)) * ...
                      cos(deg2rad(s.measurements(i).pitch + s.pitch_offset));

    analyzed_measurements(i, :) = energy_vectored;
    if(s.measurements(i).yaw > 180)
        yaws(i) = s.measurements(i).yaw - 360;
    else
        yaws(i) = s.measurements(i).yaw;
    end

    if(s.measurements(i).pitch > 180)
        pitches(i) = s.measurements(i).pitch - 360;
    else
        pitches(i) = s.measurements(i).pitch;
    end
end

octaves = octFiltBank.getCenterFrequencies();
%%
mkdir("graphs");
for i = 1:octaves_count
    fig = figure;
    xlin = linspace(min(yaws), max(yaws), 100);
    ylin = linspace(min(pitches), max(pitches), 100);
    [X,Y] = meshgrid(xlin, ylin);
    Z = griddata(yaws, pitches, analyzed_measurements(:,i), X, Y, 'v4');
    mesh(X,Y,Z);
    %clim([0.002, 0.1]);
    xlabel("yaw [$^{\circ}$]",'Interpreter','latex');
    ylabel("pitch [$^{\circ}$]",'Interpreter','latex');
    %zlabel("rms()");
    hcb=colorbar;
    colormap('jet');
    hcb.Title.String = "$\frac{m}{s \cdot V}$";
    hcb.Title.Interpreter = 'latex';
    view(0,90);
    title(strcat("Wykres dla tercji ", num2str(octaves(i), '%.1f'), "Hz"));
    saveas(fig, "graphs/" + num2str(i, '%2.0f') + "_GraphThird.jpg");
end