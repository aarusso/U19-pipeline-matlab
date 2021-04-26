function [seg_directory] = get_seg_save_directory(mc_directory,key,separator)
%get_seg_save_directory
%  Get save directory for segmentation process

% Inputs
%  mc_directory          = directory where motion correction results are stored
%  key                   = key when segmentation processes is run. It has imaging.SegParameterSet info

% Outputs
%   seg_directory        = directory where segmentation results should be stored

%Create a string that defines the current mc_parameter_set
seg_dir_string = [key.seg_method '_set_' num2str(key.seg_parameter_set_id)];

%Create directory
seg_directory = spec_fullfile(separator,mc_directory, seg_dir_string);


