function obj = getSchema
prefix = getenv('DB_PREFIX');
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'optogenetics', [prefix 'optogenetics']);
end
obj = schemaObject;
end
