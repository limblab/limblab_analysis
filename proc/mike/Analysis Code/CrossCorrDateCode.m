Mini_days= Mini_days; %{

%     '09-02-2011', ...
%     '09-07-2011', ...
%     '09-08-2011', ...
%     '09-09-2011', ...
%     '09-12-2011', ...
%     '03-19-2012', ...
%     '03-21-2012', ...
%     '03-28-2012', ...
%     '03-30-2012', ...
%     '04-02-2012', ...
%     '09-26-2011',...
%     '10-03-2011',...
%     '10-10-2011',...
%     '10-17-2011',...
%     '10-24-2011',...
%     '11-07-2011',...
%     '11-14-2011',...
%     '11-21-2011',...
%     '11-28-2011',...
%     '12-05-2011',...
%     '12-13-2011',...
%     '12-15-2011',...
%     '01-05-2012',...
%     '01-16-2012',...
%     '01-27-2012',...
%     '02-06-2012',...
%     '02-13-2012',...
%     '02-15-2012',...
%     '02-22-2012',...
%     '02-27-2012',...
%     '03-05-2012',...
%     '03-12-2011',...
%     '08-25-2011',...
%     '08-26-2011',...
%     '08-31-2011',...
%};


FileIndex = 1;
BDFlist_all=[];

for n=1:length(Mini_days)
    % take a day, find the kinStruct, and identifies all the
    % files of the given control type that were included.
    try
    BDFlist=findBDF_withControl('Mini',Mini_days{n},'hand');
    catch
        continue
    end
    BDFlist_all=[BDFlist_all; BDFlist'];
    FileList{n} = BDFlist;
    
    for k=1:length(BDFlist)
        
        DecoderAge = datenum(Mini_days{n}) - datenum('08-24-2011');
        DecoderAges(FileIndex) = DecoderAge;
        FileIndex = FileIndex + 1;
        
    end
end

