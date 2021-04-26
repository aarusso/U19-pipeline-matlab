

this_path = fileparts(mfilename('fullpath'));
file2save = fullfile(this_path, 'sessions_wrong_filepath.mat');

subj_key = 'subject_fullname not like "testuser%" ';

session_struct = fetch(acquisition.SessionStarted & subj_key, 'remote_path_behavior_file', 'ORDER BY session_date');


num_diff_sessions = 0
for j=1:length(session_struct)
    
    [j length(session_struct)]
    
    filename = session_struct(j).remote_path_behavior_file;
    filename = strrep(filename, '/mnt/bucket', '');
    
    if ~contains(filename, '/jukebox/')
        
        if ismac
            acqsession_file = ['/Volumes' filename];
        elseif isunix
            acqsession_file = ['/mnt/bucket' filename];
        end
        
        %[~, acqsession_file] = lab.utils.get_path_from_official_dir(session_struct(j).remote_path_behavior_file);
        
        %Load behavioral file & update water eanred
        
        if ~exist(acqsession_file, 'file')
            
            num_diff_sessions = num_diff_sessions + 1
            
            aux_key = session_struct(j);
            session_diff_struct(num_diff_sessions) = aux_key;
        end
        
    end
    
    
end

save(file2save, 'session_diff_struct', '-v7.3')