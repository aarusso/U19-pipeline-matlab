%{
# Maintenance action on a module.
-> rig_maintenance.Module	                          # Module of the maintenance action.
maintenance_action		               : varchar(32)  #	Name of the maintenance action
---
maintenance_action_description		   : varchar(255)	
%}

classdef MaintenanceAction < dj.Lookup
    properties

    end
end
