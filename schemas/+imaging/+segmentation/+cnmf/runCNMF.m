function [outputFiles,fileChunk] = runCNMF(moviePath, fileChunk, cfg, gofCfg, redoPostProcessing, fromProtoSegments, lazy, scratchDir, varargin)

%% ------------------------------------------------------------------------
%% segmentation code stripped down for datajoint
%% ------------------------------------------------------------------------

%% --------------------------------------------------------------------------------------------------

  warning('off','MATLAB:nargchk:deprecated');       % HACK because of cvx
  
  if nargin < 2 
    fileChunk             = [];
  end
  if nargin < 3 
    cfg                   = [];
  end
  if nargin < 4 
    gofCfg                = [];
  end
  if nargin < 5 || isempty(redoPostProcessing)
    redoPostProcessing    = false;
  end
  if nargin < 6 || isempty(fromProtoSegments)
    fromProtoSegments     = true;
  end
  if nargin < 7 || isempty(lazy)
    lazy                  = true;
  end
  if nargin < 8
    scratchDir            = '';
  end
  if nargin < 9
    saveDir            = '';
    mcdir              = '';
  else
      if mod(length(varargin),2 ~= 0)
          error('Varargin must come in pairs')
      end
      for i=1:2:length(varargin)
          if strcmp(varargin{i}, 'SaveDir')
              savedir = varargin{i+1};
          elseif strcmp(varargin{i}, 'McDir')
              mcdir = varargin{i+1};
          end
      end
  end
  
  repository                  = [];
  
  % Parallel pool preferences
  parSettings                 = parallel.Settings;
  parSettings.Pool.AutoCreate = false;
  
  % segmentation settings
  if fromProtoSegments
    method                = { 'search_method' , 'dilate'                          ... % search locations when updating spatial components
                            , 'se'            , strel('disk',4)                   ... % morphological element for method dilate
                            };
  else
    method                = { 'search_method' , 'ellipse'                         ... % search locations when updating spatial components
                            };
  end
  cfg.options             = CNMFSetParms( 'd1', 0,'d2', 0                         ... % dimensions of datasets
                                        , 'dist'          , 3                     ... 
                                        , 'deconv_method' , 'constrained_foopsi'  ... % activity deconvolution method
                                        , 'temporal_iter' , 2                     ... % number of block-coordinate descent steps 
                                        , 'fudge_factor'  , 0.9                   ... % bias correction for AR coefficients
                                        , 'merge_thr'     , 0.8                   ... % merging threshold
                                        , 'bas_nonneg'    , true                  ...
                                        , 'block_size'    , 10                    ... for FFT preprocessing 
                                        , 'split_data'    , true                  ... for FFT preprocessing 
                                        , method{:}                               ...
                                        );

  % Get movies and associated statistics info
  outputFiles           = {};
  movieFile             = rdir(fullfile(moviePath, '*.tif'));
  movieFile             = {movieFile.name};
  if isempty(movieFile)
    movieFile           = rdir(fullfile(moviePath, '*.stats.mat'));
    movieFile           = {movieFile.name};
    [dir,name]          = parsePath(movieFile);
    [~,name]            = parsePath(name);
    movieFile           = fullfile(dir, strcat(name, '.tif'));
  end

  % Collect the desired number of files into processing chunks. Can be done
  % explictly by passing fileChunk or automatically by chunking up
  % according to max number of files per chunk, cfg.filesPerChunk
  % fileChunk an array of size chunks x 2, where rows are [firstFileIdx lastFileIdx] 
  if isempty(fileChunk)
    fileChunkTemp       = chunkIndices(1, cfg.filesPerChunk);
    numChunks           = numel(fileChunkTemp)-1;
    fileChunk           = zeros(numChunks,2);
    for iChunk = 1:numChunks
      fileChunk(iChunk,:) = [fileChunkTemp(iChunk) fileChunkTemp(iChunk+1)-1];
    end
  end
  
  [~,name]              = parsePath(movieFile);
  acquisInfo            = regexp(name, '(.+)[_-]([0-9]+)$', 'tokens', 'once');
  acquisInfo            = cat(1, acquisInfo{:});
  acquis                = unique(acquisInfo(:,1));
  acquisPrefix          = fullfile(savedir, acquis{1});

  % Proto-segmentation
  if fromProtoSegments
    [protoROI, outputFiles]       ...
                        = imaging.segmentation.cnmf.getProtoSegmentation(movieFile, fileChunk, acquisPrefix, lazy, cfg, outputFiles, scratchDir, mcdir);
  else
    protoROI            = [];
  end

  % Full segmentation
  nil                 = cell(1,numel(fileChunk)-1);
  chunk               = struct('movieFile', nil, 'roiFile', nil);
  for iChunk = 1:size(fileChunk,1)
    iFile                     = fileChunk(iChunk,1):fileChunk(iChunk,2);
    chunkFiles                = movieFile(iFile);
    chunk(iChunk).movieFile   = stripPath(chunkFiles);

    [cnmf, source, roiFile, summaryFile, gofCfg.timeScale, binnedY, outputFiles]  ...
                              = imaging.segmentation.cnmf.cnmfSegmentation( ...
                              chunkFiles, acquisPrefix, iFile, protoROI, cfg, repository, lazy, outputFiles, scratchDir, mcdir);
    if ~isempty(cnmf)
      chunk(iChunk).reference = source.fileMCorr.reference;
      chunk(iChunk).numFrames = size(cnmf.temporal,2);
      [chunk, outputFiles]    = imaging.segmentation.cnmf.postprocessROIs(...
          chunk, iChunk, roiFile, summaryFile, cnmf, source, binnedY, gofCfg, repository, ~redoPostProcessing, outputFiles);
    end
    clear cnmf source binnedY;
  end

  chunk(cellfun(@isempty, {chunk.roiFile})) = [];
  if ~isempty(chunk)
    outputFiles     = imaging.segmentation.cnmf.globalRegistration(chunk, savedir, acquisPrefix, repository, cfg, outputFiles);
  end
  
  outputFiles       = unique(outputFiles);
  
end