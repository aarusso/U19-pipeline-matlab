function [status,converted_column] = check_scalar_column(column)
%check_scalar_column 

status = false;
converted_column = column;

if isnumeric(column)
    status = true;
    return
else
    if all(cellfun(@isscalar, column))
        status = true;
        converted_column = cell2mat(column);
    end
end

end

