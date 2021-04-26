 
 
clearvars;
this_path = fileparts(mfilename('fullpath'));
file2save = fullfile(this_path, 'session_time_fetch_comp2.mat');
file2save2 = fullfile(this_path, 'sessions_diff.mat');
 
fields_session = {'subject_fullname', 'session_date'};
fields_trials = {'trial_type', ...
'choice', ...
'trial_abs_start', ...
'cue_presence_left', ...
'cue_presence_right', ...
'cue_onset_left', ...
'cue_onset_right', ...
'cue_offset_left', ...
'cue_offset_right', ...
'cue_pos_left', ...
'cue_pos_right', ...
'trial_duration', ...
'excess_travel', ...
'i_arm_entry', ...
'i_blank', ...
'i_cue_entry', ...
'i_mem_entry', ...
'i_turn_entry', ...
'iterations', ...
'trial_id', ...
'trial_prior_p_left', ...
'vi_start', ...
'trial_time', ...             
'position', ...    
'collision', ...  
'velocity', ...              
'sensor_dots'
};

session_struct = fetch(proj(acquisition.Session,'session_location->sess_loc') * acquisition.SessionStarted, ...
    'remote_path_behavior_file', 'ORDER BY session_date');
 
num_sessions = 500;
num_runs_fields = [5 4 3 0];

session_perm = randperm(length(session_struct));

session_time_fetch = nan(num_sessions, length(num_runs_fields), 2);

num_runs = 0;
for k=num_runs_fields
    
    num_runs = num_runs + 1;
    
    fields_ac = fields_trials(1:end-k);
    
    for j=1:num_sessions
    
        [num_runs j num_sessions]
        ac_session = session_perm(j);
    
        tic
        trial_struct = fetch(behavior.TowersBlockTrialOld & session_struct(ac_session),fields_ac{:});
        session_time_fetch(j, num_runs, 1)  = toc;
        tic
        trials_struct = fetch(behavior.TowersBlockTrial & session_struct(ac_session),fields_ac{:});
        session_time_fetch(j, num_runs, 2)  = toc;
   
        
        tf = isequaln(trial_struct,trials_struct);
        if ~tf
            fields_diff = {};
            status_diff = 0;
            for i=1:length(fields_ac)
                trial_field = {trial_struct.(fields_ac{i})};
                trials_field = {trials_struct.(fields_ac{i})};
                idx_nempty_trial = find(cellfun(@length, trial_field) ~= 0);
                idx_nempty_trials = find(cellfun(@length, trial_field) ~= 0);
                trial_field = trial_field(idx_nempty_trial);
                trials_field = trials_field(idx_nempty_trials);
                tfi = isequaln(trial_field,trials_field);
                if ~tfi
                        status_diff = 1;
                end
            end
            if status_diff
                num_diff_sessions = num_diff_sessions + 1
                aux_key = session_struct(j);
                session_diff_struct(num_diff_sessions) = aux_key;
            end
        end
        
        
     end
    
end

save(file2save, 'session_time_fetch', '-v7.3')
if exist('session_diff_struct')
    save(file2save2, 'session_diff_struct', '-v7.3')
end


