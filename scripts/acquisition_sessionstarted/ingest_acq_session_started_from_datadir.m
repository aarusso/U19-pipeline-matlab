function ingest_acq_session_started_from_datadir()
%INGEST_ACQ_SESSION
% Look for missing u19.acquisition.SessionStarted records from u19_behavior.DataDirectory
%
% Inputs

%Defaults
from_date = '2010-01-01';
default_local_path = 'C:/Data';

%Just check after certain date
sess_Date_key = ['session_date >= ''' from_date ''''];

%Only needed fields
fields = {'subject_fullname', 'session_date', 'session_number',  'session_start_time', ...
          'combined_file_name->remote_path_behavior_file', 'session_location', 'bucket_default_path'};
      
%Get data directory, acq session, and lab location minus session started records      
session_struct = fetch(behavior.DataDirectory * acquisition.Session ...
                       * proj(lab.Location,'location->session_location', 'bucket_default_path')...
                       - proj(acquisition.SessionStarted, 'session_location->na') ...
                       & sess_Date_key,fields{:})
                   
                   
if ~isempty(session_struct)
    
    for i=1:length(session_struct)
                        
        %Replace /brainit/rigx ... with c:/data in local path
        session_struct(i).local_path_behavior_file = ...
            strrep(session_struct(i).remote_path_behavior_file, ...
                   session_struct(i).bucket_default_path, default_local_path);
               
        
        %Local path is for windows       
        session_struct(i).local_path_behavior_file = ...
            strrep(session_struct(i).local_path_behavior_file, ...
                   '/', '\');       
               
                        
    end
    
    %Remove bucket_default_path field since is not in SessionStarted
    session_struct = rmfield(session_struct, 'bucket_default_path');
    insert(acquisition.SessionStarted, session_struct)
    
    
end
