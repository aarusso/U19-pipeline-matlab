function cell_boxes = get_cell_boxes()
%For now gof data is not saved in the db, for now load it from results file

local_data = true;

if local_data
    results_path     = fullfile(fileparts(mfilename('fullpath')), 'imaging_data');
    posthocFile      = dir(fullfile(results_path, '*.cnmf-proto-roi-posthoc.mat'));
    posthocFile      = posthocFile(end);
    posthocFile      = fullfile(results_path, posthocFile.name);
end

cnmf = load(posthocFile, 'cnmf');

idx_bad = 1164;

cell_boxes = cnmf.cnmf.box;
cell_boxes(idx_bad, :) = [];

end

