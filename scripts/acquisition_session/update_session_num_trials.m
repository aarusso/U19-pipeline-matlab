
key = struct();
key.num_trials = -1;
session_table_relvar = acquisition.Session * behavior.TowersSession;

columns = {'chosen_side', 'num_trials'};
session_info = fetch(session_table_relvar & key, columns{:});

for i=1:length(session_info)
    
    disp(i)
    disp(length(session_info))
    
    num_trials_sess = length(session_info(i).chosen_side);
    
    session_key.subject_fullname = session_info(i).subject_fullname;
    session_key.session_date     = session_info(i).session_date;
    session_key.session_number   = session_info(i).session_number;
    
    update(acquisition.Session & session_key, 'num_trials', num_trials_sess)
    update(acquisition.Session & session_key, 'num_trials_try', num_trials_sess)
    
end