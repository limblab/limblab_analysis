%runpredfp6 
%Uses MRSpredictionsfromfp6allDecoderBuild
direct = 'C:\Documents and Settings\Administrator\Desktop\ChewieData\Spike LFP Decoding\Mini';
%Set directory to desired directory

cd(direct);

Days=dir(direct);
Days(1:2)=[];
DaysNames={Days.name};

for i = 7:length(DaysNames)
    %Convert plx to bdf
    DayName = [direct,'\',DaysNames{i},'\'];
    cd(DayName);

    %Get mat file names and create decoder
    Files=dir(DayName);
    FileNames={Files.name};
    MATfiles=FileNames(cellfun(@isempty,regexp(FileNames,'_Spike_LFP.*(?<!poly.*)\.mat'))==0);
    if isempty(MATfiles)
        fprintf(1,'no MAT files found.  Make sure no files have ''only'' in the filename\n.')
        disp('quitting...')
        return
    end

    %Set file to desired filename(s)

    
    %Variables are declared inside and outside loop the same order they are input
    %to fxn: MRSpredictionsfromfp6allDecoderBuild

    %***Declare all input arguments that stay constant through all loop
    %iterations outside loop (vars to be declared inside loop are commented out below):

    %sig 
    signalType = 'vel';
    %numberOfFps
    binsize = .05;
    folds = 10;
    numlags = 10;
    numsides = 1;
    %samprate
    %fp
    %fptimes
    %analog_times
    %fnam

    %***Variable Arguments In (varargin)***
    windowsize= 256;
    nfeat = 150;
    PolynomialOrder = 3;  %for Wiener Nonlinear cascade
    Use_Thresh = 0;
    %H          
    %words                      
    emgsamplerate = 1000;
    lambda = 1;
    %smoothfeats
    
    for l=1:length(MATfiles)
        fnam = MATfiles{l}
        fname=[direct,'\',DaysNames{i},'\',fnam];
        load(fnam);
        
        if l == 2
            load([sname,'LFP decoding using decoder from HC file','.mat'])
            BEST_ind = find(max(sum(r2,2))==sum(r2,2));
            Hbest = H{BEST_ind};
            r2best(:,:) = r2(BEST_ind,:);
            featindBEST = featind;
            %save(['Chewie_Spike_LFP_08082011003.mattik6 velpred 100 feats lambda1poly0_BEST.mat'],...
             %   'Hbest','r2best','featind')
            save([sname,'LFP decoding using decoder from HC file','_BEST','.mat']...
                ,'Hbest','r2best','featindBEST','P');
            disp('Saved best decoder from first file');
            clear v* y* x* r* best* H
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Use if loading decoder used for online LFP control
        %Hbest = H;
        %P = P;
        %for j = 1:length(bestc)  
        %    featindBEST(j) = (bestc(j)-1)*6+bestf(j);
        %end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        sname=[direct,'\',fnam];
        
        if exist('out_struct','var')
            bdf = out_struct;
            clear out_struct
        end
        %Load previous H matrix for offline predictions if desired
        %load([dir,'Chewie_Spike_LFP_08012011001tik6 velpred 100 feats lambda1poly0_BEST.mat'])
        if exist('Hbest','var')
        H = Hbest; %<- Use if inputting H matrix, also don't 'clear' H in loop
        featind = featindBEST;
        else
        H = []; 
        featind = [];
        P = [];%<- Use if not inputting H matrix, and make sure featind not input to decoder fxn
        end
        %Declare input variables within loop that vary in each loop iteration:
        sig = bdf.vel;
        samplerate= bdf.raw.analog.adfreq(1,1);
        %Sample Rate for this file
        words=bdf.words;

        % If fp channels do not have same amount of elements, find the
        % shortest and shorten the rest to that length
        fpchans=find(cellfun(@isempty,regexp(bdf.raw.analog.channels,'[0-9]+'))==0);
        fpchanlength = zeros(1,length(fpchans));
        for j = 1:length(fpchans)
            fpchanlength(j) = size(bdf.raw.analog.data{fpchans(j)},1);
        end
        minfpchanlength = min(fpchanlength);
        for k = 1:length(fpchans)
            bdf.raw.analog.data{fpchans(k)}=bdf.raw.analog.data{fpchans(k)}(1:minfpchanlength);
        end

        % Concatenate lfp channels and put into one matrix
        fp=double(cat(2,bdf.raw.analog.data{fpchans}))';

        numberOfFps = size(fp,1);

        %Set time base for fps
        adfreq = samplerate;
        fp_start_time = 1/adfreq;
        fp_stop_time = length(fp)/adfreq;
        fptimes = fp_start_time:1/adfreq:fp_stop_time;

        %Set analog time base for other signals recorded (Pos/Vel/EMG)
        analog_time_base = sig(:,1);

        [vaf,vmean,vsd,y_test,y_pred,r2m,r2sd,r2,vaftr,bestf,bestc,H,bestfeat,x,...
         y,featMat,ytnew,xtnew,predtbase,P,featind] =... %,sr]...
         MRSpredictionsfromfp6allDecoderBuild(sig,signalType,numberOfFps,binsize,folds,numlags,numsides,samplerate,fp,...
         fptimes,analog_time_base,fnam,windowsize,nfeat,PolynomialOrder,Use_Thresh,H,words,emgsamplerate,lambda,0,featind,P);

        %save([sname,'velpred Using LFP Decoder from first HC file.mat'],'v*','y*','x*','r*','best*','H','feat*','P*','Use*','binsize');
        save([sname,'LFP decoding using decoder from HC file','.mat'],'v*','y*','x*','r*','best*','H','feat*','P*','Use*','binsize');
        
        clear H featind v* y* x* r* best* bdf out_struct...
              sig numberOfFps samplerate fp fptimes analog_time_base fnam words
              
        close all

    end
    clear H Hbest featind featindBEST sig signalType numberOfFps binsize folds numlags...
        numsides samplerate fp fptimes analog_time_base fnam windowsize nfeat...
        PolynomialOrder Use_Thresh words emgsamplerate lambda bestc bestf P %<--Clear bestc bestf & P 
                                                                            %if using decoder from online LFP control 
    
    direct = 'C:\Documents and Settings\Administrator\Desktop\ChewieData\Spike LFP Decoding\Mini';
    %Set directory to desired directory
    cd(direct);

    Days=dir(direct);
    Days(1:2)=[];
    DaysNames={Days.name};
end