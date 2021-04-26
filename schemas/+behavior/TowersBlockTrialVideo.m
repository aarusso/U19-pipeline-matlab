%{
-> behavior.TowersBlockTrial
---
video_path:                 varchar(255)         # video directory + filename for each trial
%}

classdef TowersBlockTrialVideo < dj.Imported
   % properties(SetAccess=protected)
   %     master = behavior.TowersBlock
   % end
   methods(Access=protected)
        function makeTuples(self, key)
        end
   end
end