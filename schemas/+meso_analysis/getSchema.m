function obj = getSchema
prefix = getenv('DB_PREFIX');
persistent schemaObject
if isempty(schemaObject)
  schemaObject = dj.Schema(dj.conn, 'meso_analysis', [prefix 'meso_analysis']);
%   schemaObject = dj.Schema(dj.conn, 'external', 'external');
end
obj = schemaObject;
end

