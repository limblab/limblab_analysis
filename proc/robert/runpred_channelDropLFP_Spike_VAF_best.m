function runpred_channelDropLFP_Spike_VAF_best(PathName)

% is actually a batch file.

% create a folder for the outputs.  Create them with trailing numbers that
% will increment so that no folder is ever overwritten.
folderStr='channel_dropping_LFP_Spike_best1';
if exist(folderStr,'dir')~=0
    D=dir(PathName);
    folderStrNoNumbers=regexp(folderStr,'.*(?=[0-9])','match','once');
    folderNumbers=cellfun(@(x) str2num(x),regexp({D.name}, ...
        ['(?<=',folderStrNoNumbers,')[0-9]+'],'match','once'),'UniformOutput',0);
    folderNew=[folderStrNoNumbers, num2str(max(cat(2,folderNumbers{:}))+1)];
else
    folderNew=folderStr;
end
mkdir(folderNew)

% different for LFPs vs. spikes.  for LFPs, part of the decoder file is
% bestc, so we can load that up and know what the ranking of channels was.
% For spikes, the decoder uses all the channels, so use the weightings of
% the H matrix to order the channels.  To make it channel dropping rather
% than just neuron dropping, it is necessary to go back to the data file,
% load the bdf, and consult bdf.units.id to find out what channel numbers
% correspond to which rows of the H matrix.  If we don't do that, it's
% neuron dropping instead of channel dropping.

if ~nargin
    % dialog
else
    cd(PathName)
    Files=dir(PathName);
    Files(1:2)=[];
    FileNames={Files.name};
    LFPfiles=find(cellfun(@isempty,regexp(FileNames,'feats'))==0);
    spikeFiles=find(cellfun(@isempty,regexp(FileNames,'spikes'))==0);
end


for i=1:length(LFPfiles)
    FileName=FileNames{LFPfiles(i)};
    load(FileName,'x')
    load(FileName,'y')
    load(FileName,'bestc')
    load(FileName,'EMGchanNames')
    
    EMGVAFmallLFP=nan(length(unique(bestc)),size(EMGchanNames,2));
    EMGVAFsdallLFP=nan(length(unique(bestc)),size(EMGchanNames,2));

    n=1;
    while length(unique(bestc)) > 1
        x(:,ismember(bestc,bestc(1)))=[];
        bestc(:,ismember(bestc,bestc(1)))=[];
        disp([FileName,' LFP: ',num2str(length(unique(bestc))),' channels'])
        
        [vmean,~,~,~,~,~,~,~,~,~,~,~,~,vsd]=predonlyxy_nofeatselect(x,y,2,0,1,1,1,1,10,0);
        close
        EMGVAFmallLFP(n,:)=vmean;
        EMGVAFsdallLFP(n,:)=vsd;
        n=n+1;
    end
    save(fullfile(folderNew,[FileName(1:end-4),'chan drop.mat']),'EMGVAFmallLFP','EMGVAFsdallLFP')
end

for i=1:length(spikeFiles)
    % spikes have to be done differently.
    FileName=FileNames{spikeFiles(i)};
    load(FileName,'x')
    load(FileName,'y')
    load(FileName,'H')
    load(FileName,'EMGchanNames')
    
    % get the unit list from the bdf.  we'll need it.
    BDFfilesList=dir('C:\Documents and Settings\Administrator\Desktop\RobertF\data\sorted');
    recordingName=regexp(FileName,'.*(?=spikes tik)','match','once');
    if any(cellfun(@isempty,regexp({BDFfilesList.name},recordingName))==0)
        try
            load(fullfile('C:\Documents and Settings\Administrator\Desktop\RobertF\data\sorted', ...
                recordingName),'bdf')
        catch ME
            if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
                load(fullfile('C:\Documents and Settings\Administrator\Desktop\RobertF\data\sorted', ...
                    recordingName),'out_struct')
                bdf=out_struct;
            else
                rethrow(ME)
            end
        end
        cells=unit_list(bdf);
        cells(cells(:,2)==0,:)=[];
        
        EMGVAFmallSpike=nan(length(unique(cells(:,1))),size(EMGchanNames,2));
        EMGVAFsdallSpike=nan(length(unique(cells(:,1))),size(EMGchanNames,2));

        bestHc=[];
        for n=1:length(H)
%             sortInd=sortUnitsOnH(cells,H{n},10);          % 10 is numlags
            % a strong negative weight means a powerful contribution.
            % Right?
            [~,bestH]=sort(abs(H{n}(10:10:size(H{n},1),1)),'descend');
            bestHc(:,n)=cells(bestH,1);
        end
        
        for n=1:size(bestHc,2)
            Euc(n)=pdist([bestHc(:,n)'; floor(median(bestHc,2))']);
        end
        [~,position]=min(Euc);
        bestc=bestHc(:,position);
        
        n=1;
        while length(unique(bestc)) > 1
            x(:,ismember(bestc,bestc(1)))=[];
            bestc(ismember(bestc,bestc(1)))=[];
            disp([FileName,' Spike: ',num2str(length(unique(bestc))),' channels'])
            
            [vmean,~,~,~,~,~,~,~,~,~,~,~,~,vsd]=predonlyxy_nofeatselect(x,y,2,0,1,1,1,1,10,0);                    
            close
            EMGVAFmallSpike(n,:)=vmean;
            EMGVAFsdallSpike(n,:)=vsd;
            n=n+1;            
        end
        save(fullfile(folderNew,[FileName(1:end-4),'chan drop.mat']),'EMGVAFmallSpike','EMGVAFsdallSpike')
    end
end
