%{
# list of files per FOV
-> imaging.FieldOfView
file_number         : int
---
fov_filename        : varchar(255)     # file name of the new fov tiff file
file_frame_range    : blob             # [first last] frame indices in this file, with respect to the whole imaging session
%}

classdef FieldOfViewFile < dj.Part
  properties(SetAccess=protected)
    master = imaging.FieldOfView
  end
  methods(Access=protected)
    function makeTuples(self, key)
      self.insert(key)
    end
  end
  % ingestion handled by imaging.FieldOfView
end