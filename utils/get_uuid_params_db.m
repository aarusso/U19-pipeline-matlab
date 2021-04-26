function q_param = get_uuid_params_db(table, uuid_fieldname, uuid)
%Check if an uuid for a dictionary param structure is already present in table

% table                 = db table where to find the uuid 
% uuid_fieldname        = name of the field where hash uuid are stored
% uuid                  = uuid value from a dictionary param structure 

uuid_key = struct();
uuid_key.(uuid_fieldname) = uuid;
q_param = fetch(table & uuid_key, '*');

end