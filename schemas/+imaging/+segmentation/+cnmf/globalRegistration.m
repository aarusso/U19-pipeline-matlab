function outputFiles = globalRegistration(chunk, path, prefix, repository, cfg, outputFiles)
  
  disp('Here global registration')
  disp(chunk(1).roiFile)

  [~,algoLabel]                 = parsePath(chunk(1).roiFile);
  [~,~,algoLabel]               = parsePath(algoLabel);
  
  if sum(ismember(path,prefix)) == numel(path)  
    regFile                     = [prefix algoLabel '.mat'];
  else
    regFile                     = fullfile(path, [prefix algoLabel '.mat']);
  end

  if exist(regFile,'file')
    
    for iFile = 1:numel(chunk)
      roiFile                   = fullfile(path, chunk(iFile).roiFile);
      outputFiles{end+1}        = roiFile;
    end
    outputFiles{end+1}          = regFile;
    
    fprintf('====  FOUND %s, skipping global registration\n', regFile);
    return
  end
  
  fprintf('====  NOT FOUND %s, not skipping global registration\n', regFile);
  
  %% Precompute the safe frame size to contain all centered components 
  maxSize                       = [0 0];
  for iFile = 1:numel(chunk)
    maxSize                     = max( maxSize, size(chunk(iFile).shape(:,:,1)) );
  end
  cfg.templateSize              = 1 + 2*maxSize;
  origin                        = ceil(cfg.templateSize / 2);
  
  %% Apply global motion correction on component centroid locations
  startTime                     = tic;
  fprintf('====  Computing global registration shifts...');
%   movieFile                     = cat(1, chunk.movieFile);
  registration                  = cv.motionCorrect(cat(3, chunk.reference), 30, 5, false, 0.1);
  fprintf(' %.3g s\n', toc(startTime));

  startTime                     = tic;
  fprintf('====  Computing component shape templates...');
  isOccupied                    = false(cfg.templateSize);
  for iFile = 1:numel(chunk)
    chunk(iFile).globalXY       = bsxfun( @plus                                                       ...
                                        , chunk(iFile).localXY                                        ...
                                        , [registration.xShifts(iFile); registration.yShifts(iFile)]  ...
                                        );
                                  
    % Create centered component shape templates by translating the centroid
    template                    = zeros([cfg.templateSize, size(chunk(iFile).shape,3)]);
    [col, row, frame]           = meshgrid( 1:size(chunk(iFile).shape, 2)     ...
                                          , 1:size(chunk(iFile).shape, 1)     ...
                                          , 1:size(chunk(iFile).shape, 3)     ...
                                          );
    iTarget                     = sub2ind ( size(template)                  ...
                                          , row + origin(1)-1               ...
                                          , col + origin(2)-1, frame        ...
                                          );
    template(iTarget)           = chunk(iFile).shape;
    if ~isempty(chunk(iFile).centroid)
      template                  = cv.imtranslatex(template, -chunk(iFile).centroid(1,:), -chunk(iFile).centroid(2,:));
      template(isnan(template)) = 0;
    end
    
    chunk(iFile).shapeSize      = size(chunk(iFile).shape);
    chunk(iFile).templateSize   = size(template);
    chunk(iFile).shape          = sparse(reshape(chunk(iFile).shape, size(chunk(iFile).shape,1)*size(chunk(iFile).shape,2), size(chunk(iFile).shape,3)));
    chunk(iFile).template       = sparse(reshape(template, size(template,1)*size(template,2), size(template,3)));
    isOccupied(any(chunk(iFile).template,2))  = true;
  end
  
  %% Crop the templates so that they occupy as little extent as possible
  isOccupied                    = reshape(full(isOccupied), cfg.templateSize);
  occupancy                     = any(isOccupied, 1);
  xRange                        = [ find(occupancy,1,'first'), find(occupancy,1,'last') ];
  occupancy                     = any(isOccupied, 2);
  yRange                        = [ find(occupancy,1,'first'), find(occupancy,1,'last') ];
  if isempty(xRange) || isempty(yRange)
    xBorder                     = 0;
    yBorder                     = 0;
  else
    xBorder                     = min(abs(xRange - [1 size(isOccupied,2)]));
    yBorder                     = min(abs(yRange - [1 size(isOccupied,1)]));
  end

  [col, row]                    = meshgrid(xBorder+1:cfg.templateSize(2)-xBorder, yBorder+1:cfg.templateSize(1)-yBorder);
  indices                       = sub2ind(cfg.templateSize, row, col);
  cfg.templateSize              = cfg.templateSize - 2*[yBorder, xBorder];
  for iFile = 1:numel(chunk)
    chunk(iFile).template       = chunk(iFile).template(indices, :);
  end
  
  fprintf(' %.3g s\n', toc(startTime));
  

  startTime                     = tic;
  fprintf('====  Registering component identities across time...');
  
  %% Initialize global components using the first movie
  localIndex                    = find( chunk(1).morphology < RegionMorphology.Noise );
  globalXY                      = chunk(1).globalXY(:,localIndex);
  template                      = chunk(1).template(:,localIndex);
  chunk(1).globalID             = zeros(size(chunk(1).morphology));
  chunk(1).globalID(localIndex) = 1:numel(localIndex);
  chunk(1).globalDistance       = zeros(size(chunk(1).globalID));
  chunk(1).globalShapeCorr      = ones(size(chunk(1).globalID));
  
  %% Iteratively match ROIs in subsequent chunks to moving targets by proximity and shape correlation
  for iFile = 2:numel(chunk)
    localIndex(end+1,:)         = 0;
    compIndex                   = find( chunk(iFile).morphology < RegionMorphology.Noise );
    chunk(iFile).globalID       = zeros(size(chunk(iFile).morphology));
    chunk(iFile).globalDistance = nan(size(chunk(iFile).morphology));
    chunk(iFile).globalShapeCorr= nan(size(chunk(iFile).morphology));
    
    % Allow matches only between high quality components within a certain distance
    distance                    = pdist2(globalXY', chunk(iFile).globalXY(:,compIndex)', 'euclidean');
    maxDistance                 = max( cfg.minDistancePixels, cfg.maxCentroidDistance * chunk(iFile).diameter(compIndex) );
    difference                  = zeros(0, 4);
    for iComp = 1:size(distance,2)
      iNearby                   = find( distance(:,iComp) <= maxDistance(iComp) );
      if isempty(iNearby)
        continue;
      end
      
%       delta                   = bsxfun(@minus, template(:,iNearby), roi(iFile).template(:,compIndex(iComp)));
%       delta                   = sum(delta.^2, 1) ./ magnitude(iNearby) / roi(iFile).magnitude(compIndex(iComp));
      correlation               = corr(template(:,iNearby), chunk(iFile).template(:,compIndex(iComp)));    
      iPair                     = size(difference,1) + (1:numel(correlation));
      difference(iPair,1)       = correlation;
      difference(iPair,2)       = iNearby;
      difference(iPair,3)       = iComp;
      difference(iPair,4)       = distance(iNearby,iComp);
    end
    difference                  = sortrows(difference, 1);

    %% Greedily assign the most correlated components first
    isResolved                  = false(size(compIndex));
    isMatched                   = false(1, size(globalXY,2));
    for iDiff = size(difference,1):-1:1             % Highest correlation first
      iComp                     = difference(iDiff,3);
      if isResolved(iComp)
        continue;
      end
      if difference(iDiff,1) < cfg.minShapeCorr
        break;
      end
      
      %% Keep track of global components that already have (better) matches
      iGlobal                   = difference(iDiff,2);
      if isMatched(iGlobal)
        continue;
      end
      isMatched(iGlobal)        = true;
      
      %% Keep track of temporal evolution of templates
      iLocal                    = compIndex(iComp);
      globalXY(:,iGlobal)       = chunk(iFile).globalXY(:,iLocal);
      template(:,iGlobal)       = chunk(iFile).template(:,iLocal);
      localIndex(end,iGlobal)   = iLocal;
      isResolved(iComp)         = true;
      chunk(iFile).globalID(iLocal)         = iGlobal;
      chunk(iFile).globalDistance(iLocal)   = difference(iDiff,4);
      chunk(iFile).globalShapeCorr(iLocal)  = difference(iDiff,1);
    end
    
    %% Register new global components as they appear
    compIndex(isResolved)       = [];
    iGlobal                     = size(globalXY,2) + (1:numel(compIndex));
    globalXY(:,iGlobal)         = chunk(iFile).globalXY(:,compIndex);
    template(:,iGlobal)         = chunk(iFile).template(:,compIndex);
    localIndex(end,iGlobal)     = compIndex;
    chunk(iFile).globalID(compIndex)        = iGlobal;
  end
  
  
  %% Reorder global IDs by persistence across time
  [~, globalOrder]              = sort(sum(localIndex > 0, 1), 'descend');
  translation                   = 1:numel(globalOrder);
  translation(globalOrder)      = translation;
  localIndex                    = localIndex(:, globalOrder);
  globalXY                      = globalXY(:, globalOrder);
  template                      = getLocalProperty(chunk, localIndex, 'template');
  
  fprintf(' %.3g s\n', toc(startTime));
  
  %% Write global registration information to individual segmentation files
  startTime                     = tic;
  fprintf('====  Writing global registration into individual segmentation outputs...        ');
%   frameSize                     = size(registration.reference);
%   spatial                       = zeros(prod(frameSize), size(localIndex,2));
  baseline                      = zeros(1, size(localIndex,2));
  delta                         = nan(size(localIndex,2), sum([chunk.numFrames]));
  spiking                       = delta;
  dataBase                      = baseline;     % uniquely assigned pixels only
  dataDFF                       = delta;
  dataBkg                       = delta;        % annulus estimate scaled to number of pixels
  noise2                        = baseline;
  isSignificant                 = false(size(delta));
  isBaseline                    = isSignificant;
  timeChunk                     = nan(numel(chunk), 2);
  timeConstants                 = cell(size(localIndex,2), numel(chunk));
  initConcentration             = timeConstants;
  
  totalFrames                   = 0;
  chunkCfg                      = struct();
  for iFile = 1:numel(chunk)
    fprintf('\b\b\b\b\b\b\b%3d/%-3d', iFile, numel(chunk));
    drawnow;
    
    roiFile                     = fullfile(path, chunk(iFile).roiFile);
    data                        = load(roiFile);
    cnmf                        = data.cnmf;
    roi                         = data.roi;
    source                      = data.source;
    
    %{
    % Spatial translation to global image frame
    [col, row]                  = meshgrid(1:source.cropping.selectSize(2), 1:source.cropping.selectSize(1));
    col                         = col + source.cropping.xRange(1)-1;
    row                         = row + source.cropping.yRange(1)-1;
    targetPixel                 = sub2ind(frameSize, row, col);
    %}
    
    % Reduce data storage
    if isfield(cnmf.cfg.options, 'neighborhood')
      cnmf.cfg.options          = rmfield(cnmf.cfg.options, {'pixelIndex', 'spatialIndex', 'neighborhood', 'isAdjacent', 'search'});
    end
    
    % Record configuration parameters
    chunkCfg                    = imaging.utils.mergeParameters(chunkCfg, source, iFile > 1, 'protoCfg', 'timeScale', 'rebinFactor');
    chunkCfg                    = imaging.utils.mergeParameters(chunkCfg, cnmf  , iFile > 1, 'cfg');
    
    % Record global IDs for local components
    sel                         = chunk(iFile).globalID > 0;
    chunk(iFile).globalID(sel)  = translation(chunk(iFile).globalID(sel));
    cnmf.globalID               = chunk(iFile).globalID;
    cnmf.globalDistance         = chunk(iFile).globalDistance;
    cnmf.globalShapeCorr        = chunk(iFile).globalShapeCorr;
    
    % Record global shapes for local components
    for iROI = 1:numel(roi)
      if cnmf.globalID(iROI) < 1
        roi(iROI).global        = [];
      else
        roiGlob                 = template(:, :, cnmf.globalID(iROI));
        roiGlob(isnan(roiGlob)) = 0;
        roi(iROI).global        = reshape(single(roiGlob), [cfg.templateSize, size(roiGlob,2)]);
      end
    end
    
    % Concatenate local time series for global components
    id                          = cnmf.globalID(sel);
    baseline(id)                = baseline(id) + cnmf.baseline(sel);
    tRange                      = totalFrames + (1:size(cnmf.delta,2));
    totalFrames                 = totalFrames + size(cnmf.delta,2);
    delta(id,tRange)            = cnmf.delta(sel,:);
    spiking(id,tRange)          = cnmf.spiking(sel,:);
    noise2(id)                  = noise2(id) + cnmf.noise(sel).^2;
    isSignificant(id,tRange)    = cnmf.isSignificant(sel,:);
    isBaseline(id,tRange)       = cnmf.isBaseline(sel,:);

    timeChunk(iFile,:)          = tRange([1 end]);
    if ~isempty(timeConstants)
      [timeConstants{id,iFile}] = cnmf.parameters.gn{sel};
    end
    if ~isempty(initConcentration)
      [initConcentration{id,iFile}] = cnmf.parameters.c1{sel};
    end
    
%     compShape                   = cnmf.spatial(:, sel);
    uniqueData                  = cnmf.uniqueData(sel, :);
    surroundData                = cnmf.surroundData(sel, :);
    for iComp = 1:numel(id)
      %{
      support                   = compShape(:,iComp) > 0;
      iPixel                    = targetPixel(support);
      spatial(iPixel,id(iComp)) = spatial(iPixel,id(iComp)) + compShape(support,iComp);
      %}
      
      uniqueBase                = halfSampleMode(uniqueData(iComp,:)');
      dataBase(id(iComp))       = dataBase(id(iComp)) + uniqueBase;
      dataDFF(id(iComp),tRange) = uniqueData(iComp,:) / uniqueBase - 1;
      dataBkg(id(iComp),tRange) = surroundData(iComp,:) / uniqueBase - 1;
    end
    
    data.cnmf                   = cnmf;
    data.roi                    = roi;
    save(roiFile, '-struct', 'data', '-v7.3');
    outputFiles{end+1}          = roiFile;
  end
  fprintf(' in %.3g s\n', toc(startTime));
  
  
  % Remove large data
  if isfield(chunkCfg.cfg.options, 'neighborhood')
    chunkCfg.cfg.options        = rmfield(chunkCfg.cfg.options, {'pixelIndex', 'spatialIndex', 'neighborhood', 'isAdjacent', 'search'});
  end
  
  %% Divide by number of samples for averaging
  contribWeight                 = 1 ./ sum(localIndex > 0, 1);
  cnmf                          = chunkCfg;
%   cnmf.spatial                  = sparse(bsxfun(@times, spatial, contribWeight));
  cnmf.baseline                 = bsxfun(@times, baseline, contribWeight);
  cnmf.delta                    = single(delta);
  cnmf.spiking                  = single(spiking);
  cnmf.dataBase                 = bsxfun(@times, dataBase, contribWeight);
  cnmf.dataDFF                  = single(dataDFF);
  cnmf.dataBkg                  = single(dataBkg);
  cnmf.noise                    = sqrt(bsxfun(@times, noise2, contribWeight));
  cnmf.isSignificant            = sparse(isSignificant);
  cnmf.isBaseline               = isBaseline;
  cnmf.timeChunk                = timeChunk;
  cnmf.timeConstants            = timeConstants;
  cnmf.initConcentration        = initConcentration;
  
  % Organize output
  registration.localIndex       = localIndex;
  registration.globalXY         = globalXY;
  registration.template         = template;
  registration.params           = cfg;
  

  fprintf('====  SAVING to %s\n', regFile);
  save(regFile, 'chunk', 'registration', 'cnmf', 'repository', '-v7.3');
  outputFiles{end+1}          = regFile;
  
  %% Update user-defined morphology information by considering that global IDs can have changed
  morphologyFile                = fullfile(path, [prefix algoLabel '.morphology.mat']);
  if ~exist(morphologyFile, 'file')
    return;
  end
  
  % Make a backup just in case
  backupFile                    = [morphologyFile '.old'];
  if ~copyfile(morphologyFile, backupFile, 'f')
    error('runNeuronSegmentation:globalRegistration', 'Failed to create backup morphology file %s', backupFile);
  end
  load(morphologyFile, 'morphology');
  
  % Overwrite globalIDs for all chunks
  for iChunk = 1:numel(chunk)
    morphology(iChunk).globalID = chunk(iChunk).globalID;
  end
  
  % Run combination logic for assigning a single morphology to each globally identified ROI
  combineClassifications({morphology, morphologyFile}, registration, false);
    
end