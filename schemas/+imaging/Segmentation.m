%{
# ROI segmentation
-> imaging.MotionCorrection
-> imaging.SegParameterSet
---
num_chunks                      : tinyint           # number of different segmentation chunks within the session
cross_chunks_x_shifts           : blob              # nChunks x niter, 
cross_chunks_y_shifts           : blob              # nChunks x niter, 
cross_chunks_reference_image    : longblob          # reference image for cross-chunk registration
seg_results_directory           : varchar(255)      # directory where segmentation results are stored
%}

classdef Segmentation < dj.Imported
  
  methods(Access=protected)
    function makeTuples(self, key)
      
      %% imaging directory      
      if isstruct(key)
        fovdata       = fetch(imaging.FieldOfView & key,'fov_directory');
        fov_directory = lab.utils.format_bucket_path(fovdata.fov_directory);
        keydata       = key;
      else
        fov_directory  = fetch1(imaging.FieldOfView & key,'fov_directory');
        fov_directory  = lab.utils.format_bucket_path(fov_directory);
        keydata        = fetch(key);
      end
      
      %Get motion correction results directory
      mcdata = fetch(imaging.MotionCorrection & key,'mc_results_directory');
      mc_bucket_results_directory = mcdata.mc_results_directory;
      mc_results_directory        = lab.utils.format_bucket_path(mc_bucket_results_directory);
      
      %Check if fov_directory and mc directory exists in system
      lab.utils.assert_mounted_location(fov_directory)
      lab.utils.assert_mounted_location(mc_results_directory)
      
      %Get segmentation results directory
      seg_bucket_results_directory = imaging.utils.get_seg_save_directory(mc_bucket_results_directory,key,'/');
      seg_results_directory = imaging.utils.get_seg_save_directory(mc_results_directory,key,filesep);
      
      %Create segmentation results directory
      if ~exist(seg_results_directory, 'dir')
          mkdir(seg_results_directory)
      end
      
                
      %Check if segmentation directory exists in system
      lab.utils.assert_mounted_location(seg_results_directory)
        
      result          = keydata;
      
      %% analysis params
      %%Get structure for searching in SegParameterSetParameter table      
      params        = imaging.utils.getParametersFromQuery(imaging.SegParameterSetParameter & key, ...
                                                          'seg_parameter_value');
       
      params
                                                      

      params.frameRate     = fetch1(imaging.ScanInfo & key, 'frame_rate');
      
     [chunk_cfg, cnmf_cfg, gof_cfg] = imaging.utils.separate_imaging_parameters(params);
          
      %% select tif file chunks based on behavior and bleaching
        fileChunk                            = imaging.utils.selectFileChunks(key,chunk_cfg); 
        
            
      %% run segmentation and populate this table
      if isempty(gcp('nocreate'))
          
          c = parcluster('local'); % build the 'local' cluster object
          num_workers = min(c.NumWorkers, 16);

          parpool('local', num_workers, 'IdleTimeout', 120);
      end
      
      segmentationMethod = fetch1(imaging.SegmentationMethod & key,'seg_method');
      switch segmentationMethod
        case 'cnmf'
          %outputFiles                      = imaging.segmentation.cnmf.runCNMF(fov_directory, fileChunk, cnmf_cfg, gof_cfg); 
          outputFiles                       = imaging.segmentation.cnmf.runCNMF(fov_directory, fileChunk, cnmf_cfg, gof_cfg, ...
                                                      false, true, true, '', ...
                                                      'SaveDir', seg_results_directory, ...
                                                      'McDir',   mc_results_directory);
        case 'suite2p'
          warning('suite2p is not yet supported in this pipeline')
      end
      
      % just 'posthoc' files
      fileidx     = logical(cellfun(@(x)(sum(contains(x,'posthoc')>0)),outputFiles));
      outputFiles = outputFiles(fileidx);
      
      %ALS reorder outputfiles in numerical order e.g chunks 1-4 then 5-8 etc
      outputFiles = imaging.utils.reorder_output_files(outputFiles);

%       %% shut down parallel pool
%       if ~isempty(gcp('nocreate'))
%         if exist('poolobj','var')
%           delete(poolobj)
%         else
%           delete(gcp('nocreate'))
%         end
%       end
      
      %% load summary file
      reorder = false;
      for iFile = 1:numel(outputFiles)
        if contains(outputFiles{iFile},'.fig')
          outputFiles{iFile} = [outputFiles{iFile}(1:end-3) 'mat'];
          reorder = true;
        end
      end
      if reorder; outputFiles = unique(outputFiles,'stable'); end
      
      data                                 = load(outputFiles{1});
      num_chunks                           = numel(data.chunk);
      result.num_chunks                    = num_chunks;
      result.cross_chunks_x_shifts         = data.registration.xShifts;
      result.cross_chunks_y_shifts         = data.registration.yShifts;
      result.cross_chunks_reference_image  = data.registration.reference;
      result.seg_results_directory         = seg_bucket_results_directory;
      self.insert(result)
      
      %% write to imaging.SegmentationChunks (some session chunk-specific info)
      chunkRange = zeros(num_chunks,2);
      chunkdata  = cell(1,num_chunks);
      for iChunk = 1:num_chunks
        result                       = keydata;
        chunkdata{iChunk}            = load(outputFiles{1+iChunk});
        result.segmentation_chunk_id = iChunk;
        result.tif_file_list         = chunkdata{iChunk}.source.movieFile;
        result.region_image_size     = chunkdata{iChunk}.source.cropping.selectSize;
        result.region_image_x_range  = chunkdata{iChunk}.source.cropping.xRange;
        result.region_image_y_range  = chunkdata{iChunk}.source.cropping.yRange;
        
        % figure out imaging frame range in the chunk (with respect to whole session)
        frame_range_first            = fetch1(imaging.FieldOfViewFile & key & ...
                                              sprintf('fov_filename=''%s''',result.tif_file_list{1}),'file_frame_range');
        frame_range_last             = fetch1(imaging.FieldOfViewFile & key & ...
                                              sprintf('fov_filename=''%s''',result.tif_file_list{end}),'file_frame_range');   
        chunkRange(iChunk,:)         = [frame_range_first(1) frame_range_last(end)];
        result.imaging_frame_range   = chunkRange(iChunk,:);
        
        insert(imaging.SegmentationChunks, result)
        clear result 
        
        % write global background (neuropil) activity data to imaging.SegmentationBackground
        result                       = keydata;
        result.segmentation_chunk_id = iChunk;
        result.background_spatial    = reshape(chunkdata{iChunk}.cnmf.bkgSpatial,chunkdata{iChunk}.cnmf.region.ImageSize);
        result.background_temporal   = chunkdata{iChunk}.cnmf.bkgTemporal;
        
        insert(imaging.SegmentationBackground, result)
        clear result
      end
            
      %% write ROI-specific info into relevant tables
      fprintf('inserting data in ROI tables...\n')
      % initialize data structures
      globalXY      = data.registration.globalXY;
      nROIs         = size(globalXY,2);
      totalFrames   = fetch1(imaging.ScanInfo & key,'nframes');
      roi_data      = keydata;
      morpho_data   = keydata;
      trace_data    = keydata;
      
      %Perform classification
      disp('Performing classification')
      classifier = 'generic_morphology_classifier.mat';
      classifier = load(classifier);
      name       = fieldnames(classifier);
      classifier = classifier.(name{:});
      
      metrics             = morphologyMetrics(chunkdata{iChunk});
      
      hasInfo             = metrics.Morphology < RegionMorphology.Noise;
      morphology_classified = RegionMorphology(classifier.predictFcn(metrics(hasInfo,:)))';
      chunkdata{iChunk}.cnmf.morphology(hasInfo) = morphology_classified;
      
            
      % loop through ROIs
      for iROI = 1:nROIs
        roi_data.roi_idx                    = iROI;  
        morpho_data.roi_idx                 = iROI;
        trace_data.roi_idx                  = iROI;
        
        roi_data.roi_global_xy              = globalXY(:,iROI);
        roi_data.roi_is_in_chunks           = [];   
        roi_data.roi_spatial                = [];
        
        %Save all chunks that were present at least on first ROI
        if isempty(data.cnmf.timeConstants{iROI,1})
            continue
        end

        trace_data.time_constants           = data.cnmf.timeConstants{iROI,1};
        trace_data.init_concentration       = data.cnmf.initConcentration{iROI,1};
        trace_data.dff_roi                  = nan(1,totalFrames);
        trace_data.dff_surround             = nan(1,totalFrames);
        trace_data.spiking                  = nan(1,totalFrames);
        trace_data.dff_roi_is_significant   = nan(1,totalFrames);
        trace_data.dff_roi_is_baseline      = nan(1,totalFrames);
        
        % now look in file chunks and fill activity etc
        for iChunk = 1:numel(chunkdata)
          % find roi in chunks
          localIdx                          = data.chunk(iChunk).globalID== iROI;
          if sum(localIdx) == 0; continue; end
          roi_data.roi_is_in_chunks         = [roi_data.roi_is_in_chunks iChunk];
  
          % activity traces
          frameIdx                                    = chunkRange(iChunk,1):chunkRange(iChunk,2);
          uniqueData                                  = chunkdata{iChunk}.cnmf.uniqueData(localIdx,:);
          uniqueBase                                  = halfSampleMode(uniqueData');
          surroundData                                = chunkdata{iChunk}.cnmf.surroundData(localIdx,:);
          trace_data.dff_roi(frameIdx)                = uniqueData / uniqueBase - 1;
          trace_data.dff_surround(frameIdx)           = surroundData / uniqueBase - 1;
          trace_data.spiking(frameIdx)                = chunkdata{iChunk}.cnmf.spiking(localIdx,:);
          trace_data.dff_roi_is_significant(frameIdx) = chunkdata{iChunk}.cnmf.isSignificant(localIdx,:);
          trace_data.dff_roi_is_baseline(frameIdx)    = chunkdata{iChunk}.cnmf.isBaseline(localIdx,:);
          
          % roi: shape and morphological classification
          if isempty(roi_data.roi_spatial)
            roi_data.roi_spatial      = reshape(full(chunkdata{iChunk}.cnmf.spatial(:,localIdx)),chunkdata{iChunk}.cnmf.region.ImageSize);
            roi_data.surround_spatial = reshape(full(chunkdata{iChunk}.cnmf.surround(:,localIdx)),chunkdata{iChunk}.cnmf.region.ImageSize);
            morpho_data.morphology    = char(chunkdata{iChunk}.cnmf.morphology(localIdx));
          end
        end
        
        % insert in tables
        inserti(imaging.SegmentationRoi, roi_data)
        inserti(imaging.SegmentationRoiMorphologyAuto, morpho_data)
        inserti(imaging.Trace, trace_data)
      end

    end
  end
end
