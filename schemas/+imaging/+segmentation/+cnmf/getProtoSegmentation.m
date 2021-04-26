%% --------------------------------------------------------------------------------------------------
function [prototypes, outputFiles] = getProtoSegmentation(movieFile, fileChunk, prefix, lazy, cfg, outputFiles, scratchDir, mcdir)
  
  %% Look for existing work if available
  protoFile       = [prefix, '.proto-roi.mat'];
  figFile         = [prefix, '.proto-roi.fig'];
  if ~isequal(lazy,false) && exist(protoFile, 'file')
    fprintf('====  Found existing proto-segmentation results %s\n', protoFile);
    load(protoFile);
    return;
  end

  %% Process input in chunks
  fig             = gobjects(0);
  prototypes      = struct();
  for iChunk = 1:size(fileChunk,1)
    chunkFiles                    = movieFile(fileChunk(iChunk,1):fileChunk(iChunk,2));

    %ALS Get stats files from chunck files
    [~, movieNames] = cellfun(@fileparts, chunkFiles, 'UniformOutput', false);
    statsFile = fullfile(mcdir, movieNames);
    statsFile = strcat(statsFile, '.stats.mat');

    prototypes(iChunk).movieFile  = stripPath(chunkFiles);
    chunkLabel                    = sprintf('%s_%d-%d', prefix, fileChunk(iChunk,1), fileChunk(iChunk,2));
    fprintf('====  Performing proto-segmentation of %s\n', chunkLabel);
    
    %% Read motion corrected statistics and crop the border to avoid correction artifacts
    [frameMCorr, fileMCorr]       = getMotionCorrection(chunkFiles, 'never', true, 'SaveDir', mcdir);
    cropping      = getMovieCropping(frameMCorr);
    metric        = getActivityMetric(statsFile, fileMCorr, cropping.selectMask, cropping.selectSize);
    
    %% Read and temporally downsample movie
    startTime     = tic;
    fprintf('====  Reading input movie...\n');
    binning       = numel(metric.kernel);
    [binnedF, ~, ~, info]                                   ...
                  = cv.imreadsub(chunkFiles, frameMCorr, binning, cropping, 'verbose');
    if ~isempty(scratchDir)
      delete(gcp('nocreate'));
    end
    if cfg.zeroIsMinimum
      zeroLevel   = min(binnedF(:));
    else
      [~,zeroLevel] = estimateZeroLevel(binnedF, false);
    end
    fprintf('       ... %.3g s\n', toc(startTime));
    
    %% For nonlinear motion correction, replace NaNs with the zeroLevel -- FIXME probably we should crop more if necessary?
    if info.nonlinearMotionCorr
      binnedF(isnan(binnedF)) = zeroLevel;
    end
    
    
    %% Linear interpolation constants for per-file significance computation
    if numel(info.fileFrames) == 1
      metric.w1   = ones(1, size(binnedF,3));
      metric.w2   = zeros(1, size(binnedF,3));
      metric.iRef = ones(1, size(binnedF,3));
    else
      refFrame    = round( [0, cumsum(info.fileFrames(1:end-1)/binning)] + info.fileFrames/2/binning );
      frameFrac   = accumfun(2, @(x,y) (0:y-x-1) / (y-x+1), refFrame(1:end-1), refFrame(2:end));
      frameFrac   = [ones(1,refFrame(1)-1), frameFrac, zeros(1,size(binnedF,3)-refFrame(end)+1)];
      if numel(refFrame) > 1
        refIndex  = accumfun(2, @(x,y) x * ones(1,y), 1:numel(refFrame)-1, diff(refFrame));
        refIndex  = [ones(1,refFrame(1)-1), 1+refIndex, numel(refFrame)*ones(1,size(binnedF,3)-refFrame(end)+1)];
      else
        refIndex  = ones(1,refFrame(1));
      end
      metric.w1   = 1 - frameFrac;
      metric.w2   = frameFrac;
      metric.iRef = refIndex;
    end
    metric.nonlinearMotionCorr                              ...
                  = info.nonlinearMotionCorr;
    
    %% Run proto-segmentation 
    pool          = startParallelPool(scratchDir);
    [spatial, prototypes(iChunk).params, fig(end+1)]        ...
                  = estimateNeuronCount_mesoscope( binnedF, zeroLevel, metric, chunkLabel );
                
    %% Undo cropping for ease of re-registration; labels at the boundaries are replicated to minimize
    % loss of component area due to motion correction
    spatial       = reshape(full(spatial), [cropping.selectSize, size(spatial,2)]);
    spatial       = rectangularUncrop(spatial, false, cropping);

    %% Store sparse version to save on space
    prototypes(iChunk).spatial                = sparse(reshape(spatial, size(spatial,1) * size(spatial,2), size(spatial,3)));
    prototypes(iChunk).zeroLevel              = zeroLevel;
    prototypes(iChunk).registration           = cropping;
    prototypes(iChunk).registration.xGlobal   = fileMCorr.xShifts;
    prototypes(iChunk).registration.yGlobal   = fileMCorr.yShifts;
    prototypes(iChunk).registration.reference = fileMCorr.reference;
    prototypes(iChunk).metric                 = metric;
  end
  
  
  %% Save output and figures
  save(protoFile, 'prototypes', '-v7.3');
  savefig(fig, figFile, 'compact');
  close(fig);
  
  outputFiles{end+1}  = protoFile;
  outputFiles{end+1}  = figFile;
  
end