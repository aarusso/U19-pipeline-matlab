%{
->reference.BrainArea
location_idx:              int              # Index (for same brainArea but different coordinates)   
---
ap_coordinates:            decimal(5,2)     # anteroposterior coordinates in mm
dv_coordinates:            decimal(5,2)     # dorsoventral coordinates in mm
ml_coordinates:            decimal(5,2)     # mediolateral coordinates in mm
location_description= '':  varchar(255)
%}


classdef BrainLocation < dj.Lookup
    properties
        
    end
end