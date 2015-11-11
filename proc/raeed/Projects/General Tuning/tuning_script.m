%% Get isometric tuning
folder='Y:\Han_13B1\Processed\experiment_20150127_iso';
clear options
options.prefix='Han_20150128';
options.only_sorted=1;
function_name='get_tuning_curves_v2';
options.labnum=6;
options.dual_array = 1;
options.array_break = 64;
options.move_corr = 'force';
options.plot_curves = true;
% options.bdf = bdf;

output_data=run_data_processing(function_name,folder,options);

%% Get RW tuning
folder='Y:\Han_13B1\Processed\experiment_20141204_RW';
clear options
options.prefix='Han_20141204';
options.only_sorted=1;
function_name='get_tuning_curves_v2';
options.labnum=6;
options.dual_array = 1;
options.array_break = 64;
options.move_corr = 'vel';
options.plot_curves = true;
% options.bdf = bdf;

output_data=run_data_processing(function_name,folder,options);