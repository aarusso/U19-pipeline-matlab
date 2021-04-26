%{
# activity traces for each ROI
-> meso.SegmentationRoi
---
f_roi_raw              : blob@meso  # raw f for each cell, 1 x nFrames. For all 1 x nFrames attributes, in case of chunks in segmentation, frames with no data are filled with NaN
f_roi                  : blob@meso  # f for each cell after neuropil correction, 1 x nFrames. 
f0_roi_raw             : float      # baseline for each cell, calculated on f_roi_raw
f0_roi                 : float      # baseline for each cell, calculated on f_roi (neurpil corrected)
f_surround_raw         : blob@meso  # raw surround f for each cell, 1 x nFrames. 
dff_roi                : blob@meso  # delta f/f for each cell, 1 x nFrames, after baseline correction and neuropil correction (calculated from f_roi and f0_roi)
dff_roi_uncorrected    : blob@meso  # delta f/f, baseline corrected but no neuropil correction, 1 x nFrames (calculated from f_roi_raw and f0_roi_raw)
spiking                : blob@meso  # recovered firing rate of the trace using infered f
time_constants         : blob       # 2 floats per roi, estimated calcium kernel time constants
init_concentration     : float      # estimated initial calcium concentration for estimated kernel
noise                  : float      # 1 x ROI, noise values for significance estimation
%}


classdef Trace < dj.Imported
  methods(Access=protected)
    function makeTuples(self, key)
      self.insert(key)
    end
  end
end

% inserted by segmentation