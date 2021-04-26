function [cnmf, gof, roi] = classifyMorphology(cnmf, binnedF, frameSize, cfg, protoCfg)
  
  somaElem                      = strel('disk', protoCfg.somaRadius);
  neuriteElem                   = strel('disk', floor(protoCfg.somaRadius/2));
  meanF                         = mean(binnedF, 3);
  
  gof.cfg                       = cfg;
  gof.numPixels                 = zeros(size(cnmf.baseline), 'int32');
  gof.numCorePixels             = zeros(size(cnmf.baseline), 'int32');
  gof.perimeter                 = zeros(size(cnmf.baseline), 'int32');
  gof.xyCovariance              = zeros(size(cnmf.baseline));
  gof.majorAxis                 = zeros(size(cnmf.baseline));
  gof.minorAxis                 = zeros(size(cnmf.baseline));
  gof.activation                = zeros(size(cnmf.baseline));
  gof.shapeVariance             = zeros(size(cnmf.baseline));
  gof.shapeCorrelation          = zeros(size(cnmf.baseline));
  gof.hellingerDistance         = zeros(size(cnmf.baseline));
  gof.spatialCoherence          = zeros(size(cnmf.baseline));
  gof.numSomaPieces             = zeros(size(cnmf.baseline), 'int32');
  gof.numPunctaPieces           = zeros(size(cnmf.baseline), 'int32');
  gof.numSomaLike               = zeros(size(cnmf.baseline), 'int32');
  gof.numPunctaLike             = zeros(size(cnmf.baseline), 'int32');
  gof.punctaFraction            = zeros(size(cnmf.baseline));
  gof.skeletonFraction          = zeros(size(cnmf.baseline));
  gof.centerWeight              = zeros(size(cnmf.baseline));
  gof.ringWeight                = zeros(size(cnmf.baseline));
  
  activity                      = rebin(full(cnmf.delta .* cnmf.isSignificant), cfg.timeScale, 2);
  isBaseline                    = rebin(full(cnmf.isBaseline), cfg.timeScale, 2, @all) > 0;
  roi                           = repmat(struct(), 1, numel(cnmf.baseline));
  for iComp = 1:numel(cnmf.baseline)
    % Compute contour extents for display purposes
    [spatial,inside,core,muF]   = getRegionChunk( cnmf, frameSize, iComp, cnmf.spatial(:,iComp)     ...
                                                , cnmf.inside(:,iComp), cnmf.core(:,iComp), meanF   ...
                                                );
    [roi(iComp).support, ~, support]            = boundaryLines(spatial > 0);
    [roi(iComp).inside, gof.perimeter(iComp)]   = boundaryLines(inside);
    roi(iComp).core             = boundaryLines(core);

    % Compute ranking variable
    gof.activation(iComp)       = cnmf.baseline(iComp) * max(cnmf.delta(iComp,:)) / cnmf.noise(iComp);
    
    
    % Shape discrepancy
    [mode, sigma]               = estimateLocationScale(cnmf.hellinger(iComp, isBaseline(iComp,:)));
    sumActivity                 = sum( activity(iComp,:) );
    gof.shapeCorrelation(iComp) = sum( activity(iComp,:) .* cnmf.shapeCorr(iComp,:)          ) / sumActivity;
    gof.hellingerDistance(iComp)= sum( activity(iComp,:) .* cnmf.hellinger(iComp,:)          ) / sumActivity;
    gof.spatialCoherence(iComp) = sum( activity(iComp,:) .* (mode - cnmf.hellinger(iComp,:)) ) / sumActivity;
                        
    % Number of pixels in spatial support and around the peak
    peakHeight                  = max(cnmf.spatial(:,iComp));
    gof.numPixels(iComp)        = sum(support(:));
    gof.numCorePixels(iComp)    = full(sum(cnmf.spatial(:,iComp) > peakHeight/2));

    % Component shape
    [gof.xyCovariance(iComp), ~, gof.majorAxis(iComp), gof.minorAxis(iComp)]          ...
                                = shapeCovariance ( min ( cnmf.spatial(:,iComp)       ...
                                                        , peakHeight/2                ...
                                                        )                             ...
                                                  , frameSize                         ...
                                                  );
    gof.shapeVariance(iComp)    = var(cnmf.spatial(:,iComp)) / mean(cnmf.spatial(:,iComp));
    
    % Soma-like blobs
    somaLike                    = imerode(inside, somaElem);
    pieces                      = bwconncomp(bwmorph(somaLike, 'clean'));
    gof.numSomaPieces(iComp)    = pieces.NumObjects;
    if pieces.NumObjects > 0
      [~,iMax]                  = max(cellfun(@numel, pieces.PixelIdxList));
      gof.numSomaLike(iComp)    = numel(pieces.PixelIdxList{iMax});
    end
    
    % Puncta like spots
    punctaShape                 = spatial;
    punctaShape(punctaShape < 0.25 * peakHeight)  = 0;
    pieces                      = bwconncomp(punctaShape);
    gof.numPunctaPieces(iComp)  = pieces.NumObjects;
    if pieces.NumObjects > 0
      [~,iMax]                  = max(cellfun(@numel, pieces.PixelIdxList));
      gof.numPunctaLike(iComp)  = numel(pieces.PixelIdxList{iMax});
    end
    gof.punctaFraction(iComp)   = sum(punctaShape(:));

    % Thinness of component
    skeleton                    = imclose(inside, somaElem);
    skeleton                    = imdilate(bwmorph(skeleton, 'thin', inf), neuriteElem);
    gof.skeletonFraction(iComp) = sum(inside(:) .* skeleton(:)) / sum(inside(:));

    % Doughnut shape parameters
    shape                       = bwconvhull(inside, 'union');
    muF(~shape & spatial <= 0)  = 0;
    muF                         = muF / sum(muF(:));
    center                      = muF .* imerode(shape, somaElem);
    ring                        = muF .* (center == 0);
    gof.centerWeight(iComp)     = imaging.utils.negativeIfNaN(quantile(center(center > 0), 0.25));
    gof.ringWeight(iComp)       = imaging.utils.negativeIfNaN(quantile(ring(ring > 0)    , 0.75));
  end
  
end