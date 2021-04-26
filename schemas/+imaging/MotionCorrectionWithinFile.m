%{
# within each tif file, x-y shifts for motion registration
-> imaging.FieldOfViewFile
-> imaging.McParameterSet
---
within_file_x_shifts         : longblob      # nFrames x 2, meta file, frameMCorr-xShifts
within_file_y_shifts         : longblob      # nFrames x 2, meta file, frameMCorr-yShifts
within_reference_image       : longblob      # 512 x 512, meta file, frameMCorr-reference
%}


classdef MotionCorrectionWithinFile < dj.Part
    properties(SetAccess=protected)
        master   = imaging.MotionCorrection
    end
    % ingested by imaging.MotionCorrection
end