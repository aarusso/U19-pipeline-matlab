
%{
# available motion correction method
mc_method:           varchar(128)
---
correlation_type='Normalized' : enum('Normalized', 'NonNormalized')
tranformation_type='Linear'   : enum('Linear', 'NonLinear')
%}

    
 classdef McMethod < dj.Lookup
     properties
        contents = {'LinearNormalized', 'Normalized', 'Linear';
                    'NonLinearNormalized', 'Normalized', 'NonLinear'};
     end
 end