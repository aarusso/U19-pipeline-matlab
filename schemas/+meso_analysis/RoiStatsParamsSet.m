%{
# ROI stats parameters
roi_stats_parameter_set_id   : int       # id of the set of parameters
---

good_morpho_only        : tinyint   # whether to use just blobs and doughnuts
min_dff                 : float     # 
min_spike               : float
min_significance        : int       # 
min_active_fraction     : float     #
min_active_seconds      : float     #

%}

classdef RoiStatsParamsSet < dj.Lookup
  properties(SetAccess = protected)
    contents = {
                1,      ...
                1,      ...
                0.3,    ...
                1e-5,   ...
                3,      ...
                0.25,   ...
                0.2     
                }
  end
end