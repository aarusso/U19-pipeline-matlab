%{
-> acquisition.Session
block                       : tinyint                       # block number
---
%}


%     'CREATE TABLE `u19_behavior`.`_test_towers_block` (
%      `subject_fullname` varchar(64) NOT NULL COMMENT "username_mouse_nickname",
%      `session_date` date NOT NULL COMMENT "date of experiment",
%      `session_number` int NOT NULL COMMENT "number",
%      `block` tinyint NOT NULL COMMENT "block number",
%      `task` varchar(32) NOT NULL COMMENT "",
%      `level` int NOT NULL COMMENT "difficulty level",
%      `set_id` int NOT NULL DEFAULT "1" COMMENT "parameter set id",
%      PRIMARY KEY (`subject_fullname`,`session_date`,`session_number`,`block`),
%      CONSTRAINT `-_P1hFgw` FOREIGN KEY (`subject_fullname`,`session_date`,`session_number`) REFERENCES `u19_behavior`.`_towers_session` (`subject_fullname`,`session_date`,`session_number`) ON UPDATE CASCADE ON DELETE RESTRICT,
%      CONSTRAINT `g7P9uUf6` FOREIGN KEY (`task`,`level`,`set_id`) REFERENCES `u19_task`.`#task_level_parameter_set` (`task`,`level`,`set_id`) ON UPDATE CASCADE ON DELETE RESTRICT
%      ) ENGINE = InnoDB, COMMENT ""'

classdef SessionBlock < dj.Imported
    properties
        %keySource = acquisition.Session & acquisition.SessionStarted
        %keySource = proj(acquisition.Session, 'level->na_level') * ...
        %         proj(acquisition.SessionStarted, 'session_location->na_location', 'remote_path_behavior_file')
    end
    methods(Access=protected)
        function makeTuples(self, key)
            
            [status, data] = lab.utils.read_behavior_file(key);            
            if status
                try
                    %Check if it is a real behavioral file
                    log = data.log;
                    if isfield(log, 'session')
                        %Insert Blocks and trails from BehFile
                        self.insertSessionBlockFromFile(key,log)
                    else
                        disp(['File does not match expected Towers behavioral file: ', data_dir])
                    end
                catch err
                    disp(err.message)
                    sprintf('Error in here: %s, %s, %d',err.stack(1).file, err.stack(1).name, err.stack(1).line )
                end
            end
            
        end
        
    end
    
    % Public methods
    methods
        function insertSessionBlockFromFile(self, key,log)
            % Insert blocks and blocktrials record from behavioralfile
            % Called at the end of training or when populating towersBlock
            % Input
            % self = behavior.TowersBlock instance
            % key  = behavior.TowersSession key (subject_fullname, date, session_no)
            % log  = behavioral file as stored in Virmen
            
            for iBlock = 1:length(log.block)
                tuple = key;          
                tuple.block = iBlock;
              
                self.insert(tuple);
                
                nTrials = length([log.block(iBlock).trial.choice]);
                for itrial = 1:nTrials        
                    tuple_trial = tuple;
                    tuple_trial.trial_idx = itrial;
                 
                    insert(acquisition.SessionBlockTrial, tuple_trial)
                end
            end
        end
    end
end



