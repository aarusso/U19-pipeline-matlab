%{
# automatic morphological classification of the ROIs
-> imaging.SegmentationRoi
---
morphology:  enum('Doughnut', 'Blob', 'Puncta', 'Filament', 'Other', 'Noise') # shape classification
%}

classdef SegmentationRoiMorphologyAuto < dj.Part
  properties(SetAccess=protected)
    master = imaging.Segmentation
  end
end

% inserted by Segmentation 