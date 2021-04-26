
%Script to find behavior files for a given set of users
%and call ingestion of acquisition.Session and acquisition.SessionStarted


%Local main directories used by users_id
users_dirs = {
    'koay',       'sakoay';};

%users_dirs = { ...
 %   'efonseca',   'efonseca'; ...
 %   'emdiamanti', 'lucas'; ...
 %   'jjulian',    'josh'; ...
 %   'jounhong',   'ryancho'; ...
 %   'lpinto',     'lucas'; ...
 %   'sbolkan',    'sbolkan'; ...
%    'koay',       'sakoay'; ...
 %   'hnieh',      'edward'};

users_dirsT  = cell2table(users_dirs, ...
    'VariableNames',{'user_id' 'user_folder_name'});
users_dirsT.user_id = categorical(users_dirsT.user_id);
% Create a user_struct to filter only these users in query
user_array = cell2struct(users_dirs(:,1),{'user_id'},2);

%Just check after certain date
from_date = '2015-11-01';
sess_Date_key = ['session_date >= ''' from_date ''''];

%Get unique combination (subject - locations)
new_sessions  = acquisition.SessionStarted & sess_Date_key;
%all_locations_session = proj(lab.Location) & proj(new_sessions,'session_location->location');
%session_struct = fetch(proj(subject.Subject & user_array, 'user_id') * all_locations_session, '*');

session_struct = fetch(proj(subject.Subject & user_array, 'user_id') * proj(lab.Location) & ...
                       proj(new_sessions,'session_location->location'), '*');
                        
      
%Transform to table and make a categorical index
unique_sessions = struct2table(session_struct);
unique_sessions.user_id = categorical(unique_sessions.user_id);

%Just keep in table sessions from users_dirs we stated
unique_sessions = unique_sessions(...
                ismember(unique_sessions.user_id,users_dirsT.user_id),:);

%Join tables to get corresponding user_folder_name
unique_sessions = join(unique_sessions,users_dirsT);

%Convert back to cell categorical column
unique_sessions.user_id = cellstr(nominal(unique_sessions.user_id));

% Call ingest_acq_session for every combination
for i=1:size(unique_sessions,1)
    
    disp(['ingestion for ' ...
            ' subject: ' unique_sessions{i,'subject_fullname'}{:} ...
            ' location: ' unique_sessions{i,'location'}{:} ...
            ' local folder: ' unique_sessions{i,'user_folder_name'}{:} ...
            ])
    
    ingest_acq_session(unique_sessions{i,'subject_fullname'}{:},...
                       unique_sessions{i,'user_folder_name'}{:}, ...
                       unique_sessions{i,'location'}{:})
end
