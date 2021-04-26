%{
task:                   varchar(32)
---
task_description='':    varchar(512)
table_population='':    varchar(512)         # list of main tables the task will be populated
%}

classdef Task < dj.Lookup
    properties
        contents = {
            'AirPuffs',               '', 'PuffsSession'
            'Towers',                 '', 'TowersSession'
            'Towers_LickResponse',    '', 'TowersSession, TowersBlockTrialLicks'
            'Clicks',                 '', ''
            'LinearTrack',            '', ''
            }
    end
end
