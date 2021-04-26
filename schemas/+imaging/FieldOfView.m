%{
# meta-info about specific FOV within mesoscope imagining session
-> imaging.Scan
fov                     :  tinyint        # number of the field of view in this scan
---
fov_directory           :  varchar(255)   # the absolute directory created for this fov
fov_name=null           :  varchar(32)    # name of the field of view
fov_depth               :  float          # depth of the field of view  should be a number or a vector?
fov_center_xy           :  blob           # X-Y coordinate for the center of the FOV in microns. One for each FOV in scan
fov_size_xy             :  blob           # X-Y size of the FOV in microns. One for each FOV in scan (sizeXY)
fov_rotation_degrees    :  float          # rotation of the FOV with respect to cardinal axes in degrees. One for each FOV in scan
fov_pixel_resolution_xy :  blob           # number of pixels for rows and columns of the FOV. One for each FOV in scan
fov_discrete_plane_mode :  tinyint        # true if FOV is only defined (acquired) at a single specifed depth in the volume. One for each FOV in scan should this be boolean?
%}

classdef FieldOfView < dj.Imported
  % ingestion handled by ScanInfo
  methods(Access=protected)
    function makeTuples(self, key)
      self.insert(key)
    end
  end
end