% load_paths.m
%
% Loads all of the necessary paths to run s1_analysis.  Should only be
% used once per session.

% $Id: $

dir = pwd;

addpath(dir);
addpath([dir '\\lib']);
addpath([dir '\\lib\\ml']);
addpath([dir '\\lib\\stats']);
addpath([dir '\\mimo']);
addpath([dir '\\spike']);
addpath([dir '\\bdf']);
addpath([dir '\\bdf\\event_decoders']);
addpath([dir '\\bdf\\lib_cb']);
addpath([dir '\\bdf\\lib_plx']);
addpath([dir '\\BMI_analysis']);
clear dir;