function VAFstruct=batchAnalyzeECoGv6(infoStruct,signalToDecode,FPsToUse,paramStructIn)

% syntax VAFstruct=batchAnalyzeECoGv6(infoStruct,signalToDecode,FPsToUse,paramStructIn);
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
%               FPsToUse       - one of {'MS','ME','S','EP'}, or a
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
% a common paramStructIn might be:
%
%   paramStructIn=struct('PolynomialOrder',3,'folds',10,'numlags',10, ...
%       'wsz',[256 512],'nfeat',6:6:(6:N),'smoothfeats',0:20:500, ...
%       'binsize',[0.05 0.1],'fpSingle',0,'zscore',[0 1],'lambda',1);
%
% for a parameter search.  In reality, any numerical value in paramStructIn
% can be a scalar or a vector.  To use all the features, make
% paramStructIn.nfeat some large value that will overshoot the maximum
% number of features, such as 1000.  If so, it's best to do this only with
% scalar-valued paramStructIn.nfeat, as otherwise the code will experience
% a Known Issue, and loop several times at the real max value for the file
% until it would have made it up to the requested max value by iterating.
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
%
% KEY to input parameter signalToDecode:
%
%       'emg'       decodes EMG signals from FPs.
%       'emgTASK'   decodes TASK from EMG, where TASK is either 
%                       'CG' or 'force'
%       'CG'        decodes CG from FPs
%       'force'     decodes force from FPs
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

defaultElectrodeTypes={'MS','ME','S','EP'};
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
        if exist('N_KsectionInterp','var')==1
            signal=[BCI2000signal(:,1:32), N_KsectionInterp];
        else
            signal=BCI2000signal;
        end
    elseif regexp(infoStruct(fileInd).path,'\.dat')
        [signal,states,parameters,~]=load_bcidat(infoStruct(fileInd).path);
        BCI2000signal=signal;
    end
    % if something is done to cg (portion of the signal cut short to
    % eliminate noise, etc), do that same thing to analog_times.
    if exist('samprate','var')~=1
        samprate=1000;
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
    
    if strncmpi(signalToDecode,'emg',3)
        % notch filter first
        y=BCI2000signal(:,ismember(parameters.ChannelNames.Value, ...
            infoStruct(fileInd).EMG.channels));
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
        sig=[sig(:,1), remove_artifacts(sig(:,2:end),3)];
        
        % if we're decoding CG or force from the EMGs, then EMGs are the
        % FPs.
        signalToDecode(1:3)='';
        if ~isempty(signalToDecode) && strcmpi(signalToDecode,'CG')
            fp=sig(:,2:end)';
        end
    end

    % assign and condition behavioral signals.
    if strcmpi(signalToDecode,'CG')
        for i=1:22
            cg(:,i)=eval(['states.GloveSensor',int2str(i)]);
        end
        clear i
        % make sure and delete outrageously large deviations
        % within the signals, often occurring at the beginning of files.
        % Also, employ this for EMGs after filtering/rectification/etc.
        cg=single(cg(:,infoStruct(fileInd).CG.channels))';
        cgz=zscore(cg')'; clear cg
        %Remove the noise "pops" that occur from using >1 file, or just inherent
        %noise from the sensors, by interpolating in the parts that are >2SDs from
        %the mean
        %Do each channel separately in case they are different on different
        %channels
        cgnew=cgz;
        for j=1:size(cgz,1)
            clear badinds badepoch badstartinds badendinds
            badinds=find(abs(cgz(j,:))>3);
            if ~isempty(badinds)
                badepoch=find(diff(badinds)>1);
                badstartinds=[badinds(1) badinds(badepoch+1)];
                badendinds=[badinds(badepoch) badinds(end)];
                if badendinds(end)==length(cgnew)
                    badendinds(end)=badendinds(end)-1;
                end
                if badstartinds(1)==1 
                    %If at the very beginning of the file need a 0 at start of file
                    cgnew(j,1)=cgnew(j,badendinds(1)+1);
                    badstartinds(1)=2;
                end
                for i=1:length(badstartinds)
                    cgnew(j,badstartinds(i):badendinds(i))=interp1([(badstartinds(i)-1) ...
                        (badendinds(i)+1)],[cgnew(j,badstartinds(i)-1) ...
                        cgnew(j,badendinds(i)+1)], (badstartinds(i):badendinds(i)));
                end
            else
                cgnew(j,:)=cgz(j,:);
            end
        end
        cgz=cgnew;
        clear cgnew
        
        [~,scores,variances,~] = princomp(cgz');

        % to determine how many components to use, find the # that account for
        % >= 90% of the variance.
        % FOR POSITION THE FUNCTION EXPECTS A TIME VECTOR PREPENDED
        temp=cumsum(variances/sum(variances));
%         positionData=[rowBoat(analog_times), scores(:,1:find(temp >= 0.9,1,'first'))];
        positionData=[rowBoat(analog_times), scores(:,1:3)];
        fprintf(1,'Using %d PCs, which together account for\n',size(positionData,2)-1)
%         fprintf(1,'Using %d PCs, which together account for\n',size(positionData,2)-1)
        fprintf(1,'%.1f%% of the total variance in the PC signal\n', ...
            100*temp(size(positionData,2)-1))

%         sig=[positionData(:,1:2), atan2(positionData(:,3),positionData(:,3))];
        sig=positionData; % 'position'
        % if you want to try velocity you're going to have to smooth the
        % position signal first; probably with a wide window since the
        % position signal is full of little discontinuous jumps (because
        % it's only sampled every 50msec!).
    end
    
    if strcmp(signalToDecode,'force')
%         [bh,ah] = butter(2, 0.1*2/1000, 'high');
%         forceSignal=filtfilt(bh,ah, ...
%             double(BCI2000signal(:,strcmpi(parameters.ChannelNames.Value,'force'))));
        forceSignal=double(BCI2000signal(:,strcmpi(parameters.ChannelNames.Value,'force')));
        % smooth force signal.  Takes place below in the loop, to take
        % advantage of the varying smoothing spans possible.  But,
        % forceSignal has to be determined up here, out of the loop.
    end
          
    fptimes=(1:size(fp,2))/samprate;
    if strcmp(signalToDecode,'xcorr')
        numfp=size(fp,1);
%         R=zeros(numfp,numfp,6,length(infoStruct));
        % do CAR
        fp=fp-repmat(mean(fp,1),numfp,1);
        [~,PB] = makefmatbp(fp,analog_times,numfp,0.05,samprate,256);
        
        R(:,:,1,fileInd)= corrcoef(squeeze(PB(1,:,:))');
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
            [~,vaf(:,elecInd),~,~,~,~,y_pred,~,ytnew]=predonlyxy_nofeatselect(fp,sig(:,2),3,0,1,10,1,1,10,0);
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

        
    emgsamplerate=samprate;
    numsides=1;
    Use_Thresh=0; words=[]; % lambda=1;    
    
    % add a dimension for smoothing of the CG signals?  
    % any of the fields of paramStructIn can hold an array, which will put
    % the code into parameter-exploration mode.  Otherwise, if given one
    % value for each of the fields of paramStructIn, the code will just
    % run once for each file in infoStruct.
    for PolynomialOrder=paramStructIn.PolynomialOrder
        for folds=paramStructIn.folds
            for numlags=paramStructIn.numlags
                for wsz=paramStructIn.wsz
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
                    for nfeat=numFeats
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
                        for smoothfeats=paramStructIn.smoothfeats
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
                            for binsize=paramStructIn.binsize
                                for lambda=paramStructIn.lambda;
                                    if paramStructIn.fpSingle==0
                                        numfp=size(fp,1);
                                        warning('off','MATLAB:polyfit:RepeatedPointsOrRescale')
                                        warning('off','MATLAB:nearlySingularMatrix')                                        
                                        [vaf,~,~,~,y_pred,~,~,r2,~,bestf,bestc,H,~,~,~,~,ytnew,~,~,P, ...
                                            ~,~,vaf_vald,ytnew_vald,y_pred_vald,P_vald,r2_vald] ...
                                            = predictionsfromfp8v2(sig,'pos', ...
                                            numfp,binsize,folds,numlags,numsides,samprate, ...
                                            fp,fptimes,analog_times,'',wsz,nfeat,PolynomialOrder, ...
                                            Use_Thresh,words,emgsamplerate,lambda,smoothfeats,1:nbands,0); %#ok<ASGLU>
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
                                        
                                        % fprintf(1,'emgsamplerate=%d\n',emgsamplerate)
                                        % fprintf(1,'zscoring fp signals\n')
                                        % OR
                                        fprintf(1,'\n')
                                        if strcmpi(signalToDecode,'CG') && size(cgz,1)<22
                                            fprintf(1,'elimindating %d bad cg signals\n', ...
                                                22-size(cgz,1))
                                        else
                                            fprintf(1,'\n')
                                        end
                                        
                                        [vaf,vaf_vald]
                                        
                                        formatstr='%s vaf mean across folds:    %.4f';
                                        if size(sig,2)>2
                                            for n=2:size(sig,2)
                                                formatstr=[formatstr, '    %.4f'];
                                            end
                                            clear n
                                        end
                                        formatstr=[formatstr, '\n'];
                                        fprintf(1,formatstr,signalToDecode,mean(nonzeros(vaf),1))
                                        fprintf(1,'\noverall mean vaf %.4f\n',mean(vaf(:)))
                                    else
                                        for fpSingleInd=1:length(infoStruct(fileInd).montage{strcmp(FPsToUse,...
                                                defaultElectrodeTypes)})
                                            fpKeep=fp(fpSingleInd,:);
                                            numfp=1;
                                            [vaf,~,~,~,y_pred,~,~,~,~,bestf, ...
                                                bestc,H,~,~,~,~,ytnew,~,~,P] ...
                                                = predictionsfromfp8(sig,'pos', ...
                                                numfp,binsize,folds,numlags,numsides,samprate, ...
                                                fpKeep,fptimes,analog_times,'',wsz,nfeat, ...
                                                PolynomialOrder,Use_Thresh,words, ...
                                                emgsamplerate,lambda,smoothfeats,1:nbands,0);
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
                                            
                                            % fprintf(1,'emgsamplerate=%d\n',emgsamplerate)
                                            % fprintf(1,'zscoring fp signals\n')
                                            % OR
                                            fprintf(1,'\n')
                                            if strcmpi(signalToDecode,'CG') && size(cgz,1)<22
                                                fprintf(1,'elimindating %d bad cg signals\n', ...
                                                    22-size(cgz,1))
                                            else
                                                fprintf(1,'\n')
                                            end
                                            
                                            vaf
                                            
                                            formatstr='%s vaf mean across folds:    %.4f';
                                            if size(sig,2)>2
                                                for n=2:size(sig,2)
                                                    formatstr=[formatstr, '    %.4f'];
                                                end
                                                clear n
                                            end
                                            formatstr=[formatstr, '\n'];
                                            fprintf(1,formatstr,signalToDecode,mean(vaf,1))
                                            fprintf(1,'\noverall mean vaf %.4f\n',mean(vaf(:)))
                                            fprintf(1,'single channel: %d \n',fpSingleInd)
                                        end % fpSingle for loop
                                    end % fpSingle if statement
                                    assignin('base','VAFstruct',VAFstruct)
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