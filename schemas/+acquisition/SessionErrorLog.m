%{
# Information generated when a session fails
error_log_id                : int AUTO_INCREMENT            # error identifier
---
-> acquisition.SessionStarted
error_time                  : time                          # time when error occured
session_phase               : enum('Runtime', 'Population') # at which phase of the experiment error ocurred
error_message               : varchar(4096)                 # message of error in matlab  
error_exception             : BLOB                          # mexception structure with error information
%}

classdef SessionErrorLog < dj.Manual
    
    methods(Access=protected)
      
    end
end

