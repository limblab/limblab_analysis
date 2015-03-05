%script to set input data and execute data processing
%% process PDs using Raeed/Tucker functions
folderpath='C:\Users\limblab\Documents\Matlab test';
input_data.prefix='Chips_20150303_RW_tucker_004';
input_data.only_sorted=1
function_name='get_PDs';
input_data.labnum=6;
input_data.do_unit_pds=1;
input_data.do_electrode_pds=1;
data_struct = run_data_processing(function_name,folderpath,input_data);