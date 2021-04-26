%{
-> action.Surgery
device_idx:                   int
---
-> lab.InsertionDevice
hemisphere:                   enum('L', 'R', 'Bilateral')
-> reference.BrainLocation
real_ap_coordinates:          decimal(5,2)             # anteroposterior coordinates in mm   
real_dv_coordinates:          decimal(5,2)             # dorsoventral coordinates in mm
real_ml_coordinates:          decimal(5,2)             # mediolateral coordinates in mm
theta:                        decimal(5, 2)            # (deg) - elevation - rotation about the ml-axis [0, 180] - w.r.t the z+ axis
phi:                          decimal(5, 2)            # (deg) - azimuth - rotation about the dv-axis [0, 360] - w.r.t the x+ axis
%}


classdef SurgeryLocation < dj.Manual
end