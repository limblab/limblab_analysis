% this script reads all the spike timestamp and a/d info from a plx file into matlab
% variables.

% Open a plx file
% this will bring up the file-open dialog
StartingFileName = '';
%StartingFileName = 'c:\plexondata\NSSample.plx';
%StartingFileName = 'c:\plexondata\au101602a.plx';
[OpenedFileName, Version, Freq, Comment, Trodalness, NPW, PreThresh, SpikePeakV, SpikeADResBits, SlowPeakV, SlowADResBits, Duration, DateTime] = plx_information(StartingFileName);

disp(['Opened File Name: ' OpenedFileName]);
disp(['Version: ' num2str(Version)]);
disp(['Frequency : ' num2str(Freq)]);
disp(['Comment : ' Comment]);
disp(['Date/Time : ' DateTime]);
disp(['Duration : ' num2str(Duration)]);
disp(['Num Pts Per Wave : ' num2str(NPW)]);
disp(['Num Pts Pre-Threshold : ' num2str(PreThresh)]);
% some of the information is only filled if the plx file version is >102
if ( Version > 102 )
    if ( Trodalness < 2 )
        disp('Data type : Single Electrode');
    elseif ( Trodalness == 2 )
        disp('Data type : Stereotrode');
    elseif ( Trodalness == 4 )
        disp('Data type : Tetrode');
    else
        disp('Data type : Unknown');
    end
        
    disp(['Spike Peak Voltage (mV) : ' num2str(SpikePeakV)]);
    disp(['Spike A/D Resolution (bits) : ' num2str(SpikeADResBits)]);
    disp(['Slow A/D Peak Voltage (mV) : ' num2str(SlowPeakV)]);
    disp(['Slow A/D Resolution (bits) : ' num2str(SlowADResBits)]);
end   



% get some counts
[tscounts, wfcounts, evcounts] = plx_info(OpenedFileName,1);

% tscounts, wfcounts are indexed by (unit+1,channel+1)
% tscounts(:,ch+1) is the per-unit counts for channel ch
% sum( tscounts(:,ch+1) ) is the total wfs for channel ch (all units)
% [nunits, nchannels] = size( tscounts )
% To get number of nonzero units/channels, use nnz() function

% gives actual number of units (including unsorted) and actual number of
% channels plus 1
[nunits1, nchannels1] = size( tscounts );   

% we will read in the timestamps of all units,channels into a two-dim cell
% array named allts, with each cell containing the timestamps for a unit,channel.
% Note that allts second dim is indexed by the 1-based channel number.
for iunit = 0:nunits1-1   % starting with unit 0 (unsorted) 
    for ich = 1:nchannels1-1
        if ( tscounts( iunit+1 , ich+1 ) > 0 )
            % get the timestamps for this channel and unit 
            [nts, allts{iunit+1,ich}] = plx_ts(OpenedFileName, ich , iunit );
         end
    end
end
           
% get some other info about the spike channels
[nspk,spk_filters] = plx_chan_filters(OpenedFileName);
[nspk,spk_gains] = plx_chan_gains(OpenedFileName);
[nspk,spk_threshs] = plx_chan_thresholds(OpenedFileName);
[nspk,spk_names] = plx_chan_names(OpenedFileName);


% get the a/d data into a cell array also.
% This is complicated by channel numbering.
% The presence/absence of slow analog data can be seen by looking at the
% evcounts array at indexes 300-363. E.g. the number of samples for
% analog channel 0 is stored at evcounts(300).
% Note that analog ch numbering starts at 0, not 1 in the data, but the
% 'allad' cell array is indexed by ich+1
for ich = 0:63
    if ( evcounts(300+ich) > 0 )
        [adfreq, nad, tsad, fnad, allad{ich+1}] = plx_ad(OpenedFileName, ich);
    end
end
[nad,adfreqs] = plx_adchan_freqs(OpenedFileName);
[nad,adgains] = plx_adchan_gains(OpenedFileName);
[nad,adnames] = plx_adchan_names(OpenedFileName);

% just for fun, plot the channels with a/d data
[adrows,nActiveADs] = size(allad);
for ich = 1:nActiveADs
    if ( size(allad{ich}) > 0 )
        subplot(nActiveADs,1,ich); plot(allad{ich});
    end
end

% and finally the events
for iev = 1:299
    if ( evcounts(iev) > 0 )
        if ( iev == 257 )
            % treat strobed channel seperately, just to avoid setting up a
            % cell array to hold strobed values when only one channel will
            % have them.
            [nevs{iev}, tsevs{iev}, svStrobed] = plx_event_ts(OpenedFileName, iev); 
        else
            [nevs{iev}, tsevs{iev}, svdummy] = plx_event_ts(OpenedFileName, iev);
        end
    end
end
[nev,evnames] = plx_event_names(OpenedFileName);
