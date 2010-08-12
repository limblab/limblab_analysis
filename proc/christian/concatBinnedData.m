function binnedData = concatBinnedData(struct1,struct2,varargin)

if nargin > 2
    neuronIDs = varargin{1};
else
    neuronIDs = [];
end

if struct1.timeframe(2)-struct1.timeframe(1)~=struct2.timeframe(2)-struct2.timeframe(1)
    disp('incompatible sampling rate - data concatenation aborted');
    binnedData = struct1;
    return;
else
    binnedData = struct1;
    
    binsize = round(1000*(struct1.timeframe(2)-struct1.timeframe(1)))/1000;
    t_offset = struct1.timeframe(end)+binsize;
    tf2 = struct2.timeframe+t_offset;
  %     tf2 = (0:size(struct2.timeframe,1)-1)*(binsize) + t_offset;
    binnedData.timeframe = [struct1.timeframe; tf2]; 
    clear tf2;
end

%% Concat EMGs
if isfield(struct1, 'emgguide') && isfield(struct2, 'emgguide')
    EMG_FLAG = 0;
    for i = 1:size(struct1.emgguide,1)
        if ~strcmp(deblank(struct1.emgguide(i,:)),deblank(struct2.emgguide(i,:)))
            disp('incompatible EMG labels - concatenation aborted');
            binnedData = struct1;
            return;           
        end
    end

    if ~isfield(struct1, 'emgdatabin') || ~isfield(struct2, 'emgdatabin') || (size(struct1.emgguide,1)~=size(struct2.emgguide,1))
        disp('incompatible EMG data - concatenation aborted');
        binnedData = struct1;
        return;
    else
        binnedData.emgdatabin = [struct1.emgdatabin; struct2.emgdatabin];
    end
end            
%% Concat Spikes
if isfield(struct1, 'spikeguide') && isfield(struct2, 'spikeguide')
    %NeuronIDs file provided?
    if isempty(neuronIDs) %no -
        SPIKE_FLAG = 0;
        for i = 1:size(struct1.spikeguide,1)
            if ~strcmp(deblank(struct1.spikeguide(i,:)),deblank(struct2.spikeguide(i,:)))
                disp(sprintf('incompatible spike labels index %d - concatenation aborted',i));
                binnedData = struct1;
                return;
            end
        end
        if ~isfield(struct1, 'spikeratedata') || ~isfield(struct2, 'spikeratedata') || (size(struct1.spikeguide,1)~=size(struct2.spikeguide,1))
            disp('incompatible spike data - concatenation aborted');
            binnedData = struct1;
            return;
        else
            binnedData.spikeratedata = [struct1.spikeratedata; struct2.spikeratedata];
        end
    
    else % use neuronIDs to concat only some of the units and discard others
        num_units = size(neuronIDs,1);
        Neurons1 = spikeguide2neuronIDs(struct1.spikeguide);
        Neurons2 = spikeguide2neuronIDs(struct2.spikeguide);
        
        s1_i = zeros(1,num_units);
        s2_i = zeros(1,num_units);
        for i = 1:num_units
            spot1 = find( Neurons1==neuronIDs(i,1),1,'first');
            spot2 = find( Neurons2==neuronIDs(i,1),1,'first');
            if isempty(spot1) || isempty(spot2)
                disp('incompatible spike data - concatenation aborted');
                binnedData = struct1;
                return;
            else
                s1_i(i) = spot1;
                s2_i(i) = spot2;
            end
        end
        binnedData.spikeguide = neuronIDs2spikeguide(neuronIDs);
        binnedData.spikeratedata = [struct1.spikeratedata(:,s1_i); struct2.spikeratedata(:,s2_i)];
        clear Neurons1 Neurons2 num_units s1_i s2_i spot1 spot2;
    end
    
end
    
%% Concat Force
if isfield(struct1, 'forcelabels') && isfield(struct2, 'forcelabels')
    for i = 1:size(struct1.forcelabels,1)
        if ~strcmp(deblank(struct1.forcelabels(i,:)),deblank(struct2.forcelabels(i,:)))
            disp('incompatible force labels - concatenation aborted');
            binnedData = struct1;
            return;
        end
    end

    if ~isfield(struct1, 'forcedatabin') || ~isfield(struct2, 'forcedatabin') || (size(struct1.forcelabels,1)~=size(struct2.forcelabels,1))
        disp('incompatible force data - concatenation aborted');
        binnedData = struct1;
        return;
    else
        binnedData.forcedatabin = [struct1.forcedatabin; struct2.forcedatabin];
    end
end

%% Concat Pos
if isfield(struct1, 'cursorposlabels') && isfield(struct2, 'cursorposlabels')
    for i = 1:size(struct1.cursorposlabels,1)
        if ~strcmp(deblank(struct1.cursorposlabels(i,:)),deblank(struct2.cursorposlabels(i,:)))
            disp('incompatible position labels - concatenation aborted');
            binnedData = struct1;
            return;
        end
    end

    if ~isfield(struct1, 'cursorposbin') || ~isfield(struct2, 'cursorposbin') || (size(struct1.cursorposlabels,1)~=size(struct2.cursorposlabels,1))
        disp('incompatible position data - concatenation aborted');
        binnedData = struct1;
        return;
    else
        binnedData.cursorposbin = [struct1.cursorposbin; struct2.cursorposbin];
    end
end

%% Concat Words
if isfield(struct1, 'words') && isfield(struct2, 'words')
    w2 = [struct2.words(:,1)+t_offset struct2.words(:,2)];
    binnedData.words = [struct1.words; w2];
    clear w2;
end

%% Concat Targets
if isfield(struct1, 'targets') && isfield(struct2, 'targets')
    if isfield(struct1.targets, 'corners') && isfield(struct2.targets, 'corners')
        c2 = [struct2.targets.corners(:,1)+t_offset struct2.targets.corners(:,2:end)];
        binnedData.targets.corners = [struct1.targets.corners; c2];
        clear c2;
    end
end

if isfield(struct1, 'targets') && isfield(struct2, 'targets')
    if isfield(struct1.targets, 'rotation') && isfield(struct2.targets, 'rotation')
        c2 = [struct2.targets.rotation(:,1)+t_offset struct2.targets.rotation(:,2:end)];
        binnedData.targets.rotation = [struct1.targets.rotation; c2];
        clear c2;
    end
end

    