%{
# General information of an ephys session
-> acquisition.Session
---
ephys_filepath              : varchar(255)                  # Path were session file will be stored in bucket
%}

classdef EphysSession < dj.Manual


end
