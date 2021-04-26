%{
# available segmentation methods
seg_method:    varchar(16)
%}

classdef SegmentationMethod < dj.Lookup
    
    properties
        contents = {'cnmf'}
    end
end