function outputFiles = reorder_output_files(outputFiles)
% Reorder chunk output files 
%(e.g chunks filenames original order (as strings): 1-5 11-15 6-10  )
%(e.g chunks filenames intended order (as numbers): 1-5 6-10  11-15 )
% Input
% outputFiles = List of chunk files unsorted
% Output
% outputFiles = List of chunk files sorted

%Get the _x-y. pattern (1st file of chunks does not have it and remains 1st file)
expr = '_\d+-\d.';
reg_match = regexp(outputFiles, expr);
idx_outcorr = ~cellfun(@isempty,reg_match);
outputFiles_not_corr = outputFiles(~idx_outcorr);

% Get list of remaining output files and get regexp number match
outputFiles_corr = outputFiles(idx_outcorr);
reg_match        = reg_match(idx_outcorr);

%Extract number part of files and sort them
outputFiles_order = cellfun(@(x,y) x(y+1:y+2), outputFiles_corr, reg_match, 'UniformOutput', false);
outputFiles_order = strrep(outputFiles_order, '-', '');
outputFiles_order = cellfun(@str2num, outputFiles_order);
[~, outputFiles_order] = sort(outputFiles_order);
outputFiles_corr = outputFiles_corr(outputFiles_order);

%Concatenate outputFiles with the 1st file again
outputFiles = [outputFiles_not_corr outputFiles_corr];

end

