function varargout=get_cursor_kinematics(inputItem)

% syntax varargout=get_cursor_kinematics(inputItem)
%
%              INPUT:
%                   inputItem - can either be left out, or 
%                               a path to the BDF-formatted
%                               .mat file, or a BDF-formatted
%                               struct from the workspace
%                               
%              OUTPUT:
%                   varargout - if specified, will return a BDF-formatted 
%                               struct with the .pos field having been 
%                               filled in from the BR log array.  If 
%                               unspecified, the function will save the 
%                               updated .mat file to the same location 
%                               from which the original .mat file was 
%                               read in.
%


if ~nargin                      % dialog for bdf
    [FileName,PathName]=uigetfile('*.mat','select a bdf file');
    pathToBDF=fullfile(PathName,FileName);
    load(pathToBDF)
    if exist('bdf','var')~=1
        if exist('out_struct','var')~=1
            error(sprintf(['neither ''bdf'' or ''out_struct'' was found.\n', ...
                'if %s\n contains a properly formatted bdf structure, \n', ...
                'load it manually, and pass it as an argument.\n']))
        else
            bdf=out_struct;
            clear out_struct
            varName='out_struct';
        end
    else
        varName='bdf';
    end     % if we make it to this point we know the variable bdf exists.
else
    if isstr(inputItem) % path to bdf is input
        pathToBDF=inputItem;
        load(pathToBDF)
        if exist('bdf','var')~=1
            if exist('out_struct','var')~=1
                error(sprintf(['neither ''bdf'' or ''out_struct'' was found.\n', ...
                    'if %s\n contains a properly formatted bdf structure, \n', ...
                    'load it manually, and pass it as an argument.\n']))
            else
                bdf=out_struct;
                clear out_struct
                varName='out_struct';
            end
        else
            varName='bdf';
        end     % if we make it to this point we know the variable bdf exists.        
    else                % bdf has been passed in.
        bdf=inputItem;
        clear inputItem
        varName=inputname(1);
        % try to be smart about where bdf might be located.  Do something
        % with bdf.meta.filename
        CCMbank={'Chewie_8I2','Mini_7H1'};
        animal=regexp(bdf.meta.filename,'Chewie|Mini','match','once');
        if isempty(animal)
            % revert to dialog, because the name was not found in our
            % database.  But now, the dialog is looking for the text file
            [FileNameTxt,PathNameTxt]=uigetfile('*.txt','select the log file');
            pathToBR=fullfile(PathNameTxt,FileNameTxt);
            % this is stupid, but at least it keeps things consistent.
            % Just switch the logic on the application below.
            pathToBDF=regexprep(fullfile(PathNameTxt,FileNameTxt), ...
                {['BrainReader logs',filesep,'online'],'\.txt'},{'bdf','\.mat'});
        else
            if ismac
                % automagically, assuming /Volumes is the mount point for data.
                pathToCitadelData=[fullfile('/Volumes','data', ...
                    CCMbank{cellfun(@isempty,regexp(CCMbank,animal))==0})];
                [status,result]=unix(['find ',pathToCitadelData,' -name "', ...
                    regexprep(bdf.meta.filename,'\.plx','\.mat" -print')]);
                if status==0
                    pathToBDF=result;
                else
                    % revert to dialog, we couldn't automagically locate the
                    % BDF.  But now, the dialog is looking for the text file;
                    % the pathToBDF will be reverse-lookup'd (not a word).
                    [FileNameTxt,PathNameTxt]=uigetfile('*.mat','select a bdf file');
                    pathToBR=fullfile(PathNameTxt,FileNameTxt);
                    % this is stupid, but at least it keeps things consistent.
                    % Just switch the logic on the application below.
                    pathToBDF=regexprep(fullfile(PathNameTxt,FileNameTxt), ...
                        {['BrainReader logs',filesep,'online'],'\.txt'},{'bdf','\.mat'});
                end
            else
                % PC case.  revert to dialog, or smartly determine drive
                % letter, etc. for citadel/data
            end
        end
    end
end

% strip out trailing CR, if present.
pathToBDF(regexp(pathToBDF,sprintf('\n')))='';


% load the BrainReader file
switch animal
    case 'Mini'
        pathToBR=regexprep(pathToBDF,{'bdf','\.mat'}, ...
            {['BrainReader logs',filesep,'online'],'\.txt'});
    case 'Chewie'
        pathToBR=regexprep(pathToBDF,{'BDFs','\.mat'}, ...
            {['BrainReader logs',filesep,'online'],'\.txt'});
end
% just in case
pathToBR(regexp(pathToBR,sprintf('\n')))='';
BRarray=readBrainReaderFile_function(pathToBR);

% get rid of any lead-in data
tmp=size(BRarray,1);
BRarray(BRarray(:,7)==0,:)=[];
fprintf(1,'deleted %d lines with time stamp=0\n',tmp-size(BRarray,1))

BR_original_time_vector=BRarray(:,7);
% scale time vector
BRarray(:,7)=BRarray(:,7)/1e9;
BRarray(:,7)=BRarray(:,7)-BRarray(1,7);

% to do a back-corrected BR log file: put a breakpoint at the first line of
% code that occurs below these comments. then, at the command line:
%
% BR_original_time_vector(find(BRarray(:,7)>=start_time,1,'first'))
%
% where start_time is something you've already determined in the past,
% using BRalign.m If you're going to run BRalign.m again, just do this
% operation there, it's simpler.
%
% if it comes out looking like    4.4182e+12
% just call
%
% format long g
% 
% and reissue the command.  Once you've got something more like
%
% 4418176548864
%
% copy that, open up the BR log in a text editor (NOT windows, it won't
% like the carriage returns/linefeeds/whatever), do a find on that number
% (the EXACT number should be represented in the time array), and then ON
% THE LINE ABOVE where the number was found, insert a blank line, and type 
%
% Plexon recording startup
%
% save, and re-execute this function.  It should run properly at that
% point.

% interpolate BRarray to 50msec bins before substituting in for bdf.pos.
newTvector=0:0.05:0.05*(size(BRarray,1)-1);
newXpos=interp1(BRarray(:,7),BRarray(:,3),newTvector);
newYpos=interp1(BRarray(:,7),BRarray(:,4),newTvector);
bdf.pos=[newTvector' newXpos' newYpos'];

newXvel=interp1(BRarray(:,7),BRarray(:,5),newTvector);
newYvel=interp1(BRarray(:,7),BRarray(:,6),newTvector);
bdf.vel=[newTvector' newXvel' newYvel'];


bdf.meta.brain_control=1;
decoderDate=decoderDateFromLogFile(pathToBR);
bdfDate=datenum(regexp(bdf.meta.datetime,'\s*[0-9]+/\s*[0-9]+/[0-9]+','match','once'));
bdf.meta.decoder_age=bdfDate-decoderDate;
% could look into the brainReader file as it's read in, guess from the
% decoder file's name whether it was spike control or LFP control, and save
% that info in bdf.meta.brain_control, rather than just a 1.

if nargout
    varargout{1}=bdf;
else
    % automatically re-save the bdf
    if strcmp(varName,'out_struct')
        out_struct=bdf;
        clear bdf
    end
    save(pathToBDF,varName)
end