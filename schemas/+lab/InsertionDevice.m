%{
insertion_device_name         : varchar(128)               # device identifier
---
device_description            : varchar(255)              
%}

classdef InsertionDevice < dj.Lookup
        properties
        contents = {
            'generic_electrode'            , 'electrode for ephys sessions';
            'generic_optogenetics_cannula',  'cannula for optogenetics sessions';
            }
    end
end


