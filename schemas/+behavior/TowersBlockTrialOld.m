%{
-> acquisition.SessionBlockTrial
-> behavior.TowersBlock
---
trial_type:                 enum('L', 'R')               # answer of this trial, left or right
choice:                     enum('L', 'R', 'nil')   # choice of this trial, left or right
trial_time:                 longblob # time series of this trial, start from zero for each trial
trial_abs_start:            float    # absolute start time of the trial realtive to the beginning of the session
collision:                  longblob # boolean vector indicating whether the subject hit the maze on each time point
cue_presence_left:          blob     # boolean vector for the presence of the towers on the left
cue_presence_right:         blob     # boolean vector for the presence of the towers on the right
cue_onset_left=null:        blob     # onset time of the cues on the left (only for the present ones)
cue_onset_right=null:       blob     # onset time of the cues on the right (only for the present ones)
cue_offset_left=null:       blob     # offset time of the cues on the left (only for the present ones)
cue_offset_right=null:      blob     # offset time of the cues on the right (only for the present ones)
cue_pos_left=null:          blob     # position of the cues on the left (only for the present ones)
cue_pos_right=null:         blob     # position of the cues on the right (only for the present ones)
trial_duration:             float    # duration of the entire trial
excess_travel:              float    #
i_arm_entry:                int      # the index of the time series when the mouse enters the arm part
i_blank:                    int      # the index of the time series when the mouse enters the blank zone
i_cue_entry:                int      # the index of the time series when the mouse neters the cue zone
i_mem_entry:                int      # the index of the time series when the mouse enters the memory zone
i_turn_entry:               int      # the index of the time series when the mouse enters turns
iterations:                 int      # length of the meaningful recording
position:                   longblob # 3d recording of the position of the mouse, length equals to interations
velocity:                   longblob # 3d recording of the velocity of the mouse, length equals to interations
sensor_dots:                longblob # raw recordings of the ball
trial_id:                   int      #
trial_prior_p_left:         float    # prior probablity of this trial for left
vi_start:                   int      #
%}

classdef TowersBlockTrialOld < dj.Part
    properties(SetAccess=protected)
        master = behavior.TowersBlock
    end
    
    methods
        
        function ingestFromBehaviorBlockTrial(self)
            %Function to copy over trials from behavior.TowersBlockTrial -> behavior.TowersBlockTrials
            
            all_sessions = fetch(acquisition.Session - self);
            
            %For all sessions
            num_sessions = length(all_sessions);
            for i=1:num_sessions
                
                [i num_sessions]
                
                %Get trial information and insert
                trial_info = fetch(behavior.TowersBlockTrial & all_sessions(i), '*');
                tic
                if ~isempty(trial_info)
                    insert(self, trial_info, 'IGNORE');
                end
                toc
                
            end
            
        end
        
        
    end
    
end