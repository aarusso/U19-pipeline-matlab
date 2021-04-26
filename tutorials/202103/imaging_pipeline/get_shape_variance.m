function shape_variance = get_shape_variance()
%For now gof data is not saved in the db, for now load it from results file

local_data = true;

if local_data
    results_path     = fullfile(fileparts(mfilename('fullpath')), 'imaging_data');
    posthocFile      = dir(fullfile(results_path, '*.cnmf-proto-roi-posthoc.mat'));
    posthocFile      = posthocFile(end);
    posthocFile      = fullfile(results_path, posthocFile.name);
end

gof = load(posthocFile, 'gof');

idx_bad = 1164;

shape_variance = gof.gof.shapeVariance;
shape_variance(idx_bad) = [];

end

