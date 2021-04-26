%{
-> puffs.PuffsSession
-----
subject_delta_data=null      : blob   # num of right - num of left, x ticks for data
subject_pright_data=null     : blob   # percentage went right for each delta bin for data
subject_delta_error=null     : blob   # num of right - num of left, x ticks for data confidence interval 
subject_pright_error=null    : blob   # confidence interval for precentage went right of data
subject_delta_fit=null       : blob   # num of right - num of left, x ticks for fitting results
subject_pright_fit=null      : blob   # fitting results for percent went right
%}

classdef PuffsSubjectCumulativePsych < dj.Computed
    
    methods(Access=protected)
        
        function makeTuples(self, key)

            deltaBins           = -12:3:12;       % controls binning of #R - #L
            deltaBins           = deltaBins(:);
           
            session_start_time = fetch1(acquisition.Session & key, 'session_start_time');
            
            sessions_included = fetch(acquisition.Session & 'level < 8' ...
                & struct('subject_fullname', key.subject_fullname) ...
                & puffs.PuffsSession ... 
                & sprintf('session_start_time <= "%s"', session_start_time));
            
            [numR, numL, choices_str] = fetchn(puffs.PuffsSessionTrial & sessions_included, ...
                'num_puffs_received_r', 'num_puffs_received_l', 'choice');
            
            choices = zeros(size(choices_str));
            
            choices(strcmp(choices_str, 'L')) = 1;
            choices(strcmp(choices_str, 'R')) = 2;
            choices(strcmp(choices_str, 'nil')) = inf;
            
            fit_results = behavior.utils.psychFit(deltaBins, numR, numL, choices);
            
            f = fieldnames(fit_results);
            for i = 1:length(f)
               key.(strcat('subject_', f{i})) = fit_results.(f{i});
            end
            
            self.insert(key)
        end
    end
end