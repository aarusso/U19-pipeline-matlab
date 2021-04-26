function target = mergeIfDifferent(target, source)

  if isstruct(source)
    for field = fieldnames(source)'
      target.(field{:}) = imaging.utils.mergeIfDifferent(target.(field{:}), source.(field{:}));
    end
  elseif isequaln(target, source)
  elseif iscell(target) && (~iscell(source) || numel(source) > 1)
    target{end+1}       = source;
  elseif ~iscell(target) && numel(source) > 1
    target              = {target, source};
  else
    target(end+1)       = source;
  end
  
end