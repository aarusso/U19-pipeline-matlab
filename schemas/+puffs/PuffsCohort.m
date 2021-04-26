%{
# 
-> lab.User
project_name                : varchar(64)                   # Corresponds to the path on bucket /puffs/netid/project_name/cohortX/ ...
cohort                      : varchar(64)                   # Corresponds to the path on bucket /puffs/netid/project_name/cohortX/ ...
%}


classdef PuffsCohort < dj.Manual
end