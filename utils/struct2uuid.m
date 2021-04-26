function uuid = struct2uuid(structure)
% Given a dictionary structure, returns a hash string as UUID

%Convert structure to cell array to take into account fieldnames in transformation
%(e.g   
%a.s =1 a.c = 2    -->  {'s', 1, 'c', 2}

fields          = fieldnames(structure);
associated_cell = struct2cell(structure); 
final_cell_array = cell(1,length(fields)*2);
final_cell_array(1:2:end) = fields;
final_cell_array(2:2:end) = associated_cell;


%Convert cell
if isempty(final_cell_array)
    uuid = hashlib.md5hex('none');
else
    uuid = hashlib.md5hex(final_cell_array);
end



end

