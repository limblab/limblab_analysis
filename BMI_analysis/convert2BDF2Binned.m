function binnedData = convert2BDF2Binned(cerebus_filename,varargin)

[datapath,filename,ext] = fileparts(cerebus_filename);
BDF_filename = [filename '_BDF.mat'];
bin_filename = [filename '_bin.mat'];

if nargin >1
    use_default = varargin{1};
else
    use_default = false;
end

if use_default
    BDF2BinArgs = [];
else
    BDF2BinArgs = convertBDF2binnedGUI;
end
    
fprintf('Converting %s to BDF structure...\n',cerebus_filename);
BDF = get_cerebus_data(cerebus_filename,'verbose');
fprintf('Saving BDF structure %s...\n',BDF_filename);
save([datapath filesep BDF_filename], 'BDF');
fprintf('Done.\n');

if use_default
    BDF2BinArgs = get_default_binning_params(BDF);
end

if BDF2BinArgs.ArtRemEnable
    disp('Looking for Artifacts...');
    BDF = artifact_removal(BDF,BDF2BinArgs.NumChan,BDF2BinArgs.TimeWind, 1);
end
fprintf('Binning data: %s...\n', BDF_filename);
binnedData = convertBDF2binned(BDF,BDF2BinArgs);
fprintf('Saving binned data file %s...\n',bin_filename);
save([datapath filesep bin_filename], 'binnedData');
fprintf('Done.\n');

    