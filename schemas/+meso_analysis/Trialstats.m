%{
# behavioral info by trial
-> imaging.Scan
trial_idx                    : int       # virmen trial struct number
---
 
went_right                   : tinyint   # true when mouse turned right
went_left                    : tinyint   # true when mouse turned left
is_right_trial               : tinyint   # true when trial type is right
is_left_trial                : tinyint   # true when trial type is left
is_correct                   : tinyint   # true when choice is correct
is_error                     : tinyint   # true when choice is incorrect
is_towers_task               : tinyint   # true when trial is towers task
is_visguided_task            : tinyint   # true when trial is visually-guided task
is_hard                      : tinyint   # for towers task, whether trial is on top 50th prctile of trial difficulty -- delta_towers / total_towers
is_easy                      : tinyint   # for towers task, whether trial is on bottom 50th prctile of trial difficulty -- delta_towers / total_towers
has_distractor_towers        : tinyint   # true if trial has towers on non-majority side
has_no_distractor_towers     : tinyint   # true if trial does not have towers on non-majority side
is_excess_travel             : tinyint   # true if total travel > 1.1*nominal maze length
is_not_excess_travel         : tinyint   # true if total travel < 1.1*nominal maze length
is_first_trial_in_block      : tinyint   # true if first trial in a block 
time                         : blob      # 1 x virmen iterations, clock time starting from zero on each trial
position_x                   : blob      # 1 x virmen iterations, x position in the maze
position_y                   : blob      # 1 x virmen iterations, y position in the maze
position_theta               : blob      # 1 x virmen iterations, view angle position in the maze
dx                           : blob      # 1 x virmen iterations, x displacement in the maze
dy                           : blob      # 1 x virmen iterations, y  displacement in the maze
dtheta                       : blob      # 1 x virmen iterations, view angle  displacement in the maze
raw_sensor_data              : blob      # 5 x virmen iterations, raw readings from the velocity sensors
run_speed_instant            : blob      # instantaneous running speed from x-y displacement
run_speed_avg_stem           : float     # average running speed at 0 < position_y < 300
excess_travel                : float     # distance traveled normalized by nominal maze length
trial_dur_sec                : float     # total trial duration in sec
total_stem_displacement      : float     # total x-y displacement in maze stem
block_id                     : int       # identity of the trial block
mean_perf_block              : float     # average performance during that block
mean_bias_block              : float     # average side bias during that block
stim_train_id                : int       # identity of the stimulus train in the trial
left_draw_generative_prob    : float     # underlying generative probability of drawing and left trial
cue_pos_right=NULL           : blob      # array with y positions of right towers
cue_pos_left=NULL            : blob      # array with y positions of left towers
cue_onset_time_right=NULL    : blob      # array with onset times of right towers
cue_onset_time_left=NULL     : blob      # array with onset times of left towers
cue_offset_time_right=NULL   : blob      # array with offset times of right towers
cue_offset_time_left=NULL    : blob      # array with offset times of left towers
ncues_right                  : int       # total number of right towers
ncues_left                   : int       # total number of left towers
ncues_right_minus_left       : int       # ncues_right_minus_left / ncues_total
ncues_total                  : int       # grand total number of towers on both sides
trial_difficulty             : float     # average performance during that block
true_cue_period_length_cm    : int       # effective y length of cue period, ie between first and last tower
true_mem_period_length_cm    : int       # effective y length of delay period, ie between last tower and end of stem
true_cue_period_dur_sec      : int       # effective duration of cue period in sec, ie between first and last tower
true_mem_period_dur_sec      : int       # effective duration of memory period in sec, ie between last tower and end of stem
meso_frame_per_virmen_iter   : blob      # array with imaging frame ids per virmen iteration
meso_frame_unique_ids        : blob      # array with unique imaging frame ids per behavioral trial
behav_time_by_meso_frame     : blob      # average behavior clock time per imaging frame
position_x_by_meso_frame     : blob      # average x position per imaging frame
position_y_by_meso_frame     : blob      # average y position per imaging frame
position_theta_by_meso_frame : blob      # average theta position per imaging frame
dx_by_meso_frame             : blob      # average x position per imaging frame
dy_by_meso_frame             : blob      # average y position per imaging frame
dtheta_by_meso_frame         : blob      # average theta position per imaging frame
cues_by_meso_frame_right     : blob      # total number of right towers per imaging frame (should typically be ones and zeros)
cues_by_meso_frame_left      : blob      # total number of right towers per imaging frame (should typically be ones and zeros)
trial_start_meso_frame=NULL  : int       # imaging frame id corresponding to trial start
cue_entry_meso_frame=NULL    : int       # imaging frame id corresponding to cue period start
mem_entry_meso_frame=NULL    : int       # imaging frame id corresponding to delay period start
arm_entry_meso_frame=NULL    : int       # imaging frame id corresponding to entry in the side arm
trial_end_meso_frame=NULL    : int       # imaging frame id corresponding to trial end (= reward time in correct trials)
iti_meso_frame=NULL          : int       # imaging frame id corresponding to start of ITI
timeout_meso_frame=NULL      : int       # imaging frame id corresponding to start of extra ITI (ie timeout) for error trials
iti_end_meso_frame=NULL      : int       # imaging frame id corresponding to end of ITI (last frame before next trial)
%}
 
 
classdef Trialstats < dj.Computed
  methods(Access=protected)
    function makeTuples(self, key)
      
      % handle key data type
      if ~isstruct(key)
        results = fetch(key);
      else
        results = key;
      end
      
      % get behavioral and sync info from DJ (nested)
      lg = getFlattenedLog(key); 
      
      % initialize data structure
      results.trial_idx = [];
      var_list          = {'went_right','went_left','is_right_trial','is_left_trial',                                ...
                           'is_correct','is_error','is_towers_task','is_visguided_task',                             ...
                           'is_hard','is_easy','has_distractor_towers','has_no_distractor_towers',                   ...
                           'is_excess_travel','is_not_excess_travel','is_first_trial_in_block','time',               ...
                           'position_x','position_y','position_theta','dx', 'dy', 'dtheta',                          ...
                           'raw_sensor_data','run_speed_instant','run_speed_avg_stem','excess_travel',               ...
                           'trial_dur_sec','total_stem_displacement','block_id','mean_perf_block',                   ...
                           'mean_bias_block','stim_train_id','left_draw_generative_prob','cue_pos_right',            ...
                           'cue_pos_left','cue_onset_time_right','cue_onset_time_left','cue_offset_time_right',      ...
                           'cue_offset_time_left','ncues_right','ncues_left','ncues_right_minus_left',               ...
                           'ncues_total','trial_difficulty','true_cue_period_length_cm','true_mem_period_length_cm', ...
                           'true_cue_period_dur_sec','true_mem_period_dur_sec','meso_frame_per_virmen_iter',         ...
                           'meso_frame_unique_ids','behav_time_by_meso_frame','position_x_by_meso_frame',            ...
                           'position_y_by_meso_frame','position_theta_by_meso_frame','dx_by_meso_frame',             ...
                           'dy_by_meso_frame','dtheta_by_meso_frame','cues_by_meso_frame_right',                     ...
                           'cues_by_meso_frame_left','trial_start_meso_frame','cue_entry_meso_frame',                ...
                           'mem_entry_meso_frame','arm_entry_meso_frame','timeout_meso_frame',                       ...
                           'iti_meso_frame','trial_end_meso_frame','iti_end_meso_frame'  ...
                           };
      for iVar = 1:numel(var_list)
        results.(var_list{iVar}) = [];
      end
      
      % loop through trials to fill structure array, transform nan's into
      % -1s for non-blob variables
      num_trials = numel(lg.choice);
      results    = repmat(results,[1 num_trials]);
      for iTrial = 1:num_trials
        results(iTrial).trial_idx = iTrial;
        for iVar = 1:numel(var_list)
          if iscell(lg.(var_list{iVar})(iTrial))
            results(iTrial).(var_list{iVar}) = lg.(var_list{iVar}){iTrial};
          else
            thisvar = lg.(var_list{iVar})(iTrial);
            if isnan(thisvar); thisvar = -1; end
            results(iTrial).(var_list{iVar}) = thisvar;
          end
        end
      end
      
       %chop structure if SI started later
      VirmenIterOn = ~arrayfun(@(x)isempty(x.meso_frame_per_virmen_iter),results);
      results = results(VirmenIterOn);
      
      % write to table in one go
      self.insert(results)
    end
  end
end
 
 
% =========================================================================
%% get flattened log
function lg = getFlattenedLog(key)
 
%% load data from dj and create flattened format
blockData  = fetch(behavior.TowersBlock & key,'level');
nBlocks    = numel(blockData);
 
lg         = initLog; % start empty matrices
 
for iBlock = 1:nBlocks
  % some trial data (choice, trial type, excess travel)
  trialData  = fetch(behavior.TowersBlockTrial & key & sprintf('block = %d',iBlock),          ...
                     'trial_type','choice','excess_travel','trial_abs_start','trial_id',      ...
                     'trial_prior_p_left','sensor_dots','trial_time','trial_duration',        ...
                     'position','i_cue_entry','i_arm_entry','cue_pos_right','cue_pos_left',   ...
                     'cue_onset_right','cue_onset_left','cue_offset_right','cue_offset_left'  ...
                     );
  nTrials    = numel(trialData);
  
  if nTrials == 0; continue; end
  
  % block-wise data
  currMaze                                     = blockData(iBlock).level;
  lg.currMaze(end+1:end+nTrials)               = uint8(currMaze.*ones(1,nTrials));
  firstTrialVec                                = false(1,nTrials);
  firstTrialVec(1)                             = true;
  lg.is_first_trial_in_block(end+1:end+nTrials)= firstTrialVec;
  lg.block_id(end+1:end+nTrials)               = uint8(blockData(iBlock).block.*ones(1,nTrials));
  
  % trial_wise data
  trialType                                    = {trialData(:).trial_type};
  trialType(strcmp(trialType,'R'))             = {analysisParams.rightCode};
  trialType(strcmp(trialType,'L'))             = {analysisParams.leftCode};
  trialType                                    = cell2mat(trialType);
  lg.trialType(end+1:end+nTrials)              = single(trialType);
  
  choice                                       = {trialData(:).choice};
  choice(strcmp(choice,'R'))                   = {analysisParams.rightCode};
  choice(strcmp(choice,'L'))                   = {analysisParams.leftCode};
  choice(strcmp(choice,'nil'))                 = {nan};
  choice                                       = cell2mat(choice);
  lg.choice(end+1:end+nTrials)                 = single(choice);
  excess_travel                                = [trialData(:).excess_travel];
  lg.excess_travel(end+1:end+nTrials)          = single(excess_travel);
  
  % block-wise performance for finished trials with acceptable excess travel
  goodidx = excess_travel < .1 & ~isnan(choice);
  Ridx    = trialType == analysisParams.rightCode;
  Lidx    = trialType == analysisParams.leftCode;
  perf    = sum(choice(goodidx) == trialType(goodidx))/sum(goodidx);
  perfR   = sum(choice(goodidx & Ridx) == trialType(goodidx & Ridx))/sum(goodidx & Ridx);
  perfL   = sum(choice(goodidx & Lidx) == trialType(goodidx & Lidx))/sum(goodidx & Lidx);
  
  lg.mean_perf_block(end+1:end+nTrials) = single(perf.*ones(1,nTrials));
  lg.mean_bias_block(end+1:end+nTrials) = single((perfR-perfL).*ones(1,nTrials));
  
  % some more trial data 
  lg.startTime(end+1:end+nTrials)                     = single([trialData(:).trial_abs_start]);
  lg.stim_train_id(end+1:end+nTrials)                 = int64([trialData(:).trial_id]);
  lg.left_draw_generative_prob(end+1:end+nTrials)     = single([trialData(:).trial_prior_p_left]);
  lg.raw_sensor_data(end+1:end+nTrials)               = {trialData(:).sensor_dots};
  time                                                = {trialData(:).trial_time};
  lg.time(end+1:end+nTrials)                          = time;
  lg.trial_dur_sec(end+1:end+nTrials)                 = single([trialData(:).trial_duration]);
  
  % position, displacement & speed
  position                                 = {trialData(:).position};
  displacement                             = cell(size(position));
  inst_speed                               = cell(size(position));
  total_stem_displace                      = zeros(1,numel(position));
  speed_avg_stem                           = zeros(1,numel(position));
  for iTrial = 1:numel(position)
    position{iTrial}(:,3)      = -rad2deg(position{iTrial}(:,3)); % convert view angle to deg
    displacement{iTrial}       = [0 0 0; diff(position{iTrial})]; % displacement in Maze, cell array; [x y angle]
    if trialData(iTrial).i_cue_entry > 0
      stemXYdispl              = displacement{iTrial}(trialData(iTrial).i_cue_entry:trialData(iTrial).i_arm_entry-1,1:2); % total XY displacement in Maze stem
    else
      stemXYdispl              = 0;
    end
    all_displ                   = sqrt(sum(displacement{iTrial}(:,1:2).^2,2)); 
    dt                          = [0; diff(time{iTrial})];
    inst_speed{iTrial}          = all_displ ./ dt(1:numel(all_displ));
    total_stem_displace(iTrial) = sum(sqrt(sum(stemXYdispl.^2,2))); % total displacement in stem
    
    if trialData(iTrial).i_cue_entry > 0
      if trialData(iTrial).i_arm_entry > 0
        speed_avg_stem(iTrial)  = total_stem_displace(iTrial)/...
                                           (time{iTrial}(trialData(iTrial).i_arm_entry) - time{iTrial}(trialData(iTrial).i_cue_entry)); % speed in maze stem
      else
        speed_avg_stem(iTrial)  = total_stem_displace(iTrial)/...
                                         (time{iTrial}(size(position{iTrial},1)) - time{iTrial}(trialData(iTrial).i_cue_entry)); % speed in maze stem
      end
    else
      speed_avg_stem(iTrial)    = nan;
    end
  end
  lg.pos(end+1:end+nTrials)                         = position;
  lg.displ(end+1:end+nTrials)                       = displacement;
  lg.run_speed_instant(end+1:end+nTrials)           = inst_speed;
  lg.total_stem_displacement(end+1:end+nTrials)     = total_stem_displace;
  lg.run_speed_avg_stem(end+1:end+nTrials)          = single(speed_avg_stem);
 
  % key frames (virmen iterations)
  i_cue_entry = nan(1,numel(position));
  i_mem_entry = nan(1,numel(position));
  i_arm_entry = nan(1,numel(position));
  i_reward    = nan(1,numel(position));
  i_iti       = nan(1,numel(position));
  i_timeout   = nan(1,numel(position));
  
  for iTrial = 1:numel(position)
    if isnan(choice(iTrial)); continue; end
    i_cue_entry(iTrial) = find(position{iTrial}(:,2) >= 0, 1, 'first');
    i_mem_entry(iTrial) = find(position{iTrial}(:,2) >= 200, 1, 'first');
    i_arm_entry(iTrial) = find(abs(position{iTrial}(:,1)) > 1, 1, 'first'); % using y position is not good when they cut the corner, use x instead
    i_reward(iTrial)    = size(position{iTrial},1);
    i_iti(iTrial)       = size(position{iTrial},1)+1; % iti starts after last recorded position
    if choice(iTrial) ~= trialType(iTrial)
      i_timeout(iTrial) = find(time{iTrial} >= time{iTrial}(i_iti(iTrial))+3,1,'first'); % for error trials, extra timeout is 3 s after regular iti
    end
  end
  
  lg.i_cue_entry(end+1:end+nTrials)  = i_cue_entry;
  lg.i_mem_entry(end+1:end+nTrials)  = i_mem_entry;
  lg.i_arm_entry(end+1:end+nTrials)  = i_arm_entry;
  lg.i_reward(end+1:end+nTrials)     = i_reward;
  lg.i_iti(end+1:end+nTrials)        = i_iti;
  lg.i_timeout(end+1:end+nTrials)    = i_timeout;
  
  % towers
  lg.cue_pos_right(end+1:end+nTrials)           = {trialData(:).cue_pos_right};
  lg.cue_pos_left(end+1:end+nTrials)            = {trialData(:).cue_pos_left};
  
  % onsets are iterations not time
  on_r  = cell(1,nTrials);
  on_l  = cell(1,nTrials);
  off_r = cell(1,nTrials);
  off_l = cell(1,nTrials);
  for iTrial = 1:nTrials
    % unreached cues are recorded as zeroth iteration
    if any(trialData(iTrial).cue_onset_right == 0)
      zero_idx      = trialData(iTrial).cue_onset_right == 0;
      thisvec       = ones(1,sum(zero_idx)) * -1;
      thisvec(~zero_idx) = time{iTrial}(trialData(iTrial).cue_onset_right(~zero_idx))';
      on_r{iTrial}  = thisvec;
    else
      % if the iteration is off, infer from cue position (cue appears 10 cm away from mouse)
      if any(trialData(iTrial).cue_onset_right > numel(time{iTrial}))
        for iTower = 1:numel(trialData(iTrial).cue_pos_right)
          on_r{iTrial}(:,iTower) = time{iTrial}(find(position{iTrial}(:,2) >= trialData(iTrial).cue_pos_right(iTower)-10,1,'first'));
        end
      else
        on_r{iTrial}  = time{iTrial}(trialData(iTrial).cue_onset_right)';
      end
    end
    
    if any(trialData(iTrial).cue_onset_left == 0)
      zero_idx      = trialData(iTrial).cue_onset_left == 0;
      thisvec       = ones(1,sum(zero_idx)) * -1;
      thisvec(~zero_idx) = time{iTrial}(trialData(iTrial).cue_onset_left(~zero_idx));
      on_l{iTrial}  = thisvec;
    else
      if any(trialData(iTrial).cue_onset_left > numel(time{iTrial}))
        for iTower = 1:numel(trialData(iTrial).cue_pos_left)
          on_l{iTrial}(:,iTower) = time{iTrial}(find(position{iTrial}(:,2) >= trialData(iTrial).cue_pos_left(iTower)-10,1,'first'));
        end
      else
        on_l{iTrial}  = time{iTrial}(trialData(iTrial).cue_onset_left)';
      end
    end
    
    if any(trialData(iTrial).cue_offset_right == 0)
      zero_idx      = trialData(iTrial).cue_offset_right == 0;
      thisvec       = ones(1,sum(zero_idx)) * -1;
      thisvec(~zero_idx) = time{iTrial}(trialData(iTrial).cue_offset_right(~zero_idx));
      off_r{iTrial}  = thisvec;
    else
      if any(trialData(iTrial).cue_offset_right > numel(time{iTrial}))
        off_r{iTrial}  = on_r{iTrial} + .2; % 200-ms towers
      else
        off_r{iTrial}  = time{iTrial}(trialData(iTrial).cue_offset_right)';
      end
    end
    
    if any(trialData(iTrial).cue_offset_left == 0)
      zero_idx      = trialData(iTrial).cue_offset_left == 0;
      thisvec       = ones(1,sum(zero_idx)) * -1;
      thisvec(~zero_idx) = time{iTrial}(trialData(iTrial).cue_offset_left(~zero_idx));
      off_l{iTrial}  = thisvec;
    else
      if any(trialData(iTrial).cue_offset_left > numel(time{iTrial}))
        off_l{iTrial}  = on_l{iTrial} + .2; % 200-ms towers
      else
        off_l{iTrial}  = time{iTrial}(trialData(iTrial).cue_offset_left)';
      end
    end
  end
  
  lg.cue_onset_time_right(end+1:end+nTrials)    = on_r;
  lg.cue_onset_time_left(end+1:end+nTrials)     = on_l;
  lg.cue_offset_time_right(end+1:end+nTrials)   = off_r;
  lg.cue_offset_time_left(end+1:end+nTrials)    = off_l;
  
 
end
 
%% record more easy-access variables
 
% trial selection booleans
lg.went_right      = lg.choice == analysisParams.rightCode;
lg.went_left       = lg.choice == analysisParams.leftCode;
lg.is_right_trial  = lg.trialType == analysisParams.rightCode;
lg.is_left_trial   = lg.trialType == analysisParams.leftCode;
lg.is_correct      = lg.choice == lg.trialType;
lg.is_error        = lg.choice ~= lg.trialType;
lg.is_towers_task  = lg.currMaze == 11 | lg.currMaze == 10;
lg.is_visguided_task    = lg.currMaze == 12 | lg.currMaze == 4;
lg.is_excess_travel     = lg.excess_travel > 0.1;
lg.is_not_excess_travel = lg.excess_travel <= 0.1;
 
% divide position and displacement axes
lg.position_x     = cellfun(@(x)(x(:,1)),lg.pos,'uniformOutput',false);
lg.position_y     = cellfun(@(x)(x(:,2)),lg.pos,'uniformOutput',false);
lg.position_theta = cellfun(@(x)(x(:,3)),lg.pos,'uniformOutput',false);
lg.dx             = cellfun(@(x)(x(:,1)),lg.displ,'uniformOutput',false);
lg.dy             = cellfun(@(x)(x(:,2)),lg.displ,'uniformOutput',false);
lg.dtheta         = cellfun(@(x)(x(:,3)),lg.displ,'uniformOutput',false);
 
% cues and effective durations
lg.ncues_right             = single(cell2mat(cellfun(@(x)(numel(x)),lg.cue_pos_right,'uniformOutput',false)));
lg.ncues_left              = single(cell2mat(cellfun(@(x)(numel(x)),lg.cue_pos_left,'uniformOutput',false)));
lg.ncues_right_minus_left  = lg.ncues_right - lg.ncues_left;
lg.ncues_total             = lg.ncues_right + lg.ncues_left;
lg.trial_difficulty        = 1 - (abs(lg.ncues_right_minus_left) ./ lg.ncues_total);
lg.is_hard                 = lg.trial_difficulty >= nanmedian(lg.trial_difficulty);
lg.is_easy                 = lg.trial_difficulty < nanmedian(lg.trial_difficulty);
lg.has_distractor_towers   = (lg.is_left_trial & lg.ncues_right > 0) | (lg.is_right_trial & lg.ncues_left > 0);
lg.has_no_distractor_towers= (lg.is_left_trial & lg.ncues_right == 0) | (lg.is_right_trial & lg.ncues_left == 0);
 
maxr = cellfun(@max,lg.cue_pos_right,'UniformOutput',false);
maxl = cellfun(@max,lg.cue_pos_left,'UniformOutput',false);
minr = cellfun(@min,lg.cue_pos_right,'UniformOutput',false);
minl = cellfun(@min,lg.cue_pos_left,'UniformOutput',false);
for iT = 1:numel(maxr)
  maxrl(iT) = max([maxr{iT} maxl{iT}]);
  minrl(iT) = min([minr{iT} minl{iT}]);
end
lg.true_cue_period_length_cm  = maxrl - minrl;
lg.true_mem_period_length_cm  = 300 - lg.true_cue_period_length_cm;
 
maxr = cellfun(@max,lg.cue_onset_time_right,'UniformOutput',false);
maxl = cellfun(@max,lg.cue_onset_time_left,'UniformOutput',false);
minr = cellfun(@min,lg.cue_onset_time_right,'UniformOutput',false);
minl = cellfun(@min,lg.cue_onset_time_left,'UniformOutput',false);
mem  = zeros(size(maxr));
for iT = 1:numel(maxr)
  maxrl(iT) = max([maxr{iT} maxl{iT}]);
  minrl(iT) = min([minr{iT} minl{iT}]);
  mem(iT)   = lg.time{iT}(find(lg.position_y{iT} <= 300, 1, 'last'));
end
lg.true_cue_period_dur_sec = maxrl - minrl;
lg.true_mem_period_dur_sec = mem - maxrl;
 
%% info
lg.info.frameDtVirmen = mode(diff(lg.time{1}));
 
%% imaging sync
 
% field of view key
imagingSessKey          = fetch(imaging.FieldOfView & key & 'fov=2');
 
% frame rate
framerate               = fetch1(imaging.ScanInfo & key, 'frame_rate');
lg.info.frameDtImaging  = 1/framerate;
 
% sync info
syncInfo                = fetch(imaging.SyncImagingBehavior & imagingSessKey,                                                       ...
                               'sync_im_frame','sync_im_frame_global','sync_behav_block_by_im_frame',                            ...
                               'sync_behav_trial_by_im_frame','sync_behav_iter_by_im_frame','sync_im_frame_span_by_behav_block', ...
                               'sync_im_frame_span_by_behav_trial','sync_im_frame_span_by_behav_iter'                            ...
                              );
 
% imaging sync
lg                      = extractFrameTimeByTrials_mesoscope(lg,syncInfo,imagingSessKey);
  
 
 
end
 
% =========================================================================
%% initialize vectors
function lg = initLog 
 
lg.currMaze                  = [];
lg.is_first_trial_in_block   = [];
lg.block_id                  = [];
lg.trialType                 = [];
lg.choice                    = [];
lg.excess_travel             = [];
lg.mean_perf_block           = [];
lg.mean_bias_block           = [];
lg.startTime                 = [];
lg.stim_train_id             = [];
lg.left_draw_generative_prob = [];
lg.raw_sensor_data           = {};
lg.time                      = {};
lg.trial_dur_sec             = [];
lg.pos                       = {};
lg.displ                     = {};
lg.total_stem_displacement   = [];
lg.run_speed_avg_stem        = [];
lg.cue_pos_right             = {};
lg.cue_pos_left              = {};
lg.cue_onset_time_right      = {};
lg.cue_onset_time_left       = {};
lg.cue_offset_time_right     = {};
lg.cue_offset_time_left      = {};
lg.run_speed_instant         = {};
lg.i_cue_entry               = [];
lg.i_mem_entry               = [];
lg.i_arm_entry               = [];
lg.i_reward                  = [];
lg.i_iti                     = [];
lg.i_timeout                 = [];
 
end
 
% =========================================================================
%% sync with imaging
function lg = extractFrameTimeByTrials_mesoscope(lg,syncInfo,imagingSessKey)
 
% lg = extractFrameTimeByTrials_mesoscope(lg,syncInfo)
% aligns behavioral events to imaging frames on a trial-by-trial basis.
% Both provides imaging frame equivalents for every virmen frame and bins
% behavioral events at imaging frame frame
 
lg.meso_frame_per_virmen_iter = cellfun(@(x)(x(:,1)),syncInfo.sync_im_frame_span_by_behav_iter,'uniformOutput',false);
ntrials                       = numel(syncInfo.sync_im_frame_span_by_behav_trial);
lg.meso_frame_unique_ids      = cell(1,ntrials);
lg.behav_time_by_meso_frame   = cell(1,ntrials);
lg.cues_by_meso_frame_right   = cell(1,ntrials);
lg.cues_by_meso_frame_left    = cell(1,ntrials);
lg.binned_pos                 = cell(1,ntrials);
lg.binned_displ               = cell(1,ntrials);
  
for iTrial = 1:ntrials
 
  uniqueFrames                     = unique(lg.meso_frame_per_virmen_iter{iTrial});
  lg.meso_frame_unique_ids{iTrial} = uniqueFrames;
  
  lg.behav_time_by_meso_frame{iTrial} = nan(size(uniqueFrames));
  lg.binned_displ{iTrial}             = nan(numel(uniqueFrames),3);
  lg.binned_pos{iTrial}               = nan(numel(uniqueFrames),3);
  lg.cues_by_meso_frame_right{iTrial} = nan(size(uniqueFrames));
  lg.cues_by_meso_frame_left{iTrial}  = nan(size(uniqueFrames));
  for iFrame = 1:numel(uniqueFrames)
    idx = lg.meso_frame_per_virmen_iter{iTrial} == uniqueFrames(iFrame);
    
    % average over virmen frames
    lg.behav_time_by_meso_frame{iTrial}(iFrame) = nanmean(lg.time{iTrial}(idx));
    
    % displacement and position don' exist in ITI
    idx(size(lg.displ{iTrial},1)+1:end) = [];
    % position and displacement
    lg.binned_displ{iTrial}(iFrame,:) = nanmean(lg.displ{iTrial}(idx,:),1);
    pos_range                         = lg.pos{iTrial}(idx,:);
    lg.binned_pos{iTrial}(iFrame,:)   = nanmean(pos_range,1);
 
    % number of towers within imaging frame
    if isempty(pos_range); continue; end
    lg.cues_by_meso_frame_right{iTrial}(iFrame) = sum(lg.cue_pos_right{iTrial} > pos_range(1,2) & lg.cue_pos_right{iTrial} <= pos_range(end,2));
    lg.cues_by_meso_frame_left{iTrial}(iFrame)  = sum(lg.cue_pos_left{iTrial} > pos_range(1,2) & lg.cue_pos_left{iTrial} <= pos_range(end,2));
    
  end
end
 
% divide position and displacement axes
lg.position_x_by_meso_frame     = cellfun(@(x)(x(:,1)),lg.binned_pos,'uniformOutput',false);
lg.position_y_by_meso_frame     = cellfun(@(x)(x(:,2)),lg.binned_pos,'uniformOutput',false);
lg.position_theta_by_meso_frame = cellfun(@(x)(x(:,3)),lg.binned_pos,'uniformOutput',false);
lg.dx_by_meso_frame             = cellfun(@(x)(x(:,1)),lg.binned_displ,'uniformOutput',false);
lg.dy_by_meso_frame             = cellfun(@(x)(x(:,2)),lg.binned_displ,'uniformOutput',false);
lg.dtheta_by_meso_frame         = cellfun(@(x)(x(:,3)),lg.binned_displ,'uniformOutput',false);
 
% key frames 
lg = getKeyFrames(lg,syncInfo,imagingSessKey);
 
end
 
% =========================================================================
%% imaging frames of key trial events
function lg = getKeyFrames(lg,syncInfo,key)
 
% get first and last frame for each trial
span_perTrial = syncInfo.sync_im_frame_span_by_behav_trial;
iter2frame    = syncInfo.sync_im_frame_span_by_behav_iter;
globalFrame   = syncInfo.sync_im_frame_global;
 
span_perTrial = cell2mat(span_perTrial'); % reformat to tr x 2
 
lg.trial_start_meso_frame = span_perTrial(:,1);
lg.iti_end_meso_frame     = span_perTrial(:,2);
 
% rebinFactor as calculated in runNeuronSegmentation_mesoscope()
%[timeResolution, frameRate] = fetchn(imaging.SegParameterSetParameter & key,'cnmf_time_resolution','cnmf_frame_rate');
%rebinFactor                 = ceil(timeResolution / (1000/frameRate));
%MDia set rebin factor to 1 (no binning)
rebinFactor                  = 1;

% in case cnmf resolution ~= native imaging resolution
frame2globalFrame           = num2cell(1 + floor( (globalFrame - 1) / rebinFactor ));
%% DEAL WITH THIS: Due to temporal downsampling the same CNMF data point can be assigned to two different
%        behavioral iterations; this is a particular problem at the beginning/end of trials as it
%        doesn't make sense for dF/F to be assigned to two trials. An arbitrary choice is made to
%        assign these ambiguous frames to the first trial (for reasons of causality of responses)
% convert virmen iteration w/in trial index to global frame number
 
lg.cue_entry_meso_frame = event_iter2frame(lg.i_cue_entry, iter2frame, frame2globalFrame);
lg.mem_entry_meso_frame = event_iter2frame(lg.i_mem_entry, iter2frame, frame2globalFrame);
lg.arm_entry_meso_frame = event_iter2frame(lg.i_arm_entry, iter2frame, frame2globalFrame);
lg.trial_end_meso_frame = event_iter2frame(lg.i_reward, iter2frame, frame2globalFrame);
lg.iti_meso_frame       = event_iter2frame(lg.i_iti, iter2frame, frame2globalFrame);
lg.timeout_meso_frame   = event_iter2frame(lg.i_timeout, iter2frame, frame2globalFrame);
 
end
 
% =========================================================================
%% virmen iteration to imaging frame
function [event_frame] = event_iter2frame(event_iteration, iter2frame, frame2globalFrame)
%%%% in getBehaviorPlusImaging_mesoscope(); [tEvent, frame] = getEventTime(iteration, reg, sync, cnmf)
 
event_frame     = nan(size(event_iteration));
index           = nan(size(event_iteration));
 
% make sure iteration index is valid (>0 and within the trial's iteration duration)
isValid         = event_iteration > 0 & event_iteration <= cellfun(@(it) size(it,1), iter2frame); 
 
% index interation to frame mapping with iteration for event of interest
index(isValid)  = cellfun(@(i2f,ei) i2f(ei,1), iter2frame(isValid), num2cell(event_iteration(isValid)));
isValid         = index > 0;
 
% convert to global frame ID (would be different if multiple acquisitions)
frame2globalFrame     = cell2mat(frame2globalFrame);
%Mdia for case when SI started half way through the behavior
frame2globalFrame     = frame2globalFrame(frame2globalFrame > 0); 
event_frame(isValid)  = frame2globalFrame(index(isValid));
 
end
 
 

