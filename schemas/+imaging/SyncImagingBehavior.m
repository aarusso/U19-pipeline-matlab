%{
# synchronization between imaging and behavior
-> imaging.FieldOfView
---
sync_im_frame                      :    longblob   # frame number within tif file
sync_im_frame_global               :    longblob   # global frame number in scan
sync_behav_block_by_im_frame       :    longblob   # array with behavioral block for each imaging frame
sync_behav_trial_by_im_frame       :    longblob   # array with behavioral trial for each imaging frame
sync_behav_iter_by_im_frame        :    longblob   # array with behavioral trial for each imaging frame, some extra zeros in file 1, marking that the behavior recording hasn't started yet.
sync_im_frame_span_by_behav_block  :    longblob   # cell array with first and last imaging frames for for each behavior block
sync_im_frame_span_by_behav_trial  :    longblob   # cell array with first and last imaging frames for for each behavior trial
sync_im_frame_span_by_behav_iter   :    longblob   # cell array with first and last imaging frames for for each behavior iteration within each trial
%}


classdef SyncImagingBehavior < dj.Computed
  
  methods(Access=protected)
    
    function makeTuples(self, key)
      
      %% behav
      [~, acqsession_file] = lab.utils.get_path_from_official_dir(...
                           fetch1(acquisition.SessionStarted & key, 'remote_path_behavior_file'));
      behavdata = load(acqsession_file, 'log');
      block     = behavdata.log.block;
      
      %% add some stuff that for whatever reason isn't on some mesosocope logs
      block     = fixLogs(block);
      
      %% imaging sync
      cfg.minBehaviorSecs           = 2;      % for assuming that frames with no sync data are actually within some abnormally long behavioral iteration
      cfg.syncTolerance             = 0.1;
      
      syncFrame                     = [];
      syncGlobal                    = [];
      refEpoch                      = [];
      currentAcquis                 = 0;
      totalFrames                   = 0;
      
      % path
      fov_bucket_directory          = fetch1(imaging.FieldOfView & key,'fov_directory');

      fov_directory = lab.utils.format_bucket_path(fov_bucket_directory);

      %Check if directory exists in system
      lab.utils.assert_mounted_location(fov_directory)

      [order,movieFiles]            = fetchn(imaging.FieldOfViewFile & key, 'file_number', 'fov_filename');
      movieFiles                    = cellfun(@(x)(fullfile(fov_directory,x)),movieFiles(order),'uniformoutput',false); % full path
      imagingF                      = struct('movieFile', movieFiles);
      
      fprintf('==[ SYNCHRONIZATION ]==   %s\n', fov_directory);
      
      for iFile = 1:numel(movieFiles)        
        
        % Synchronization info
        [imagingF(iFile).acquisition, imagingF(iFile).epoch, imagingF(iFile).frameTime, imagingF(iFile).syncTime, data]   ...
                                    = cv.getSyncInfo(movieFiles{iFile}, 'uint16', []);
        fileAcquis                  = regexp(movieFiles{iFile}, '_([0-9]+)_[0-9]+[.][^.]+$', 'tokens', 'once');
        if ~isempty(fileAcquis)
          fileAcquis                = str2double(fileAcquis{:});
          if fileAcquis ~= imagingF(iFile).acquisition
            warning ( 'processimagingInfo:acquisition'                                                                ...
                    , 'Acquisition number according to file name (%d) not equal to that stored (%d) in file %s.'      ...
                    , fileAcquis, imagingF(iFile).acquisition, movieFiles{iFile}                                       ...
                    );
            imagingF(iFile).acquisition  = fileAcquis;
          end
        end
        
        if iFile == 1
          refEpoch                  = imagingF(iFile).epoch;
        else
          timeOffset                = etime(imagingF(iFile).epoch, refEpoch);
          imagingF(iFile).frameTime  = imagingF(iFile).frameTime + timeOffset;
          imagingF(iFile).syncTime   = imagingF(iFile).syncTime  + timeOffset;
        end
        
        imagingF(iFile).numFrames    = numel(imagingF(iFile).frameTime);
        startTime                   = datenum( imagingF(iFile).epoch );
        imagingF(iFile).clockTime    = arrayfun(@(x) addtodate(startTime,x,'second'), round(imagingF(iFile).frameTime));
        if isempty(data)
          imagingF(iFile).block      = zeros(1,numel(imagingF(iFile).syncTime));
          imagingF(iFile).trial      = zeros(1,numel(imagingF(iFile).syncTime));
          imagingF(iFile).iteration  = zeros(1,numel(imagingF(iFile).syncTime));
        else
          imagingF(iFile).block      = double(data(1,:));
          imagingF(iFile).trial      = double(data(2,:));
          imagingF(iFile).iteration  = double(data(3,:));
        end
        
        if imagingF(iFile).acquisition > currentAcquis
          currentAcquis             = imagingF(iFile).acquisition;
          totalFrames               = 0;
        elseif imagingF(iFile).acquisition < currentAcquis
          error('processimagingFInfo:acquisition', 'Encountered decreasing acquisition number while processing supposedly sorted files.');
        end
        
        frames                      = 1:imagingF(iFile).numFrames;
        syncFrame(end + frames)     = frames;
        syncGlobal(end + frames)    = totalFrames + frames;
        totalFrames                 = totalFrames + imagingF(iFile).numFrames;
      end
      meta.imagingF                  = imagingF;
      
      %-------------------------------------------------------------------------------------------------
      
      %% Detect frames with no synchronization info but only due to incommensurate frame rates
      frameTime                     = [imagingF.frameTime];
      syncTime                      = [imagingF.syncTime];
      frameDeltaT                   = diff(frameTime);
      if any(diff([imagingF.acquisition]) < 0)
        %     keyboard
        error('processimagingInfo:sanity', 'imagingF acquisition numbers are not in non-decreasing order for %s. Are the file timestamps correct?', fov_directory);
      end
      if any(frameDeltaT <= 0)
        %     keyboard
        error('processimagingInfo:sanity', 'imagingF frame times are not in strictly ascending order for %s. Are the file timestamps correct?', fov_directory);
      end
      frameDeltaT                   = mean(frameDeltaT);
      
      
      %% Omit no-data stretches at the beginning and the end of the session since these are ambiguous
      [noSync, i1, i2]              = SplitVec(double(isnan(syncTime)), 'equal', 'firstval', 'first', 'last');
      noSync                        = noSync(:) & (i1 > 1) & (i2 < numel(frameTime));
      i1                            = i1(noSync);
      i2                            = i2(noSync);
      deltaTime                     = frameTime(i2 + 1) - frameTime(i1);
      
      poorSync                      = (deltaTime > cfg.minBehaviorSecs);
      if any(poorSync)
        warning('processimagingInfo:HACK', 'Extremely long lags encountered between behav frames: %s', num2str(deltaTime(poorSync)));
      end
      
      %% Patch all missing chunks using the nearest past frame that has sync info
      syncBlock                     = [imagingF.block];
      syncTrial                     = [imagingF.trial];
      syncIter                      = [imagingF.iteration];
      for iMiss = 1:numel(i1)
        iRange                      = i1(iMiss):i2(iMiss);
        syncBlock(iRange)           = syncBlock(i1(iMiss) - 1);
        syncTrial(iRange)           = syncTrial(i1(iMiss) - 1);
        syncIter(iRange)            = syncIter(i1(iMiss) - 1);
      end
      
      %% test sync success
      if any((syncBlock == 0) ~= (syncTrial == 0))
        error('processimagingInfo:HACK', 'Incompatible presence of block/trial synchronization info for %s.', fov_directory);
        %     keyboard
        %     iChange = 1 + find(diff(syncBlock) ~= 0 | diff(syncTrial) ~= 0)';
        %     [syncBlock([iChange-1, iChange, iChange+1]), syncTrial([iChange-1, iChange, iChange+1]), syncIter([iChange-1, iChange, iChange+1])]
      end

      % HACK for forcibly terminated trials that are not recorded in behav, but still appear as part
      % of the sync info since there is no feedback
      [imgBlock, bracket]           = SplitVec(syncBlock, 'equal', 'firstval', 'bracket');
      for iBlock = 1:numel(imgBlock)
        jBlock                      = imgBlock(iBlock);
        if jBlock < 1
          continue;
        end
        iSync                       = bracket(iBlock,1):bracket(iBlock,2);
        maxTrial                    = max(syncTrial(iSync));
        if maxTrial == numel(block(jBlock).trialType) + 1
          warning('processimagingInfo:sanity', 'Nonexistent trial %d recorded in imagingF data (%s) for behavioral block %d (%d trials); will assume that it was aborted.', maxTrial, fov_directory, jBlock, numel(block(jBlock).trialType));
          iErase                    = iSync(1)-1 + find(syncTrial(iSync) == maxTrial);
          syncBlock(iErase)         = 0;
          syncTrial(iErase)         = 0;
          syncIter(iErase)          = 0;
        elseif maxTrial > numel(block(jBlock).trialType)
          error('processimagingInfo:sanity', 'Trial %d recorded in imagingF data (%s) for behavioral block %d which only has %d trials.', maxTrial, fov_directory, jBlock, numel(block(jBlock).trialType));
        end
      end

      % Write back into the file-based storage structure
      prevFrames                    = 0;
      for iFile = 1:numel(movieFiles)
        iSync                       = prevFrames + (1:imagingF(iFile).numFrames);
        imagingF(iFile).block        = syncBlock(iSync);
        imagingF(iFile).trial        = syncTrial(iSync);
        imagingF(iFile).iteration    = syncIter(iSync);
        prevFrames                  = prevFrames + imagingF(iFile).numFrames;
      end
      
      
      %-------------------------------------------------------------------------------------------------
      %% Store synchronization info indexed by a global time coordinate
      
      % First lay this out using the imagingF frames
      sync                          = [ syncFrame; syncGlobal; imagingF.block; imagingF.trial; imagingF.iteration ];
      sync                          = cell2struct(num2cell(sync), {'frame', 'global', 'block', 'trial', 'iteration'}, 1);
      prevFrames                    = 0;
      for iFile = 1:numel(movieFiles)
        iSync                       = prevFrames + (1:imagingF(iFile).numFrames);
        [sync(iSync).imagingF]       = deal(iFile);
        [sync(iSync).acquisition]   = deal(imagingF(iFile).acquisition);
        prevFrames                  = prevFrames + imagingF(iFile).numFrames;
      end
      
      
      % Tabulate imaging vs. behav wall clock times
      blockTime                     = cellfun(@datenum, {block.start});
      [imgBlock, bracket]           = SplitVec([sync.block], 'equal', 'firstval', 'bracket');
      imgTime                       = [imagingF.clockTime];
      imgTime                       = imgTime(bracket(:,1));
      hasImg                        = ( imgBlock > 0 );

      % Locate time of behavioral blocks relative to imaging info
      hasImg                        = find(hasImg);
      blockIndex                    = binarySearch(imgTime, blockTime, -1, 0.5);
      if any(abs(blockIndex(imgBlock(hasImg)) - hasImg) > cfg.syncTolerance)
        warning('processimagingInfo:sanity', 'Encountered large deviations %s of computed vs. actual behavioral block index w.r.t. imagingF in %s.', num2str(blockIndex(imgBlock(hasImg)) - hasImg), fov_directory);
      end
      
      % Account for asynchronous clock drifts by using relative positioning
      blockSync                     = blockIndex(imgBlock(hasImg));
      iRelative                     = binarySearch(blockSync, blockIndex, -1, 2);
      blockIndex                    = blockIndex - blockSync(iRelative) + hasImg(iRelative);
      
      % Sanity check that the above time alignment worked
      if any(diff(blockIndex) <= 0)
        %     keyboard
        error('processimagingInfo:sanity', 'Behavioral block index w.r.t. imagingF must be strictly monotonic; this is not true in %s.', fov_directory);
      end
      if ~issorted(imgTime(hasImg))
        error('processimagingInfo:sanity', 'Expected blocks recorded during imagingF to be non-decreasing; this is not true in %s.', fov_directory);
      end
      
      
      %% Patch in behavioral trials that have no corresponding imaging info
      for iBlock = numel(blockIndex):-1:1
        if blockIndex(iBlock) == round(blockIndex(iBlock))
          % If the block has imaging info, patch in trials
          sync                      = [ sync(1:bracket(blockIndex(iBlock),1) - 1)                                       ...
                                      ; mergeTrials( sync(bracket(blockIndex(iBlock),1):bracket(blockIndex(iBlock),2))  ...
                                      , numel(block(iBlock).trialType), iBlock                             ...
                                      , block(iBlock).medianTrialDur, frameDeltaT                          ...
                                      )                                                                    ...
                                      ; sync(bracket(blockIndex(iBlock),2) + 1:end)                                     ...
                                      ];
        else
          % Otherwise add an entire block of trials
          iSync                     = floor(blockIndex(iBlock));
          if iSync < 1
            iSync                   = 0;
          elseif iSync > numel(imgBlock)
            iSync                   = bracket(end,2);
          else
            iSync                   = bracket(iSync,2);
          end
          sync                      = [ sync(1:iSync)                                           ...
                                      ; newTrials( numel(block(iBlock).trialType), iBlock       ...
                                      , block(iBlock).medianTrialDur, frameDeltaT    ...
                                      )                                              ...
                                      ; sync(iSync + 1:end)                                     ...
                                      ];
        end
      end      
      
      %% Record transition indices
      index                         = struct();
      span                          = struct();
      for field = {'imagingF', 'acquisition', 'block'}
        [index.(field{:}), span.(field{:})]       ...
          = SplitVec([sync.(field{:})], 'equal', 'firstval', 'bracket');
      end
      
      % Sanity checks
      if ~issorted(index.imagingF(index.imagingF > 0))
        error('processimagingInfo:sanity', 'Invalid parsing of image file indices.');
      end
      if ~issorted(index.block(index.block > 0))
        error('processimagingInfo:sanity', 'Invalid parsing of behavioral block indices.');
      end
      
      
      %% Record behav block based sync index
      behav                      = struct( 'span'  , cell(size(block))                               ...
                                            , 'trial' , repmat( {struct('span', {}, 'iteration', {})}   ...
                                            , size(block) )                                             ...
                                            );
      for iBlock = 1:numel(block)
        if isempty(block(iBlock).trialType)
          continue;
        end
        jBlock                      = find(index.block == iBlock, 1, 'first');
        behav(iBlock).span       = span.block(jBlock,:);
        if isempty(jBlock)
          numTrials                 = numel(block(iBlock).trialType);
          behav(iBlock).trial    = struct( 'span'     , repmat({zeros(0,2)},numTrials)   ...
                                            , 'iteration', repmat({zeros(0,2)},numTrials)   ...
                                            );
          continue;
        end
        
        % Locate trial ranges
        blockSync                   = sync(span.block(jBlock,1):span.block(jBlock,2));
        [trialIndex, trialSpan]     = SplitVec([blockSync.trial], 'equal', 'firstval', 'bracket');
        trialSpan                   = num2cell( trialSpan + span.block(jBlock,1)-1, 2 );
        trial                       = cell(max(trialIndex), 1);
        sel                         = trialIndex > 0;
        trial(trialIndex(sel))      = trialSpan(sel);
        trial                       = struct('span', trial, 'iteration', repmat({zeros(0,2)},size(trial)));
        
        for iTrial = 1:numel(trial)
          % Locate iteration ranges
          if isempty(trial(iTrial).span)
            continue;
          end
          
          trialSync                 = sync(trial(iTrial).span(1):trial(iTrial).span(2));
          [iterIndex, iterSpan]     = SplitVec([trialSync.iteration], 'equal', 'firstval', 'bracket');
          iteration                 = zeros(max(iterIndex), 2);
          sel                       = iterIndex > 0;
          iteration(iterIndex(sel),:) = iterSpan(sel, :);
          
          % Assume that iterations without info fall in the same sync frame as the previous one
          [noInfo, bracket]         = SplitVec(double(iteration(:,1) < 1), 'equal', 'firstval', 'bracket');
          for iBrac = 1:numel(noInfo)
            if noInfo(iBrac) && bracket(iBrac,1) > 1
              for iCol = 1:size(bracket,2)
                iteration(bracket(iBrac,1):bracket(iBrac,2), iCol)  ...
                                    = iteration(bracket(iBrac,1) - 1, iCol);
              end
            end
          end
          
          trial(iTrial).iteration   = iteration;
        end
        behav(iBlock).trial      = trial;
        
        %     if numel(trial) ~= numel(block(iBlock).trialType)
        %       keyboard
        %     end
      end
      
      %% flatten behav structure for table format
      flat_behavior.trial_span       = [];
      flat_behavior.iter_span        = {};
      for iBlock = 1:numel(behav)
        flat_behavior.trial_span = [flat_behavior.trial_span {behav(iBlock).trial(:).span}];
        for iTrial = 1:numel(behav(iBlock).trial)
          flat_behavior.iter_span{end+1} = behav(iBlock).trial(iTrial).iteration+behav(iBlock).trial(iTrial).span(1);
        end
      end

      %% translate to table and insert 
      if ~isstruct(key); key = fetch(key); end
      key.sync_im_frame                     = [sync(:).frame];
      key.sync_im_frame_global              = [sync(:).global];
      key.sync_behav_block_by_im_frame      = [sync(:).block];
      key.sync_behav_trial_by_im_frame      = [sync(:).trial];
      key.sync_behav_iter_by_im_frame       = [sync(:).iteration];
      key.sync_im_frame_span_by_behav_block = {behav(:).span};
      key.sync_im_frame_span_by_behav_trial = flat_behavior.trial_span;
      key.sync_im_frame_span_by_behav_iter  = flat_behavior.iter_span;
      
      self.insert(key);
    end
  end
  
end


% %---------------------------------------------------------------------------------------------------
function sync = mergeTrials(sync, nTrials, iBlock, trialDur, frameDeltaT)
  
  if nTrials < 1
    return;
  end
  
  % Mark all trials with sync info
  syncTrials          = [sync.trial];
  allSyncs            = 1:numel(syncTrials);
  allTrials           = 1:nTrials;
  trialIndex          = binarySearch(allTrials, syncTrials, -1, 0);
  hasSync             = (trialIndex > 0);
  syncIndex           = zeros(size(allTrials));
  syncIndex(trialIndex(hasSync))  = allSyncs(hasSync);
  
  % Locate subsets with no sync info
  [value, span]       = SplitVec(double(syncIndex > 0), 'equal', 'firstval', 'bracket');
  span                = span(value == 0, :);
  for iMiss = size(span,1):-1:1
    if span(iMiss,1) > 1
      iSync           = syncIndex( span(iMiss,1) - 1 );
    else
      iSync           = 0;
    end
    sync              = [ sync(1:iSync)                                               ...
                        ; newTrials( span(iMiss,2) - span(iMiss,1) + 1, iBlock        ...
                                   , trialDur, frameDeltaT, span(iMiss,1)             ...
                                   )                                                  ...
                        ; sync(iSync + 1:end)                                         ...
                        ];
  end
  
end

%% ---------------------------------------------------------------------------------------------------
function sync = newTrials(nTrials, iBlock, trialDur, frameDeltaT, firstTrial)
  
  if nargin < 5
    firstTrial  = 1;
  end

  if isfinite(trialDur)
    nStep       = round(trialDur / frameDeltaT);
  else
    nStep       = 1;
  end
  nSync         = nTrials * nStep;
  noInfo        = repmat({0}, nSync, 1);
  iTrial        = repmat(1:nTrials, nStep, 1);
  sync          = struct( 'frame'         , noInfo                                    ...
                        , 'global'        , noInfo                                    ...
                        , 'block'         , repmat({iBlock}, nSync, 1)                ...
                        , 'trial'         , num2cell(firstTrial-1 + iTrial(:))        ...
                        , 'iteration'     , noInfo                                    ...
                        , 'imagingF'      , noInfo                                    ...
                        , 'acquisition'   , noInfo                                    ...
                        );
  
end


%% fix logs where trial type and choice are not recorded due to bug
function block = fixLogs(block)
  
for iBlock = 1:numel(block)
  nTrials = numel(block(iBlock).trial);
  for iTrial = 1:nTrials
    if isempty(block(iBlock).trial(iTrial).trialType)
      if numel(block(iBlock).trial(iTrial).cuePos{1}) > numel(block(iBlock).trial(iTrial).cuePos{1})
        block(iBlock).trial(iTrial).trialType = Choice.L;
      else
        block(iBlock).trial(iTrial).trialType = Choice.R;
      end
    end
    if isempty(block(iBlock).trial(iTrial).choice)
      pos = block(iBlock).trial(iTrial).position;
      if pos(end,2) < 300
        block(iBlock).trial(iTrial).choice   = Choice.nil;
      else
        if pos(end,3) > 0
          block(iBlock).trial(iTrial).choice = Choice.L;
        else
          block(iBlock).trial(iTrial).choice = Choice.R;
        end
      end
    end
  end
  block(iBlock).trialType      = [block(iBlock).trial(:).trialType];
  block(iBlock).medianTrialDur = median([block(iBlock).trial(:).duration]);
end
  
end
