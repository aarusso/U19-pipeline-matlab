%{
-> behavior.TowersSession
psych_level                  : tinyint
-----
subject_delta_data=null      : blob   # num of right - num of left, x ticks for data
subject_pright_data=null     : blob   # percentage went right for each delta bin for data
subject_delta_error=null     : blob   # num of right - num of left, x ticks for data confidence interval 
subject_pright_error=null    : blob   # confidence interval for precentage went right of data
subject_delta_fit=null       : blob   # num of right - num of left, x ticks for fitting results
subject_pright_fit=null      : blob   # fitting results for percent went right
%}

classdef TowersSubjectCumulativePsychLevel < dj.Computed
    
    methods(Access=protected)
        
        function makeTuples(self, key)

            deltaBins           = -15:3:15;       % controls binning of #R - #L
            deltaBins           = deltaBins(:);
           
            [session_start_time, level] = fetch1(acquisition.Session & key, 'session_start_time', 'level');
            
            sessions_included = fetch(acquisition.Session ...
                & struct('subject_fullname', key.subject_fullname) ...
                & behavior.TowersSession & struct('level', level) ... 
                & sprintf('session_start_time <= "%s"', session_start_time));
            
            [numTowersR, numTowersL, choices] = fetchn(...
                behavior.TowersSession & sessions_included, ...
                'num_towers_r', 'num_towers_l', 'chosen_side');
            
            numTowersR = cat(2, numTowersR{:});
            numTowersL = cat(2, numTowersL{:});
            choices = cat(2, choices{:});
 
            fit_results = behavior.utils.psychFit(deltaBins, numTowersR, numTowersL, choices);
            
            f = fieldnames(fit_results);
            for i = 1:length(f)
               key.(strcat('subject_', f{i})) = fit_results.(f{i});
            end
            
            key.psych_level = level;
            
            self.insert(key)
        end
    end
end