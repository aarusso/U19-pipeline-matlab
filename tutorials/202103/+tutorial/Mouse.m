%{
# Experimental mouse
mouse_id                    : int                           # mouse id
---
dob=null                    : date                          # date of birth
sex="unknown"               : enum('M','F','unknown')       # sex of the anmial
%}

classdef Mouse < dj.Manual
end
