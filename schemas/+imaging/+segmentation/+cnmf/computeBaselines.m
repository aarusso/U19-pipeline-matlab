function cnmf = computeBaselines(cnmf, binnedF, cfg)

  cnmf.morphology     = repmat(RegionMorphology.Doughnut, 1, size(cnmf.spatial,2)-1);
  
  % Normalize spatial part to have unit integral
  energy              = full(sum(cnmf.spatial, 1));
  cnmf.spatial        = bsxfun(@times, cnmf.spatial , 1./energy);
  cnmf.temporal       = bsxfun(@times, cnmf.temporal,    energy');
  cnmf.spiking        = sparse(cnmf.spiking);
  
  % Compute quantities within a nominal region of significant contribution
  cnmf.inside         = false(size(cnmf.spatial,1), size(cnmf.spatial,2)-1);
  cnmf.insideWeight   = zeros(1, size(cnmf.inside,2));
  cnmf.core           = false(size(cnmf.spatial,1), size(cnmf.spatial,2)-1);
  cnmf.coreWeight     = zeros(1, size(cnmf.inside,2));
  for iComp = 1:size(cnmf.inside,2)
    [indices, cnmf.insideWeight(iComp)]   ...
                      = getCorePixels(cnmf.spatial(:, iComp), cfg.containEnergy);
    cnmf.inside(indices, iComp) = true;

    [indices, cnmf.coreWeight(iComp)]     ...
                      = getCorePixels(cnmf.spatial(:, iComp), cfg.coreEnergy);
    cnmf.core(indices, iComp)   = true;
  end
  cnmf.inside         = sparse(cnmf.inside);
  cnmf.core           = sparse(cnmf.core);
  cnmf.uniqueWeight   = full(sum(cnmf.spatial(:,1:end-1) .* cnmf.unique, 1));

  % Identify the "baseline" state by assuming sparse(-enough) temporal activity: locate the modal
  % temporal value within a few noise level factors of the minimum
  cnmf.noise          = nan(1, size(cnmf.inside,2));
  baseline            = nan(1, size(cnmf.inside,2));
  cnmf.isBaseline     = false(size(cnmf.temporal,1)-1, size(cnmf.temporal,2));
  cnmf.isSignificant  = false(size(cnmf.temporal,1)-1, size(cnmf.temporal,2));
  for iComp = 1:numel(baseline)
    cnmf.noise(iComp) = sqrt(sum(cnmf.parameters.sn(          ... per pixel data noise level
                                  cnmf.inside(:,iComp)        ...
                                ).^2)                         ...
                            );
    binnedNoise       = cnmf.noise(iComp) / sqrt(cfg.timeScale);
    
    compTrace         = full(cnmf.temporal(iComp,:))';
    smoothTrace       = smooth(compTrace, cfg.timeScale, 'moving');
    
    % Detect baseline state as spans of time without contiguous periods above threshold
    for iter = 1:2
      mode            = halfSampleMode(compTrace);
      activity        = cnmf.insideWeight(iComp) * ( smoothTrace - mode );
      isBaseline      = ~periodsAboveSpan ( activity > cfg.maxBaseline * binnedNoise    ...
                                          , cfg.minTimeSpan * cfg.timeScale             ...
                                          );
    end
    
    % Mark transients as contiguous periods of activity above the given threshold
    isSignificant     = periodsAboveSpan ( activity > cfg.minActivation * binnedNoise   ...
                                         , cfg.minTimeSpan * cfg.timeScale              ...
                                         )                                              ...
                      | periodsAboveSpan ( activity > cfg.highActivation * binnedNoise  ...
                                         , cfg.timeScale                                ...
                                         );
                                            
    baseline(iComp)             = mode;
    cnmf.isBaseline(iComp,:)    = isBaseline;
    cnmf.isSignificant(iComp,:) = isSignificant;
    
    % Require components to have at least one contiguous chunk of time with above-threshold activity
    if ~any(isSignificant)
      cnmf.morphology(iComp)    = RegionMorphology.Noise;
    end
  end
%   cnmf.isBaseline     = sparse(cnmf.isBaseline);

  
  % Assume that the least amount of fluorescence is explained by (neuropil) background; determine
  % the zero background level using the lowest few smoothed timepoints
  bkgTrace            = full(cnmf.temporal(end,:));
  smoothSpan          = cfg.bkgTimeSpan * cfg.timeScale / numel(bkgTrace);
  bkgTrace            = smooth(bkgTrace, smoothSpan, 'loess');
  cnmf.bkgZero        = quantile(bkgTrace, 2*smoothSpan);
  

  % Estimate baseline by absorbing all of the background in uniquely owned pixels 
  isValid             = cnmf.uniqueWeight > 0;
  cnmf.morphology(~isValid) = RegionMorphology.Noise;
  bkgBase             = full( double(cnmf.bkgZero) * cnmf.spatial(:,end) )';
  bkgContrib          = zeros(1, size(cnmf.unique,2));
  dTemporal           = bsxfun(@minus, cnmf.temporal(1:end-1,:), baseline');
  cnmf.baseline       = baseline;
  cnmf.delta          = bsxfun(@times, dTemporal, 1./baseline');
  bkgContrib(isValid)       = min ( ( bkgBase * cnmf.unique(:,isValid) )                    ...
                                   ./ cnmf.uniqueWeight(:,isValid)                          ...
                                  , ( bkgBase * (cnmf.spatial(:,isValid) > 0) )             ...
                                  );
  cnmf.baseline(isValid)    = baseline(isValid) + bkgContrib(isValid);
  cnmf.delta(isValid,:)     = bsxfun(@times, dTemporal(isValid,:), 1./cnmf.baseline(isValid)');
  isSignificant             = cnmf.isSignificant(iComp,:);
  for iComp = 1:size(isSignificant,1)
    isSignificant(iComp,:)  = isSignificant(iComp,:)                                        ...
                            & periodsAboveSpan( cnmf.delta(iComp,:) >= cfg.minDeltaFoverF   ...
                                              , cfg.timeScale                               ...
                                              );
  end
  cfg.isSignificant         = sparse(isSignificant);

  
  % Rearrange the prediction to be of the form:
  %   raw data   PMT zero            shape    baseline            "dF/F"       background
  %     Y(t)   -   Y_0     ~  sum_i   s_i   *   F_i^b   * [ 1 + \Delta_i(t) ] +  G g(t)
  % and where:
  %     || s_i ||_1 = 1
  %     \Delta_i(t) ~ 0   during the baseline state of neuron-like components
  %            g(t) ~ 0   during the baseline state of the background 
  %
  % Due to the formulation of the solution (matrix factorization without a constant term) this
  % cannot be exactly observed, but we do the best we can at the cost of not really getting the
  % background component shape correct:
  %
  %     Y(t)   -   Y_0     ~  sum_i   a_i * ( b_i + c_i^b ) * [ 1 + (c_i(t) - c_i^b)/(b_i + c_i^b) ]
  %                        +  b f(t) - sum_i a_i b_i - Y_0
  %
  % For convenience we organize the matrices such that the full prediction is given by:
  %     bsxfun(@times, baseline, spatial) * (1 + delta) + background
  % where background consists of the original time-dependent piece b f(t) plus a spatially varying
  % (but constant in time) offset

  predF               = double(1 + rebin(cnmf.delta, cfg.timeScale, 2));
  cnmf.offset         = bsxfun(@times, cnmf.spatial(:,1:end-1), bkgContrib);
  cnmf.offset         = -sum(cnmf.offset, 2);         % - double(cnmf.zeroLevel);
  cnmf.bkgSpatial     = full(cnmf.spatial(:,end));
  cnmf.bkgTemporal    = full(cnmf.temporal(end,:));   % - cnmf.zeroLevel;

  
  % Recompute residual w.r.t. data using the revised baseline (bleh!)
  binnedPred          = bsxfun(@times, cnmf.baseline, cnmf.spatial(:,1:end-1)) * predF;
  binnedPred          = binnedPred + cnmf.bkgSpatial * rebin(cnmf.bkgTemporal, cfg.timeScale, 2);
  binnedPred          = bsxfun(@plus, full(cnmf.offset), binnedPred);
  movieSize           = size(binnedF);
  residual            = binnedF - reshape(single(binnedPred), movieSize);

  
  % Compute adjacency information
  pixel               = find(any(cnmf.spatial(:,1:end-1),2));     % all pixels with components
  [row, col]          = ind2sub(movieSize(1:2), pixel);
  neighborhood        = getNeighborhoodIndex(row, col, movieSize, ones(3), true(movieSize(1:2)));
  
  [pixel,component]   = find(cnmf.spatial(pixel,1:end-1));
  adjacency           = neighborhood(pixel);
  component           = cellfun(@(x,y) y*ones(1,numel(x)), adjacency, num2cell(component), 'UniformOutput', false);
  neighborhood        = sparse([adjacency{:}], [component{:}], 1, prod(movieSize(1:2)), size(cnmf.spatial,2)-1);
  cnmf.isAdjacent     = (neighborhood' * neighborhood) > 0;

  % Compute component goodness criteria
  residual            = reshape(residual, [], size(residual,3));
  cnmf.hellinger      = nan(numel(cnmf.baseline), size(residual,2));
  cnmf.shapeCorr      = nan(numel(cnmf.baseline), size(residual,2));
  for iComp = 1:numel(cnmf.baseline)
    support           = cnmf.spatial(:,iComp) > 0;
    spatial           = full(cnmf.spatial(support, iComp));
    prediction        = cnmf.baseline(iComp) * spatial * predF(iComp,:);
    dataShape         = residual(support, :) + prediction;
    cnmf.shapeCorr(iComp,:)     = corr(spatial, dataShape);
    
    dataShape(dataShape < 0)    = 0;
    dataShape         = bsxfun(@times, dataShape, saferdiv(1,sum(dataShape,1)));
    hellinger         = bsxfun(@minus, sqrt(dataShape), sqrt(spatial)).^2;
    cnmf.hellinger(iComp,:)     = sqrt( sum(hellinger,1) / 2 );
  end
    
end