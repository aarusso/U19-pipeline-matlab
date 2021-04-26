%{
# sanity check that time bin size is good 
-> meso.Scan
-> meso_analysis.BinParamSet
---

epoch_edges             : blob  # ideal bin edges

%}


classdef TimeBinInfo < dj.Computed
  methods(Access=protected)
    function makeTuples(self, key)
      

      
      
      
      self.insert(result)
    end
  end
end