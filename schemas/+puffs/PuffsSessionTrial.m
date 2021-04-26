%{
-> acquisition.SessionBlockTrial
-> puffs.PuffsSession
---
-> task.TaskLevelParameterSet
trial_type                  : enum('L','R')                 # answer of this trial, left or right
choice                      : enum('L','R','nil')           # choice of this trial, left or right
answered_correct            : int
trial_prior_p_left          : float                         # prior probablity of this trial for left
trial_rel_start             : float                         # start time of the trial relative to the beginning of the session [seconds]
trial_rel_finish            : float                         # end time of the trial relative to the beginning of the session [seconds]
trial_duration              : float                         # duration of the trial [seconds]
cue_period                  : float                         # duration of cue period [seconds]
num_puffs_intended_l        : tinyint                       # number of puffs intended on the left side
num_puffs_received_r        : tinyint                       # number of puffs actually received on the right side
num_puffs_intended_r        : tinyint                       # number of puffs intended on the right side
num_puffs_received_l        : tinyint                       # number of puffs actually received on the left side
reward_rel_start            : float                         # timing of reward relative to the beginning of the session [seconds]
reward_scale                : float                         # subject is given 4 microliters * reward_scale as a reward
rule                        : tinyint                       # 
%}


classdef PuffsSessionTrial < dj.Manual
end