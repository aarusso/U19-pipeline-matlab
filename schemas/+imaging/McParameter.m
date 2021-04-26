%{
# parameter definition for a motion correction method
-> imaging.McMethod
mc_parameter_name:  varchar(64)
---
mc_parameter_description: varchar(255) # description of this parameter
%}

classdef McParameter < dj.Lookup
    properties
        contents = {
            'LinearNormalized' , 'mc_max_shift' , '';
            'LinearNormalized' , 'mc_max_iter' , '';
            'LinearNormalized' , 'mc_extra_param' , '';
            'LinearNormalized' , 'mc_stop_below_shift' , '';
            'LinearNormalized' , 'mc_black_tolerance' , '';
            'LinearNormalized' , 'mc_median_rebin' , '';
            'NonLinearNormalized' , 'mc_max_shift' , '';
            'NonLinearNormalized' , 'mc_max_iter' , '';
            'NonLinearNormalized' , 'mc_stop_below_shift' , '';
            'NonLinearNormalized' , 'mc_black_tolerance' , '';
            'NonLinearNormalized' , 'mc_median_rebin' , '';
            }
    end
end