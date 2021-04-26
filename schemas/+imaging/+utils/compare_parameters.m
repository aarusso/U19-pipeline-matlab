function [table_diff_params,common_params] = compare_parameters(param_table, method_key)
%COMPARE_PARAMETERS get a table of parameters set differently betwen sets and a structure of common parameters across
%all sets fro a given method

common_params = struct();

%Fetch all set params from method (including master table for description)
param_struct = fetch(param_table * param_table.master & method_key, '*');

if isempty(param_struct)
    warning('No parameter sets were found for this method')
    table_diff_params = '';
    common_params = '';
    return
end

fields = fieldnames(param_struct);

% Get id of field which correspond to (set_id, description parameter_name, parameter_value)
idx_set = contains(fields,'set_id');
set_id_field = fields{idx_set};

idx_param_description = contains(fields,'description');
param_description_field = fields{idx_param_description};

idx_param_name = contains(fields,'parameter_name');
param_name_field = fields{idx_param_name};

idx_param_value = contains(fields,'parameter_value');
param_value_field = fields{idx_param_value};
values = {param_struct.(param_value_field)};

%Get unique ids and unique params of sets
set_ids = sort(unique([param_struct.(set_id_field)]));
unique_params = unique({param_struct.(param_name_field)});

% Create pivot table for all sets for all params
table_diff_params = array2table(cell(length(set_ids), length(unique_params)+2), ...
   'VariableNames', [{'set_id', param_description_field}, unique_params]);

% Set values for pivot table
num_sets = 0;
for i=set_ids
    num_sets = num_sets+1;
    table_diff_params{num_sets,'set_id'} = {i};
    
    %Set description field for table
    idx_desc = find([param_struct.(set_id_field)] == i,1);
    table_diff_params{num_sets,param_description_field} = {param_struct(idx_desc).(param_description_field)};
    
    for j=unique_params
        
        idx_value = [param_struct.(set_id_field)] == i & matches({param_struct.(param_name_field)},j);
        
        if sum(idx_value == 1)
            table_diff_params{num_sets,j} = values(idx_value);
        else
            table_diff_params{num_sets,j} = {NaN};
        end
        
    end
end

table_diff_params.set_id = cell2mat(table_diff_params.set_id);

for j=unique_params
    
    %Convert to scalar if needed
    [status, scalar_column] = check_scalar_column(table_diff_params.(j{:}));
    
    if status
        table_diff_params.(j{:}) = scalar_column;
    end
    
    %Check if all sets are matching
    all_matches = check_all_matching(table_diff_params.(j{:}));
    
    %If all sets matches, save to common_params, delete from table
    if all_matches
        common_params.(j{:}) = table_diff_params{1,j};
        table_diff_params = removevars(table_diff_params,j);
        
    end
    
end


end

