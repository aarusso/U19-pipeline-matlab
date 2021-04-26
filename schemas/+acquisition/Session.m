%{
# General information of a session
-> acquisition.SessionStarted
---
session_start_time          : datetime                      # start time
session_end_time=null       : datetime                      # end time
(session_location) -> lab.Location
-> task.TaskLevelParameterSet
stimulus_bank = ''          : varchar(255)                  # path to the function to generate the stimulus
stimulus_commit = ''        : varchar(64)                   # git hash for the version of the function
stimulus_set                : tinyint                       # an integer that describes a particular set of stimuli in a trial
session_performance         : float                         # percentage correct on this session
num_trials=-1               : int(11)                       # Number of trials for the session
num_trials_try=null         : tinyblob                      # Accumulative number of trials for each try of the session
session_narrative = ''      : varchar(512)                  # descriptive string
session_protocol=null       : varchar(255)                  # function and parameters to generate the stimulus
session_code_version=null   : blob                          # code version of the stimulus, usually two numbers "maze_version=2.1, code_version = 4.0". In the future: a githash?
is_bad_session=0            : tinyint                       # Flag that indicates if this session had any issues
session_comments=''         : varchar(2048)                 # Text to indicate some particularity of the session (e.g. state the issues in a bad session)
%}

classdef Session < dj.Imported

    methods(Access=protected)

        function makeTuples(self, key)

            %Get behavioral file to load
            fields = {'task', 'remote_path_behavior_file'};
            data_dir = fetch(acquisition.SessionStarted & key, fields{:});

            if strcmp(data_dir.task, 'Towers')
                [~, acqsession_file] = lab.utils.get_path_from_official_dir(data_dir.remote_path_behavior_file);

                %Load behavioral file
                try
                    data = load(acqsession_file,'log');
                    log = data.log;
                    status = 1;
                catch
                    disp(['Could not open behavioral file: ', acqsession_file])
                    status = 0;
                end
                if status
                    try
                        %Check if it is a real behavioral file
                        if isfield(log, 'session')
                            self.insertSessionFromFile_Towers(key, log);
                        else
                            disp(['File does not match expected Towers behavioral file: ', acqsession_file])
                        end
                    catch err
                        disp(err.message)
                        sprintf('Error in here: %s, %s, %d',err.stack(1).file, err.stack(1).name, err.stack(1).line )
                    end
                end

            end

        end
    end


    methods

        function insertSessionFromFile_Towers(self,key,log)
            % Insert session record from behavioralfile in towersTask
            % Called at the end of training or when populating session
            % Input
            % self         = acquisition.Session instance
            % key  = structure with required fields: (subject_fullname, date, session_no)
            % log          = behavioral file as stored in Virmen


            key.session_start_time = sprintf('%d-%02d-%02d %02d:%02d:00', log.session.start(1), log.session.start(2), log.session.start(3), log.session.start(4), log.session.start(5));
            key.session_end_time = sprintf('%d-%02d-%02d %02d:%02d:00', log.session.end(1), log.session.end(2), log.session.end(3), log.session.end(4), log.session.end(5));

            key.stimulus_bank = log.block.stimulusBank;
            key.task = 'Towers';

            %Support when behavioral files has 2 "versions"
            if length(log.version) > 1
                log.version = log.version(1);
            end

            % Check if location exist, and if not insert it
            lab.utils.check_location(log.version.rig.rig);
            key.session_location = log.version.rig.rig;

            key.set_id = 1;

            %Get session_performance
            [key.session_performance, ~, key.level, key.stimulus_bank] = self.getSessionPerformance(log.block);

            %Check for log.animal.protocol in file, not all beh files have it
            if isstruct(log.animal) && isfield(log.animal, 'protocol')
                protocol3 = func2str(log.animal.protocol);
            else
                protocol3 = '';
            end

            %Prepare session_protocol
            session_protocol = [ func2str(log.version.code) '.m' ' ', ...
                log.version.name '.mat' ' ', ...
                protocol3];

            key.session_protocol = session_protocol;

            %Get commit version of session
            commit = strsplit(log.version.repository);
            commit = commit{1};
            key.stimulus_commit   = commit;


            %Session code_version
            key.session_code_version = {log.version.mazeVersion, log.version.codeVersion};

            %Get num_trials & num_trials_try
            if isfield(log, 'numTrials') && isfield(log, 'numTrialsTry')
                key.num_trials       = log.numTrials;
                key.num_trials_try   = log.numTrialsTry;
            else
                key.num_trials       = -1;
                key.num_trials_try   = [];
            end

            %and insert this session:
            insert(acquisition.Session, key)

            %Update water earned from behavioral file
            water_earned_key = struct();
            water_earned_key.subject_fullname = key.subject_fullname;
            water_earned_key.session_date = key.session_date;
            updateWaterEarnedFromFile(action.WaterAdministration, water_earned_key, log);

            %Insert sessionManipulation if present
            session_key = struct();
            session_key.subject_fullname = key.subject_fullname;
            session_key.session_date     = key.session_date;
            session_key.session_number   = key.session_number;
            insertSessionManipulation(acquisition.SessionManipulation, session_key, log);

        end

        function updateSessionFromFile_Towers(self,key,log)
            % Update session record from behavioralfile in towersTask
            % Called at the end of training or when populating session
            % Input
            % self         = acquisition.Session instance
            % key  = structure with required fields: (subject_fullname, date, session_no)
            % log          = behavioral file as stored in Virmen

            %Update end time
            session_end_time = sprintf('%d-%02d-%02d %02d:%02d:00', log.session.end(1), log.session.end(2), log.session.end(3), log.session.end(4), log.session.end(5));
            update(acquisition.Session & key, 'session_end_time', session_end_time)

            %Support when behavioral files has 2 "versions"
            if length(log.version) > 1
                log.version = log.version(1);
            end

            % Check if location exist, and if not insert it
            lab.utils.check_location(log.version.rig.rig);
            session_location = log.version.rig.rig;
            update(acquisition.Session & key, 'session_location', session_location)

            %Get session_performance
            [session_performance, ~, level] = self.getSessionPerformance(log.block);
            update(acquisition.Session & key, 'session_performance', session_performance)
            update(acquisition.Session & key, 'level', level)

            %Get num_trials & num_trials_try
            if isfield(log, 'numTrials') && isfield(log, 'numTrialsTry')
                num_trials       = log.numTrials;
                num_trials_try   = log.numTrialsTry;
            else
                num_trials       = -1;
                num_trials_try   = [];
            end

            update(acquisition.Session & key, 'num_trials', num_trials)
            update(acquisition.Session & key, 'num_trials_try', num_trials_try)

            %Update water earned from behavioral file
            water_earned_key = struct();
            water_earned_key.subject_fullname = key.subject_fullname;
            water_earned_key.session_date = key.session_date;
            updateWaterEarnedFromFile(action.WaterAdministration, water_earned_key, log);

            %Insert sessionManipulation if present
            session_key = struct();
            session_key.subject_fullname = key.subject_fullname;
            session_key.session_date     = key.session_date;
            session_key.session_number   = key.session_number;
            insertSessionManipulation(acquisition.SessionManipulation, session_key, log);

        end

        function [session_performance, num_trials, level, stimulus_bank] = getSessionPerformance(self, block)
            % Calculate SessionPerformance for session
            % Inputs
            % block         = block field of behavioral file
            % Outputs
            % performance   = performance during session
            % num_trials    = number of trials in session
            % level         = last level (maze) in session
            % stimulus_bank = path to stimulus bank used during session

             %Get session_performance
            correct_number = 0;
            num_trials = 0;
            for block_idx = 1:length(block)
                trialstruct = block(block_idx);

                %Get stimulus_bank and level from last block of session
                stimulus_bank = trialstruct.stimulusBank;
                level = trialstruct.mainMazeID;

                %Calculate correct trials for block
                for itrial = 1:length(trialstruct.trial)
                    trial = trialstruct.trial(itrial);
                    if isempty(trial.trialType)
                        break;
                    end
                    if isnumeric(trial.choice)
                        correct_number = correct_number + double(single(trial.trialType) == single(trial.choice));
                    else
                        correct_number = correct_number + strcmp(trial.trialType.char, trial.choice.char);
                    end
                    num_trials = num_trials + 1;
                end
            end
            %Calculate performance, (support when 0 trials)
            if num_trials ~= 0
                session_performance = correct_number*100 / num_trials;
            else
                session_performance = 0;
            end
        end

    end
end
