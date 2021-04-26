



spatial_file = cell(1,size(cnmf.spatial,2));
idx_match    = zeros(1,spatial_file{i});
non_matches  = 0;
for i = 1:size(cnmf.spatial,2)
    
    spatial_file{i} = zeros(503,504);
    spatial_file{i}(find(cnmf.spatial(:,i))) = nonzeros(cnmf.spatial(:,i));
    
    if i-non_matches <= length(spatial_db)
        equals = all(all(spatial_db{i-non_matches} == spatial_file{i}));
        
        if equals
            idx_match(i) = 1;
        else
            i
            non_matches = non_matches + 1
        end
    end
end

