%{
# pointer for a pre-saved set of parameter values
-> imaging.SegmentationMethod
seg_parameter_set_id:   int    # parameter set id
---
seg_parameter_set_description='':  varchar(256)     # string that describes parameter set
seg_parameter_set_hash:            UUID             # uuid hash that encodes parameter dictionary
%}

classdef SegParameterSet < dj.Manual
    methods
        function insert(self, key)
                        
            %Get & convert parameters to uuid
            keySetParameter = key;
            structParam = get_segSetParameter(imaging.SegParameterSetParameter, key);
            uuidParams = struct2uuid(structParam);
            
            %Check if uuid already in database
            recordUUID = get_uuid_params_db(self, 'seg_parameter_set_hash', uuidParams);
            if ~isempty(recordUUID)
                 error(['This set of parameters were already inserted:' newline, ...
                          'seg_parameter_set_id = ' num2str(recordUUID.seg_parameter_set_id), newline, ...
                          'seg_parameter_set_description = ' recordUUID.seg_parameter_set_description]);
            end
            
            key.seg_parameter_set_hash        = uuidParams;
            if isfield(key, 'description')
                key.seg_parameter_set_description = key.description;
            else
                key.seg_parameter_set_description = '';
            end
            insert@dj.Manual(self, key);

            %Insert into McParameterSetParameter table: each record - fields & value 
            fields = fieldnames(structParam);
            keySetParameter = repmat(keySetParameter, length(fields), 1);
            for i=1:length(fields)
                keySetParameter(i).seg_parameter_name = fields{i};
                keySetParameter(i).seg_parameter_value = structParam.(fields{i});
            end
            insert(imaging.SegParameterSetParameter, keySetParameter);
            
        end
    end
end
            
            
            
   