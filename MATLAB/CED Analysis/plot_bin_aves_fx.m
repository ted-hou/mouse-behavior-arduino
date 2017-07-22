function [] = plot_bin_aves_fx(DLS_bin_aves, SNc_bin_aves, nbins)

figure,
subplot(1,2,1)

for ibins = 2:nbins+1
	plot(smooth(DLS_bin_aves{ibins}, 500, 'moving'), 'linewidth', 3);
	hold on;
	names{ibins-1} = ['Bin # ', num2str(ibins)];
	xlim([0,18500])
	ylim([min(DLS_bin_aves{2})-.001,max(DLS_bin_aves{2})+.001])
end
legend(names);
% ylim([min(DLS_bin_aves{nbins})-.001,max(DLS_bin_aves{2})+.001])
ylim([-.5,.5])
hold on
plot([1500, 1500], [min(DLS_bin_aves{2})-.01,max(DLS_bin_aves{2})+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(DLS_bin_aves{2})-.01,max(DLS_bin_aves{2})+.01], 'r-', 'linewidth', 3)
title('DLS binned averages');
xlabel('time (ms)')
ylabel('signal')


subplot(1,2,2)

for ibins = 2:nbins+1
	plot(smooth(SNc_bin_aves{ibins}, 500, 'moving'), 'linewidth', 3);
	hold on;
	names{ibins-1} = ['Bin # ', num2str(ibins)];
	xlim([0,18500])
	ylim([min(SNc_bin_aves{2})-.001,max(SNc_bin_aves{2})+.001])
end
legend(names);
ylim([-.5,.5])
hold on
plot([1500, 1500], [min(SNc_bin_aves{2})-.01,max(SNc_bin_aves{2})+.01], 'r-', 'linewidth', 3)
hold on
plot([6500, 6500], [min(SNc_bin_aves{2})-.01,max(SNc_bin_aves{2})+.01], 'r-', 'linewidth', 3)
title('SNc binned averages');
xlabel('time (ms)')
ylabel('signal')


% % figure,
% % for ibins = 2:nbins+1
% % 	subplot(nbins+1,1,ibins)
% % 	plot(smooth(DLS_bin_aves{ibins}, 500, 'moving'), 'linewidth', 3);
% % 	hold on;
% % 	title(['DLS Bin # ', num2str(ibins)]);
% % 	xlabel('time (ms)')
% % 	ylabel('signal')
% % 	xlim([0,18500])
% % 	% ylim([min(DLS_bin_aves{ibins+1})-.001,max(DLS_bin_aves{ibins+1})+.001])
% % 	ylim([-.5,.5])
% % 	hold on
% % 	plot([1500, 1500], [-.5,.5], 'r-', 'linewidth', 3)
% % 	hold on
% % 	% plot([6500, 6500], [min(DLS_bin_aves{ibins+1})-.01,max(DLS_bin_aves{ibins+1})+.01], 'r-', 'linewidth', 3)
% % 	plot([6500, 6500], [-.5,.5], 'r-', 'linewidth', 3)
% % end
% % 
% % 
% % figure,
% % for ibins = 2:nbins+1
% % 	subplot(nbins+1,1,ibins)
% % 	plot(smooth(SNc_bin_aves{ibins},500,'moving'), 'linewidth', 3);
% % 	hold on;
% % 	title(['SNc Bin # ', num2str(ibins)]);
% % 	xlabel('time (ms)')
% % 	ylabel('signal')
% % 	xlim([0,18500])
% % 	% ylim([min(SNc_bin_aves{ibins+1})-.001,max(SNc_bin_aves{ibins+1})+.001])
% % 	ylim([-.5,.5])
% % 	hold on
% % 	plot([1500, 1500], [-.5,.5], 'r-', 'linewidth', 3)
% % 	hold on
% % 	plot([6500, 6500], [-.5,.5], 'r-', 'linewidth', 3)
% % end







end