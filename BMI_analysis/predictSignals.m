function [PredData] = predictSignals(varargin)

filter       = varargin{1};
BinnedData   = varargin{2};
if nargin    == 3
    FiltPred = varargin{3};
else
    FiltPred = false;
end

if ischar(filter)
    filter = LoadDataStruct(filter,'filter');
end
if ischar(BinnedData)
    BinnedData = LoadDataStruct(BinnedData,'binned');
end

spikeData = BinnedData.spikeratedata;

%get usable units from filter info
matchingInputs = FindMatchingNeurons(BinnedData.spikeguide,filter.neuronIDs);

%% Inputs:
%populate spike data for units in the filter using actual data
    % 1 - preallocate with zeros 
usableSpikeData = zeros(size(spikeData,1),size(filter.neuronIDs,1));
    % 2 - copy spike data for matching units between filter and data
for i = 1:length(matchingInputs)
    if matchingInputs(i)
        usableSpikeData(:,i)= spikeData(:,matchingInputs(i));
    end
end

% Uncomment next line to use EMGs as model inptuts:
%usableSpikeData=BinnedData.emgdatabin;

%% Outputs:  assign memory with real or dummy data, just cause predMIMO requires something there
% just send dummy data as outputs for the function
ActualData=zeros(size(spikeData));

%% Use the neural filter to predict the Data
numsides=1; fs=1;
[PredictedData,spikeDataNew,ActualEMGsNew]=predMIMO3(usableSpikeData,filter.H,numsides,fs,ActualData);

clear ActualData spikeData;

%% Threshold: apply threshold to predicted data
if isfield(filter, 'T')
if ~isempty(filter.T)
    BetweenThresholds = false(size(PredictedData));
    for z=1:size(PredictedData,2)
            BetweenThresholds(:,z) = and(PredictedData(:,z)>=filter.T(z,1),PredictedData(:,z)<=filter.T(z,2));
            PredictedData(BetweenThresholds(:,z),z)= filter.patch(z);
    end
end 
end
%% If you have one, convolve the predictions with a Wiener cascade polynomial.
if ~isempty(filter.P)
    Ynonlinear=zeros(size(PredictedData));
    for z=1:size(PredictedData,2);
        Ynonlinear(:,z) = polyval(filter.P(z,:),PredictedData(:,z));
    end
    PredictedData=Ynonlinear;
end

%% Smooth EMG Predictions, moving average with variable length based on 1st deriv of ave FR
FiltPred = true;
% 1 - Binary average lag time
% if FiltPred
%     PredictedData_S = zeros(size(PredictedData));
%     
%     PredRate = round(1/(BinnedData.timeframe(2)-BinnedData.timeframe(1)));
%     Pred_smoothlag_max = int32(0.5*PredRate); % whatever number of bins that makes 500ms
%     Pred_smoothlag_min = 0; %no smoothing.
%     
%     %abs of first derivative of (5-point smoothed) firing rate
%     FR_smoothlag = 5; %5-point moving average
%     AveFR = mean(spikeDataNew,2);
%     AveFR_S = tsmovavg(AveFR','m',FR_smoothlag);
%     AveFR(FR_smoothlag:end) = AveFR_S(FR_smoothlag:end);
%     
%     FR_mod = [ 0; abs(diff(AveFR)) ]; %abs of first derivative
% %    FR_mod = 1-(FR_mod/max(FR_mod));%normalize & inverse
% 
%     threshold = mean(FR_mod)+std(FR_mod);
%     FR_thresh = false(length(FR_mod),1);
%     FR_thresh( FR_mod >= threshold) = true;
% 
%     %now "debounce" threshold signal
%     offset_FR_thresh = [FR_thresh(2:end); false];
%     risingEdge   = find(~FR_thresh &  offset_FR_thresh);
%     clear offset_FR_thresh;
%     minBinDuration = 0.300*PredRate; %300 ms in number of bins (20Hz->6bins)
%     debounced_FR_thresh = false(size(FR_thresh));
%     
%     step =1;    
%     for i = 1:step:length(risingEdge)-minBinDuration
%         if mean(FR_thresh(risingEdge(i):risingEdge(i)+minBinDuration))>0.5
%             %mostly "up" -> debounce up
%             debounced_FR_thresh(risingEdge(i):risingEdge(i)+minBinDuration) = true;
%             step = find(risingEdge(i+1:end)-risingEdge(i)>minBinDuration,1);
%             if ~step
%                 break;
%             end
%         else
%             step = 1;
%         end
%     end     
%     
%     %higher cortical modulation -> shorter moving window for preds
%     FR_EMG_delta = round(0.1*PredRate); %100ms delay (in number of bins) between FR_mod and Preds
%     PredictedData_S(1:FR_EMG_delta) = PredictedData(1:FR_EMG_delta);
%     max_lag = FR_EMG_delta;
%         
%     FR_thresh = debounced_FR_thresh;
%     for i=1+FR_EMG_delta:size(PredictedData,1);
%         smooth_flag = true;
%         if FR_thresh(i-FR_EMG_delta)
%              %cortical activity is changing, don't smooth Preds
%             Pred_smoothlag = Pred_smoothlag_min;
%             if smooth_flag
%                 %we just entered a change in cortical activity
%                 %reset max_lag to 0 so future lag won't include
%                 %predictions older than this point
%                 max_lag = 0;
%                 smooth_flag = false;
%             end
%         else
%             %no much change in cortical activity, smooth preds
%             Pred_smoothlag = Pred_smoothlag_max;
%             smooth_flag = true;
%         end
%         Pred_smoothlag = min(max_lag,Pred_smoothlag); % in case Pred_smoothlag is longer than previous data
%         PredictedData_S(i,:) = mean(PredictedData((i-Pred_smoothlag):i,:),1);
%         max_lag = max_lag+1;
%     end
%     PredictedData = PredictedData_S;
%     clear PredictedData_S;
% end

%% 2- truely variable window length
if FiltPred
    PredictedData_S = zeros(size(PredictedData));
    
    PredRate = round(1/(BinnedData.timeframe(2)-BinnedData.timeframe(1)));
    Pred_smoothlag_max = round(0.5*PredRate); % whatever number of bins that makes 500ms
    
    %abs of first derivative of (5-point smoothed) firing rate
    FR_smoothlag = 5; %5-point moving average
    AveFR = mean(spikeDataNew,2);
    AveFR_S = tsmovavg(AveFR','m',FR_smoothlag);
    AveFR(FR_smoothlag:end) = AveFR_S(FR_smoothlag:end);
    
    FR_mod = [ 0; abs(diff(AveFR)) ]; %abs of first derivative
    FR_mod = 1-(FR_mod/max(FR_mod));%normalize & inverse
    %use exponential to weight average window length:
    % weigth w is set so when FR_mod is average, window = 63%*Pred_smoothlag_max
    w = log(1-(1/exp(1)))/(mean(FR_mod)-1);
    mod_index = round(  Pred_smoothlag_max * exp( w * (FR_mod-1))  );
    
    %then make sure mod_index do not increase by more than one from one
    %bin to the next (it can and should decrease as fast as it is though)
    mod_index_offset = [NaN; mod_index(1:end-1)];
    steep_rises = mod_index-mod_index_offset > 1;
    while any(steep_rises)
        mod_index(steep_rises) = mod_index(find(steep_rises)-1)+1;
        mod_index_offset = [NaN; mod_index(1:end-1)];
        steep_rises = mod_index-mod_index_offset > 1;
    end
    
    %higher cortical modulation -> shorter moving window for preds
    FR_EMG_delta = round(0.1*PredRate); %100ms delay (in number of bins) between FR_mod and Preds
    PredictedData_S(1:FR_EMG_delta) = PredictedData(1:FR_EMG_delta);
    
    for i=1+FR_EMG_delta:size(PredictedData,1);
        
        Pred_smoothlag = mod_index(i-FR_EMG_delta);
        Pred_smoothlag = min(i-1,Pred_smoothlag);        
        PredictedData_S(i,:) = mean(PredictedData((i-Pred_smoothlag):i,:),1);
    end
    PredictedData = PredictedData_S;
    clear PredictedData_S;
end
%% Aggregate Outputs in a Structure

[numpts,Nx]=size(usableSpikeData);
[nr,Ny]=size(filter.H);
fillen=nr/Nx;
timeframeNew = BinnedData.timeframe(fillen:numpts);
%timeframeNew = BinnedData.timeframe(fillen+1:numpts); % to account for additional bin removed at beginning of PredictedEMGs

PredData = struct('timeframe', timeframeNew,...
                  'preddatabin', PredictedData,...
                  'spikeratedata', spikeDataNew,...
                  'outnames',filter.outnames,...
                  'spikeguide', filter.neuronIDs);

end
