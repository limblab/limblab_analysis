function [r_map,r_map_mean, rho, pval, f, x] = CorrCoeffMap(Data,PlotOn,DecoderAge)

r_map = zeros(size(Data,2), size(Data,2));

for i = 1:size(Data,2)
    for j = 1:size(Data,2)
    r_r = circ_nancorrcc(Data(:,i),Data(:,j));
    r_map(i,j) = r_r;
%     r_r = corrcoef(r2_Y_SingleUnitsSorted_DayAvg(:,i),r2_Y_SingleUnitsSorted_DayAvg(:,j));
%     r_r_Y_SingleUnitsDayAvg(i,j) = r_r(1,2);
    end
end

figure
imagesc(r_map)
title('Correlation Coefficient Map of Cosine tuning model of spikes')
xlabel('LFP Decoder Age')
ylabel('LFP Decoder Age')

for i=1:size(Data,2)
    inds=setdiff(1:(size(Data,2)),i);
    r_map_mean(i)=mean(r_map(inds,i));
end

if PlotOn == 1   
    figure
    if iscell(DecoderAge)
        x = cell2mat(DecoderAge)';
    else
        x = DecoderAge;
    end
    
    plot(x(32:end), r_map_mean_Offline(32:end),'ko')
    xlabel('Decoder Age')
    ylabel('Mean Correlation Coefficient')
    title('Mean Corr Coeff of PD Map')
    
    Xticks = x(1:5:end); % size(Xlabels,1)];
    Xticks = [Xticks' get(gca,'Xtick')]';
    Xticks = sort(Xticks)
    Xticks = unique(Xticks);
    set(gca,'XTick',Xticks,'XTickLabel',Xticks)
    
    hold on 
    p = polyfit(x,r_map_mean,1);
    f = polyval(p,x);
    plot(x(32:end),f(32:end),'k-')
    
    [rho pval] = corr(x',r_map_mean')
    legend('Mean PD Map Correlation',['Linear Fit - ','R= ' num2str(rho,4) '  (P = ',num2str(pval),')'])
    
end

% f = fittype('a*x+b','independent','x','coefficient',{'a' 'b'})
% [c2,gof2] = fit(x',r_map_mean',f,'startpoint',[0,0])
% plot(c2,'c-x')
