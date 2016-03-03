function [figure_handles,output_data] = plot_PD_change(folder,options)
    %% set up options
%     output_data.unit_tuning_stats_DL = options.unit_tuning_stats_DL;
%     output_data.unit_tuning_stats_PM =  options.unit_tuning_stats_PM;
%     output_data.unit_tuning_stats_full = options.unit_tuning_stats_full;
%     output_data.unit_tuning_stats_DL_bimodal = options.unit_tuning_stats_bimodal;
%     output_data.unit_tuning_stats_PM_bimodal = options.unit_tuning_stats_bimodal;
    output_data.unit_tuning_stats_DL = unit_tuning_stats_DL;
    output_data.unit_tuning_stats_PM =  unit_tuning_stats_PM;
    output_data.unit_tuning_stats_full = unit_tuning_stats_full;
    output_data.unit_tuning_stats_DL_bimodal = unit_tuning_stats_DL_bimodal;
    output_data.unit_tuning_stats_PM_bimodal = unit_tuning_stats_PM_bimodal;

    %% Get PD tables
    output_data.unit_pd_table_DL=sortrows(get_pd_table(output_data.unit_tuning_stats_DL_bimodal),[1 2]);
    output_data.unit_pd_table_PM=sortrows(get_pd_table(output_data.unit_tuning_stats_PM_bimodal),[1 2]);
    output_data.unit_pd_table_full=sortrows(get_pd_table(output_data.unit_tuning_stats_full),[1 2]);

    % Get PD tables for major axis direction
    unit_pd_table_DL_bimodal=sortrows(get_pd_table(output_data.unit_tuning_stats_DL_bimodal,'bimodal'),[1 2]);
    unit_pd_table_PM_bimodal=sortrows(get_pd_table(output_data.unit_tuning_stats_PM_bimodal,'bimodal'),[1 2]);
    % Adjust bimodal PDs (double PDs)
    dir_CI_adj = (mod(unit_pd_table_DL_bimodal.dir_CI-repmat(unit_pd_table_DL_bimodal.dir,1,2)+pi,2*pi)-pi)/2;
    unit_pd_table_DL_bimodal.dir = unit_pd_table_DL_bimodal.dir/2;
    unit_pd_table_DL_bimodal.dir_CI = mod(dir_CI_adj+repmat(unit_pd_table_DL_bimodal.dir,1,2)+pi,2*pi)-pi;
    dir_CI_adj = (mod(unit_pd_table_PM_bimodal.dir_CI-repmat(unit_pd_table_PM_bimodal.dir,1,2)+pi,2*pi)-pi)/2;
    unit_pd_table_PM_bimodal.dir = unit_pd_table_PM_bimodal.dir/2;
    unit_pd_table_PM_bimodal.dir_CI = mod(dir_CI_adj+repmat(unit_pd_table_PM_bimodal.dir,1,2)+pi,2*pi)-pi;
    % Save bimodal PDs
    output_data.unit_pd_table_DL_bimodal = unit_pd_table_DL_bimodal;
    output_data.unit_pd_table_PM_bimodal = unit_pd_table_PM_bimodal;

    %make a table that only has the best tuned units:
    DL_CI_width = diff(output_data.unit_pd_table_DL.dir_CI,1,2); % get CI widths
    PM_CI_width = diff(output_data.unit_pd_table_PM.dir_CI,1,2);
    DL_CI_width(DL_CI_width<0) = DL_CI_width(DL_CI_width<0)+2*pi;
    PM_CI_width(PM_CI_width<0) = PM_CI_width(PM_CI_width<0)+2*pi;
%         DL_CI_width = min(DL_CI_width,2*pi-DL_CI_width); % in case we get larger slice of circle instead of smaller slice
%         PM_CI_width = min(PM_CI_width,2*pi-PM_CI_width);
    output_data.unit_best_modulated_table_DL=output_data.unit_pd_table_DL(DL_CI_width<pi/4,:);
    output_data.unit_best_modulated_table_PM=output_data.unit_pd_table_PM(PM_CI_width<pi/4,:);
    [~,best_combined_idx_DL,best_combined_idx_PM] = intersect(double(output_data.unit_best_modulated_table_DL(:,1:2)),double(output_data.unit_best_modulated_table_PM(:,1:2)),'rows');
    output_data.unit_best_combined_table_DL = output_data.unit_best_modulated_table_DL(best_combined_idx_DL,:);
    output_data.unit_best_combined_table_PM = output_data.unit_best_modulated_table_PM(best_combined_idx_PM,:);

    unit_pd_table_DL = output_data.unit_pd_table_DL;
    unit_pd_table_PM = output_data.unit_pd_table_PM;
    unit_best_modulated_table_DL = output_data.unit_best_modulated_table_DL;
    unit_best_modulated_table_PM = output_data.unit_best_modulated_table_PM;
    unit_best_combined_table_DL = output_data.unit_best_combined_table_DL;
    unit_best_combined_table_PM = output_data.unit_best_combined_table_PM;

    %% figures
    if(options.dual_array)
        array_break = options.array_break;
    end

    figure_handles = [];

    %polar plot of all pds, with radial length equal to scaled 
    %modulation depth
    %compute a scaling factor for the polar plots to use. Polar plots
    %will use a log function of moddepth so that the small modulation
    %PDs are visible. The scaling factor scales all the moddepths up so
    %that the log produces positive values rather than negative values.
    %all log scaled polar plots of the unit PDs will use the same
    %factor
    mag_scale_DL=1/min(unit_pd_table_DL.moddepth);
    angs_DL=[unit_pd_table_DL.dir unit_pd_table_DL.dir]';
    mags_DL=log((1+[zeros(size(unit_pd_table_DL.dir)), mag_scale_DL*unit_pd_table_DL.moddepth])');
    angs_best_DL=[unit_best_modulated_table_DL.dir unit_best_modulated_table_DL.dir]';
    mags_best_DL=log((1+[zeros(size(unit_best_modulated_table_DL.dir)), mag_scale_DL*unit_best_modulated_table_DL.moddepth])');

    %Plot the DL set in unsaturated colors
    h=figure('name','unit_polar_PDs_DL');
    figure_handles=[figure_handles h];
    polar(0,max(mags_DL(2,:)))
    hold all
    if(options.dual_array)
        %assumes table is sorted by channel and then unit
        array_break_idx = find(unit_pd_table_DL.channel>array_break,1,'first');
        h=polar(angs_DL(:,1:array_break_idx-1),mags_DL(:,1:array_break_idx-1));
        set(h,'linewidth',2,'color',[0.8 0.8 1])
        h=polar(angs_DL(:,array_break_idx:end),mags_DL(:,array_break_idx:end));
        set(h,'linewidth',2,'color',[0.8 01 0.8])

        array_break_idx = find(unit_best_modulated_table_DL.channel>array_break,1,'first');
        h=polar(angs_best_DL(:,1:array_break_idx-1),mags_best_DL(:,1:array_break_idx-1));
        set(h,'linewidth',2,'color',[0 0 1])
        h=polar(angs_best_DL(:,array_break_idx:end),mags_best_DL(:,array_break_idx:end));
        set(h,'linewidth',2,'color',[0 1 0])
    else
        h=polar(angs_DL,mags_DL);
        set(h,'linewidth',2,'color',[0.8 0.8 1])
        h=polar(angs_best_DL,mags_best_DL);
        set(h,'linewidth',2,'color',[0 0 1])
    end
    hold off
    title(['\fontsize{14}Polar plot of all DL unit PDs.','\newline',...
            '\fontsize{10}Amplitude normalized and log scaled'])

    %Set up the PM things
    mag_scale_PM=1/min(unit_pd_table_PM.moddepth);
    angs_PM=[unit_pd_table_PM.dir unit_pd_table_PM.dir]';
    mags_PM=log((1+[zeros(size(unit_pd_table_PM.dir)), mag_scale_PM*unit_pd_table_PM.moddepth])');
    angs_best_PM=[unit_best_modulated_table_PM.dir unit_best_modulated_table_PM.dir]';
    mags_best_PM=log((1+[zeros(size(unit_best_modulated_table_PM.dir)), mag_scale_PM*unit_best_modulated_table_PM.moddepth])');

    %Plot the PM set in unsaturated colors
    h=figure('name','unit_polar_PDs_PM');
    figure_handles=[figure_handles h];
    polar(0,max(mags_PM(2,:)))
    hold all
    if(options.dual_array)
        %assumes table is sorted by channel and then unit
        array_break_idx = find(unit_pd_table_PM.channel>array_break,1,'first');
        h=polar(angs_PM(:,1:array_break_idx-1),mags_PM(:,1:array_break_idx-1));
        set(h,'linewidth',2,'color',[0.8 0.8 1])
        h=polar(angs_PM(:,array_break_idx:end),mags_PM(:,array_break_idx:end));
        set(h,'linewidth',2,'color',[0.8 01 0.8])

        array_break_idx = find(unit_best_modulated_table_PM.channel>array_break,1,'first');
        h=polar(angs_best_PM(:,1:array_break_idx-1),mags_best_PM(:,1:array_break_idx-1));
        set(h,'linewidth',2,'color',[0 0 1])
        h=polar(angs_best_PM(:,array_break_idx:end),mags_best_PM(:,array_break_idx:end));
        set(h,'linewidth',2,'color',[0 1 0])
    else
        h=polar(angs_PM,mags_PM);
        set(h,'linewidth',2,'color',[0.8 0.8 1])
        h=polar(angs_best_PM,mags_best_PM);
        set(h,'linewidth',2,'color',[0 0 1])
    end
    hold off
    title(['\fontsize{14}Polar plot of all PM unit PDs.','\newline',...
            '\fontsize{10}Amplitude normalized and log scaled'])


    %%% Plot PD change diagram
    % map CI width (range: (0,pi))to whiteness values between 0 and 1
    DL_white = DL_CI_width/pi;
    PM_white = PM_CI_width/pi;
    change_white = max(DL_white,PM_white);
    
    change_white(change_white>1/4)=1;
    change_table = array2table([unit_pd_table_DL.channel unit_pd_table_DL.unit angs_PM(1,:)' angs_DL(1,:)' change_white],'VariableNames',{'chan','unit','angs_PM','angs_DL','change_white'});
    change_table = sortrows(change_table,'change_white','descend');

    h=figure('name','unit_polar_PD_differences');
    figure_handles=[figure_handles h];
    %plot circles
    h=polar(linspace(-pi,pi,1000),ones(1,1000));
    set(h,'linewidth',2,'color',[1 0 0])
    hold all
    h=polar(linspace(-pi,pi,1000),0.5*ones(1,1000));
    set(h,'linewidth',2,'color',[0.6 0.5 0.7])

    % plot changes with alpha dependent on CI width
    for unit_ctr = 46%1:height(change_table)
        if(options.dual_array)
            if(change_table.chan(unit_ctr)<=array_break)
                h=polar(linspace(change_table.angs_PM(unit_ctr),change_table.angs_DL(unit_ctr),2),linspace(0.5,1,2));
                set(h,'linewidth',2,'color',[change_table.change_white(unit_ctr) change_table.change_white(unit_ctr) 1])
            else
                h=polar(linspace(change_table.angs_PM(unit_ctr),change_table.angs_DL(unit_ctr),2),linspace(0.5,1,2));
                set(h,'linewidth',2,'color',[change_table.change_white(unit_ctr) 1 change_table.change_white(unit_ctr)])
            end
        else
            alpha = 1-change_table.change_white(unit_ctr);
            h=polar(linspace(change_table.angs_PM(unit_ctr),change_table.angs_DL(unit_ctr),2),linspace(0.5,1,2));
            set(h,'linewidth',2,'color',alpha*[0.1 0.6 1] +  (1-alpha)*[1 1 1])
        end
    end
    %plot circles again
    h=polar(linspace(-pi,pi,1000),ones(1,1000));
    set(h,'linewidth',2,'color',[1 0 0])
    hold all
    h=polar(linspace(-pi,pi,1000),0.5*ones(1,1000));
    set(h,'linewidth',2,'color',[0.6 0.5 0.7])
    
    set(findall(gcf, 'String','  0.2','-or','String','  0.4','-or','String','  0.6','-or','String','  0.8',...
            '-or','String','  1') ,'String', ' '); % remove a bunch of labels from the polar plot; radial and tangential
        
    title('Plot of PD changes')

    % Plot all tuning curves
    % get tuning curves for DL
%     tuningopts_DL.behaviors = behaviors_DL_bimodal;
%     tuningopts_DL.plot_curves = 0;
%     tuningopts_DL.binsize = 1;
%     [~,tuning_out_DL] = get_tuning_curves(folder,tuningopts_DL);
% 
%     % get tuning curves for PM
%     tuningopts_PM.behaviors = behaviors_PM_bimodal;
%     tuningopts_PM.plot_curves = 0;
%     tuningopts_PM.binsize = 1;
%     [~,tuning_out_PM] = get_tuning_curves(folder,tuningopts_PM);
% 
%     % plot tuning curves
%     unit_ids = behaviors_DL.unit_ids;
%     angs_DL_bimodal=[unit_pd_table_DL_bimodal.dir unit_pd_table_DL_bimodal.dir]';
%     angs_PM_bimodal=[unit_pd_table_PM_bimodal.dir unit_pd_table_PM_bimodal.dir]';
%     dir_CI_DL = unit_pd_table_DL.dir_CI;
%     dir_CI_PM = unit_pd_table_PM.dir_CI;
%     dir_CI_DL_bimodal = unit_pd_table_DL_bimodal.dir_CI;
%     dir_CI_PM_bimodal = unit_pd_table_PM_bimodal.dir_CI;
%     for i=1:length(unit_ids)
%         h = figure('name',['channel_' num2str(unit_ids(i,1)) '_unit_' num2str(unit_ids(i,2)) '_tuning_plot']);
%         figure_handles = [figure_handles h];
% 
%         % Figure out max size to display at
% %             rad_DL = unit_pd_table_DL.moddepth(i);
% %             rad_PM = unit_pd_table_PM.moddepth(i);
%         max_rad = max([tuning_out_DL.binned_FR(:,i); tuning_out_PM.binned_FR(:,i)]);
%         rad_DL = max_rad;
%         rad_PM = max_rad;
% 
%         % plot initial point
%         h=polar(0,max_rad);
%         set(h,'color','w')
%         hold all
% 
%         % DL workspace tuning curve
%         h=polar(repmat(tuning_out_DL.bins,2,1),repmat(tuning_out_DL.binned_FR(:,i),2,1));
%         set(h,'linewidth',2,'color',[1 0 0])
%         th_fill = [flipud(tuning_out_DL.bins); tuning_out_DL.bins(end); tuning_out_DL.bins(end); tuning_out_DL.bins];
%         r_fill = [flipud(tuning_out_DL.binned_CI_high(:,i)); tuning_out_DL.binned_CI_high(end,i); tuning_out_DL.binned_CI_low(end,i); tuning_out_DL.binned_CI_low(:,i)];
%         [x_fill,y_fill] = pol2cart(th_fill,r_fill);
%         patch(x_fill,y_fill,[1 0 0],'facealpha',0.3,'edgealpha',0);
% 
%         % DL workspace PD
%         h=polar(angs_DL(:,i),rad_DL*[0;1]);
%         set(h,'linewidth',2,'color',[1 0 0])
%         th_fill = [dir_CI_DL(i,2) angs_DL(1,i) dir_CI_DL(i,1) 0];
%         r_fill = [rad_DL rad_DL rad_DL 0];
%         [x_fill,y_fill] = pol2cart(th_fill,r_fill);
%         patch(x_fill,y_fill,[1 0 0],'facealpha',0.3);
%         h=polar(angs_DL_bimodal(:,i),rad_DL*[0;1]/2);
%         set(h,'linewidth',2,'color',[1 0 0])
%         th_fill = [dir_CI_DL_bimodal(i,2) angs_DL_bimodal(1,i) dir_CI_DL_bimodal(i,1) 0];
%         r_fill = [rad_DL rad_DL rad_DL 0]/2;
%         [x_fill,y_fill] = pol2cart(th_fill,r_fill);
%         patch(x_fill,y_fill,[1 0 0],'facealpha',0.3);
% 
%         % PM workspace tuning curve
%         h=polar(repmat(tuning_out_PM.bins,2,1),repmat(tuning_out_PM.binned_FR(:,i),2,1));
%         set(h,'linewidth',2,'color',[0.6 0.5 0.7])
%         th_fill = [flipud(tuning_out_PM.bins); tuning_out_PM.bins(end); tuning_out_PM.bins(end); tuning_out_PM.bins];
%         r_fill = [flipud(tuning_out_PM.binned_CI_high(:,i)); tuning_out_PM.binned_CI_high(end,i); tuning_out_PM.binned_CI_low(end,i); tuning_out_PM.binned_CI_low(:,i)];
%         [x_fill,y_fill] = pol2cart(th_fill,r_fill);
%         patch(x_fill,y_fill,[0.6 0.5 0.7],'facealpha',0.3,'edgealpha',0);
% 
%         % PM workspace PD
%         h=polar(angs_PM(:,i),rad_PM*[0;1]);
%         set(h,'linewidth',2,'color',[0.6 0.5 0.7])
%         th_fill = [dir_CI_PM(i,2) angs_PM(1,i) dir_CI_PM(i,1) 0];
%         r_fill = [rad_PM rad_PM rad_PM 0];
%         [x_fill,y_fill] = pol2cart(th_fill,r_fill);
%         patch(x_fill,y_fill,[0.6 0.5 0.7],'facealpha',0.3);
%         h=polar(angs_PM_bimodal(:,i),rad_PM*[0;1]/2);
%         set(h,'linewidth',2,'color',[0.6 0.5 0.7])
%         th_fill = [dir_CI_PM_bimodal(i,2) angs_PM_bimodal(1,i) dir_CI_PM_bimodal(i,1) 0];
%         r_fill = [rad_PM rad_PM rad_PM 0]/2;
%         [x_fill,y_fill] = pol2cart(th_fill,r_fill);
%         patch(x_fill,y_fill,[0.6 0.5 0.7],'facealpha',0.3);
%         hold off
%     end

    %% Statistics on PD changes
    % only look at best tuned units
    % find how many significantly change PD (non-overlapping CI)
    dir_CI_DL = unit_best_combined_table_DL.dir_CI;
    dir_CI_PM = unit_best_combined_table_PM.dir_CI;
    sig_change = ~( (dir_CI_DL(:,1)>dir_CI_PM(:,1) & dir_CI_DL(:,1)<dir_CI_PM(:,2)) | (dir_CI_DL(:,2)>dir_CI_PM(:,1) & dir_CI_DL(:,2)<dir_CI_PM(:,2)) );
    output_data.sig_change = sig_change;
    % separate stats
    if(options.dual_array)
        %assumes table is sorted by channel and then unit
        % Check if change over each array is significantly different
        % from zero
        array_break_idx = find(unit_best_combined_table_DL.channel>array_break,1,'first');
        [hyp1,p1] = ttest(angs_best_comb_PM(1,1:array_break_idx-1),angs_best_comb_DL(1,1:array_break_idx-1));
        [hyp2,p2] = ttest(angs_best_comb_PM(1,array_break_idx:end),angs_best_comb_DL(1,array_break_idx:end));
        mean1 = mean(angs_best_comb_DL(1,1:array_break_idx-1)-angs_best_comb_PM(1,1:array_break_idx-1));
        mean2 = mean(angs_best_comb_DL(1,array_break_idx:end)-angs_best_comb_PM(1,array_break_idx:end));
        output_data.array_change_signif = [hyp1;hyp2];
        output_data.array_change_pval = [p1;p2];
        output_data.array_change_mean = [mean1;mean2];

        % Test if changes over arrays are different from each other
        PD_diff1 = angs_best_comb_DL(1,1:array_break_idx-1)-angs_best_comb_PM(1,1:array_break_idx-1);
        PD_diff2 = angs_best_comb_DL(1,array_break_idx:end)-angs_best_comb_PM(1,array_break_idx:end);
        [hyp,p] = ttest2(PD_diff1,PD_diff2,'Vartype','unequal');
        output_data.between_array_signif = hyp;
        output_data.between_array_pval = p;
        output_data.between_array_mean = mean1-mean2;

        output_data.num_changed = [sum(sig_change(1:array_break_idx-1));sum(sig_change(array_break_idx:end))];
        output_data.num_units = [sum(unit_best_combined_table_DL.channel<=array_break); sum(unit_best_combined_table_DL.channel>array_break)];
    else
        % Check if change over array is significantly different from
        % zero
        [hyp,p] = ttest(angs_best_comb_PM(1,:),angs_best_comb_DL(1,:));
        output_data.array_change_signif = hyp;
        output_data.array_change_pval = p;
        output_data.array_change_mean = mean(angs_best_comb_DL(1,:)-angs_best_comb_PM(1,:));

        output_data.num_changed = sum(sig_change);
        output_data.num_units = length(sig_change);
    end