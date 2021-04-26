%{
surgery_type:   varchar(64)
---
surgery_description: varchar(255)
%}


classdef SurgeryType < dj.Lookup
    properties
        contents = {'Craniotomy',                     '';
                    'Hippocampal window',             '';
                    'GRIN lens implant',              '';
                    'Optogenetics',                   '';
                    'Electrophysiology',              '';
                    'Optogenetics+Electrophysiology', '';
                    }
    end
end