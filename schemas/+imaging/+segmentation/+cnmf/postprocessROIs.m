%% --------------------------------------------------------------------------------------------------
function [info, outputFiles] = postprocessROIs(info, index, roiFile, summaryFile, cnmf, source, binnedF, cfg, repository, lazy, outputFiles)
  
  % Check for existing output
  [dir, name, ext]    = parsePath(roiFile);
  info(index).roiFile = [name, '-posthoc.mat'];
  roiFile             = fullfile(dir, info(index).roiFile);

  if lazy && exist(roiFile, 'file')
    fprintf('====  Existing post-processing found:  %s\n', roiFile);
    load(roiFile, 'cnmf');

  else
    startTime         = tic;
    fprintf('====  Computing baselines and rearranging prediction...');
    cnmf              = imaging.segmentation.cnmf.computeBaselines(cnmf, binnedF, cfg);
    fprintf(' %.3g s\n', toc(startTime));

    startTime         = tic;
    fprintf('====  Computing morphological and other metrics...');
    [cnmf, gof, roi]  = imaging.segmentation.cnmf.classifyMorphology(cnmf, binnedF, source.cropping.selectSize, cfg, source.protoCfg);
    fprintf(' %.3g s\n', toc(startTime));

    fprintf('====  SAVING to %s\n', roiFile);
    save(roiFile, 'cnmf', 'source', 'gof', 'roi', 'repository', '-v7.3');
    outputFiles{end+1}= roiFile;
  end

  
  % Compute registration information: centers of ROIs and baseline shapes
  imgSize             = max(cnmf.bound(1:end-1,3:4), [], 1);
  shape               = zeros([imgSize, size(cnmf.spatial,2) - 1]);
  centroid            = nan(2, size(cnmf.spatial,2) - 1);
  if ~isempty(shape)
    for iComp = 1:size(shape,3)
      img             = getRegionChunk(cnmf.bound, source.cropping.selectSize, iComp, cnmf.spatial(:,iComp));
      imgX            = 1:size(img,2);
      imgY            = 1:size(img,1);
      [x,y]           = meshgrid(imgX, imgY);
      centroid(1,iComp) = sum(img(:) .* x(:));
      centroid(2,iComp) = sum(img(:) .* y(:));
      shape(imgY,imgX,iComp)  = img;      % * cnmf.baseline(iComp);
    end
  end
  
  info(index).shape           = shape;
  info(index).centroid        = centroid;
  info(index).localXY         = bsxfun(@plus, [source.cropping.xRange(1); source.cropping.yRange(1)], cnmf.bound(:,1:2)' + centroid);
  info(index).morphology      = cnmf.morphology;
  info(index).diameter        = sqrt( 4*[cnmf.property.Area]/pi );
  
end