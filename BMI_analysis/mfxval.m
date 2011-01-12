function [R2, nfold] = mfxval(binnedData, States, dataPath, foldlength, fillen, UseAllInputsOption, PolynomialOrder,varargin)
%       R2                  : returns a (numFold,numSignals) array of R2 values, and number of folds 
%
%       binnedData          : data structure to build model from
%       dataPath            : string of the path of the data folder
%       foldlength          : fold length in seconds (typically 60)
%       fillen              : filter length in seconds (tipically 0.5)
%       UseAllInputsOption  : 1 to use all inputs, 2 to specify a neuronID file
%       PolynomialOrder     : order of the Weiner non-linearity (0=no Polynomial)
%       varargin = {PredEMG, PredForce, PredCursPos, PredVeloc, Use_Thresh, Use_SD,plotflag} : flags to include
%       EMG, Force, CursPos, Velocity in the prediction model (0=no,1=yes) also options to use State-dependent dec.

if ~isstruct(binnedData)
    binnedData = LoadDataStruct(binnedData, 'binned');
end

% default value for prediction flags
PredEMG = 1;
PredForce = 0;
PredCursPos = 0;
PredVeloc = 0;
%TODO: Use_Thresh?
plotflag = 1;

numSig    = size(binnedData.emgguide,1);
numStates = size(States,2);

%overwrite if specified in arguments
if nargin > 6
    PredEMG = varargin{1};
    if ~PredEMG
        numSig = 0;
    end
    if nargin > 7
        PredForce = varargin{2};
        if PredForce
            numSig = numSig+size(binnedData.forcelabels,1);
        end
        if nargin > 8
            PredCursPos = varargin{3};
            if PredCursPos
                numSig = numSig+size(binnedData.cursorposlabels,1);
            end
            if nargin > 9
                PredVeloc = varargin{4};
                if PredVeloc
                    numSig = numSig+size(binnedData.veloclabels,1);
                end
                if nargin > 11
                    Use_SD= varargin{6};
                    if nargin >12
                        plotflag = varargin{7};
                    end
                end
            end
        end
    end
end


binsize = binnedData.timeframe(2)-binnedData.timeframe(1);

if mod(round(foldlength*1000), round(binsize*1000)) %all this rounding because of floating point errors
    disp('specified fold length must be a multiple of the data bin size');
    disp('operation aborted');
    return;
end

duration = size(binnedData.timeframe,1);
nfold = floor(round(binsize*1000)*duration/(1000*foldlength)); % again, because of floating point errors
dataEnd = round(nfold*foldlength/binsize);
R2 = zeros(nfold,numSig);
    
%allocate structs
testData = binnedData;
modelData = binnedData;

for i=0:nfold-1
    
    disp(sprintf('processing xval %d of %d',i+1,nfold));

    testDataStart = round(1 + i*foldlength/binsize);      %move the test block from beginning of file up to the end,round because of floating point error
    testDataEnd = round(testDataStart + foldlength/binsize - 1);    

    %copy timeframe and spikeratedata segments into testData
    testData.timeframe = binnedData.timeframe(testDataStart:testDataEnd);
    testData.spikeratedata = binnedData.spikeratedata(testDataStart:testDataEnd,:);
    if Use_SD
        testData.state = binnedData.state(testDataStart:testDataEnd,:);
    end
    
    %copy timeframe and spikeratedata segments into modelData
    if testDataStart == 1
        modelData.timeframe = binnedData.timeframe(testDataEnd+1:dataEnd);    
        modelData.spikeratedata = binnedData.spikeratedata(testDataEnd+1:dataEnd,:);
        if Use_SD
            modelData.state = binnedData.state(testDataEnd+1:dataEnd,:);
        end
    elseif testDataEnd == dataEnd
        modelData.timeframe = binnedData.timeframe(1:testDataStart-1);
        modelData.spikeratedata = binnedData.spikeratedata(1:testDataStart-1,:);
        if Use_SD
            modelData.state = binnedData.state(1:testDataStart-1,:);
        end
    else
        modelData.timeframe = [ binnedData.timeframe(1:testDataStart-1); binnedData.timeframe(testDataEnd+1:dataEnd)];
        modelData.spikeratedata = [ binnedData.spikeratedata(1:testDataStart-1,:); binnedData.spikeratedata(testDataEnd+1:dataEnd,:)];        
        if Use_SD
            modelData.state = [ binnedData.state(1:testDataStart-1); binnedData.state(testDataEnd+1:dataEnd)];
        end
    end

    % copy emgdatabin segment into modelData only if PredEMG
    if PredEMG
        testData.emgdatabin = binnedData.emgdatabin(testDataStart:testDataEnd,:);    
        if testDataStart == 1
            modelData.emgdatabin = binnedData.emgdatabin(testDataEnd+1:dataEnd,:);    
        elseif testDataEnd == dataEnd
            modelData.emgdatabin = binnedData.emgdatabin(1:testDataStart-1,:);
        else
            modelData.emgdatabin = [ binnedData.emgdatabin(1:testDataStart-1,:); binnedData.emgdatabin(testDataEnd+1:dataEnd,:)];
        end
    end

    % copy forcedatabin segment into modelData only if PredForce
    if PredForce
        testData.forcedatabin = binnedData.forcedatabin(testDataStart:testDataEnd,:);    
        if testDataStart == 1
            modelData.forcedatabin = binnedData.forcedatabin(testDataEnd+1:dataEnd,:);    
        elseif testDataEnd == dataEnd
            modelData.forcedatabin = binnedData.forcedatabin(1:testDataStart-1,:);
        else
            modelData.forcedatabin = [ binnedData.forcedatabin(1:testDataStart-1,:); binnedData.forcedatabin(testDataEnd+1:dataEnd,:)];
        end
    end

    % copy cursorposbin segment into modelData only if PredCursPos
    if PredCursPos
        testData.cursorposbin = binnedData.cursorposbin(testDataStart:testDataEnd,:);    
        if testDataStart == 1
            modelData.cursorposbin = binnedData.cursorposbin(testDataEnd+1:dataEnd,:);    
        elseif testDataEnd == dataEnd
            modelData.cursorposbin = binnedData.cursorposbin(1:testDataStart-1,:);
        else
            modelData.cursorposbin = [ binnedData.cursorposbin(1:testDataStart-1,:); binnedData.cursorposbin(testDataEnd+1:dataEnd,:)];
        end
    end    
    
    % copy velocbin segement into modelData only if PredVeloc
    if PredVeloc
        testData.velocbin = binnedData.velocbin(testDataStart:testDataEnd,:);    
        if testDataStart == 1
            modelData.velocbin = binnedData.velocbin(testDataEnd+1:dataEnd,:);    
        elseif testDataEnd == dataEnd
            modelData.velocbin = binnedData.velocbin(1:testDataStart-1,:);
        else
            modelData.velocbin = [ binnedData.velocbin(1:testDataStart-1,:); binnedData.velocbin(testDataEnd+1:dataEnd,:)];
        end
    end

    if Use_SD
        filters = BuildSDModels(modelData, States, dataPath, fillen, UseAllInputsOption, PolynomialOrder, PredEMG, PredForce, PredCursPos, PredVeloc);
        PredData = predictSDSignals(filters, testData, States);
    else
        filter = BuildModels(modelData, dataPath, fillen, UseAllInputsOption, PolynomialOrder, PredEMG, PredForce, PredCursPos);
        PredData = predictSignals(filter, testData);
    end
    
    TestSigs = concatSigs(testData, PredEMG, PredForce, PredCursPos);
    
    R2(i+1,:) = CalculateR2(TestSigs(round(fillen/binsize):end,:),PredData.preddatabin)';
    
    %Concatenate predicted Data if we want to plot it later:
    if plotflag
        %Skip this for the first fold
        if i == 0
            AllPredData = PredData;
        else
            AllPredData.timeframe = [AllPredData.timeframe; PredData.timeframe];
            AllPredData.preddatabin=[AllPredData.preddatabin;PredData.preddatabin];
        end
    end
end


% Plot Actual and Predicted Data
idx = false(size(binnedData.timeframe));
for i = 1:length(AllPredData.timeframe)
    idx = idx | binnedData.timeframe == AllPredData.timeframe(i);
end    

if PredEMG
    binnedData.emgdatabin = binnedData.emgdatabin(idx,:);
end
if PredForce
    binnedData.forcedatabin = binnedData.forcedatabin(idx,:);
end
if PredCursPos
    binnedData.cursorposbin = binnedData.cursorposbin(idx,:);
end
if PredVeloc
    binnedData.velocbin = binnedData.velocbin(idx,:);
end

binnedData.timeframe = binnedData.timeframe(idx);
ActualvsOLPred(binnedData,AllPredData,plotflag);