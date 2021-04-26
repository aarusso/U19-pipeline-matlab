%{
# Parameters related to stimulation control by software during session
software_parameter_set_id        : INT AUTO_INCREMENT
---
software_parameter_description='': varchar(256)     # string that describes parameter set
software_parameter_hash          : UUID             # uuid hash that encodes parameter dictionary
software_parameters              : longblob         # structure of all parameters
%}

classdef OptogeneticSoftwareParameter < dj.Lookup
    properties (Constant = true)
    s1 = struct();
    s2 = struct('param1', 1, 'param2', 2);
    s3 = struct('param1', 1, 'paramx', 2);
    contents = ...
    {1, 'Empty parameters', ...,
        struct2uuid(optogenetics.OptogeneticSoftwareParameter.s1), ...
        optogenetics.OptogeneticSoftwareParameter.s1;
     2, 'Parameters for context task', ...,
        struct2uuid(optogenetics.OptogeneticSoftwareParameter.s2), ...
        optogenetics.OptogeneticSoftwareParameter.s2
     3, 'Parameters for airpuff task', ...,
        struct2uuid(optogenetics.OptogeneticSoftwareParameter.s3), ...
        optogenetics.OptogeneticSoftwareParameter.s3   
    }
    end
    
    
     methods
        function try_insert(self, key)
            %Insert a new record on software parameters table (additional check for repeated params)
            % Inputs
            % key = structure with information of the record (software_parameter_description, software_parameters)
            
            %Check minimum field
            if ~isfield(key, 'software_parameters')
                    error('Structure to insert need a field named: software_parameters')
            end
            
            %Convert parameters to uuid
            uuidParams = struct2uuid(key.software_parameters);
            
            %Check if uuid already in database
            params_UUID = get_uuid_params_db(self, 'software_parameter_hash', uuidParams);
            if ~isempty(params_UUID)
                 error(['This set of parameters were already inserted:' newline, ...
                          'software_parameter_set_id = ' num2str(params_UUID.software_parameter_set_id), newline, ...
                          'software_parameter_description = ' params_UUID.software_parameter_description]);
            end
            
            %Finish key data
            key.software_parameter_hash        = uuidParams;
            if ~isfield(key, 'software_parameter_description')
                key.software_parameter_description = ['Soft Parames inserted on: ' datestr(now)];
            end
            
            insert(self, key);

        end
    end
    
end
