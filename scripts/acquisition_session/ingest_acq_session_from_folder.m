function ingest_acq_session_from_folder(subject_id, file_directory)
%INGEST_ACQ_SESSION FROM FOLDER
% Insert sessions from known behavioral path locations to u19_acquisition.session & u19_acquisition.SessionStarted
% Only inserts one session per day
%
% Inputs
%  subject         = subject_fullname of the session
%  file_directory  = directory where behavioral files are found, as in spock (/mnt/bucket/...)

%Get local path
[bucket_directory, user_directory] = lab.utils.get_path_from_official_dir(file_directory);

%Get file list of candidates
file_sturct       = dir(fullfile(user_directory,'*.mat'));
file_names        = {file_sturct.name};
bucket_subj_files = fullfile(bucket_directory,file_names);
user_subj_files   = fullfile(user_directory,file_names);

for i=1:length(file_names)
    
    % Check if file is for given date
    localpath_file = user_subj_files{i};
    bucket_file    = bucket_subj_files{i};
    
    % Look for date in file and get the corresponding string
    date_idx = regexp(localpath_file, '[0-9]{8}');
    if ~isempty(date_idx)
        date_str = localpath_file(date_idx:date_idx+7);
        date_str = [date_str(1:4) '-' date_str(5:6) '-' date_str(7:8)];
    end
    
    
    % The file has other date not in array
    if isempty(date_str)
        disp(['Dates do not match this file ', localpath_file])
        continue
        % The file is of one of the dates in the array
    else
        
        %Check if session already in database
        sessionkey.subject_fullname = subject_id;
        sessionkey.session_date = date_str;
        sessionkey.session_number = 0;
        
        session_started_db = fetch(acquisition.SessionStarted & sessionkey);
        session_db = fetch(acquisition.Session & sessionkey);
        
        
        if isempty(session_started_db) || isempty(session_db)
        
        status = false;
        %Load behavioral file
        try
            data = load(localpath_file,'log');
            log = data.log;
            %Check if it is a real behavioral file
            if isfield(log, 'session')
                status = true;
            else
                disp(['File does not match expected Towers behavioral file: ', bucket_file])
            end
        catch
            disp(['Could not open behavioral file: ', bucket_file])
        end
        
        %Insert acq session started

        if isempty(session_started_db) && status
            disp(['Inserting acq.SessionStarted for ', subject_id, ...
                ' for date: ', date_str])
            insertSessionStartedFromFile_Towers(acquisition.SessionStarted, ...
                sessionkey,log, bucket_file, '');
        else
            disp([subject_id, ' ', date_str, ' already on acquisition.SessionStarted'])
        end
        
        
        % Insert acq session
        if isempty(session_db) && status
            disp(['Inserting acq.Session for ', subject_id, ...
                ' for date: ', date_str])
            
            insertSessionFromFile_Towers(acquisition.Session, sessionkey,log)
        else
            disp([subject_id, ' ', date_str, ' already on acquisition.Session'])
        end
        
        else
            disp([subject_id, ' ', date_str, ' already on acquisition.SessionStarted & acquisition.Session'])
        end
        
    end
    
end

end




