%% Pull out raw fluorescence:

raw_DLS = h4_day22_allop_0ms_DLS.values;
raw_SNc = h4_day22_allop_0ms_SNc.values;

%%
figure, plot(raw_DLS), title('DLS')
figure, plot(raw_SNc), title('SNc')
