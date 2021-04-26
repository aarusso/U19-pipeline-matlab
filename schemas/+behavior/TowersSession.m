%{
-> acquisition.Session
-----
stimulus_set:          tinyint   # an integer that describes a particular set of stimuli in a trial
ball_squal:            float     # quality measure of ball data
rewarded_side:         blob      # Left or Right X number trials
chosen_side:           blob      # Left or Right X number trials
maze_id:               blob      # level X number trials
num_towers_r:          blob      # Number of towers shown to the right x number of trials
num_towers_l:          blob      # Number of towers shown to the left x tumber of trials
%}

classdef TowersSession < dj.Imported
    
    properties
        keySource = acquisition.Session & struct('task', 'Towers');
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            %Get behavioral file to load
            data_dir = fetch1(acquisition.SessionStarted & key, 'remote_path_behavior_file');
            
            
            %Load behavioral file
            try
                [~, data_dir] = lab.utils.get_path_from_official_dir(data_dir);
                data = load(data_dir,'log');
                log = data.log;
                status = 1;
            catch
                disp(['Could not open behavioral file: ', data_dir])
                status = 0;
            end
            if status
                try
                    %Check if it is a real behavioral file
                    if isfield(log, 'session')
                        %Insert Blocks and trails from BehFile
                        self.insertTowersSessionFromFile(key, log);
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

methods

function insertTowersSessionFromFile(self, key,  log)
% Insert towers session record from behavioralfile
% Called at the end of training or when populating TowersSession
% Input
% self = behavior.Session instance
% key  = acquisition.Session key (subject_fullname, date, session_no)
% log  = behavioral file as stored in Virmen

%Write stimulus_set
if isstruct(log.animal) && isfield(log.animal, 'stimulusSet') && ~isnan(log.animal.stimulusSet)
    key.stimulus_set = log.animal.stimulusSet;
else
    key.stimulus_set = -1;
end

%Initialize variables to concatenate
key.rewarded_side = [];
key.chosen_side = [];
key.maze_id = [];
key.num_towers_r = [];
key.num_towers_l = [];

%For each block get all variables
for block_idx = 1:length(log.block)
    trialstruct = log.block(block_idx);
    
    % Get only "complete" trials (sometimes behavioral file has a lot of empty ones)
    nTrials = length([trialstruct.trial.choice]);
    trialstruct.trial = trialstruct.trial(1:nTrials);
    
    rewarded_side = double([trialstruct.trial.trialType]);
    chosen_side = double([trialstruct.trial.choice]);
    %Repeat maze id for each trial
    maze_id = repmat(trialstruct.mazeID, size(chosen_side));
    
    %Separate cueCombo to get towersR and towersL
    cueCombo = {trialstruct.trial.cueCombo};
    num_towers_r = cellfun(@(x) sum(x(Choice.R,:)), cueCombo);
    num_towers_l = cellfun(@(x) sum(x(Choice.L,:)), cueCombo);
    
    
    %Concatenate variables
    key.rewarded_side = [key.rewarded_side rewarded_side];
    key.chosen_side = [key.chosen_side chosen_side];
    key.maze_id = [key.maze_id maze_id];
    key.num_towers_r = [key.num_towers_r num_towers_r];
    key.num_towers_l = [key.num_towers_l num_towers_l];
    
end

%Support when behavioral files has 2 "versions"
if length(log.version) > 1
    log.version = log.version(1);
end

% Squal not saved in behavorial file before 2020-11-01
if isfield(log.version.rig, 'squal')
    key.ball_squal = log.version.rig.squal;
else
    key.ball_squal = -1;
end

%Finally insert record
self.insert(key);


end

end
end