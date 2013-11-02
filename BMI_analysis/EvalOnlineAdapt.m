function [adapt_stats,offline_stats] = EvalOnlineAdapt(binnedData, varargin)

offset_x = 6;
offset_y = 1.55;
cursgain = 55;
fix_time = 1200;
plotflag = 1;

if nargin >1
    plotflag = varargin{1};
end
% scale force to cursor pos
actual_force    = [binnedData.forcedatabin(:,1)/cursgain+offset_x ...
                    binnedData.forcedatabin(:,2)/cursgain+offset_y]; 
binnedData.forcedatabin = actual_force;
                
if nargin>2
    offline_decoder = varargin{2};
else
%     binnedData = set_catch_states(binnedData);
%     options.PredCursPos = 1; options.Use_SD = 1;
%     OfflineDecoder = BuildSDModel(binnedData, options);
%     offline_decoder = OfflineDecoder{1};
    options = [];
    options.PredForce = 1;
    offline_decoder = BuildModel(binnedData,options);

end

offline_preds   = predictSignals(offline_decoder,binnedData);

num_adapt = sum(binnedData.trialtable(:,12));
num_trials= size(binnedData.trialtable,1);

catch_trial_times = [binnedData.trialtable(binnedData.trialtable(:,12)==1,1) ... 
                      binnedData.trialtable(binnedData.trialtable(:,12)==1,8)];             
                  
adapt_stats = zeros(num_adapt,3,2);
offline_stats= zeros(num_adapt,3,2);

if plotflag
    figure; hold on; fig_x = gca;
    figure; hold on; fig_y = gca;
end
    
for i = 1:num_adapt
    catch_idx = binnedData.timeframe>catch_trial_times(i,1) & ...
                binnedData.timeframe<catch_trial_times(i,2);
    Act = double(actual_force(catch_idx,:));
    
    Curs= binnedData.cursorposbin(catch_idx,:);
    
    catch_idx = offline_preds.timeframe>catch_trial_times(i,1) & ...
                offline_preds.timeframe<catch_trial_times(i,2);
            
    Preds= offline_preds.preddatabin(catch_idx,:);
            
    adapt_stats(i,1,:) = CalculateR2(Act,Curs);
    adapt_stats(i,2,:) = 1-  sum( (Curs-Act).^2 ) ./ sum( (Act - repmat(mean(Act),size(Act,1),1)).^2);
    adapt_stats(i,3,:) = mean((Curs-Act).^2);
    
    offline_stats(i,1,:) = CalculateR2(Act,Preds);
    offline_stats(i,2,:) = 1-  sum( (Preds-Act).^2 ) ./ sum( (Act - repmat(mean(Act),size(Act,1),1)).^2);
    offline_stats(i,3,:) = mean((Preds-Act).^2);
    
    if plotflag
        xx = binnedData.timeframe(catch_idx);
        ytop = 10*ones(length(xx),1);
        ybot = -ytop;
        yarea = [ytop; ybot(end:-1:1)];
        xx = [xx; xx(end:-1:1)];
        area(fig_x,xx,yarea,'Facecolor',[.5 .5 .5],'LineStyle','none');
        area(fig_y,xx,yarea,'Facecolor',[.5 .5 .5],'LineStyle','none');
        
        plot(fig_x, binnedData.timeframe(catch_idx),binnedData.cursorposbin(catch_idx,1),'b');
        plot(fig_y, binnedData.timeframe(catch_idx),binnedData.cursorposbin(catch_idx,2),'b');
    
    end
end

if plotflag
    plot(fig_x,binnedData.timeframe,actual_force(:,1),'k'); title(fig_x,'Force X');
    plot(fig_x,offline_preds.timeframe,offline_preds.preddatabin(:,1),'r');
    plot(fig_y,binnedData.timeframe,actual_force(:,2),'k'); title(fig_y,'Force Y');
    plot(fig_y,offline_preds.timeframe,offline_preds.preddatabin(:,2),'r');

     last_adapt_trial = find(catch_trial_times(:,2)<=fix_time,1,'last');
%     plot(fig_x,[catch_trial_times(last_adapt_trial,2) catch_trial_times(last_adapt_trial,2)],...
%           ylim(),'k--','LineWidth',2);
% %       legend(fig_x,'online adapt preds','actual force','offline predictions');
%     plot(fig_y,[catch_trial_times(last_adapt_trial,2) catch_trial_times(last_adapt_trial,2)],...
%           ylim(),'k--','LineWidth',2);  
% %       legend(fig_y,'online adapt preds','actual force','offline predictions');
% 
    plot_adapt_stats(offline_stats,adapt_stats);
    
end

end


% %%
%--------------------------------
% mov_window = 5;
% 
% mas = mean(adapt_stats,3);
% mos = mean(offline_stats,3);
% 
% plot_adapt_stats(mos,mas,49);
% 
% 
% num_adapt = size(adapt_stats,1);
% 
% movav_adapt_stats   = zeros(num_adapt-mov_window,3,2);
% movav_offline_stats = zeros(num_adapt-mov_window,3,2);
% 
% for i = 1:num_adapt-mov_window
%     
%     movav_adapt_stats(i,:,:)  = mean(adapt_stats(i:i+mov_window,:,:));
%     movav_offline_stats(i,:,:)= mean(offline_stats(i:i+mov_window,:,:)); 
% end
% 
% plot_adapt_stats(movav_offline_stats,movav_adapt_stats,49); 