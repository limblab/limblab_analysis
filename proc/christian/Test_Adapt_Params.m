
function [R2, info] = Test_Adapt_Params()

filter = load('C:\Documents and Settings\Christian\Desktop\Adaptation2_new_sort\Strick_mid_7-9-10_001_filter.mat');
field_name = fieldnames(filter);
filter = getfield(filter, field_name{:});

TestData = load('C:\Documents and Settings\Christian\Desktop\Adaptation2_new_sort\7-9,10,11,13.mat');
field_name = fieldnames(TestData);
TestData = getfield(TestData,field_name{:});

Adapt_Enable = true;
LR = 1e-7;
Adapt_Lag = 0.45;
binsize = filter.binsize;
foldlength = 60;
duration = size(TestData.timeframe,1);
nfold = floor(round(binsize*1000)*duration/(1000*foldlength)); % again, because of floating point errors

% Adapt_Lag = 0:0.05:0.15;
% R2 = zeros(nfold,2,length(Adapt_Lag));
Tested_Param = 'LR';
LR = (31.25e-10)*2.^(0:9);
R2 = zeros(nfold,size(filter.outnames,1),length(LR));
MR2 = zeros(length(LR),2);

for i = 1:length(eval(Tested_Param))
    [R2(:,:,i), nfold] = mfxval_fixed_model(filter,TestData,foldlength,Adapt_Enable,LR(i),Adapt_Lag);
    MR2(i,:) = mean(R2(:,:,i));
end

info = struct('LR',LR,'Adapt_Lag',Adapt_Lag,'foldlength',foldlength,'nfold',nfold,'Tested_Param',Tested_Param);

figure;
hold on;
plot(eval(Tested_Param),[MR2 mean(MR2,2)],'.-');
legend(filter.outnames(1,:),filter.outnames(2,:),'average');

end
