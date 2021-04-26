
function plot_segmentation_ROIs(key, local_files)
% Function to plot segmentation ROIs boundaries for a given session key

if nargin < 2
    local_files = true;
end

ROI_TYPES = RegionMorphology.all();
ROI_TYPES_PLOT = ROI_TYPES(1:end-1);
colors = [[1 0.7 0];[0 1 0];[1 0 1];[1 1 0];[0 1 1];[0 0 1]];

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

%Load roi information
roi_info          = fetch(imaging.SegmentationRoi & key, '*');
roi_morph_info    = fetch(imaging.SegmentationRoiMorphologyAuto & key, '*');



figure;
set(gcf, 'color','w')

for iType = 1:length(ROI_TYPES_PLOT)
    
    subaxis(2,3,iType,'Spacing',0.02,'Margin',0.02,'Padding',0);
    
    %Preprocess background image
    if iType == 1
        max_image = max(movie,[],3);
        min_max_image = min(max_image(:));
        max_max_image = max(max_image(:));
        
        max_image    =  (max_image-min_max_image) / (max_max_image-min_max_image);
        image_bright = imlocalbrighten(max_image,'AlphaBlend',true);
    end
    
    
    imagesc(image_bright)
    ax = gca;
    ax.Visible = 'off';
    hold on
    colormap gray
    
    %Get matching morpholgy rois
    idx_type = matches({roi_morph_info.morphology},ROI_TYPES_PLOT{iType});
    spatial = {roi_info.roi_spatial};
    spatial = spatial(idx_type);
    
    
    %Plot boundaries of all ROIs
    for iROI = 1:size(spatial,2)
        
        borders = bwboundaries(spatial{iROI});
        
        for i=1:length(borders)
            boundary = borders{i};
            plot(boundary(:,2), boundary(:,1), 'Color', colors(iType,:), 'LineWidth', 1)
        end
        
        
    end
    
end


%Add legend
subaxis(2,3,6,'Spacing',0.02,'Margin',0.02,'Padding',0);

for i=1:length(ROI_TYPES_PLOT)
    
    line(0,0,'Color',colors(i,:), 'LineWidth', 2)
    ax = gca;
    ax.Visible = 'off';
    
    
end
legend(ROI_TYPES_PLOT,'FontSize',16);



