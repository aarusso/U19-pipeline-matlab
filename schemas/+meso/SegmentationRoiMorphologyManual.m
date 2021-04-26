%{
# manula curation of morphological classification of the ROIs
-> meso.SegmentationRoi
---
morphology:  enum('Doughnut', 'Blob', 'Puncta', 'Filament', 'Other', 'Noise')
%}

classdef SegmentationRoiMorphologyManual < dj.Manual
  methods(Access=protected)
    function makeTuples(self, key)
      self.insert(key)
    end
  end
end

% inserted by the GUI of curation of morphology: viewSegmentation_dj()