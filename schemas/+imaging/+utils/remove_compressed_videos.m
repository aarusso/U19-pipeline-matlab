function remove_compressed_videos(fl, directory)
% if there are gz files, remove them if tif files where extracted on that directory
%
% Inputs
% fl        = list of tif files to check
% directory = path  where tif files are located
%

for iF = 1:numel(fl)
    file_base = fullfile(directory, fl{iF});
    gz_file = [file_base '.gz'];
    
    if exist(gz_file,'file') && exist(file_base,'file') 
        disp(['removing ' gz_file])
        delete(gz_file)
    else
        disp(['Could not find compressed pair ' file_base])
    end
end

end


