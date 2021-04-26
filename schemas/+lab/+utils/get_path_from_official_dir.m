function [bucket_path, local_path] =  get_path_from_official_dir(baseDir)
%Get entire bucket path location and accesible "local" path from a
%reference to buckets in u19
%
% Inputs:
% baseDir = Reference to a bucket location 
% 
% Outputs
% bucket_path = path in the bucket (as seen in spock and scotty)
% local_path  = reference path when function is run from local computer
%
% Examples
% basedir = 'Bezos/RigData/scope/bay3'
% get_path_from_official_dir(baseDir)  %  (from local mac)
% bucket_path == '/mnt/bucket/PNI-centers/Bezos/RigData/scope/bay3'
% local_path ==  '/Volumes/Bezos-center/RigData/scope/bay3''

%Get OS of the system
system = get_OS();

%Get all path table frokm u19_lab.Path ("official sites")
[path_table] = lab.utils.get_path_table();

%Check the base dir corresponds to which global path 
idx_basedir = cellfun(@(s) contains(baseDir, s), path_table.global_path);

path_record = path_table(idx_basedir & path_table.system == system,:);

if isempty(path_record)
    warning('The base directory is not found in official sites of u19')
    bucket_path = '';
    local_path = '';
    return 
elseif size(path_record,1) > 1
    % Get the first occurrence of path (e.g /braininit/user/bezostest.mat is braininit not Bezos)
    [~, idx_min] = min(cellfun(@(s) strfind(baseDir, s), path_record.global_path));
    path_record = path_record(idx_min, :);
    %warning('The base directory makes reference to more than one official location of the u19')
end

%Find where in baseDir is located the globalPath
ac_global_path = path_record.global_path{:};

%Erase that part of the path (will be replaced with corresponding path of the actual system)
if startsWith(baseDir, path_record.local_path{:})
    baseDir(1:length(path_record.local_path{:})) = [];
elseif startsWith(baseDir, path_record.net_location{:})
    baseDir(1:length(path_record.net_location{:})) = [];
else
    idx_global_path = strfind(baseDir, ac_global_path);

    baseDir(1:idx_global_path+length(ac_global_path)-1) = [];
end

bucket_path = fullfile(path_record.bucket_path{:}, baseDir);

if ispc
    %For pc the accesible path is the net_location field
    local_path  = fullfile(path_record.net_location{:}, baseDir);
    %Correct bucket path to have "linux" slashes
    bucket_path = strrep(bucket_path,'\','/');
    bucket_path = strrep(bucket_path,'//','/');
else
    %For mac and linux the accesible path is the local_path field
    local_path = fullfile(path_record.local_path{:}, baseDir);
end

%If this system is spock, local and bucket path is the same
if u19_dj_utils.is_this_spock()
    local_path = bucket_path;
end
      
end