%{
# binning parameter for behavior and neural data
bin_parameter_set_id   : int       # id of the set of parameters
---

epoch_binning      : blob      # number of bins per epoch 1 x 6 array
#good_morpho_only   : tinyint   # whether to use just blobs and doughnuts

%}

classdef BinningParameters < dj.Lookup
  properties(SetAccess = protected)
    contents = {
                1, [5 20 13 5 21 19]
                }
  end
end