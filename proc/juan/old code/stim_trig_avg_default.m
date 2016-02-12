%
% Parameters to do stimulus triggered averaging of the EMG
%
%       function sta_params = stim_trig_avg_default()
%
%       stim_trig_avg_params    : structure with fields
%           stim_elecs          : 1-by-2 vector with stimulation electrode numbers
%           stimulator_resolut  : step size (mA)
%           sync_out_elec       : sync out electrode number (to sync with cerebus)
%           stim_ampl           : stimulation amplitude (mA)
%           stim_pw             : stimulation pulse width (ms)
%           stim_freq           : stimulation frequency (Hz)
%           train_duration      : trains duration (ms)
%           ITI                 : interval between bursts (ms)
%           nbr_stims_ch        : nbr stimuli delivered at each channel
%           pre_stim_win        : delay for the stimulation command (ms), 
%           t_before            : time before the stim that is plotted and used for computations (ms)
%           t_after             : time after the stim that is plotted and used for computations (ms)
%           record_force_yn     : 
%           save_data_yn        : save Matlab and Cerebus data
%           plot_yn             : plot the results
%           data_dir            : directory where the data will be saved
%           monkey              : monkey name, to generate the filename
%           task                : task name, to generate the filename
%
%   Note: to stimulate with single pulses, train_duration has to be
%   1000/stim_freq, and equal to ITI


function sta_params = stim_trig_avg_default()


sta_params              = struct( ...
    'stim_elecs',               9, ...
    'stimulator_resolut',       0.018, ...
    'sync_out_elec',            32, ...
    'stim_ampl',                0.54, ...%0.054, ...
    'stim_pw',                  0.2, ...
    'stim_freq',                13, ...            % 15, ...
    'train_duration',           76.9231, ...        % 66.6667, ...
    'ITI',                      76.9231, ...        % 66.6667, ...
    'nbr_stims_ch',             1000, ...
    'pre_stim_win',             30, ...
    't_before',                 20, ...             % 20
    't_after',                  30, ...             % 30
    'record_force_yn',          1, ...
    'save_data_yn',             0, ...
    'plot_yn',                  1, ...
    'data_dir',                 'E:\Data-lab1\12A1-Jango\CerebusData\TDCS', ...
    'monkey',                   'Jango', ...
    'bank',                     'A', ...
    'task',                     'WF');
