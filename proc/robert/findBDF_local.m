function pathToBDF=findBDF_local(nameIn,suppressDialog)

% syntax pathToBDF=findBDF_local(nameIn,suppressDialog)
%
% looks for a BDF-formatted file on the local computer.  Assumptions about
% base directories will be machine-specific.

% TODO: get name of user with "set use" command?
%       any useful differences that can be assumed based on winXP or win7?

if nargin < 2
    suppressDialog=0;
end

% if the file name as a .mat extension, keep it.
[~,~,ext]=FileParts(nameIn);

switch ext
    case '.plx'
        nameIn=regexprep(nameIn,'\.plx','\.mat');
    case '.txt'
         nameIn=regexprep(nameIn,'\.txt','\.mat');
    case '.mat'
%         nameIn=nameIn;
    otherwise
        nameIn=[nameIn, '.mat'];
end

animal=regexp(nameIn,'Chewie|Mini','match','once');

switch lower(machineName)
    case 'bumblebeeman'
        basePath=fullfile('E:\monkey data',animal);
    case 'gob'
        basePath=fullfile('C:\Documents and Settings\Administrator\Desktop\RobertF\data',animal);
end
[status,result]=dos(['cd /d ',basePath,' && dir *',nameIn,'* /s /b']);

% evaluate, based on results of system commands to find file.
if status==0
    returns=regexp(result,'\n');
    pathToBDF=result(1:(returns-1));
else
    % revert to dialog, we couldn't automagically locate the
    % BDF.
    if ~suppressDialog
        [FileName,PathName]=uigetfile('*.mat','select a bdf file');
        pathToBDF=fullfile(PathName,FileName);
    else
        error('file not found: %s\n',nameIn)
    end
end

pathToBDF(regexp(pathToBDF,sprintf('\n')))='';
