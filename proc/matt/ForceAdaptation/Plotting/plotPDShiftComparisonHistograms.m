function plotPDShiftComparisonHistograms(varargin)
% possible inputs:
%   baseDir
%   *usedate (use cell, if multiple loop through and add them?)
%   *adaptType
%   *useTask
%   *useTitles
%   usePeriod
%   binSize
%   maxAngle
%   classColors
%
% *these ones should be cells of same length to allow for multiple files

doAD = 0;
doWO = 0;
doBar = 0;

useColors = {[0.7 0 0],[0 0 0.7],[0 0 1]};

% some defaults
binSize = 3; %degrees
maxAngle = 45; %degrees
useArray = 'PMd';
figurePosition = [200, 200, 800, 600];
savePath = [];
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'dir'
            baseDir = varargin{i+1};
        case 'dates'
            useDate = varargin{i+1};
        case 'period'
            usePeriod = varargin{i+1};
        case 'binsize'
            binSize = varargin{i+1};
        case 'maxangle'
            maxAngle = varargin{i+1};
        case 'figurepos'
            figurePosition = varargin{i+1};
        case 'array'
            useArray = varargin{i+1};
        case 'savepath'
            savePath = varargin{i+1};
    end
end

% load plotting parameters
fontSize = 16;

histBins = -(maxAngle-binSize/2):binSize:(maxAngle-binSize/2);

adaptingCount = cell(1,size(useDate,1));
nonadaptingCount = cell(1,size(useDate,1));
fileDiffPDs = cell(1,size(useDate,1));
for iFile = 1:size(useDate,1)
    
    % only load the needed array
    classes = load(fullfile(baseDir, useDate{iFile,1}, useDate{iFile,4}, [useDate{iFile,3} '_' useDate{iFile,2} '_classes_' useDate{iFile,1} '.mat']));
    tracking = load(fullfile(baseDir, useDate{iFile,1}, [useDate{iFile,3} '_' useDate{iFile,2} '_tracking_' useDate{iFile,1} '.mat']));
    tuning = load(fullfile(baseDir, useDate{iFile,1}, useDate{iFile,4}, [useDate{iFile,3} '_' useDate{iFile,2} '_tuning_' useDate{iFile,1} '.mat']));
    
    % histograms of BL->AD and AD->WO
    
    tune_idx = classes.(useArray).regression.(usePeriod).tuned_cells;
    tune_sg = classes.(useArray).regression.(usePeriod).unit_guide;
    tuned_cells = tune_sg(tune_idx,:);
    
    % get unit guides and pd matrices
    sg_bl = tuning.BL.(useArray).regression.(usePeriod).unit_guide;
    sg_ad = tuning.AD.(useArray).regression.(usePeriod).unit_guide;
    sg_wo = tuning.WO.(useArray).regression.(usePeriod).unit_guide;
    
    pds_bl = tuning.BL.(useArray).regression.(usePeriod).pds;
    pds_ad = tuning.AD.(useArray).regression.(usePeriod).pds;
    pds_wo = tuning.WO.(useArray).regression.(usePeriod).pds;
    
    % check to make sure the unit guides are okay
    badUnits = checkUnitGuides(sg_bl,sg_ad,sg_wo);
    sg_master = setdiff(sg_bl,badUnits,'rows');
    
    % third column is PD
    cellClasses = classes.(useArray).regression.(usePeriod).classes(:,3);
    
    useComp = tracking.(useArray){1}.chan;
    
    allDiffPDs = [];
    useClasses = -1*ones(size(cellClasses));
    for unit = 1:size(sg_master,1)
        % if the cell meets the tuning criteria
        %   and also if the cell is tracked across epochs
        if ismember(sg_master(unit,:),tuned_cells,'rows')
            
            % don't include cell if it fails KS test
            relCompInd = useComp(:,1)==sg_master(unit,1)+.1*sg_master(unit,2);
            if ~any(diff(useComp(relCompInd,:)))
                
                useInd = sg_bl(:,1)==sg_master(unit,1) & sg_bl(:,2)==sg_master(unit,2);
                pds(1) = pds_bl(useInd,1);
                useInd = sg_ad(:,1)==sg_master(unit,1) & sg_ad(:,2)==sg_master(unit,2);
                pds(2) = pds_ad(useInd,1);
                useInd = sg_wo(:,1)==sg_master(unit,1) & sg_wo(:,2)==sg_master(unit,2);
                pds(3) = pds_wo(useInd,1);
                
                classInd = tune_sg(:,1)==sg_master(unit,1) & tune_sg(:,2)==sg_master(unit,2);
                useClasses(unit) = cellClasses(classInd);
                
                % BL->AD, AD->WO, BL->WO
                allDiffPDs = [allDiffPDs; angleDiff(pds(1),pds(2),true,true), angleDiff(pds(2),pds(3),true,true), angleDiff(pds(1),pds(3),true,true)];
            end
        end
    end
    
    % now count how many adapting and non-adapting cells there are
    useClasses = useClasses(useClasses~=-1);
    
    % store these for plotting later
    adaptingCount{iFile} = sum(useClasses == 2 | useClasses == 3);
    nonadaptingCount{iFile} = sum(useClasses == 1 | useClasses == 4);
    fileDiffPDs{iFile} = allDiffPDs;
end


%%
% Make histograms
if doAD
    fh = figure('Position', figurePosition);
    hold all;
    
    % group together files with same title
    titles = useDate(:,5);
    uTitles = unique(titles);
    
    
    for iFile = 1:length(uTitles)
        
        % concatenate relevant data
        groupDiffPDs = [];
        for j = 1:size(useDate,1)
            if strcmp(useDate(j,5),uTitles{iFile})
                groupDiffPDs = [groupDiffPDs; fileDiffPDs{j}(:,1)];
            end
        end
        
        % histograms of BL->AD for FF and VR
        hist(groupDiffPDs.*180/pi,histBins);
        h = findobj(gca,'Type','patch');
        
        if iFile == 1
            set(h,'FaceColor',useColors{iFile});
        else
            set(h,'EdgeColor','w','facealpha',0.7,'edgealpha',0.7);
        end
        
        arrow('Start',[mean(groupDiffPDs).*180/pi 6.5],'Stop',[mean(groupDiffPDs).*180/pi 6],'Width',3)
        
    end
    
    % add legend
    for iFile = 1:length(uTitles)
        rectangle('Position',[16 7-0.7*(iFile-1) 5 0.5],'FaceColor',useColors{iFile});
        text(22,7.25-0.7*(iFile-1),uTitles{iFile},'FontSize',16);
    end
    
    % show perturbation
    arrow('Start',[-30,7],'Stop',[-7 7],'Width',3);
    text(-30,7.5,'Perturbation Direction','FontSize',16);
    
    
    title('Baseline -> Adaptation','FontSize',18);
    xlabel('Change in PD (Deg)','FontSize',16);
    ylabel('Count','FontSize',16);
    axis('tight');
    V=axis;
    axis([V(1) V(2) 0 8]);
    set(gca,'FontSize',16);
    
    if ~isempty(savePath)
        fn = [savePath '_ad.png'];
        saveas(fh,fn,'png');
    end
end


% print -depsc2 -adobecset -painter filename.eps

%%
if doWO
    fh = figure('Position', [200, 200, 800, 600]);
    hold all;
    
    for iFile = 1:length(uTitles)
        
        % concatenate relevant data
        groupDiffPDs = [];
        for j = 1:size(useDate,1)
            if strcmp(useDate(j,5),uTitles{iFile})
                groupDiffPDs = [groupDiffPDs; fileDiffPDs{j}(:,3)];
            end
        end
        
        % histograms of BL->AD for FF and VR
        hist(groupDiffPDs.*180/pi,histBins);
        h = findobj(gca,'Type','patch');
        if iFile == 1
            set(h,'FaceColor',useColors{iFile},'EdgeColor','w');
        else
            set(h,'EdgeColor','w','facealpha',0.7,'edgealpha',0.7);
        end
    end
    
    for iFile = 1:length(uTitles)
        arrow('Start',[mean(groupDiffPDs).*180/pi 6.5],'Stop',[mean(groupDiffPDs).*180/pi 6],'Width',3)
    end
    
    % add legend
    for iFile = 1:length(uTitles)
        rectangle('Position',[16 7-0.7*(iFile-1) 5 0.5],'FaceColor',useColors{iFile});
        text(22,7.25-0.7*(iFile-1),uTitles{iFile},'FontSize',16);
    end
    
    % show perturbation
    arrow('Start',[-30,7],'Stop',[-7 7],'Width',3);
    text(-30,7.5,'Perturbation Direction','FontSize',16);
    
    
    title('Baseline -> Washout','FontSize',18);
    xlabel('Change in PD (Deg)','FontSize',16);
    ylabel('Count','FontSize',16);
    axis('tight');
    V=axis;
    axis([V(1) V(2) 0 8]);
    set(gca,'FontSize',16);
    
    if ~isempty(savePath)
        fn = [savePath '_wo.png'];
        saveas(fh,fn,'png');
    end
end


%% Now plot bar of cell counts
if doBar
    xticks = [];
    xticklabels = repmat({'Non-Adapting','Adapting'},1,length(useDate));
    
    fh = figure('Position', [200, 200, 800, 600]);
    hold all;
    for iFile = 1:length(uTitles)
        
        % concatenate relevant data
        groupAdaptingCount = 0;
        groupNonadaptingCount = 0;
        for j = 1:size(useDate,1)
            if strcmp(useDate(j,5),uTitles{iFile})
                groupAdaptingCount = groupAdaptingCount + adaptingCount{j};
                groupNonadaptingCount = groupNonadaptingCount + nonadaptingCount{j};
            end
        end
        
        xPos = [1+3*(iFile-1), 2.3+3*(iFile-1)];
        % histograms of BL->WO for FF and VR
        bar(xPos,[groupNonadaptingCount, groupAdaptingCount]);
        h = findobj(gca,'Type','patch');
        
        if iFile == 1
            set(h,'FaceColor',useColors{iFile},'EdgeColor','w');
        else
            set(h,'EdgeColor','w','facealpha',0.7,'edgealpha',0.7);
        end
        
        xticks = [xticks xPos];
    end
    
    V = axis;
    set(gca,'YTick',V(3):3:V(4),'XTick',xticks,'XTickLabel',xticklabels,'FontSize',fontSize);
    ylabel('Count','FontSize',16);
    
    if ~isempty(savePath)
        fn = [savePath '_bar.png'];
        saveas(fh,fn,'png');
    end
end
