function [figure_list,data_struct]=compute_electrode_stability(fpath,input_data)
    %required fields in the input_data struct:
    %num_channels   the number of channels in the array. This is a
    %               workaround till I can implement something that actually
    %               looks at the data to see how many channels are in the
    %               files loaded
    %min_moddepth   the minimum modulation depth to consider a unit when
    %               computing the number of units and change in number of
    %               units
    foldercontents=dir(fpath);
    fnames={foldercontents.name};%extracts just the names from the foldercontents
    data_struct.file_list=[];
    figure_list=[];
    ctr=0;
    for i=1:length(foldercontents)
        if (length(fnames{i})>3)
        
            %skip things that aren't files
            if exist(strcat(fpath,fnames{i}),'file')~=2
                continue
            end
            %generate a new path to the source file of shortcuts
            temppath=follow_links(strcat(fpath,fnames{i}));
            if strcmp(temppath(end-3:end),'.mat')
                disp(strcat('Working on: ',temppath))
                ctr=ctr+1;
                try
                    disp('loading pd dataset from from file')
                    temp=load(temppath);
                    if length(fieldnames(temp))==1
                        fields=fieldnames(temp); 
                        temp=temp.(fields{1});
                        if isstruct(temp)
                            data_struct.all_pds{ctr}=
                        else
                            data_struct.all_pds{ctr}=temp;
                        end
                        clear temp
                        data_struct.file_list=strcat(data_struct.file_list,',',temppath);
                    elseif isempty(fieldnames(temp))
                        error(['compute_generic_stability_metrics:NoVariableInFile'],['Tried to load' temppath 'but found no variables in the file'])
                    else
                        error(['compute_generic_stability_metrics:MultipleVariableInFile'],['Tried to load' temppath 'but found multiple variables in the file'])
                    end
                catch temperr %catches the error in a MException class object called temperr
                    disp(strcat('Failed to process: ', temppath))
                    disp(temperr.identifier)
                    disp(temperr.message)
                end
            end
        end
    end
    if isempty(data_struct.file_list)
        error('compute_generic_stability_metrics:NoFilesFound','Found no .mat files to load')
    end
    %now that we have loaded all the files, get the pd and moddepth on each
    % channel each day into a single matrix
    data_struct.pdmat=zeros(input_data.num_channels,length(data_struct.all_pds));
    data_struct.moddepthmat=zeros(input_data.num_channels,length(data_struct.all_pds));
    for i=1:length(data_struct.all_pds)
        for j=1:length(data_struct.all_pds{i}.dir)
            if data_struct.all_pds{i}.channel(j)<=input_data.num_channels;
                data_struct.pdmat(data_struct.all_pds{i}.channel(j),i)=data_struct.all_pds{i}.dir(j);
                data_struct.moddepthmat(data_struct.all_pds{i}.channel(j),i)=data_struct.all_pds{i}.moddepth(j);
            end
        end
    end
    %assume that we have a full list of channels because we generated pdmat
    %and moddepth mat with a fixed dimension and limited our loop to only
    %those channels with the same dimension
    data_struct.chan_list=[1:input_data.num_channels]';
    
    %now make a smaller matrix containing only those rows where the
    %moddepth on the first day was larger than the limit set in input_data
    data_struct.welltuned_pdmat=data_struct.pdmat(data_struct.moddepthmat(data_struct.chan_list,1)>input_data.min_moddepth,:);
    data_struct.welltuned_moddepthmat=data_struct.moddepthmat(data_struct.moddepthmat(data_struct.chan_list,1)>input_data.min_moddepth,:);
    data_struct.welltuned_list=data_struct.chan_list(data_struct.moddepthmat(data_struct.chan_list,1)>input_data.min_moddepth,1);
    
    %make a few plots:
    temp=data_struct.welltuned_pdmat;
    mask=repmat(temp(:,1),1,size(temp,2));
    temp=temp-mask;

    temp(temp>pi)=temp(temp>pi)-2*pi;
    temp(temp<-pi)=temp(temp<-pi)+2*pi;
    figure_list=[figure_list figure('name','PD_change')];
    plot(temp')
    title(['Change in PD from first file for channels with moddepth greater than ' num2str(input_data.min_moddepth) ' in file 1'])
    xlabel('file number')
    ylabel('change in PD')
    h=legend(num2str(data_struct.welltuned_list));
    set(h,'Location','northwest')
    format_for_lee(figure_list(length(figure_list)))
    set(gca,'ylim',[-4 4])
    set(figure_list(length(figure_list)),'Position',[100 100 1000 1000])
    
    av=mean(temp,1);
    st=std(temp,1);
    figure_list=[figure_list figure('name','mean_PD_change')];
    boundedline([1:length(av)],av,st)
    title(['Mean change in PD from first file for channels with moddepth greater than ' num2str(input_data.min_moddepth) ' in file 1'])
    xlabel('file number')
    ylabel('change in PD')
    format_for_lee(figure_list(length(figure_list)))
    set(figure_list(length(figure_list)),'Position',[100 100 1000 1000])
    set(gca,'Layer','top')
    set(gca,'ylim',[-4 4])
end