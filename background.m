recObj = audiorecorder;
recordblocking(recObj, 10);
data = getaudiodata(recObj);

octFiltBank = octaveFilterBank('1/3 octave', recObj.SampleRate);
octFiltBank.FrequencyRange(1) = 22;
octFiltBank.FrequencyRange(2) = 4000;

data_filtered = octFiltBank(data);
data_rms_bckg = rms(data_filtered);

figure
plot(octFiltBank.getCenterFrequencies(), data_rms_bckg);

save("Background.mat", "data_rms_bckg");