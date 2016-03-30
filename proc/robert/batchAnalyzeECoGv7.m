function VAFstruct=batchAnalyzeECoGv7(infoStruct,signalToDecode,FPsToUse,paramStructIn)

% syntax VAFstruct=batchAnalyzeECoGv7(infoStruct,signalToDecode,FPsToUse,paramStructIn);
%
%   INPUTS:
%               infoStruct     - generated by ECoGprojectAllFileInfo.m
%                                only hand in to this funciton the
%                                infoStruct specific for the files you
%                                want processed, i.e. 1 day.
%               signalToDecode - one of the following, case-insensitive:
%                                   'emg[Task]'
%                                   'CG'
%							   	    'force'
%                                   'xcorr'
%                                   'chanRatio'
%               FPsToUse       - one of {'MS','ME','S','EP','EEG'}, or a
%                                number indexing this array
%               paramStructIn  - allows input specifying what values/
%                                ranges to use for the input parameters.
%                                See below for an example.
%
%   OUTPUTS:
%               VAFstruct      - MxN struct, where M is the number of
%                                files that were included, and N is the
%                                overall number of permutations resulting
%                                from iterating through the possible
%                                parameter values.  Each location in the
%                                array has the following fields:
%                                   name
%                                   PolynomialOrder
%                                   folds
%                                   numlags
%                                   wsz
%                                   nfeat
%                                   smoothfeats
%                                   binsize
%                                   vaf
%                                   lambda
%                                   montage
%                                   electrodeType
%                                   bestc
%                                   bestf
%                                   signalToDecode
%                                   H
%                                   P
%
% a common paramStructIn might be (updated 01-15-2014):
%
%   paramStructIn=struct('PolynomialOrder',3,'folds',11,'numlags',10, ...
%       'wsz',[256 512],'nfeat',6:6:(6:N),'smoothfeats',0:20:500, ...
%       'binsize',[0.05 0.1],'fpSingle',0,'zscore',[0 1], ...
%       'lambda',[0 1 2:2:10],'bands','1 2 3 4 5 6','random',0, ...
%       'classify',struct('eventsToUse',[nan(1,4) 1 1]));
%
% for a parameter search.  In reality, any numerical value in paramStructIn
% can be a scalar or a vector.  To use all the features, make
% paramStructIn.nfeat some large value that will overshoot the maximum
% number of features, such as 1000.  If so, it's best to do this only with
% scalar-valued paramStructIn.nfeat, as otherwise the code will experience
% a Known Issue, and loop several times at the real max value for the file
% until it would have made it up to the requested max value by iterating.
%
% 01-15-2014: the 'classify' field has been added to paramStructIn.
% Currently its only contents are 1 sub-field, 'eventsToUse'.  The
% size and composition of paramStructIn.classify.eventsToUse is dependent
% on the events file, which is to be found at the appropriate path
% indicated by infoStruct(n).eventsPath
%
% in v2, the paramStructIn was added
% in v3, artifact rejection utilizing remove_artifact.m was added for
%   EMG signals.
% in v4, the assignment of the fp variable was left off until inside the
% loop, so that single-electrode analysis could be done.  To do
% single-electrode analysis,
% in v5, added a scan for a lambda vector in the input parameters.
% in v6, we added the option to do a validation pass (using
% predictionsfromfp8.m).
% in v7, force and CG data can be combined.  Also, eventually
%   uses predictionsfromfp9.m, which does separate
%   feature selection for each fold.  Also, a CAR is used by default.
%   update (01-15-2014): v7 now also permits the use of a classifier, for
%   analyzing combined kinematic-kinetic data.
% update 04-13-2015: CAR now uses median (not mean) to calculate the
% average reference.
%
% KEY to input parameter signalToDecode:
%
%       'emg'       decodes EMG signals from FPs.
%       'emgTASK'   decodes TASK from EMG, where TASK is either
%                       'CG' or 'force'
%       'CG'        decodes CG from FPs
%       'force'     decodes force from FPs
%       'CG;force'  decodes both CG (raw signals not PCA) and force
%
% advanced usage: to calculate the decoding of each channel in turn
% by its fellows, construct InfoStruct and paramStructIn as normal,
% but then, something like:
%
%       infoStructRep=repmat(infoStruct(6),1,length(infoStruct(6).montage{strcmp({'MS','ME','S','EP'},'MS')}));
%       batchAnalyzeECoGv4(infoStructRep,'chanRatio','MS',paramStructIn);
%
% from the command line.  This function will then loop N times,
% where N is the number of electrodes in this montage.  However, on
% each iteration of the loop it will just repeat on infoStruct(6),
% because that's the construction of infoStructRep.  But each time
% through, because of chanRatio tag, it will calculate the VAF for
% a different electrode, using the others as population.  If infoStructRep
% is not constructed in this way (so as to cause looping), the code will
% still predict channel 1 from channels 2-N, but it will stop there.


% folds and numlags might not end up getting changed much, nor
% polynomaialOrder, but let's keep their information for completeness.
VAFstruct=struct('name','','PolynomialOrder',[],'folds',[],'numlags',[], ...
    'wsz',[],'nfeat',[],'smoothfeats',[],'binsize',[],'vaf',[]);

defaultElectrodeTypes={'MS','ME','S','EP','EEG'};
if ~isnumeric(FPsToUse) && ~ischar(FPsToUse)
    disp('bad input for FPsToUse.  see help')
    return
end

if strcmp(signalToDecode,'xcorr')
    R=[];
end

% necessary to account for modifications made to signalToDecode inside the
% loop.  Preserve original signalToDecode for reference from inside the loop.
% Kind of stupid, but works.
signalToDecodeIn=signalToDecode;

for fileInd=1:length(infoStruct)
    m=1;
    signalToDecode=signalToDecodeIn;
    % load in file according to its path
    if regexp(infoStruct(fileInd).path,'\.mat')
        load(infoStruct(fileInd).path)
        % we assumes the names of two variables: signal and
        % N_KsectionInterp
        BCI2000signal=signal; clear signal
        % N_KsectionInterp might have the EMG,force,TTL etc tacked on, or
        % it might not.  Shouldn't matter; fp will be taken from the
        % overall signal array (the first 32 columns of BCI2000 signal +
        % whatever there is of N_KsectionInterp).  BCI2000signal is
        % reliable, because it was originally loaded in with load_bcidat.m
        % and not modified.  force, emg will be taken
        % from the extra columns of BCI2000signal, for that reason.  So,
        % N_KsectionInterp can have extra columns, or it can come up
        % short.  As long as infoStruct(fileInd).montage{FPsToUse} indexes
        % it correctly, it doesn't matter.
        allVars=whos;
        NKvarMatch=regexp({allVars.name}','[BN]_[SK]sectionInterp','match','once');
        if nnz(cellfun(@isempty,NKvarMatch)==0) > 0
            NKvar=allVars(cellfun(@isempty,NKvarMatch)==0).name;
            signal=[BCI2000signal(:,1:32), eval(NKvar)];
        else
            signal=BCI2000signal;
        end
    elseif regexp(infoStruct(fileInd).path,'\.dat')
        [signal,states,parameters,~]=load_bcidat(infoStruct(fileInd).path); %#ok<*ASGLU>
        if ~isa(signal,'double'), signal=double(signal); end        
        signal=bsxfun(@times,signal,parameters.SourceChGain.NumericValue');
        BCI2000signal=signal;
    end
    % if something is done to cg (portion of the signal cut short to
    % eliminate noise, etc), do that same thing to analog_times.
    if exist('samprate','var')~=1
        samprate=parameters.SamplingRate.NumericValue;
    end
    analog_times=(1:size(BCI2000signal,1))/samprate;
    
    % assign FP signals according to the provided montage.  Doesn't this
    % section relieve the need for harsh insistence on a filled-out
    % N_KsectionInterp array?
    if isnumeric(FPsToUse) && length(FPsToUse)==1
        fp=BCI2000signal(:,infoStruct(fileInd).montage{FPsToUse});
    elseif ischar(FPsToUse)
        fp=signal(:,infoStruct(fileInd).montage{strcmpi(FPsToUse, ...
            defaultElectrodeTypes)});
    end
    if isfield(paramStructIn,'zscore') && paramStructIn.zscore==1
        fp=zscore(fp)';
        if exist('forceSignal','var')==1
            forceSignal=zscore(forceSignal);
        end
        % was never previously zscoring EMGs.
    else
        fp=fp';
    end
    % CAR.  fp has been cut down by this point, according to
    % infoStruct.montage
    fp=bsxfun(@minus,fp,median(fp,1));
    
    % baseline subtract
    %  fp=bsxfun(@minus,fp,mean(fp,2));
    
    if strncmpi(signalToDecode,'emg',3)
        % notch filter first
        y=BCI2000signal(:,ismember(parameters.ChannelNames.Value, ...
            infoStruct(fileInd).EMG.channels));
        if isempty(y)
            error('no emg channels were found in %s',infoStruct(fileInd).path)
        end
        % want to remove huge noise spikes BEFORE filtering, especially
        % before low-pass filtering, which brings them down much closer to
        % everything else.  The 30 SDs is not a typo.
        y=remove_artifacts(y,30);
        samprate=parameters.SamplingRate.NumericValue;
        [b,a]=butter(2,[58 62]/(samprate/2),'stop');
        tempEMG=filtfilt(b,a,double(y));  % yf is channels X samples
        % EMG filter.
        EMG_hp = 50; % default high pass at 50 Hz
        EMG_lp = 5;
        [bh,ah] = butter(2, EMG_hp*2/samprate, 'high'); %highpass filter params
        [bl,al] = butter(2, EMG_lp*2/samprate, 'low');  %lowpass filter params
        
        tempEMG = filtfilt(bh,ah,tempEMG); %highpass filter
        tempEMG = abs(tempEMG); %rectify
        
        % if we're decoding EMG from the FPs, then EMGs are the sig
        sig=[rowBoat(analog_times), filtfilt(bl,al,tempEMG)]; %lowpass filter
        % sig=[sig(:,1), remove_artifacts(sig(:,2:end),3)];
        
        % if we're decoding CG or force from the EMGs, then EMGs are the
        % FPs.
        signalToDecode(1:3)='';
        if ~isempty(signalToDecode) %&& strcmpi(signalToDecode,'CG')
            fp=sig(:,2:end)';
        end
    end
    
    % assign and condition behavioral signals.
    if ~isempty(regexp(signalToDecode,'CG','once'))
        % take out bad CG channels before calling getSigFromBCI2000.m
        % because that function doesn't know about infoStruct
        badCGchans=setdiff(1:22,infoStruct(fileInd).CG.channels);
        for badCGind=1:numel(badCGchans)
            if isfield(states,['GloveSensor',num2str(badCGchans(badCGind))])
                states=rmfield(states,['GloveSensor',num2str(badCGchans(badCGind))]);
            end
        end
        [sig,CG]=getSigFromBCI2000(BCI2000signal,states, ...
            parameters,signalToDecode);
        % TODO: add option to read in automatically which CG you want to
        % use, if it's not the PCA output.
    end
    
    if ~isempty(regexp(signalToDecode,'force','once'))
        %         [bh,ah] = butter(2, 0.1*2/1000, 'high');
        %         forceSignal=filtfilt(bh,ah, ...
        %             double(BCI2000signal(:,strcmpi(parameters.ChannelNames.Value,'force'))));
        forceSignal=double(BCI2000signal(:,strcmpi(parameters.ChannelNames.Value,'force')));
        if isempty(forceSignal)
            forceSignal=double(BCI2000signal(:,strcmpi(parameters.ChannelNames.Value,'ainp1')));
        end
        % smooth force signal.  Takes place below in the loop, to take
        % advantage of the varying smoothing spans possible.  But,
        % forceSignal has to be determined up here, out of the loop.
    end
    
    % TODO: make it smarter.  Could also make it more general, so that we
    % could add together whatever arbitrary signals.
    if strcmpi(signalToDecode,'CG;force')
        sig=[rowBoat(analog_times), forceSignal, ...
            remove_artifacts(CG.data(:,infoStruct.CG.channels),3)];
    end
    
    fptimes=(1:size(fp,2))/samprate;
    if strcmp(signalToDecode,'xcorr')
        numfp=size(fp,1);
        %         R=zeros(numfp,numfp,6,length(infoStruct));
        % do CAR
        fp=fp-repmat(mean(fp,1),numfp,1);
        [~,PB] = makefmatbp(fp,analog_times,numfp,0.05,samprate,256);
        
        R(:,:,1,fileInd)= corrcoef(squeeze(PB(1,:,:))'); %#ok<*AGROW>
        R(:,:,2,fileInd)= corrcoef(squeeze(PB(2,:,:))');
        R(:,:,3,fileInd)= corrcoef(squeeze(PB(3,:,:))');
        R(:,:,4,fileInd)= corrcoef(squeeze(PB(4,:,:))');
        R(:,:,5,fileInd)= corrcoef(squeeze(PB(5,:,:))');
        R(:,:,6,fileInd)= corrcoef(squeeze(PB(6,:,:))');
        
        % this is for decoding individual channels
        bandToUse=6; bandToDecode=1;      % setdiff(1:6,bandToUse);
        % this is to decode bands from the other bands, treating each
        % channel as independent of the others.
        for elecInd=1:size(PB,2)
            fp=squeeze(PB(bandToUse,elecInd,:));
            
            fptimes=(1:size(PB,3))*0.05;
            sig=[rowBoat(fptimes), squeeze(PB(bandToDecode,elecInd,:))];
            % [vmean,vaf,vaftr,r2mean,r2sd,r2,y_pred,y_test,varargout]= ...
            %   predonlyxy_nofeatselect(x,y,PolynomialOrder,Use_Thresh,lambda,numlags,numsides,binsamprate,folds,smoothflag)
            % P
            [~,vaf(:,elecInd),~,~,~,~,y_pred,~,ytnew]=predonlyxy_nofeatselect(fp,sig(:,2),3,0,1,10,1,1,10,0); %#ok<NASGU>
        end
        continue
    end
    
    if strcmp(signalToDecode,'chanRatio')
        % advanced usage: to calculate the decoding of each channel in turn
        % by its fellows, construct InfoStruct and paramStructIn as normal,
        % but then, something like:
        %
        %       infoStructRep=repmat(infoStruct(6),1,length(infoStruct(6).montage{strcmp({'MS','ME','S','EP'},'MS')}));
        %       batchAnalyzeECoGv4(infoStructRep,'chanRatio','MS',paramStructIn);
        %
        % from the command line.  This function will then loop N times,
        % where N is the number of electrodes in this montage.  However, on
        % each iteration of the loop it will just repeat on infoStruct(6),
        % because that's the construction of infoStructRep.  But each time
        % through, because of the below code, it will calculate the VAF for
        % a different electrode, using the others as population.
        sig=[fptimes', fp(fileInd,:)'];
        fp=fp(setdiff(1:size(fp,1),fileInd),:);
    end
    
    if isfield(paramStructIn,'random') && paramStructIn.random==1
        fp=pharand(fp')';
    end
    
    if isfield(paramStructIn,'classify')
        load(infoStruct(fileInd).eventsPath,'eventsMatrix','eventsNames')
        % paramStructIn.classify.eventsToUse should be a vector of digits
        % that label the events.  Pass in NaN to exclude the event.
        % For example, for a force - noForce set of
        % windows, pass in [1 1 NaN NaN NaN NaN] while a force vs. pinch
        % would be done if we passed in [1 1 2 2 NaN NaN] and to include
        % all, pass in [1 1 2 2 3 3]
        eventsMatrix(isnan(paramStructIn.classify.eventsToUse))=[];
        eventsNames(isnan(paramStructIn.classify.eventsToUse))=[];
        eventsMatrixToUse{1}=cat(2,eventsMatrix{:});        
        eventsMatrixToUse{2}=unique(regexpi(eventsNames,'(?<=start|stop).*','match','once'));
    else
        eventsMatrixToUse=cell(1,2);
    end
    
    emgsamplerate=samprate;
    numsides=1;
    Use_Thresh=0; words=[]; % lambda=1;
    
    % add a dimension for smoothing of the CG signals?
    % any of the fields of paramStructIn can hold an array, which will put
    % the code into parameter-exploration mode.  Otherwise, if given one
    % value for each of the fields of paramStructIn, the code will just
    % run once for each file in infoStruct.
    if ~iscell(paramStructIn.bands)
        % if it was just passed in as a string, then put it in a 1x1 cell
        % so that the length will properly reflect the number of times we
        % want the code to execute.
        paramStructIn.bands={paramStructIn.bands};
    end
    for PolynomialOrder=rowBoat(paramStructIn.PolynomialOrder)'
        for folds=rowBoat(paramStructIn.folds)'
            for numlags=rowBoat(paramStructIn.numlags)'
                for wsz=rowBoat(paramStructIn.wsz)'
                    if isempty(infoStruct(fileInd).montage{strcmp(FPsToUse, ...
                            defaultElectrodeTypes)})
                        error('%s electrodes not found in\n %s.',FPsToUse, ...
                            infoStruct(fileInd).path)
                    end
                    if ischar(paramStructIn.nfeat) && strcmpi(paramStructIn.nfeat,'all')
                        numFeats=10*floor(6*length(infoStruct(fileInd).montage{strcmp(FPsToUse, ...
                            defaultElectrodeTypes)})/10);
                    else
                        numFeats=paramStructIn.nfeat;
                    end
                    for nfeat=rowBoat(numFeats)'
                        if samprate >= 600
                            nbands=6;
                        else
                            nbands=5;
                        end
                        if (nfeat>nbands*length(infoStruct(fileInd).montage{ ...
                                strcmp(FPsToUse,defaultElectrodeTypes)})) || (nfeat>size(fp,1)*nbands)
                            % safety valve, in case we ask for too many.
                            % This is the source of a known issue, the
                            % break signal is not registering properly and
                            % we're ending up with extra iterations for
                            % files with fewer features than we request.
                            nfeat=10*floor(nbands*length(infoStruct(fileInd).montage{ ...
                                strcmp(FPsToUse,defaultElectrodeTypes)})/10);
                            if nfeat > size(fp,1)
                                nfeat=size(fp,1)*nbands;
                            end
                            nfeatBreakSignal=1;
                            % don't forget the break below.
                        else
                            nfeatBreakSignal=0;
                        end
                        for smoothfeats=rowBoat(paramStructIn.smoothfeats)'
                            if strcmpi(signalToDecode,'force')
                                % smooth forceSignal?  if so, keep the
                                % actual forceSignal virgin, so there are
                                % no repeated smoothings
                                % sig=[rowBoat(analog_times), ...
                                %       smooth(forceSignal,smoothfeats)];
                                % alternate way of smoothing.
                                % sig=[rowBoat(analog_times), ...
                                %       rowBoat(filtfilt(ones(1,smoothfeats)/smoothfeats, ...
                                %       1,forceSignal))];
                                sig=[rowBoat(analog_times), rowBoat(forceSignal)];
                            end
                            for binsize=rowBoat(paramStructIn.binsize)'
                                for lambda=rowBoat(paramStructIn.lambda)'
                                    for bandGrps=1:length(paramStructIn.bands)
                                        if paramStructIn.fpSingle==0
                                            numfp=size(fp,1);
                                            warning('off','MATLAB:polyfit:RepeatedPointsOrRescale')
                                            warning('off','MATLAB:nearlySingularMatrix')
                                            [vaf,~,~,~,y_pred,~,~,r2,~,bestf,bestc,H,~,~,~,~,ytnew,~,~,P, ...
                                                ~,~,vaf_vald,ytnew_vald,y_pred_vald,P_vald,r2_vald,covMI] ...
                                                = predictionsfromfp9(sig,'pos', ...
                                                numfp,binsize,folds,numlags,numsides,samprate, ...
                                                fp,fptimes,analog_times,'',wsz,nfeat,PolynomialOrder, ...
                                                Use_Thresh,words,emgsamplerate,lambda,smoothfeats, ...
                                                paramStructIn.bands{bandGrps},0,0,eventsMatrixToUse);        %#ok<ASGLU>
                                            % close                                                        % featShift
                                            warning('on','MATLAB:polyfit:RepeatedPointsOrRescale')
                                            warning('on','MATLAB:nearlySingularMatrix')
                                            [~,name,ext]=fileparts(infoStruct(fileInd).path);
                                            VAFstruct(fileInd,m).name=[name,ext];
                                            VAFstruct(fileInd,m).PolynomialOrder=PolynomialOrder;
                                            VAFstruct(fileInd,m).folds=folds;
                                            VAFstruct(fileInd,m).numlags=numlags;
                                            VAFstruct(fileInd,m).wsz=wsz;
                                            VAFstruct(fileInd,m).nfeat=nfeat;
                                            VAFstruct(fileInd,m).smoothfeats=smoothfeats;
                                            VAFstruct(fileInd,m).binsize=binsize;
                                            VAFstruct(fileInd,m).vaf=vaf;
                                            VAFstruct(fileInd,m).lambda=lambda;
                                            VAFstruct(fileInd,m).vaf_vald=vaf_vald;
                                            if strcmpi(signalToDecode,'emg')
                                                VAFstruct(fileInd,m).emg= ...
                                                    infoStruct(fileInd).EMG.channels;
                                            end
                                            VAFstruct(fileInd,m).montage= ...
                                                infoStruct(fileInd).montage{strcmp(FPsToUse, ...
                                                defaultElectrodeTypes)};
                                            VAFstruct(fileInd,m).electrodeType=FPsToUse;
                                            VAFstruct(fileInd,m).bestc=bestc;
                                            VAFstruct(fileInd,m).bestf=bestf;
                                            VAFstruct(fileInd,m).signalToDecode=signalToDecode;
                                            VAFstruct(fileInd,m).H=H;
                                            VAFstruct(fileInd,m).P=P;
                                            VAFstruct(fileInd,m).bands=paramStructIn.bands{bandGrps};
                                            VAFstruct(fileInd,m).covMI=rowBoat(covMI);
                                            m=m+1;
                                            
                                            % export so we can look at raw data
                                            % comparisons, maybe do the weights
                                            % analysis.
                                            assignin('base','y_pred',y_pred)
                                            assignin('base','ytnew',ytnew)
                                            assignin('base','bestf',bestf)
                                            assignin('base','bestc',bestc)
                                            assignin('base','H',H)
                                            assignin('base','vaf',vaf)
                                            assignin('base','sig',sig)
                                            
                                            fprintf(1,'file %s.\n',infoStruct(fileInd).path)
                                            
                                            if isnumeric(FPsToUse)
                                                fprintf(1,'Using %s electrodes.\n', ...
                                                    defaultElectrodeTypes{FPsToUse})
                                            elseif ischar(FPsToUse)
                                                fprintf(1,'Using %s electrodes.\n', ...
                                                    defaultElectrodeTypes{strcmpi(defaultElectrodeTypes,FPsToUse)})
                                            end
                                            
                                            % echo to the command window for the diary.
                                            fprintf(1,'folds=%d\n',folds)
                                            fprintf(1,'numlags=%d\n',numlags)
                                            fprintf(1,'lambda=%d\n',lambda)
                                            fprintf(1,'wsz=%d\n',wsz)
                                            fprintf(1,'nfeat=%d of a possible %d\n',nfeat,size(fp,1)*nbands)
                                            fprintf(1,'PolynomialOrder=%d\n',PolynomialOrder)
                                            fprintf(1,'smoothfeats=%d\n',smoothfeats)
                                            fprintf(1,'binsize=%.2f\n',binsize)
                                            fprintf(1,'bands %s\n',paramStructIn.bands{bandGrps})
                                            
                                            % fprintf(1,'emgsamplerate=%d\n',emgsamplerate)
                                            % fprintf(1,'zscoring fp signals\n')
                                            % OR
                                            fprintf(1,'\n')
                                            if strcmpi(signalToDecode,'CG') && size(CG.data,2)<22
                                                fprintf(1,'elimindating %d bad cg signals\n', ...
                                                    22-size(CG.data,2))
                                            else
                                                fprintf(1,'\n')
                                            end
                                            
                                            [vaf,vaf_vald]                                              %#ok<NOPRT>
                                            
                                            formatstr='%s vaf mean across folds:    %.4f';
                                            if size(vaf,2)>1
                                                for n=2:size(vaf,2)
                                                    formatstr=[formatstr, '    %.4f'];
                                                end
                                                clear n
                                            end
                                            formatstr=[formatstr, '\n'];
                                            fprintf(1,formatstr,signalToDecode,mean(vaf(1:(folds-1),:),1))
                                            fprintf(1,'\noverall mean vaf %.4f\n',mean(vaf(:)))
                                        else
                                            warning('off','MATLAB:polyfit:RepeatedPointsOrRescale')
                                            warning('off','MATLAB:nearlySingularMatrix')
                                            for fpSingleInd=1:length(infoStruct(fileInd).montage{strcmp(FPsToUse,...
                                                    defaultElectrodeTypes)})
                                                fpKeep=fp(fpSingleInd,:);
                                                numfp=1;
                                                [vaf,~,~,~,y_pred,~,~,r2,~,bestf,bestc,H,~,~, ...
                                                    ~,~,ytnew,~,~,P,~,~,vaf_vald,ytnew_vald, ...
                                                    y_pred_vald,P_vald,r2_vald,covMI] ...
                                                    = predictionsfromfp9(sig,'pos', ...
                                                    numfp,binsize,folds,numlags,numsides,samprate, ...
                                                    fpKeep,fptimes,analog_times,'',wsz,nfeat, ...
                                                    PolynomialOrder,Use_Thresh,words, ...
                                                    emgsamplerate,lambda,smoothfeats, ...
                                                    paramStructIn.bands{bandGrps},0);
                                                warning('on','MATLAB:polyfit:RepeatedPointsOrRescale')
                                                warning('on','MATLAB:nearlySingularMatrix')
                                                % close
                                                [~,name,ext]=fileparts(infoStruct(fileInd).path);
                                                VAFstruct(fileInd,m).name=[name,ext];
                                                VAFstruct(fileInd,m).PolynomialOrder=PolynomialOrder;
                                                VAFstruct(fileInd,m).folds=folds;
                                                VAFstruct(fileInd,m).numlags=numlags;
                                                VAFstruct(fileInd,m).wsz=wsz;
                                                VAFstruct(fileInd,m).nfeat=nfeat;
                                                VAFstruct(fileInd,m).smoothfeats=smoothfeats;
                                                VAFstruct(fileInd,m).binsize=binsize;
                                                VAFstruct(fileInd,m).vaf=vaf;
                                                VAFstruct(fileInd,m).lambda=lambda;
                                                if strcmpi(signalToDecode,'emg')
                                                    VAFstruct(fileInd,m).emg= ...
                                                        infoStruct(fileInd).EMG.channels;
                                                end
                                                VAFstruct(fileInd,m).montage= ...
                                                    infoStruct(fileInd).montage{strcmp(FPsToUse, ...
                                                    defaultElectrodeTypes)}(fpSingleInd);
                                                VAFstruct(fileInd,m).electrodeType=FPsToUse;
                                                VAFstruct(fileInd,m).bestc=bestc;
                                                VAFstruct(fileInd,m).bestf=bestf;
                                                VAFstruct(fileInd,m).signalToDecode=signalToDecode;
                                                VAFstruct(fileInd,m).H=H;
                                                VAFstruct(fileInd,m).P=P;
                                                VAFstruct(fileInd,m).bands=paramStructIn.bands{bandGrps};
                                                VAFstruct(fileInd,m).covMI=rowBoat(covMI);
                                                VAFstruct(fileInd,m).vaf_vald=vaf_vald;
                                                m=m+1;
                                                
                                                % export so we can look at raw data
                                                % comparisons, maybe do the weights
                                                % analysis.
                                                assignin('base','y_pred',y_pred)
                                                assignin('base','ytnew',ytnew)
                                                assignin('base','bestf',bestf)
                                                assignin('base','bestc',bestc)
                                                assignin('base','H',H)
                                                assignin('base','vaf',vaf)
                                                assignin('base','sig',sig)
                                                
                                                fprintf(1,'file %s.\n',infoStruct(fileInd).path)
                                                
                                                if isnumeric(FPsToUse)
                                                    fprintf(1,'Using %s electrodes.\n', ...
                                                        defaultElectrodeTypes{FPsToUse})
                                                elseif ischar(FPsToUse)
                                                    fprintf(1,'Using %s electrodes.\n', ...
                                                        defaultElectrodeTypes{strcmpi(defaultElectrodeTypes,FPsToUse)})
                                                end
                                                
                                                % echo to the command window for the diary.
                                                fprintf(1,'folds=%d\n',folds)
                                                fprintf(1,'numlags=%d\n',numlags)
                                                fprintf(1,'lambda=%d\n',lambda)
                                                fprintf(1,'wsz=%d\n',wsz)
                                                fprintf(1,'nfeat=%d\n',nfeat)
                                                fprintf(1,'PolynomialOrder=%d\n',PolynomialOrder)
                                                fprintf(1,'smoothfeats=%d\n',smoothfeats)
                                                fprintf(1,'binsize=%.2f\n',binsize)
                                                fprintf(1,'bands %s\n',paramStructIn.bands{bandGrps})
                                                
                                                % fprintf(1,'emgsamplerate=%d\n',emgsamplerate)
                                                % fprintf(1,'zscoring fp signals\n')
                                                % OR
                                                fprintf(1,'\n')
                                                if strcmpi(signalToDecode,'CG') && size(CG.data,2)<22
                                                    fprintf(1,'elimindating %d bad cg signals\n', ...
                                                        22-size(CG.data,2))
                                                else
                                                    fprintf(1,'\n')
                                                end
                                                
                                                vaf                                                     %#ok<NOPRT>
                                                
                                                formatstr='%s vaf mean across folds:    %.4f';
                                                if size(vaf,2) > 1
                                                    for n=2:size(vaf,2)
                                                        formatstr=[formatstr, '    %.4f'];
                                                    end
                                                    clear n
                                                end
                                                formatstr=[formatstr, '\n'];
                                                fprintf(1,formatstr,signalToDecode,mean(vaf(1:(folds-1),:),1))
                                                fprintf(1,'\noverall mean vaf %.4f\n',mean(vaf(:)))
                                                fprintf(1,'single channel: %d \n',fpSingleInd)
                                                disp('done')
                                            end % fpSingle for loop
                                        end % fpSingle if statement
                                        assignin('base','VAFstruct',VAFstruct)
                                    end % band selection
                                end % lambda
                            end % binsize
                        end % smoothfeats
                        % if we hit a value of nfeat that is too high
                        % considering the number of fp (10:10:90 when one
                        % of the files has only 14 fp channels), then
                        % break here.  Currently this isn't working for
                        % some reason.
                        if nfeatBreakSignal, break, end
                    end % nfeat
                end % wsz
            end % numlags
        end % folds
    end % polynomialOrder
end % file index

if strcmp(signalToDecode,'xcorr')
    figure
    Rm=mean(R,4);
    for j=1:6
        subplot(2,3,j)
        imagesc(Rm(:,:,j))
        title(['Corrcoef for freq band ',num2str(j)])
        caxis([0 1])
    end
    VAFstruct(fileInd).vaf=vaf;
end

disp('done')

end % function batchAnalyzeECoGv7

% diferentiater function for kinematic signals
% should differentiate, LP filter at 100Hz and add a zero to adjust for
% temporal shift
function dx = kin_diff(x,fs)

[b, a] = butter(8, 100/fs);
dx = diff(x) .* fs;
dx = filtfilt(b,a,dx);
if size(dx,1) > size(dx,2)
    dx = [zeros(1,size(dx,2)); dx];
else
    dx = [zeros(size(dx,1),1), dx];
end

end % function kin_diff
