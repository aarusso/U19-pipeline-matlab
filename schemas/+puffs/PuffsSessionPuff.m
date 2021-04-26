%{
# 
-> puffs.PuffsSessionTrial
puff_idx                    : tinyint                       # the index of the puff in this particular trial
---
side                        : tinyint                       # 0 = left side, 1 = right side
puff_rel_time               : float                         # time of the puff relative to the beginning of the trial [seconds]
%}


classdef PuffsSessionPuff < dj.Manual
end