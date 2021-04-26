%---------------------------------------------------------------------------------------------------
function cnmf = computeDataChecks(cnmf, source, Y, cfg)

  % Compute pixels that belong solely to one component
  cnmf.unique               = cnmf.spatial(:,1:end-1) > 0;
  hasOverlap                = sum(cnmf.unique, 2) > 1;
  cnmf.unique(hasOverlap,:) = false;
  cnmf.uniqueWeight         = full(sum(cnmf.spatial(:,1:end-1) .* cnmf.unique, 1));
  isValid                   = cnmf.uniqueWeight > 0;
  cnmf.unique(:,~isValid)   = 0;
  
  % Collect data traces within uniquely assigned pixels
  cnmf.uniqueData           = nan(numel(cnmf.uniqueWeight), size(Y,2), 'like', Y);
  for iComp = 1:size(cnmf.uniqueData,1)
    cnmf.uniqueData(iComp,:)= mean(Y(cnmf.unique(:,iComp),:), 1);
  end
  
  % Exclude all identified neural activity
  frameSize                 = source.cropping.selectSize;
  neuropilOnly              = reshape(full(~any(source.prototypes, 2)), frameSize);

  % Compute mask for pixels surrounding each component
  leewayElem                = strel('disk', cfg.pixelsSurround(1));
  surroundElem              = strel('disk', cfg.pixelsSurround(2));
  surround                  = false(size(cnmf.unique));
  cnmf.surroundData         = nan(size(cnmf.uniqueData), 'like', Y);
  for iComp = 1:size(surround,2)
    coordOffset             = cnmf.bound(iComp, 1:2) - cfg.pixelsSurround(2);
    
    % Get component shape within a bounding box with leeway for dilation
    compShape               = false(cnmf.bound(iComp, [4 3]) + 2*cfg.pixelsSurround(2));
    [row,col]               = ind2sub(frameSize, find(cnmf.spatial(:,iComp) > 0));
    row                     = row - coordOffset(2);
    col                     = col - coordOffset(1);
    pixels                  = sub2ind(size(compShape), row, col);
    compShape(pixels)       = true;
    
    % Get neuropil-only mask within the same bounding box
    isNeuropil              = getChunkInBox(coordOffset(1), coordOffset(2), size(compShape,2), size(compShape,1), neuropilOnly, 1, false);
    
                                          
    % Dilate the component shape twice to obtain an annulus
    compSurround            = imdilate(compShape, surroundElem) & ~imdilate(compShape, leewayElem);
    [row,col]               = find(compSurround & isNeuropil);
    row                     = row + coordOffset(2);
    col                     = col + coordOffset(1);
    inRange                 = row >= 1 & row <= frameSize(1)   ...
                            & col >= 1 & col <= frameSize(2)   ...
                            ;
    surround( sub2ind(frameSize, row(inRange), col(inRange)), iComp ) = true;
    
    % Collect data trace in surrounding pixels
    cnmf.surroundData(iComp,:)  = mean(Y(surround(:,iComp),:), 1);
  end
  cnmf.surround             = sparse(surround);
  
end
