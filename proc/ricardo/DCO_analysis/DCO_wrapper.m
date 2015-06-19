% params.DCO_file_prefix = 'Ricardo_2014-09-11_DCO_iso_ruiz';
params.DCO_file_prefix = 'Chewie_2015-06-15_DCO_emg_emg_cartesian';
% target_folder = ['D:\Data\TestData\' params.DCO_file_prefix];
target_folder = ['D:\Chewie_8I2\' params.DCO_file_prefix '\CerebusData\'];
% target_folder = ['D:\Data\Kevin_12A2\Data\' params.DCO_file_prefix];
params.reprocess_data = 0;
params.plot_behavior = 0;
params.plot_units = 0;
params.plot_emg = 0;
params.plot_raw_emg = 0;
params.decode_arm = 0;
params.make_movie = 0;
params.movie_range = [10 250];
params.num_lags = 10;
params.rot_handle = 1; 
params.fig_handles = [];
params.cmp_file = '\\citadel\limblab\lab_folder\Animal-Miscellany\Chewie 8I2\Blackrock implant surgery 6-14-10\1025-0394.cmp';
% params.cmp_file = '\\citadel\limblab\lab_folder\Animal-Miscellany\Mini 7H1\Blackrock array info\1025-0592.cmp';
% params.arm_model_location = ['E:\ricardo\Miller Lab\Matlab\s1_analysis\proc\'...
%     'ricardo\MuscleController\InverseArmNN\left_arm_nn.mat'];
params.left_handed = 1;

data_struct = run_data_processing('DCO_analysis',target_folder,params);
params = data_struct.params;