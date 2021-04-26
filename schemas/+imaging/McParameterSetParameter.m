%{
# pre-saved parameter values
-> imaging.McParameterSet
-> imaging.McParameter
---
mc_parameter_value         : blob     # value of parameter
%}

classdef McParameterSetParameter < dj.Part
    properties(SetAccess=protected)
        master   = imaging.McParameterSet
    end
    methods
        function structParam = get_mcSetParameter(self, key)
            
            query = imaging.McParameter & key;
            parameters = query.fetchn('mc_parameter_name');
            
            tableParam  =cell2table({
                'LinearNormalized' , 'mc_max_shift' , 15;
                'LinearNormalized' , 'mc_max_iter' , 5;
                'LinearNormalized' , 'mc_extra_param' , false;
                'LinearNormalized' , 'mc_stop_below_shift' , 0.3;
                'LinearNormalized' , 'mc_black_tolerance' , -1;
                'LinearNormalized' , 'mc_median_rebin' , 10;
                
                'NonLinearNormalized' , 'mc_max_shift' , [15 15];
                'NonLinearNormalized' , 'mc_max_iter' , [5 2];
                'NonLinearNormalized' , 'mc_stop_below_shift' , 0.3;
                'NonLinearNormalized' , 'mc_black_tolerance' , -1;
                'NonLinearNormalized' , 'mc_median_rebin' , 10;
                
                }, 'VariableNames',{'mc_method' 'mc_parameter_name' 'mc_parameter_value'});
            
            tableParam.mc_method = categorical(tableParam.mc_method);
            tableParam.mc_parameter_name = categorical(tableParam.mc_parameter_name);
            
            %Filter current key parameters
            tableParam = tableParam(tableParam.mc_method == key.mc_method, :);
            
            %Transform parameters into struct
            structParam = cell2struct(tableParam.mc_parameter_value, cellstr(tableParam.mc_parameter_name));
            
            %Check if all parameter declared for this method are present in param definition
            for i=1:length(parameters)
                key.mc_parameter_name = parameters{i};
                value_cell = tableParam{tableParam.mc_parameter_name == key.mc_parameter_name, 'mc_parameter_value'};
                
                if size(value_cell,1) > 1
                    warning('More than one value for this key found: %s %d %s',key.mc_method, key.mc_parameter_set_id, key.mc_parameter_name)
                elseif size(value_cell,1) == 0
                    warning('No value for this key found: : %s %d %s',key.mc_method, key.mc_parameter_set_id, key.mc_parameter_name)
                end
                
            end
            
        end
    end
    
    
end
