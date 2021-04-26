%{
# 
-> puffs.PuffsSessionTrial
phase                       : tinyint                       # phase index, 0=intro, 1=stimulus period, ... see Puffs Task Documentation
---
phase_rel_start             : float                         # start time of the phase relative to the beginning of the session [seconds]
phase_rel_finish            : float                         # end time of the phase relative to the beginning of the session [seconds]
%}


classdef PuffsSessionTrialPhase < dj.Manual
end