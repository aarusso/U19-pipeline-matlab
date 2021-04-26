function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'puffs', 'u19_puffs');
end
obj = schemaObject;
end
