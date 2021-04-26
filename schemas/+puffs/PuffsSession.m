%{
# 
-> acquisition.Session
---
session_params=null         : blob                          # The parameters for this session, e.g. phase_durations, whether puffs are on, etc...
-> puffs.Rig
notes                       : varchar(1024)                 # notes recorded by experimenter during the session
stdout=null                 : blob                          # stdout for the GUI during the session
stderr=null                 : blob                          # stderr for the GUI during the session
sync=null                   : blob                          # At the start of the session, the software runs multiple python processes. This column contains the times of these processes in seconds
%}


classdef PuffsSession < dj.Manual
end