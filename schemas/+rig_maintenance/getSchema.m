function obj = getSchema
prefix = getenv('DB_PREFIX');
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'rig_maintenance', [prefix 'rig_maintenance']);
end
obj = schemaObject;
end
