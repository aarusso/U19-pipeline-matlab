
clearvars;
this_path = fileparts(mfilename('fullpath'));
file2load = fullfile(this_path, 'sessions_wrong_filepath.mat');
file2save = fullfile(this_path, 'sessions_wrong_filepath2.mat');

load(file2load)

num_diff_sessions = 0;
for j=1:length(session_diff_struct)
    
    [j length(session_diff_struct)]
    
    filename = session_diff_struct(j).remote_path_behavior_file;
    
    if ismac
        acqsession_file = ['/Volumes' filename];
    elseif isunix
        acqsession_file = ['/mnt/bucket' filename];
    end
    
    if ~exist(acqsession_file, 'file')
        
        c1 = regexp(filename,'/data/');
        
        if ~isempty(c1)
            
            c2 = c1 + length('/data/');
            c3 = strfind(filename(c2:end), '/');
            c3 = c3(1)-1;
            
            subj_name = lower(filename(c2:c2+c3-1));
            
            
            filename = [filename(1:c2-1)  subj_name filename(c2+c3:end)];
            
            if ismac
                acqsession_file = ['/Volumes' filename];
            elseif isunix
                acqsession_file = ['/mnt/bucket' filename];
            end
            
            if ~exist(acqsession_file, 'file')
                
                num_diff_sessions = num_diff_sessions + 1
                
                aux_key = session_diff_struct(j);
                session_diff_struct2(num_diff_sessions) = aux_key;
            else
                key = struct();
                key.subject_fullname = session_diff_struct(j).subject_fullname;
                key.session_date = session_diff_struct(j).session_date;
                key.session_number = session_diff_struct(j).session_number;
                
                update(acquisition.SessionStarted & key, 'remote_path_behavior_file', filename);
            end
            
        end
        
    end
    
end


save(file2save, 'session_diff_struct2', '-v7.3')