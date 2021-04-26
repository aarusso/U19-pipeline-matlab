%{
# pointer for a pre-saved set of parameter values
-> imaging.McMethod
mc_parameter_set_id:              int              # parameter set id
---
mc_parameter_set_description='':  varchar(256)     # string that describes parameter set
mc_parameter_set_hash:            UUID             # uuid hash that encodes parameter dictionary
%}

classdef McParameterSet < dj.Manual
    methods
        function insert(self, key)
                        
            %Get & convert parameters to uuid
            keySetParameter = key;
            structParam = get_mcSetParameter(imaging.McParameterSetParameter, key);
            uuidParams = struct2uuid(structParam);
            
            %Check if uuid already in database
            recordUUID = get_uuid_params_db(self, 'mc_parameter_set_hash', uuidParams);
            if ~isempty(recordUUID)
                 error(['This set of parameters were already inserted:' newline, ...
                          'mc_parameter_set_id = ' num2str(recordUUID.mc_parameter_set_id), newline, ...
                          'mc_parameter_set_description = ' recordUUID.mc_parameter_set_description]);
            end
            
            key.mc_parameter_set_hash        = uuidParams;
            if isfield(key, 'description')
                key.mc_parameter_set_description = key.description;
            else
                key.mc_parameter_set_description = '';
            end
            insert@dj.Manual(self, key);

            %Insert into McParameterSetParameter table: each record - fields & value 
            fields = fieldnames(structParam);
            keySetParameter = repmat(keySetParameter, length(fields), 1);
            for i=1:length(fields)
                keySetParameter(i).mc_parameter_name = fields{i};
                keySetParameter(i).mc_parameter_value = structParam.(fields{i});
            end
            insert(imaging.McParameterSetParameter, keySetParameter);
            
        end
    end
end
