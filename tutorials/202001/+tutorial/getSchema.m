function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'tutorial', 'diamanti_tutorial');
end
obj = schemaObject;
end