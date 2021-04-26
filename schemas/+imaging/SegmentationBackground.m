%{
# for each chunck, global background info (from cnmf)
-> imaging.SegmentationChunks
---
background_spatial  :   longblob   # 2D matrix flagging pixels that belong to global background in cnmf  
background_temporal :   longblob   # time course of global background in cnmf
%}

classdef SegmentationBackground < dj.Part
  properties(SetAccess=protected)
    master = imaging.Segmentation
  end
end

% inserted by segmentation