clear;
close all;
clc;

% loadMat = '05272013_move_peak_bin.mat';
loadMat = [];

ciSig = 30; %degrees
% doType = [0 0]; % target, peak
% doType = [0 1]; % target, initial
% doType = [0 2]; % target, final
% doType = [0 3]; % target, pre
% doType = [1 0]; % movement, peak
doType = [1 1]; % movement, initial
% doType = [1 2]; % movement, final
% doType = [1 3]; % move, pre


% Define locations
pmdDir = '/Users/Matt/Desktop/mrt/pmd/BDFStructs';
m1Dir = '/Users/Matt/Desktop/mrt/m1/BDFStructs';

useDate = '05272013';
filePreM1 = 'MrT_M1_CO_FF_';
filePrePMd = 'MrT_PMd_CO_FF_';

if isempty(loadMat)
    
    blM1File = fullfile(m1Dir,useDate,[filePreM1 'BL_' useDate '_001.mat']); %baseline file
    adM1File = fullfile(m1Dir,useDate,[filePreM1 'AD_' useDate '_002.mat']); %adaptation file
    woM1File = fullfile(m1Dir,useDate,[filePreM1 'WO_' useDate '_003.mat']); %washout file
    
    blPMdFile = fullfile(pmdDir,useDate,[filePrePMd 'BL_' useDate '_001.mat']); %baseline file
    adPMdFile = fullfile(pmdDir,useDate,[filePrePMd 'AD_' useDate '_002.mat']); %adaptation file
    woPMdFile = fullfile(pmdDir,useDate,[filePrePMd 'WO_' useDate '_003.mat']); %washout file
    
    % Get the pds for M1 cells
    disp('Baseline M1...')
    [pdsM1BL,ciM1BL,sgM1BL,ttBL] = fitTuningCurves(blM1File,[],doType,false);
    disp('Adaptation M1...')
    [pdsM1AD,ciM1AD,sgM1AD,ttAD] = fitTuningCurves(adM1File,[],doType,false);
    disp('Washout M1...')
    [pdsM1WO,ciM1WO,sgM1WO,ttWO] = fitTuningCurves(woM1File,[],doType,false);
    
    % Get the pds for PMd cells
    %    Pass in a cell array with the M1 and PMd files
    disp('Baseline PMd...')
    [pdsPMdBL,ciPMdBL,sgPMdBL] = fitTuningCurves(blPMdFile,ttBL,doType,false);
    disp('Adaptation PMd...')
    [pdsPMdAD,ciPMdAD,sgPMdAD] = fitTuningCurves(adPMdFile,ttAD,doType,false);
    disp('Washout PMd...')
    [pdsPMdWO,ciPMdWO,sgPMdWO] = fitTuningCurves(woPMdFile,ttWO,doType,false);
    
else
    load(loadMat);
    ciSig = 30; %degrees
end

% Currently I assume that the spike guide doesn't change between files
% sigM1BL = angleDiff(ciM1BL(:,1),ciM1BL(:,2)) <= ciSig;
% sigM1AD = angleDiff(ciM1AD(:,1),ciM1AD(:,2)) <= ciSig;
% sigM1WO = angleDiff(ciM1WO(:,1),ciM1WO(:,2)) <= ciSig;
%
% sigPMdBL = angleDiff(ciPMdBL(:,1),ciPMdBL(:,2)) <= ciSig;
% sigPMdAD = angleDiff(ciPMdAD(:,1),ciPMdAD(:,2)) <= ciSig;
% sigPMdWO = angleDiff(ciPMdWO(:,1),ciPMdWO(:,2)) <= ciSig;

sigM1BL = ( angleDiff(pdsM1BL,ciM1BL(:,1)) + angleDiff(pdsM1BL,ciM1BL(:,2)) ) <= ciSig;
sigM1AD = ( angleDiff(pdsM1AD,ciM1AD(:,1)) + angleDiff(pdsM1AD,ciM1AD(:,2)) ) <= ciSig;
sigM1WO = ( angleDiff(pdsM1WO,ciM1WO(:,1)) + angleDiff(pdsM1WO,ciM1WO(:,2)) ) <= ciSig;

sigPMdBL = ( angleDiff(pdsPMdBL,ciPMdBL(:,1)) + angleDiff(pdsPMdBL,ciPMdBL(:,2)) ) <= ciSig;
sigPMdAD = ( angleDiff(pdsPMdAD,ciPMdAD(:,1)) + angleDiff(pdsPMdAD,ciPMdAD(:,2)) ) <= ciSig;
sigPMdWO = ( angleDiff(pdsPMdWO,ciPMdWO(:,1)) + angleDiff(pdsPMdWO,ciPMdWO(:,2)) ) <= ciSig;

% Find cells that are tuned in all three epochs
useM1 = find(sigM1BL & sigM1AD & sigM1WO);
usePMd = find(sigPMdBL & sigPMdAD & sigPMdWO);

useCIM1BL = ciM1BL(useM1,:);
useCIPMdBL = ciPMdBL(usePMd,:);
useCIM1AD = ciM1AD(useM1,:);
useCIPMdAD = ciPMdAD(usePMd,:);
useCIM1WO = ciM1WO(useM1,:);
useCIPMdWO = ciPMdWO(usePMd,:);

diffM1_BB = wrapAngle(pdsM1BL(useM1).*(pi/180) - pdsM1BL(useM1).*(pi/180),0).*(180/pi);
diffPMd_BB = wrapAngle(pdsPMdBL(usePMd).*(pi/180) - pdsPMdBL(usePMd).*(pi/180),0).*(180/pi);

diffM1_AB = wrapAngle(pdsM1AD(useM1).*(pi/180) - pdsM1BL(useM1).*(pi/180),0).*(180/pi);
diffPMd_AB = wrapAngle(pdsPMdAD(usePMd).*(pi/180) - pdsPMdBL(usePMd).*(pi/180),0).*(180/pi);

diffM1_WB = wrapAngle(pdsM1WO(useM1).*(pi/180) - pdsM1BL(useM1).*(pi/180),0).*(180/pi);
diffPMd_WB = wrapAngle(pdsPMdWO(usePMd).*(pi/180) - pdsPMdBL(usePMd).*(pi/180),0).*(180/pi);


% figure;
% subplot1(2,1);
% subplot1(1);
% hist(diffM1_WB,10);
% subplot1(2);
% hist(diffPMd_WB,10);

% Plot raw PDs
% figure;
% hold all;
% for i = 1:length(usePMd)
%     plot([0 1 2],[pdsPMdBL(usePMd(i)), pdsPMdAD(usePMd(i)), pdsPMdWO(usePMd(i))],'k','LineWidth',2);
%     plot([0 0],[ciPMdBL(usePMd(i),1) ciPMdBL(usePMd(i),2)],'k','LineWidth',1);
%     plot([1 1],[ciPMdAD(usePMd(i),1) ciPMdAD(usePMd(i),2)],'k','LineWidth',1);
%     plot([2 2],[ciPMdWO(usePMd(i),1) ciPMdWO(usePMd(i),2)],'k','LineWidth',1);
% end
% title('PMd');
% set(gca,'XLim',[-1 3]);

% Plot differences
figure;
subplot1(2,1);
subplot1(1);
hold all;
for i = 1:length(diffM1_BB)
    % mark it as blue if it is significantly different in any epoch
    % check for overlap of CIs
    ad_sig_diff = range_intersection(useCIM1AD(i,:),useCIM1BL(i,:));
    wo_sig_diff = range_intersection(useCIM1WO(i,:),useCIM1BL(i,:));

    if isempty(ad_sig_diff) || isempty(wo_sig_diff);
        usecolor = 'b';
    else
        usecolor = 'k';
    end
    
    plot([0 1 2],[diffM1_BB(i), diffM1_AB(i), diffM1_WB(i)],'Color',usecolor,'LineWidth',2);
end
text(0.1,80,['A  M1 (N = ' num2str(length(useM1)) ')'],'FontSize',16);

subplot1(2);
hold all;
for i = 1:length(diffPMd_BB)
    % mark it as blue if it is significantly different in any epoch
    % check for overlap of CIs
    ad_sig_diff = range_intersection(useCIPMdAD(i,:),useCIPMdBL(i,:));
    wo_sig_diff = range_intersection(useCIPMdWO(i,:),useCIPMdBL(i,:));
    
    if isempty(ad_sig_diff) || isempty(wo_sig_diff);
        usecolor = 'b';
    else
        usecolor = 'k';
    end
    
    plot([0 1 2],[diffPMd_BB(i), diffPMd_AB(i), diffPMd_WB(i)],'Color',usecolor,'LineWidth',2);
end
text(0.1,-60,['B  PMd (N = ' num2str(length(usePMd)) ')'],'FontSize',16);


if 0
    % some extra analysis code
    clear;
    close all;
    load('05272013_move_peak_bin.mat');
    
    keyboard
    
    
    
end
