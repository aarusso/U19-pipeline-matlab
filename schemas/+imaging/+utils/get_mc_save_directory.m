function [mc_directory] = get_mc_save_directory(fov_directory,key,separator)
%get_mc_save_directory
%  Get save directory for motion correction process

% Inputs
%  fov_directory         = directory where tif files are stored
%  key                   = key when motion correction processes is run. It has imaging.McParameterSet info

% Outputs
%   mc_directory         = directory where motion correction results should be stored

%Create a string that defines the current mc_parameter_set
mc_dir_string = [key.mc_method '_set_' num2str(key.mc_parameter_set_id)];

%Create directory
mc_directory = spec_fullfile(separator,fov_directory, mc_dir_string);


