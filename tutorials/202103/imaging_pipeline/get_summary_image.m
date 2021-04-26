
function summary_image = get_summary_image(key, local_files)
% Function to plot segmentation ROIs boundaries for a given session key

if nargin < 2
    local_files = true;
end

%Get segmentation information
segmenation_path  = fetch(imaging.Segmentation & key, 'seg_results_directory');

if length(segmenation_path) > 1
    error('More than one session selected on key');
elseif isempty(segmenation_path)
    error('No segmentaiton was run with selected key');
end

segmenation_path = lab.utils.format_bucket_path(segmenation_path.seg_results_directory);

%Get summary file from local source
if local_files
    results_path = fullfile(fileparts(mfilename('fullpath')), 'imaging_data');
    
    summaryFile      = dir(fullfile(results_path, '*.summary.mat'));
    
    if isempty(summaryFile)
        error('No summary file present on segmentation');
    end
    
    summaryFile      = fullfile(results_path, summaryFile.name);
else
    
    %Get summary file from db & bucket source
    %Check if fov_directory and mc directory exists in system
    lab.utils.assert_mounted_location(segmenation_path)
    
    summaryFile      = dir(fullfile(segmenation_path, '*.summary.mat'));
    
    if isempty(summaryFile)
        error('No summary file present on segmentation');
    end
    
    summaryFile = fullfile(segmenation_path, summaryFile.name);
end


load(summaryFile, 'binnedF');
movie = binnedF;
clear binnedF

max_image = max(movie,[],3);
min_max_image = min(max_image(:));
max_max_image = max(max_image(:));
        
max_image     =  (max_image-min_max_image) / (max_max_image-min_max_image);
summary_image = imlocalbrighten(max_image,'AlphaBlend',true);
