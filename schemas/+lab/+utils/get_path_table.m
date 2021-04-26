function path_table = get_path_table()
% get path table from u19_lab.#path and format it to use it more easily
%
% Output
% path_table   = formatted path table from datajoint
%

%Get all path table from u19_lab.Path ("official sites")
path_struct = fetch(lab.Path, '*');
path_table = struct2table(path_struct);
path_table.system = categorical(path_table.system);

%Change bezos-center global path to just bezos to match base_dir more easily
path_table.global_path(contains(path_table.global_path, 'Bezos')) = {'Bezos'};
path_table.global_path = strrep(path_table.global_path, '/', '');

end
