function fileChunk = selectFileChunks(key,chunk_cfg)

%% ------------------------------------------------------------------------
%% file chunk selection
%% ------------------------------------------------------------------------
% fileChunk is an array of size chunks x 2, where rows are [firstFileIdx lastFileIdx]

%% check if enforcing this is actually desired
file_ids       = fetchn(imaging.FieldOfViewFile & key,'file_number');
nfiles         = numel(file_ids);
fileChunk      = [1 nfiles];

if ~chunk_cfg.auto_select_behav && ~chunk_cfg.auto_select_bleach && nfiles < chunk_cfg.filesPerChunk
  %fileChunk = [];
  return
end

%% select imaging chunks based on behavior blocks (at least two consecutive blocks)
if chunk_cfg.auto_select_behav

  % flatten log and summarize block info 
  addImagingSync     = false;
  logSumm            = flattenVirmenLogFromDJ(key,addImagingSync); %%%%% write this

  session.badData    = false;
  session.blockID    = unique(logSumm.blockID);
  badTr              = isBadTrial(logSumm);

  nBlock             = numel(session.blockID);
  session.fracBadTr  = nan(1,nBlock);     
  session.meanPerf   = nan(1,nBlock); 
  session.nTrials    = nan(1,nBlock);
  session.meanBias   = nan(1,nBlock); 
  session.mazeID     = nan(1,nBlock);

  for iBlock = 1:nBlock
    thisBlock                   = session.blockID(iBlock);
    theseTrials                 = logSumm.blockID == thisBlock;
    session.fracBadTr(iBlock)   = sum(badTr(theseTrials))/sum(theseTrials);
    session.meanPerf(iBlock)    = mode(logSumm.meanPerfBlock(theseTrials));
    session.meanBias(iBlock)    = mode(logSumm.meanBiasBlock(theseTrials));
    session.mazeID(iBlock)      = mode(logSumm.currMaze(theseTrials));
    session.nTrials(iBlock)     = sum(theseTrials);
  end

  isRealBlock                   = session.nTrials > 3;
  realBlockIdx                  = 1:sum(isRealBlock);
  session.blockIdx              = nan(1, numel(session.nTrials));
  session.blockIdx(isRealBlock) = realBlockIdx;

  % find blocks/sessions with good behavior
  goodSess                      = enforcePerformanceCriteria(session, chunk_cfg);

  if isempty(goodSess)
    fileChunk = [];
    return
  end
  
  % if good blocks, determine which imaging files to segment based on behavior
  % do this by picking a continuous stretch of files going from the first
  % tif file containing the first good behavior block to the last tif file
  % containing the last good behavior block. Further chunking will depend
  % on max num file criterion / bleaching
  isGoodBlock              = [goodSess.extractThisBlock false];
  frameRanges              = fetchn(imaging.SyncImagingBehavior & key,'sync_im_frame_span_by_behav_block');
  frameRangesPerBlock      = cell2mat(frameRanges{1}');
  frameRangesPerGoodBlock  = frameRangesPerBlock(goodSess.extractThisBlock,:);
  frameRangesPerFile       = cell2mat(fetchn(imaging.FieldOfViewFile & key,'file_frame_range'));
  
  % break chunks of non-consecutive blocks if necessary
  if chunk_cfg.breakNonConsecBlocks
    isGood_diff        = diff([0 isGoodBlock]);
    numchunks          = sum(isGood_diff == 1);
    fileChunk          = zeros(numchunks,2);
    
    curr_idx = 1;
    for iChunk = 1:numchunks
      firstidx             = find(isGoodBlock(curr_idx:end) & isGood_diff(curr_idx:end) == 1,1,'first') + curr_idx - 1;
      lastidx              = find(~isGoodBlock(firstidx:end) & isGood_diff(firstidx:end) < 1,1,'first') + firstidx - 2;
      curr_idx             = lastidx+find(isGoodBlock(lastidx+1:end),1,'first')-2;
      
      thisRange            = frameRangesPerBlock(firstidx:lastidx,:);
      fileChunk(iChunk,:)  = [find(min(thisRange(:)) < frameRangesPerFile(:,2), 1, 'first') ...
                              find(max(thisRange(:)) > frameRangesPerFile(:,1), 1, 'last')];
    end
    
  else
    fileChunk              = [find(min(frameRangesPerGoodBlock(:)) < frameRangesPerFile(:,2), 1, 'first') ...
                              find(max(frameRangesPerGoodBlock(:)) > frameRangesPerFile(:,1), 1, 'last')];
  end
  
end

%% enforce bleaching and max num file criteria if necessary
% bleaching
if chunk_cfg.auto_select_bleach
  lastGoodFile           = fetch1(imaging.ScanInfo & key,'last_good_file');
  deleteIdx              = fileChunk(:,1) > lastGoodFile;
  fileChunk(deleteIdx,:) = [];
  if isempty(fileChunk); return; end
  fillInIdx              = fileChunk(:,2) > lastGoodFile;
  fileChunk(fillInIdx,2) = lastGoodFile;
end

% max files per chunk. Split in half if it exceeds this criterion in the
% case of many consecutive blocks, otherwise break at disjoint blocks
if size(fileChunk,1) == 1
  if diff(fileChunk) > chunk_cfg.filesPerChunk
    oldchunk       = fileChunk;    
    fileChunk(1,:) = [oldchunk(1) round(oldchunk(end)/2)]; 
    fileChunk(2,:) = [round(oldchunk(end)/2)+1 oldchunk(end)]; 
  end
end

end