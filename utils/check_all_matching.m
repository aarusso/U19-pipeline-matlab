function all_matches = check_all_matching(array)
%CHECK_ALL_MATCHING 

N = numel(array);
[X,Y] = ndgrid(1:N);
Z = tril(true(N),-1);

if iscell(array)
    all_matches = all(arrayfun(@(x,y)isequal(array{x},array{y}),X(Z),Y(Z)));
else
    all_matches = all(arrayfun(@(x,y)isequal(array(x),array(y)),X(Z),Y(Z)));
end

end

