% params.RP_file_prefix = 'Test_2014-11-21_RP_iso_hu';
% target_folder = ['D:\Data\TestData\' params.RP_file_prefix];
params.RP_file_prefix = 'Chewie_2015-05-19_RP_n2e2_hu';
target_folder = ['D:\Chewie_8I2\' params.RP_file_prefix '\CerebusData\'];
params.reprocess_data = 0;
params.plot_behavior = 0;
params.plot_units = 0;
params.plot_each_neuron = 0;
params.plot_emg = 0;
params.plot_predicted_emg = 0;
params.plot_raw_emg = 0;
params.plot_pca = 0;

params.make_movie = 0;
params.movie_range = [10 250];
params.rot_handle = 1; 
params.fig_handles = [];
params.cmp_file = '\\citadel\limblab\lab_folder\Animal-Miscellany\Kevin 12A2\Microdrive info\MicrodriveMapFile_diagonal.cmp';
params.left_handed = 1;
params.offline_decoder = 'D:\Data\Chewie_8I2\Chewie_2014-09-05_DCO_iso_ruiz\Output_Data\bdf-cartesian_Binned_Decoder';

data_struct = run_data_processing('RP_analysis',target_folder,params);
params = data_struct.params;