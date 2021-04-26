function ingest_acq_session(subject_id, user_folder, rig, find_paths)
%INGEST_ACQ_SESSION
% Look for missing behavioral files in bucket and add them to u19_acquisition.session % u19_acquisition.SessionStarted
% Only inserts one session per day
%
% Inputs
%  subject      = subject_fullname of the session
%  user_folder  = user that ran the session
%  rig          = rigname of the session

% Execute function to find or generate paths in spock tree
if nargin < 4
    find_paths = 1;
end

verbose = 0;

%Cher for subject in database
subj_key.subject_fullname = subject_id;
subject_db = fetch(subject.Subject & subj_key, 'subject_fullname', 'user_id');

if isempty(subject_db)
    error('There is no such subject in the database')
end

%Check rig existence
rigkey.location = rig;
rig_db = fetch(lab.Location & rigkey, 'location', 'bucket_default_path');
if isempty(rig_db)
    error('There is no such rig in the database')
end
% Get rig default path for behavior files
rig_directory = lab.utils.format_bucket_path(rig_db.bucket_default_path);
lab.utils.assert_mounted_location(rig_directory);

% Get user directory for specific rig
user_directory = fullfile(rig_directory, user_folder);
bucket_directory = fullfile(rig_db.bucket_default_path, user_folder);

%Mark an error if there is no drectory for user in that rig (nickname or user id)
if ~exist(user_directory, 'dir')
    disp(['looking inside this directory: ' user_directory])
    warning('No directory found for inserted user')
    return
end

%Get all files of corresponding subject
current_directory = fileparts(mfilename('fullpath'));
if find_paths
    disp(['looking inside this directory: ' user_directory])
    
    subj_files = RecFindFiles(user_directory, subject_db.subject_fullname, {}, 7, verbose);
    save(fullfile(current_directory, 'subj_files.mat'), 'subj_files')
else
    load(fullfile(current_directory, 'subj_files.mat'), 'subj_files')
end

if isempty(subj_files)
    disp(['No files found for subject ', subject_db.subject_fullname])
end

%Get all files of corresponding subject guessing new subject_fullname
if isempty(subj_files)
    disp(['looking inside this directory for guess subject: ' user_directory])
    
    idx_underscore = strfind(subject_db.subject_fullname, '_');
    guess_subject = '';
    if ~isempty(idx_underscore)
        guess_subject = strrep(subject_db.subject_fullname, subject_db.subject_fullname(1:idx_underscore(1)), '');
    end
    subj_files = RecFindFiles(user_directory, guess_subject, {}, 7, verbose);
    if isempty(subj_files) && ~isempty(guess_subject)
        disp(['No files found for subject (guess) ', guess_subject])
    end
end

%Get all files of corresponding subject guessing new subject_fullname with lower case 
if isempty(subj_files)
    disp(['looking inside this directory: ' user_directory])
    
    idx_underscore = strfind(subject_db.subject_fullname, '_');
    if ~isempty(idx_underscore)
        guess_subject = lower(strrep(subject_db.subject_fullname, subject_db.subject_fullname(1:idx_underscore(1)), ''));
    end
    subj_files = RecFindFiles(user_directory, guess_subject, {}, 7, verbose);
    if isempty(subj_files)
        disp(['No files found for subject (guess) ', subject_db.subject_fullname])
    end
end


bucket_subj_files = cellfun(@(x) strrep(x, user_directory, bucket_directory), subj_files, ...
    'UniformOutput', false);

% For all directories that end with subject id
matfile_pattern = '.mat';
for i=1:length(subj_files)
    
    % Check if file is for given date
    file = subj_files{i}{1};
    bucket_file = bucket_subj_files{i}{1};
    
    ismatfile = regexp(file, matfile_pattern, 'once');
    
    % If is not a mat file is not a behavior session file
    if isempty(ismatfile)
        continue
    end
    
    % Look for date in file and get the corresponding string
    date_idx = regexp(file, '[0-9]{8}');
    if ~isempty(date_idx)
        date_str = file(date_idx:date_idx+7);
        date_str = [date_str(1:4) '-' date_str(5:6) '-' date_str(7:8)];
    end
    
    
    % The file has other date not in array
    if isempty(date_str)
        disp(['Dates do not match this file ', file])
        continue
        % The file is of one of the dates in the array
    else
        
        %Check if session already in database
        sessionkey.subject_fullname = subject_db.subject_fullname;
        sessionkey.session_date = date_str;
        sessionkey.session_number = 0;

        status = false;
        %Load behavioral file
        try
            data = load(file,'log');
            log = data.log;
            %Check if it is a real behavioral file
            if isfield(log, 'session')
                status = true;
            else
                disp(['File does not match expected Towers behavioral file: ', acqsession_file])
            end
        catch
            disp(['Could not open behavioral file: ', acqsession_file])
        end
        
        %Insert acq session started
        session_started_db = fetch(acquisition.SessionStarted & sessionkey);
        if isempty(session_started_db) && status
            disp(['Inserting acq.SessionStarted for ', subject_db.subject_fullname, ...
                ' for date: ', date_str])
            insertSessionStartedFromFile_Towers(acquisition.SessionStarted, ...
                sessionkey,log, bucket_file, rig_db.bucket_default_path);            
        end
        
        
        % Insert acq session
        session_db = fetch(acquisition.Session & sessionkey);
        if isempty(session_db) && status
            disp(['Inserting acq.Session for ', subject_db.subject_fullname, ...
                ' for date: ', date_str])
            
            insertSessionFromFile_Towers(acquisition.Session, sessionkey,log)
               
        end
        
    end
    
end

end




