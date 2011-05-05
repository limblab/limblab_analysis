tic;

% clear all

addpath('Kalman');
addpath('KPMstats');
addpath('KPMtools');

%%load 2 binned data files... call trainData and testData

window = 0.500; % in seconds (for spike averaging) should match training

bin = double(trainData.timeframe(2) - trainData.timeframe(1));
window_bins = floor(window/bin);

%%adjust timing of words and target info to coincide with bins
% trainData.words(:,1) = ceil(trainData.words(:,1)./bin)*bin;
% trainData.targets.corners(:,1) = ceil(trainData.targets.corners(:,1)./bin)*bin;
% trainData.words(:,1) = ceil(trainData.words(:,1)./0.05)*0.05;
% trainData.targets.corners(:,1) = ceil(trainData.targets.corners(:,1)./0.05)*0.05;
trainData.words(:,1) = ceil(trainData.words(:,1).*20)*.05;
trainData.targets.corners(:,1) = ceil(trainData.targets.corners(:,1).*20)*.05;

%%extract target times and positions for center and outer targets
trainData.centergoals = zeros(length(find(trainData.words(:,2) == 48)),3);
trainData.centergoals(:,1) = trainData.words(trainData.words(:,2) == 48,1);
% trainData.outergoals = zeros(size(trainData.targets.corners,1),3);
trainData.outergoals = repmat(trainData.words([false; false; (trainData.words(3:end,2) >= 64 & trainData.words(3:end,2) < 80)],1),1,3);
starts = trainData.words((trainData.words(:,2) == 17),1);
for x = 1:length(trainData.outergoals)
    trial_start = starts(find(starts < trainData.outergoals(x,1),1,'last'));
    trainData.outergoals(x,2) = mean(trainData.targets.corners((trainData.targets.corners(:,1) == trial_start),[2 4]),2);
    trainData.outergoals(x,3) = mean(trainData.targets.corners((trainData.targets.corners(:,1) == trial_start),[3 5]),2);
end
trainData.goals = [trainData.centergoals; trainData.outergoals];

%%build training set
training_set = zeros(length(trainData.timeframe),(length(trainData.spikeguide)-2)*window_bins); % removed channel 70 for Chewie data
% training_set = zeros(length(trainData.timeframe),length(trainData.spikeguide)*window_bins);

transitions = zeros(length(trainData.timeframe),1);
targets = zeros(length(trainData.timeframe),2);

for x = window_bins:length(trainData.timeframe)
    observation = [];
    for y = 1:window_bins
        observation = [observation trainData.spikeratedata(x-(y-1),1:89) trainData.spikeratedata(x-(y-1),92:97)]; % removed channel 70 for Chewie data
%         observation = [observation trainData.spikeratedata(x-(y-1),:)];
    end
    training_set(x,:) = observation;

    if sum(trainData.goals(:,1) == trainData.timeframe(x))
        transitions(x) = 1;
        targets(x,:) = trainData.goals((trainData.goals(:,1) == trainData.timeframe(x)),2:3);
    end
end

%%separate training data into reaches
startindex = find(transitions);
endindex = [(startindex(2:end) - 1); length(transitions)];

n=0;
for i = 1:length(startindex)
    n=n+1;
    p = trainData.cursorposbin(startindex(i):endindex(i),:);
    v = trainData.velocbin(startindex(i):endindex(i),1:2);
    a = [zeros(1,2); diff(v)];
%     v = [zeros(1,2); diff(p)];
%     a = [zeros(2,2); diff(diff(p))];
    targ = repmat(targets(startindex(i),:),length(p),1); % make target new target position
    X{n} = [p v a targ];
    X0{n} = [p v a];
    Z{n} = training_set(startindex(i):endindex(i),:);
end

fprintf('Finished building training set\n')
toc

%%train KF parameters
[A, C, Q, R] = train_kf(X,Z);%%with target
[A0, C0, Q0, R0] = train_kf(X0,Z);%%without target
xpredc=zeros(length(transitions),6);
xpred0c = xpredc;
clear X Z X0 transitions

fprintf('Finished training\n')
toc

%%adjust timing of words and target info to coincide with bins
% testData.words(:,1) = ceil(testData.words(:,1)./bin)*bin;
% testData.targets.corners(:,1) = ceil(testData.targets.corners(:,1)./bin)*bin;
% testData.words(:,1) = ceil(testData.words(:,1)./0.05)*0.05;
% testData.targets.corners(:,1) = ceil(testData.targets.corners(:,1)./0.05)*0.05;
testData.words(:,1) = ceil(testData.words(:,1).*20)*.05;
testData.targets.corners(:,1) = ceil(testData.targets.corners(:,1).*20)*.05;

%%extract target times and positions for center and outer targets
testData.centergoals = zeros(length(find(testData.words(:,2) == 48)),3);
testData.centergoals(:,1) = testData.words(testData.words(:,2) == 48,1);
% testData.outergoals = zeros(size(testData.targets.corners,1),3);
testData.outergoals = repmat(testData.words([false; false; (testData.words(3:end,2) >= 64 & testData.words(3:end,2) < 80)],1),1,3);
starts = testData.words((testData.words(:,2) == 17),1);
for x = 1:length(testData.outergoals)
    trial_start = starts(find(starts < testData.outergoals(x,1),1,'last'));
    testData.outergoals(x,2) = mean(testData.targets.corners((testData.targets.corners(:,1) == trial_start),[2 4]),2);
    testData.outergoals(x,3) = mean(testData.targets.corners((testData.targets.corners(:,1) == trial_start),[3 5]),2);
end
% for x = 1:length(testData.outergoals)
%     testData.outergoals(x,2) = mean(testData.targets.corners((testData.targets.corners(:,1) == testData.outergoals(x,1)),[2 4]),2);
%     testData.outergoals(x,3) = mean(testData.targets.corners((testData.targets.corners(:,1) == testData.outergoals(x,1)),[3 5]),2);
% end
testData.goals = [testData.centergoals; testData.outergoals];

%%build test set
test_set = zeros(length(testData.timeframe),length(testData.spikeguide)*window_bins);

transitions = zeros(length(testData.timeframe),1);
targets = zeros(length(testData.timeframe),2);

for x = window_bins:length(testData.timeframe)
    observation = [];
    for y = 1:window_bins
        observation = [observation testData.spikeratedata(x-(y-1),:)];
    end
    test_set(x,:) = observation;

    if sum(testData.goals(:,1) == testData.timeframe(x))
        transitions(x) = 1;
        targets(x,:) = testData.goals((testData.goals(:,1) == testData.timeframe(x)),2:3);
    end
end

%%separate test data into reaches
startindex = find(transitions);
endindex = [(startindex(2:end) - 1); length(transitions)];

n=0;
for i = 1:length(startindex)
    n=n+1;
    p = testData.cursorposbin(startindex(i):endindex(i),:);
    v = testData.velocbin(startindex(i):endindex(i),1:2);
    a = [zeros(1,2); diff(v)];
%     v = [zeros(1,2); diff(p)];
%     a = [zeros(2,2); diff(diff(p))];
    targ = repmat(targets(startindex(i),:),length(p),1); % make target new target position
    X{n} = [p v a targ];
    X0{n} = [p v a];
    Z{n} = test_set(startindex(i):endindex(i),:);
end

fprintf('Finished building test set\n')
toc

%%test KF
for i = 1:length(X)
    if i == 1
        initx = X{i}(1,:)';
        initx0 = X0{i}(1,:)';
        initV = zeros(length(initx));
        initV0 = zeros(length(initx0));
    else
        initx = [xpred{i-1}(1:end-2,end); X{i}(1,end-1:end)'];
        initV = squeeze(Vpred{i-1}(:,:,end));

        initx0 = xpred0{i-1}(:,end);
        initV0 = squeeze(Vpred0{i-1}(:,:,end));
    end
    [xpred{i}, Vpred{i}, VV{i}, loglik(i)] = kalman_filter(Z{i}', A, C, Q, R, initx, initV); %%with target
    [xpred0{i}, Vpred0{i}, VV0{i}, loglik0(i)] = kalman_filter(Z{i}', A0, C0, Q0, R0, initx0, initV0); %%without target

    xpredc(startindex(i):endindex(i),:) = xpred{i}(1:6,:)';
    xpred0c(startindex(i):endindex(i),:) = xpred0{i}(1:6,:)';
end

fprintf('Finished testing\n')
toc

[r2 vaf mse] = getvaf(testData.cursorposbin(startindex(1):end,1:2),xpredc(startindex(1):end,1:2));
[r20 vaf0 mse0] = getvaf(testData.cursorposbin(startindex(1):end,1:2),xpred0c(startindex(1):end,1:2));

KF_mVAF = getmvaf(testData.cursorposbin(startindex(1):end,:),xpred0c(startindex(1):end,1:2))
KFT_mVAF = getmvaf(testData.cursorposbin(startindex(1):end,:),xpredc(startindex(1):end,1:2))

figure
plot((startindex(1):length(testData.cursorposbin))./bin, testData.cursorposbin(startindex(1):end,1),'k')
hold on
plot((startindex(1):length(testData.cursorposbin))./bin, xpredc(startindex(1):end,1),'g')
plot((startindex(1):length(testData.cursorposbin))./bin, xpred0c(startindex(1):end,1),'r')
title(['x Predictions - KFT VAF = ' num2str(vaf(1)) '; KF VAF = ' num2str(vaf0(1))])
ylabel('Handle Position (cm)')
xlabel('Time (x)')
legend('Real', 'KFT', 'KF')

figure
plot((startindex(1):length(testData.cursorposbin))./bin, testData.cursorposbin(startindex(1):end,2),'k')
hold on
plot((startindex(1):length(testData.cursorposbin))./bin, xpredc(startindex(1):end,2),'g')
plot((startindex(1):length(testData.cursorposbin))./bin, xpred0c(startindex(1):end,2),'r')
title(['y Predictions - KFT VAF = ' num2str(vaf(2)) '; KF VAF = ' num2str(vaf0(2))])
ylabel('Handle Position (cm)')
xlabel('Time (x)')
legend('Real', 'KFT', 'KF')

%%plot with transitions

figure
plot((startindex(1):length(testData.cursorposbin)).*bin, testData.cursorposbin(startindex(1):end,1)-mean(testData.cursorposbin(startindex(1):end,1)),'b')
hold on
plot((startindex(1):length(testData.cursorposbin)).*bin, xpredc(startindex(1):end,1)-mean(testData.cursorposbin(startindex(1):end,1)),'g')
plot((startindex(1):length(testData.cursorposbin)).*bin, xpred0c(startindex(1):end,1)-mean(testData.cursorposbin(startindex(1):end,1)),'r')
plot((startindex(1):length(testData.cursorposbin)).*bin, transitions(startindex(1):end)*20-20,'k*')
title(['x Predictions - KFT VAF = ' num2str(vaf(1)) '; KF VAF = ' num2str(vaf0(1))])
ylabel('Handle Position (cm)')
xlabel('Time (x)')
axis([startindex(1)*bin length(testData.cursorposbin)*bin min(xpred0c(:,1)) max(xpred0c(:,1))])
legend('Real', 'KFT', 'KF', 'Trans')

figure
plot((startindex(1):length(testData.cursorposbin)).*bin, testData.cursorposbin(startindex(1):end,2)-mean(testData.cursorposbin(startindex(1):end,2)),'b')
hold on
plot((startindex(1):length(testData.cursorposbin)).*bin, xpredc(startindex(1):end,2)-mean(testData.cursorposbin(startindex(1):end,2)),'g')
plot((startindex(1):length(testData.cursorposbin)).*bin, xpred0c(startindex(1):end,2)-mean(testData.cursorposbin(startindex(1):end,2)),'r')
plot((startindex(1):length(testData.cursorposbin)).*bin, transitions(startindex(1):end)*20-20,'k*')
title(['y Predictions - KFT VAF = ' num2str(vaf(2)) '; KF VAF = ' num2str(vaf0(2))])
ylabel('Handle Position (cm)')
xlabel('Time (x)')
axis([startindex(1)*bin length(testData.cursorposbin)*bin min(xpred0c(:,1)) max(xpred0c(:,1))])
legend('Real', 'KFT', 'KF', 'Trans')