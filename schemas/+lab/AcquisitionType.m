%{
# The type of acquisition that was performed on a session given a certain location
acquisition_type:              varchar(64)
-----
acquisition_description='':    varchar(255)
%}

classdef AcquisitionType < dj.Lookup
    properties
    end
end