function [datapath filelist] = two_alternative_experiment_list

datapath = 'D:\Data\TestData\';

filelist(1).name = 'ricardo_2afc_test_001';
filelist(1).system = 'cerebus';
filelist(1).pd = [3.142 3.142 3.142 3.142];
filelist(1).codes = [0 0 0 0];
filelist(1).electrodes = [57 59 61 63];
filelist(1).pulsewidth = [200 200 200 200];
filelist(1).current = [80 40 80 40];
filelist(1).period = [3.3 3.3 3.3 3.3];
filelist(1).pulses = [150 150 150 150];
filelist(1).stim_delay = [1 1.5 2 2.5];
filelist(1).bump_duration = .125;
filelist(1).date = '2011-01-26';
filelist(1).serverdatapath = 'Z:\Miller\TestData\CerebusTests';

filelist(2).name = 'Ricardo_2AFC_001';
filelist(2).system = 'cerebus';
filelist(2).pd = [0];
filelist(2).codes = [nan];
filelist(2).electrodes = [nan];
filelist(2).pulsewidth = [nan];
filelist(2).current = [80 40 80 40 nan];
filelist(2).period = [nan];
filelist(2).pulses = [nan];
filelist(2).stim_delay = [nan];
filelist(2).bump_duration = .2;
filelist(2).date = '2011-01-31';
filelist(2).serverdatapath = 'Z:\Miller\TestData\Ricardo';

filelist(3).name = 'Ricardo_2AFC_002';
filelist(3).system = 'cerebus';
filelist(3).pd = [0];
filelist(3).codes = [nan];
filelist(3).electrodes = [nan];
filelist(3).pulsewidth = [nan];
filelist(3).current = [80 40 80 40 nan];
filelist(3).period = [nan];
filelist(3).pulses = [nan];
filelist(3).stim_delay = [nan];
filelist(3).bump_duration = .2;
filelist(3).date = '2011-01-31';
filelist(3).serverdatapath = 'Z:\Miller\TestData\Ricardo';

filelist(4).name = 'Ricardo_2AFC_003';
filelist(4).system = 'cerebus';
filelist(4).pd = [0];
filelist(4).codes = [nan];
filelist(4).electrodes = [nan];
filelist(4).pulsewidth = [nan];
filelist(4).current = [80 40 80 40 nan];
filelist(4).period = [nan];
filelist(4).pulses = [nan];
filelist(4).stim_delay = [nan];
filelist(4).bump_duration = .2;
filelist(4).date = '2011-01-31';
filelist(4).serverdatapath = 'Z:\Miller\TestData\Ricardo';