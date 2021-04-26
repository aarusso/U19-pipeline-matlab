function target = mergeParameters(target, source, doCheck, varargin)
  
  if doCheck
    for iArg = 1:numel(varargin)
      target.(varargin{iArg}) = imaging.utils.mergeIfDifferent(target.(varargin{iArg}), source.(varargin{iArg}));
    end
  else
    for iArg = 1:numel(varargin)
      target.(varargin{iArg}) = source.(varargin{iArg});
    end
  end
  
end