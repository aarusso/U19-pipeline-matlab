%{
# Specific actions performed for maintenance on each rig
-> rig_maintenance.TrainingRig
-> rig_maintenance.MaintenaceAction
maintenance_time              : DATETIME
---
(maintenance_person) ->lab.User	                  
maintenance_params			  : longtext	    # Json with parameters specific for maintenance action
%}

classdef RigMaintenanceLog < dj.Manual
end
