%{
# Experimental Session
-> tutorial.Mouse
session_date                : date                          # 
---
experiment_setup            : int                           # set up number
experimenter                : varchar(32)                   # experimenter
%}

classdef Session < dj.Manual
end
