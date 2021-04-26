%{
# locations that are also training rigs
(training_rig) -> lab.Location
---
rig_type			             : enum('VR', 'MiniVR', 'NonVR')
%}

classdef TrainingRig < dj.Lookup
    properties

    end
end
