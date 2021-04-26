%{
# General information of a session
-> subject.Subject
session_date                : date                          # date of experiment
session_number              : int                           # number
---
session_start_time          : datetime                      # start time
(session_location) -> lab.Location                          # Location where training is happening
-> task.Task                                                # Which task was performed in session
local_path_behavior_file    : varchar(255)                  # Path were session file is stored in local computer
remote_path_behavior_file   : varchar(255)                  # Path were session file will be stored in bucket
is_finished=0               : tinyint                      # Flag that indicates if this session was finished successfully
%}

classdef SessionStarted < dj.Manual

    properties (Constant)

        LOCALPATHTOKEN = 'C:\Data\';

    end


    methods

        function insertNewSessionStarted(self, key, task, localPath, trainingRig)
            % function to insert in acquisition.session_started table
            % Inputs
            % key         = struct with fields (subject_fullname, session_date, session_number)
            % localPath   = path where behavior file will be stored in local computer
            % trainingRig = name of rig where subject is running

            %find if animal exists
            status               = subject.utils.check_subject(key.subject_fullname);
            session_start_time     = datestr(datetime('now'), 'YYYY-mm-dd HH:MM');

            if status
                % Check location, if there is no there yet, insert it
                location_info =  lab.utils.check_location(trainingRig);

                %Get default path
                default_rig_path_location = location_info.bucket_default_path;
                remote_location = lab.utils.get_corresponding_remote_location(...
                    self.LOCALPATHTOKEN, localPath, default_rig_path_location);

                %Define key to insert
                key.session_start_time        = session_start_time;
                key.session_location          = trainingRig;
                key.task                      = task;
                key.local_path_behavior_file  = localPath;
                key.remote_path_behavior_file = remote_location;
                key.is_finished               = 0;

                insert(acquisition.SessionStarted, key);
            else
                disp(['SessionStarted was not inserted, animal not found ', animalID])
            end
        end

         function updateSessionStarted(self, key, localPath, trainingRig)
            % function to insert in acquisition.session_started table
            % Inputs
            % key         = struct with fields (subject_fullname, session_date, session_number)
            % localPath   = path where behavior file will be stored in local computer
            % trainingRig = name of rig where subject is running


            %Check if subject exists
            status               = subject.utils.check_subject(key.subject_fullname);

            if status

                %Update start time
                session_start_time     = datestr(datetime('now'), 'YYYY-mm-dd HH:MM');
                update(acquisition.SessionStarted & key, 'session_start_time', session_start_time)

                %Update location
                location_info =  lab.utils.check_location(trainingRig);
                update(acquisition.SessionStarted & key, 'session_location', trainingRig)

                %Get path and update local and remote
                default_rig_path_location = location_info.bucket_default_path;
                remote_location = lab.utils.get_corresponding_remote_location(...
                    self.LOCALPATHTOKEN, localPath, default_rig_path_location);

                update(acquisition.SessionStarted & key, 'local_path_behavior_file', localPath)
                update(acquisition.SessionStarted & key, 'remote_path_behavior_file', remote_location)

                %Update is_finished (it has restarted)
                update(acquisition.SessionStarted & key, 'is_finished', 0)
            end

        end


        function insertSessionStartedFromFile_Towers(self,key,log, bucket_file_path, rig_default_path)
            % Insert sessionStarted record from towers task behavioralfile
            % Called at the end of training or when populating session
            % Input
            % self             = acquisition.SessionStarted instance
            % key              = structure with required fields: (subject_fullname, date, session_no)
            % log              = behavioral file as stored in Virmen
            % bucket_file_path = file path in bucket
            % rig_default_path =
            % is_finished      =

            %INSERT_ACQ_SESSION STARTED insert u19_acquisition.sessionstarted info when file is provided
            %
            % Input
            % acqsession_file  = entire file path for towers task behavior file

            %primary key values
            key.remote_path_behavior_file = bucket_file_path;


            key.session_start_time = sprintf('%d-%02d-%02d %02d:%02d:00', log.session.start(1), log.session.start(2), log.session.start(3), log.session.start(4), log.session.start(5));

            %Check location and if doesn't exist insert it.
            lab.utils.check_location(log.version.rig.rig);
            key.session_location = log.version.rig.rig;
            key.task = 'Towers';

            if isempty(rig_default_path)
               locationkey.location = key.session_location;
               rig_default_path = fetch1(lab.Location & locationkey, 'bucket_default_path');
               rig_default_path = lab.utils.get_path_from_official_dir(rig_default_path);
            end


            if ~isempty(rig_default_path)
            % Get local path from bucket path and rig default path
            local_path = strrep(bucket_file_path, rig_default_path, self.LOCALPATHTOKEN);
            local_path = fullfile(local_path);
            local_path = strrep(local_path, '/', '\');

            key.local_path_behavior_file  = local_path;

            %By default, we think this task was successfully finished
            key.is_finished = 1;


            insert(acquisition.SessionStarted, key);
            else
                error(['Location: ', key.session_location, ' does not exist'])
            end


        end

    end

end
