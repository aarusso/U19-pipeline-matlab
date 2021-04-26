%{
# activity traces for each ROI
-> imaging.SegmentationRoi
---
dff_roi                : longblob  # delta f/f for each cell, 1 x nFrames. In case of chunks in segmentation, frames with no data are filled with NaN
dff_roi_is_significant : longblob  # same size as dff_roi, true where transitents are significant
dff_roi_is_baseline    : longblob  # same size as dff_roi, true where values correspond to baseline
dff_surround           : longblob  # delta f/f for the surrounding neuropil ring
spiking                : longblob  # recovered firing rate of the trace
time_constants         : blob              # 2 floats per roi, estimated calcium kernel time constants
init_concentration     : float             # estimated initial calcium concentration for estimated kernel
%}


classdef Trace < dj.Imported
  methods(Access=protected)
    function makeTuples(self, key)
      self.insert(key)
    end
  end
end

% inserted by segmentation