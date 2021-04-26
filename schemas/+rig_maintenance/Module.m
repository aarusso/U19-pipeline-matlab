%{
# Modules (parts of a rig)
module_name               :	varchar(32)	  # Name of the module. Sum of hardware parts of a rig that form a whole functionality
---
module_description		  : varchar(255)
%}

classdef Module < dj.Lookup
    properties

    end
end
