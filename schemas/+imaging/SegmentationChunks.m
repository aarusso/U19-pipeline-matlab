%{
# registration between different segmentation chunks within a recording
-> imaging.Segmentation
segmentation_chunk_id  : tinyint    # id for the subsection of the recording this segmentation is for, for cases with multi-chunk segemntation (e.g. because of z drift)
---
tif_file_list          : blob   # cell array with names of tif files that went into this chunk
imaging_frame_range    : blob   # [firstFrame lastFrame] of this chunk with respect to the full session
region_image_size      : blob   # x-y size of the cropped image after accounting for motion correction shifts
region_image_x_range   : blob   # x range of the cropped image after accounting for motion correction shifts
region_image_y_range   : blob   # y range of the cropped image after accounting for motion correction shifts
%}

classdef SegmentationChunks < dj.Part
  properties(SetAccess=protected)
    master = imaging.Segmentation
  end
end

% inserted by segmentation