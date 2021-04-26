function [keys,description_field] = get_table_with_description(table)
% Get table key field and description field as a cell array
% For tables like ManipulationType, OptogeneticStimParameters, to show info on TrainingGUI
% This function only works for single primary keys and a unique description field.
% Inputs
% table               =  datajoint table object
% Outputs  
% keys                = primary keys of table as cell array
% description_field   = description field(s) as a cell array

%Get idx of description fields
table_fields = {table.tableHeader.attributes.name};
idx_param_description = contains(table_fields,'description');
description_field = table_fields(idx_param_description);

%Get primaryKey field
key_field = table.primaryKey;

% Assert assumptions
if isempty(description_field)
    error('There is no description field in this table: %s', table.className);
elseif length(description_field) > 1
    error('There are multiple description fields on this table: %s', strjoin(description_field, newline));
elseif length(key_field) > 1
    error('This table has a composite primary key:%s%s', newline, strjoin(key_field, newline))
end

%Fetch data
[keys,description_field] = fetchn(table, key_field{:},description_field{:});

% Join keys & description for description_field
if ~iscell(keys)
    str_keys = cellfun(@num2str, num2cell(keys), 'un', 0);
    description_field=strcat(str_keys,{': '},description_field);
else
    description_field=strcat(keys,{': '},description_field);
end

    
end