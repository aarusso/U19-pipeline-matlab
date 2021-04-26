function remote_location = get_corresponding_remote_location(local_path_token, local_path, default_rig_path_location)
%GET_CORRESPONDING_REMOTE_LOCATION 
% get remote location corresponding directory from a local path
% Inputs
% local_path                 = Local path to be transformed (e.g. path where session is stored)
% local_path_token           = Default location for all sessions in local machine
% default_rig_path_location  = Default path in bucket for the rig
% Outputs
% remote_location            = Path in bucket where session will be copied
%
% local_path_token          = 'C:\Data\'
% local_path                = 'C:\Data\lucas\blocksReboot\data\gps1\PoissonBlocksReboot_cohort1_TrainVR1_gps1_T_20201021.mat'
% default_rig_path_location = ...
%'/braininit/RigData/training/rig1/'

% remote_location           = ...
% '/braininit/RigData/training/rig1/lucas/blocksReboot/data/gps1/PoissonBlocksReboot_cohort1_TrainVR1_gps1_T_20201021.mat'



% if default rig location is not empty 
if ~isempty(default_rig_path_location)
    
    %Get fileparts from local path
    [extPath, filename, ext] = ...
        fileparts(strrep(local_path,local_path_token,''));
    
    % Format the new location
    remote_location = fullfile(default_rig_path_location,extPath, [filename, ext]);
    remote_location = strrep(remote_location,'\','/');
    remote_location = strrep(remote_location,'//','/');
else
    remote_location = '';
end


end

