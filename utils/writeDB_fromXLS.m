function writeDB_fromXLS(filename, tables)
% Write a Excel spreadsheet to datajoint tables
% Inputs
% filename  = Full path of Excel/csv file to read data from (if mac/linux csv is needed)
% tables    = Cell array of tables to insert data (e.g {action.Weighing actionWaterAdministration}

% Check file extension:
[~,~,file_extension] = fileparts(filename);

% Read data and column names
if ispc && contains(file_extension, 'xls')
[~,~,data] = xlsread(filename);
%If mac/linux, read as csv and pass data to cell
else
    data = readtable(filename);
    fields = data.Properties.VariableNames;
    data = table2cell(data);
    data = [fields; data];
end
xls_fields = data(1,:);

for i=1:length(tables)
    
    %Check all fieldnames from table
    attributes = tables{i}.tableHeader.attributes;
    attributes = struct2table(attributes, 'AsArray', true);
    table_fields = attributes.name;
    
    %Check which fields are needed for insert
    non_default_fields = cellfun(@isempty, attributes.default) ;
    nec_table_fields = ~attributes.isnullable & non_default_fields;
    
    %If not all needed fields are provided it is not possible to insert data
    idx_fields_contained = ismember(table_fields(nec_table_fields), xls_fields);
    if ~all(idx_fields_contained)
        needed_fields = table_fields(nec_table_fields);
        missing_fields = needed_fields(~idx_fields_contained);
        error(['Not all needed fields are contained on the spreadsheet: ', ...
                 strjoin(missing_fields, newline)])
    end
    
    %Filter excel data, only columns for this specific table
    idx_fields_xls = ismember(xls_fields, table_fields);
    data_table = data(:,idx_fields_xls);
    reduced_fields = data(1,idx_fields_xls);
    data_table = data_table(2:end,:);
    
    %Get corresponding indexes from spreadsheet fields and table fields
    [idx_fields_table,idx_reduced_xls] = ismember(table_fields, reduced_fields);
    idx_fields_table = find(idx_fields_table);
    
    %For each field, format accordingly to datatype
    for j=1:length(idx_fields_table)
        curr_idx = idx_fields_table(j);
        idx_xls  = idx_reduced_xls(j);
        
        if attributes.isNumeric(curr_idx)
            %data_table(:,idx_xls) = cellfun(@str2num, data_table(:,idx_xls), 'un', 0);
        end
        if attributes.type(curr_idx) == "date"
            data_table(:,idx_xls) = cellfun(...
                @(x) datestr(datenum(x), 'YYYY-mm-dd'), data_table(:,idx_xls), 'un', 0);
        end
        if attributes.type(curr_idx) == "datetime"
            data_table(:,idx_xls) = cellfun(...
                @(x) datestr(datenum(x), 'YYYY-mm-dd hh:MM'), data_table(:,idx_xls), 'un', 0);
        end
    
    end
   
    %Insert data to table (ignore duplicates)
    data_struct = cell2struct(data_table, reduced_fields, 2);
    insert(tables{i}, data_struct, 'IGNORE')
    
    
end
     
end




