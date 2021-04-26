%% ---------------------------------------------------------------------------------------------------
function [cnmf, source, roiFile, summaryFile, timeScale, binnedF, outputFiles]  ...
                    = cnmfSegmentation(movieFile, prefix, fileNum, protoROI, cfg, repository, lazy, outputFiles, scratchDir, mcdir)

  prefix            = sprintf('%s_%d-%d', prefix, fileNum(1), fileNum(end));
  fprintf('****  %s\n', prefix);
  
  %% Locate proto-segmentation results if so requested
  [frameMCorr, fileMCorr] = getMotionCorrection(movieFile, 'never', true, 'SaveDir', mcdir);
  timeScale         = cfg.defaultTimeScale;
  cropping          = getMovieCropping(frameMCorr);
  if isempty(protoROI)
    roiFile         = sprintf('%s.cnmf-greedy%d-roi.mat', prefix, cfg.K);
    
  else
    name            = stripPath(movieFile);
    
    for iProto = 1:numel(protoROI)
      iFile         = find(strcmp(protoROI(iProto).movieFile, name{1}), 1, 'first');
      
      if isempty(iFile)
        continue;
      end
      
      for jFile = 2:numel(name)
        if ~strcmp(protoROI(iProto).movieFile{iFile-1 + jFile}, name{jFile})
          error('runNeuronSegmentation:cnmfSegmentation', 'Incommensurate input vs. proto-segmentation file chunking.');
        end
      end
      prototypes    = protoROI(iProto).spatial;
      protoCfg      = protoROI(iProto).params;
      timeScale     = numel(protoROI(iProto).metric.kernel);
      break;
    end
    roiFile         = [prefix '.cnmf-proto-roi.mat'];
  end
  summaryFile       = [prefix '.summary.mat'];
  
  
  %% Check for existing output
  if ~isequal(lazy,false) && exist(roiFile, 'file')
    fprintf('====  Existing results found:  %s\n', roiFile);
    load(summaryFile, 'binnedF');
    load(roiFile, 'cnmf', 'source');
    timeScale       = source.timeScale;
    return;
  elseif isequal(lazy,'never')
    cnmf            = [];
    source          = [];
    binnedF         = [];
    return;
  end

  
  %% Re-register proto segmentation according to this movie's local registration
  if ~isempty(protoROI)
    fprintf('====  Registering proto-segmented regions...\n');

    %% Align proto-segmentation to the input movie
    protoMCorr      = cv.motionCorrect( {protoROI(iProto).registration.reference, fileMCorr.reference}  ...
                                      , 30, 1, false, 0.3                                               ...
                                      );
    prototypes      = reshape(full(prototypes), [size(cropping.selectMask), size(prototypes,2)]);
    if any(protoMCorr.xShifts(:,end) ~= 0 | protoMCorr.yShifts(:,end) ~= 0)
      prototypes    = imtranslate(prototypes, [protoMCorr.xShifts(:,end), protoMCorr.yShifts(:,end)]);
    end
    prototypes      = rectangularSubset(prototypes, cropping.selectMask, cropping.selectSize, 1);
    prototypes      = reshape(prototypes > 0, size(prototypes,1)*size(prototypes,2), size(prototypes,3));

    %% Remove ROIs that no longer exist
    prototypes(:, sum(prototypes,1) < 1)  = [];
    prototypes      = sparse(prototypes);
  end
  

  %% Rebin temporally
  rebinFactor           = ceil(cfg.timeResolution / (1000/cfg.frameRate));
  timeScale             = timeScale / rebinFactor;
  cfg.corrRebin         = protoCfg.signalRebin * timeScale;
  cfg.baselineBins      = protoCfg.baselineBins;
  cfg.sigRectification  = protoCfg.sigRectification;
  cfg.punctaNPix        = protoCfg.punctaNPix;
  cfg.options.timeChunk = protoCfg.timeChunk;


  %% Reduce data size by collapsing pixels far from possible neurons into a single vector
  if isempty(protoROI)
    binning         = rebinFactor;
    isCondensed     = false;
  else
    [Ain,cfg.options] = aggregate_background_pixels(prototypes, cropping.selectSize, cfg.options);
    binning         = {rebinFactor, cfg.options.pixelIndex, cfg.options.bkg_only_pixels, cfg.corrRebin};
    isCondensed     = true;
    fprintf ( '====  Restricting segmentation to %d/%d = %.3g%% pixels around prototypes\n'     ...
            , numel(cfg.options.pixelIndex), prod(cropping.selectSize)                          ...
            , 100 * numel(cfg.options.pixelIndex) / prod(cropping.selectSize)                   ...
            );
  end
  
  
  %% Read motion corrected movie and crop the border to avoid correction artifacts
  startTime         = tic;
  fprintf('====  Reading input movie...\n');
  if ~isempty(scratchDir)
    delete(gcp('nocreate'));
  end
  [Y, binnedF, movieSize]       ...
                    = cv.imreadsub(movieFile, frameMCorr, binning, cropping, 'verbose');
  cfg.options.d1    = movieSize(1);
  cfg.options.d2    = movieSize(2);
  T                 = movieSize(3);
  
  
  %% Ensure that the data has nonnegative transients
  if cfg.zeroIsMinimum
    zeroLevel       = min(binnedF(:));
  else
    [~,zeroLevel]   = estimateZeroLevel(binnedF, false);
  end
  Y                 = Y - zeroLevel;
  d                 = cfg.options.d1 * cfg.options.d2;    % total number of pixels
  if ~isa(Y,'double')  && isempty(protoROI)
    Y               = double(Y);                          % convert to double
  end
  
  %% Additional binning for correlation metrics only
  binnedF           = reshape(binnedF, [], size(binnedF,3));
  if isCondensed
    binnedF         = binnedF(cfg.options.pixelIndex, :);
  end
  binnedF           = binnedF - zeroLevel;
  fprintf('       ... %.3g s\n', toc(startTime));
  

  %% Data pre-processing
  if size(Y,ndims(Y)) < cfg.minNumFrames
    warning('runNeuronSegmentation:data', 'Movie file %s is too short (%d frames), cannot perform segmentation.', movieFile{1}, size(Y,ndims(Y)));
    cnmf            = [];
    source          = [];
    return;
  end
  
  invalid           = isnan(sum(Y,ndims(Y)));
  if any(invalid(:))
    %{
    % Used to set all pixels with any NaN to zeroLevel, but this doesn't work for nonlinear motion
    % correction where a small number of frames have a large number of NaN pixels; in particular 
    % this can eliminate data entirely for some components
    ySize           = size(Y);
    Y               = reshape(Y, [], T);
    Y(invalid,:)    = 0;
    Y               = reshape(Y, ySize);
    %}
    
    Y(isnan(Y))             = 0;
    binnedF(isnan(binnedF)) = 0;
    warning('runNeuronSegmentation:data', 'Data contains %d NaN pixels, setting them to zeroLevel = %.4g.', sum(invalid(:)), zeroLevel);
  end
  clear invalid;
  
  
  %% Initialize noise estimate and component seeds (for greedy method)
  pool              = startParallelPool(scratchDir);
  [P,Y]             = preprocess_data(Y, cfg.p, cfg.options);

  if isempty(protoROI)
    %% Fast initialization of spatial components using greedyROI and HALS
    [Ain,Cin,bin,fin,center]          ...
                    = initialize_components(Y,cfg.K,cfg.tau,cfg.options);   % initialize
    prototypes      = Ain;
    protoCfg        = cfg;
    protoCfg.somaRadius   = cfg.tau;
    
    Y               = reshape(Y,d,T);
  else
    %% Proto-segmentation using spatio-temporal contiguity and morphological constraints
    Cin             = [];
    fin             = [];
    
    % HACK HACK HACK : noise estimate of average background-only pixels doesn't seem sensible, use a
    % value within the range of noise estimates for data
    P.sn(end)       = median(P.sn(1:end-1));
  end
  
  
  %-------------------------------------------------------------------------------------------------
  %% Run CNMF algorithm
  %-------------------------------------------------------------------------------------------------
  
  if isempty(Ain)
    A_px            = zeros(d, size(Ain,2));
    b_px            = zeros(d, 1);
    C               = zeros(size(Ain,2), T);
    f               = zeros(1, T);
    S               = C;
  else

    %% Update spatial components
    startTime       = tic;
    fprintf('====  Initializing spatial components...\n');
    [A,b,Cin,fin]   = update_spatial_components(Y,Cin,fin,Ain,P,cfg.options);
    fprintf('       ... %.3g s\n', toc(startTime));

    %% Update temporal components
    startTime       = tic;
    fprintf('====  Initializing temporal components...\n');
    [C,f,P,S]       = update_temporal_components(Y,A,b,Cin,fin,P,cfg.options);
    fprintf('       ... %.3g s\n', toc(startTime));

    %% Restrict to a few iterations since the algorithm is not asymptotically stable
    for iter = 2:cfg.iterations
      fprintf('====  ITERATION %d\n', iter - 1);

      %% Merge found components
      startTime       = tic;
      fprintf('====  Merging overlapping components...\n');
      if isCondensed
        [Am,Cm,K_m,merged_ROIs,Pm,Sm]      ...
                      = merge_components_adjacency(Y,A,b,C,f,P,S,binnedF,cfg.corrRebin,cfg.baselineBins,cfg.sigRectification,cfg.options);
      else
        [Am,Cm,K_m,merged_ROIs,Pm,Sm]      ...
                      = merge_components(Y,A,b,C,f,P,S,cfg.options);
      end
      fprintf('       ... %d merged in %.3g s\n', numel(cat(1,merged_ROIs{:})), toc(startTime));

      %{
      fprintf('====  Removing noisy components...\n');
      [Am,Cm,K_m,removed_ROIs,P,Sm]      ...
                      = remove_noisy_components(binnedF,Am,Cm,Pm,Sm,corrRebin,cfg);
      fprintf('       ... %d removed in %.3g s\n', numel(removed_ROIs), toc(startTime));
      %}

      %% Repeat
      startTime       = tic;
      fprintf('====  Improving spatial components...\n');
      [A,b,Cm]        = update_spatial_components(Y,Cm,f,Am,Pm,cfg.options);
      fprintf('       ... %.3g s\n', toc(startTime));

      startTime       = tic;
      fprintf('====  Improving temporal components...\n');
      [C,f,P,S]       = update_temporal_components(Y,A,b,Cm,f,Pm,cfg.options);
      fprintf('       ... %.3g s\n', toc(startTime));
    end

    %% Merge found components
    startTime       = tic;
    fprintf('====  Final check for overlapping components...\n');
    if isCondensed
      [A,C,K,merged_ROIs,P,S]       ...
                    = merge_components_adjacency(Y,A,b,C,f,P,S,binnedF,cfg.corrRebin,cfg.baselineBins,cfg.sigRectification,cfg.options);
    else
      [A,C,K,merged_ROIs,P,S]       ...
                    = merge_components(Y,A,b,C,f,P,S,cfg.options);
    end
    fprintf('       ... %d merged in %.3g s\n', numel(cat(1,merged_ROIs{:})), toc(startTime));

    %% Convert back to pixel indices
    if isCondensed
      A_px          = zeros(d, size(A,2));
      b_px          = zeros(d, 1);
      pxNoise       = nan(d,1);
      A_px(cfg.options.pixelIndex,:)        = A(1:end-1,:);
      b_px(cfg.options.pixelIndex)          = b(1:end-1);
      b_px(cfg.options.bkg_only_pixels)     = b(end);
      pxNoise(cfg.options.pixelIndex)       = P.sn(1:end-1);
      pxNoise(cfg.options.bkg_only_pixels)  = P.sn(end);
      P.sn          = pxNoise;
    else
      A_px          = A;
      b_px          = b;
    end
  end
  %-------------------------------------------------------------------------------------------------
  

  %% Organize output
  startTime         = tic;
  fprintf('====  Ordering output...\n');
  
  source            = struct();
  source.movieFile  = stripPath(movieFile);
  source.cropping   = cropping;
  source.prototypes = prototypes;
  source.protoCfg   = protoCfg;
  source.frameMCorr = frameMCorr;
  source.fileMCorr  = fileMCorr;
  source.timeScale  = timeScale;
  source.rebinFactor= rebinFactor;
  
  cnmf              = struct();
  cnmf.cfg          = cfg;
  cnmf.rebinFactor  = rebinFactor;
  cnmf.zeroLevel    = zeroLevel;
  cnmf.spatial      = sparse([A_px, b_px]);     % includes background as last column
  cnmf.temporal     = single(full([C; f]));     % includes background as last row
  cnmf.spiking      = sparse(S);
  cnmf.parameters   = P;
  cnmf.iBackground  = size(cnmf.spatial,2);
  
  %% Bounding boxes for ROIs
  region            = componentsToRegions(cnmf.spatial(:,1:end-1), cropping.selectSize);
  property          = regionprops(region, 'Area', 'BoundingBox', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'EulerNumber', 'Solidity', 'ConvexImage');
  leeway            = source.protoCfg.somaRadius;
  [cnmf.bound, cnmf.box]      ...
                    = overBoundingBox(property, leeway, cropping.selectSize);
  cnmf.region       = region;
  cnmf.property     = rmfield(property, 'BoundingBox');
  fprintf('       ... %.3g s\n', toc(startTime));

  startTime         = tic;
  fprintf('====  Collecting data sanity checks...');
  clear binnedF;
  if isCondensed
    clear Y A Am A_px C Cin Cm S Sm b b_px binnedF;
    if ~isempty(scratchDir)
      delete(gcp('nocreate'));
    end
    Y               = cv.imreadsub(movieFile, frameMCorr, rebinFactor, cropping, 'verbose');
    Y               = Y - zeroLevel;
    Y               = reshape(Y,d,T);
    invalid         = isnan(sum(Y,ndims(Y)));
    if any(invalid(:))
      Y(invalid,:)    = 0;
    end
  end 
  cnmf              = imaging.segmentation.cnmf.computeDataChecks(cnmf, source, Y, cfg);

  %% Store the temporally downsampled movie
  binnedF           = rebin(Y, timeScale, 2);
  clear Y;
  binnedF           = reshape(binnedF, [cropping.selectSize, size(binnedF,2)]);
  fprintf(' %.3g s\n', toc(startTime));

  fprintf('====  SAVING to %s\n', roiFile);
  save(roiFile, 'cnmf', 'source', 'repository', '-v7.3');
  outputFiles{end+1}= roiFile;

  temp              = source;
  source            = rmfield(source, {'prototypes', 'protoCfg'});
  save(summaryFile, 'binnedF', 'source', '-v7.3');
  outputFiles{end+1}= summaryFile;
  source            = temp;

end