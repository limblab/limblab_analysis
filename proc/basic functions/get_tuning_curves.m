function [figure_handles, output_data]=get_tuning_curves(folder,options)
% GET_TUNING_CURVES

% if behaviors not in options, create it
if(~isfield(options,'behaviors'))
    % if bdf is in options, use it
    if(~isfield(options,'bdf'))
        if(folder(end)~=filesep)
            folder = [folder filesep];
        end
        bdf = get_nev_mat_data([folder options.prefix],options.labnum);
    else
        bdf=options.bdf;
    end

    %% prep bdf
    bdf.meta.task = 'RW';

    %add firing rate to the units fields of the bdf
    opts.binsize=0.05;
    opts.offset=-.015;
    opts.do_trial_table=1;
    opts.do_firing_rate=1;
    bdf=postprocess_bdf(bdf,opts);
    %% set up parse for tuning
    optionstruct.compute_pos_pds=0;
    optionstruct.compute_vel_pds=1;
    optionstruct.compute_acc_pds=0;
    optionstruct.compute_force_pds=0;
    optionstruct.compute_dfdt_pds=0;
    optionstruct.compute_dfdtdt_pds=0;
    if(isfield(options,'which_units'))
        which_units = options.which_units;
    elseif options.only_sorted
        for i=1:length(bdf.units)
            temp(i)=bdf.units(i).id(2)~=0 && bdf.units(i).id(2)~=255;
        end
        ulist=1:length(bdf.units);
        which_units=ulist(temp);
    end
    optionstruct.data_offset=-.015;%negative shift shifts the kinetic data later to match neural data caused at the latency specified by the offset
    behaviors = parse_for_tuning(bdf,'continuous','opts',optionstruct,'units',which_units);
else
    behaviors = options.behaviors;
end

% find velocities and directions
armdata = behaviors.armdata;
vel = armdata(strcmp('vel',{armdata.name})).data;
dir = atan2(vel(:,2),vel(:,1));

% bin directions
dir_bins = round(dir/(pi/4))*(pi/4);
dir_bins(dir_bins==-pi) = pi;

% average firing rates for directions
bins = -3*pi/4:pi/4:pi;
bins = bins';
for i = 1:length(bins)
    binned_FR(i,:) = sum(behaviors.FR(dir_bins==bins(i),:))/sum(dir_bins==bins(i));
end

% plot tuning curves
if options.plot_curves
    figure_handles = zeros(size(binned_FR,2),1);
    unit_ids = behaviors.unit_ids;
    for i=1:length(figure_handles)
        figure_handles(i) = figure('name',['channel_' num2str(unit_ids(i,1)) '_unit_' num2str(unit_ids(i,2)) '_tuning_plot']);

        polar(repmat(bins,2,1),repmat(binned_FR(:,i),2,1))
    end
else
    figure_handles = [];
end

output_data.bins = bins;
output_data.binned_FR = binned_FR;