%{
-> behavior.TowersSession
-----
session_delta_data=null      : blob   # num of right - num of left, x ticks for data
session_pright_data=null     : blob   # (%) percentage went right for each delta bin for data
session_delta_error=null     : blob   # num of right - num of left, x ticks for data confidence interval 
session_pright_error=null    : blob   # (%) confidence interval for precentage went right of data
session_delta_fit=null       : blob   # num of right - num of left, x ticks for fitting results
session_pright_fit=null      : blob   # (%) fitting results for percent went right
%}

classdef TowersSessionPsych < dj.Computed

    methods(Access=protected)
        
        function makeTuples(self, key)

            deltaBins           = -15:3:15;       % controls binning of #R - #L
            deltaBins           = deltaBins(:);
            
            [numTowersR, numTowersL, choices] = fetch1(behavior.TowersSession & key, 'num_towers_r', 'num_towers_l', 'chosen_side');
 
            fit_results = behavior.utils.psychFit(deltaBins, numTowersR, numTowersL, choices);
            
            f = fieldnames(fit_results);
            for i = 1:length(f)
               key.(strcat('session_', f{i})) = fit_results.(f{i});
            end


            self.insert(key)
        end
    end
end