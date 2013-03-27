function elec_map = cerebusToElectrodeMap(cerebus2ElectrodesFile)
fileID = fopen(cerebus2ElectrodesFile,'r');
text = char(fread(fileID,inf,'char'))';
fclose(fileID);

text = regexp(text,'\n','split');
elec_map = {};
for iText = 1:length(text)
    temp_text = text{iText};
    temp_text = temp_text(1:strfind(text{iText},char(13))-1);
    temp_text = regexp(temp_text,'\t','split');
    if length(temp_text)== 5 && str2double(temp_text{5})~=0 && ~strcmp(temp_text{1}(1),'/') && length(temp_text{2}>0)
        switch temp_text{3}
            case 'A'
                bank = 0;
            case 'B'
                bank = 32;
            case 'C'
                bank = 64;
        end
        elec_map{end+1,1} = {str2double(temp_text{1}) str2double(temp_text{2}) bank+str2double(temp_text{4}) temp_text{5}};
    end
end
all_num = 1;
for iElec = 1:size(elec_map,1)
    if isnan(str2double(elec_map{iElec}{4}))
        all_num = 0;
    end
end

if all_num
    elec_map_temp = elec_map;
    elec_map = [];
    for iElec = 1:size(elec_map_temp,1)
        elec_map(end+1,:) = [elec_map_temp{iElec}{1} elec_map_temp{iElec}{2}...
            elec_map_temp{iElec}{3} str2double(elec_map_temp{iElec}{4})];
    end
end