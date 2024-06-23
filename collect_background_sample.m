recObj = audiorecorder;
recordblocking(recObj, 10);
data = getaudiodata(recObj);

octFiltBank = octaveFilterBank('1/3 octave', recObj.SampleRate);
octFiltBank.FrequencyRange(1) = 22;
octFiltBank.FrequencyRange(2) = 4000;

data_filtered = octFiltBank(data);
data_rms_bckg = rms(data_filtered);
octaves = octFiltBank.getCenterFrequencies();
save("meas/Background.mat", "data_rms_bckg", "octaves");
%%
load('Background.mat')
fig = figure;
fig.Position = [10,10,700,300];
semilogx(octaves, data_rms_bckg);

% labeling only every second octave
labels=arrayfun(@(a)num2str(a, '%.1f'),octaves,'uni',0);
labels(2:2:end) = {' '};
xticks(octaves);
xticklabels(labels);

xlabel("Tercja [$Hz$]",'Interpreter','latex');
ylabel("Amplituda [rms($\frac{m}{s \cdot V}$)]",'Interpreter','latex');
title("Drgania tła (bez włączonego głośnika)");

saveas(fig, "graphs/BackgroundGraph.jpg");
