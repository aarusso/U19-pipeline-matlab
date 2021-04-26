%{
# time binned activity by trial
-> imaging.FieldOfView
-> meso_analysis.StandardizedTime
-> meso_analysis.TrialSelectionParams 

global_roi_idx         : int           # roi_idx in Suite2ptrace
trial_idx              : int           # trial number as in meso_analysis.Trialstats
---
binned_dff             : blob          # binned Dff, 1 row per neuron per trialStruct 
%}
 
 
classdef BinnedTrace < dj.Computed
  methods(Access=protected)
    function makeTuples(self, key)
      
      if ~isstruct(key)
        result = fetch(key);
      else
        result = key;
      end
      
      %% retrieve dff data
      data = fetch( meso_analysis.Suite2ptrace & key, 'dff_roi_uncorrected','roi_idx', 'is_cell');
      dff = cell2mat({data.dff_roi_uncorrected}');
      global_idx = [data.roi_idx]';
      is_cell = vertcat(data(:).is_cell);
      
      %% use manual curation to select only good rois
%       goodMorphoOnly = fetch1(meso_analysis.BinningParameters & key, 'good_morpho_only');
%       if goodMorphoOnly == 1
%         morpho               = fetchn(meso.SegmentationRoiMorphologyManual & key, 'morphology');
%       else
%         morpho               = [];
%       end
%       
%       if isempty(morpho)
%         isgood               = true(1,size(dff,1));
%       else
%         isgood               = strcmp(morpho,'Doughnut') | strcmp(morpho,'Blob');
%       end
%       isallnan               = sum(~isfinite(dff),2) == size(dff,2); % some neurons are nan'd or inf'd out
%       isgood                 = isgood & ~isallnan;
%       
%       dff(~isgood,:)         = [];
%       global_idx(~isgood,:)  = [];

%% for suite2p we need to define different metrics (eg classifier, skewness) 
        dff                    = dff(is_cell(:,1)==1,:);
        %dff(:,[1:2999, 36701:end]) = nan;
        global_idx             = global_idx(is_cell(:,1)==1);
      %% get behavioral trial info
 
      syncinfo = fetch(imaging.SyncImagingBehavior & key, '*');
 
 
    %% get trial info wrt segmented frames
      segmented_frames = ~all(isnan(dff));
 
      % this is trial within block, we need trial within session
      % MDia added indexing for sessions where scanimage started later
      trial_wi_block_by_im_frame = syncinfo.sync_behav_trial_by_im_frame(syncinfo.sync_im_frame_global ~=0);
      block_by_im_frame          = syncinfo.sync_behav_block_by_im_frame(syncinfo.sync_im_frame_global ~=0);
      im_frame_id      = syncinfo.sync_im_frame_global(syncinfo.sync_im_frame_global ~=0);
      seg_frame_id     = im_frame_id(segmented_frames);
      trial_span       = syncinfo.sync_im_frame_span_by_behav_trial;
      trial_span       = vertcat(trial_span{:});
      
      % trial starts after segmentation starts and ends before segmentation stops
      is_within_segmentation = trial_span(:,1) > seg_frame_id(1) & trial_span(:,2) < seg_frame_id(end);
      
      % convert to trial within session
      first_trial = fetchn(behavior.TowersBlock&key,'first_trial');
      trial2add = first_trial(block_by_im_frame(block_by_im_frame>0))';
      trial_by_im_frame = nan(size(trial_wi_block_by_im_frame));
      trial_by_im_frame(trial_wi_block_by_im_frame>0) = trial_wi_block_by_im_frame(trial_wi_block_by_im_frame>0)+trial2add-1;
 
      %% now that trials are wrt segmented frames, can select for good trials based on session trial idx in .TrialStats
      trial_stats = fetch(meso_analysis.Trialstats & key, 'is_not_excess_travel','mean_perf_block', ...
                                        'mean_bias_block','mean_perf_block','is_towers_task','is_visguided_task','block_id');
      trial_idx = [trial_stats.trial_idx];
      
      block_id  = [trial_stats.block_id]; % 1 x num trials
      [n_trials,~, bin]  = histcounts(block_id, 'BinMethod','integers'); %1 x num blocks
      n_trials  = n_trials(bin); % 1 x num trials
                                    
      trial_selection_parameters = fetch(meso_analysis.TrialSelectionParams & key,'no_excess_travel','towers_perf_thresh',...
                                 'towers_bias_thresh','visguide_perf_thresh','visguide_bias_thresh','min_trials_per_block');
      
      if logical(trial_selection_parameters.no_excess_travel)            
         good_running = logical([trial_stats.is_not_excess_travel]);  
      else
         good_running = true(size([trial_stats.is_not_excess_travel]));
      end
      
      good_towers_trials = good_running &  n_trials > trial_selection_parameters.min_trials_per_block & ...
                           [trial_stats.is_towers_task] & ...
                           [trial_stats.mean_perf_block] >= trial_selection_parameters.towers_perf_thresh & ...
                           [trial_stats.mean_bias_block] <= trial_selection_parameters.towers_bias_thresh;
      
      good_visguide_trials = good_running &  n_trials > trial_selection_parameters.min_trials_per_block & ...
                           [trial_stats.is_visguided_task] & ...
                           [trial_stats.mean_perf_block] > trial_selection_parameters.visguide_perf_thresh & ...
                           [trial_stats.mean_bias_block] < trial_selection_parameters.visguide_bias_thresh;
                       
      good_trial     = good_towers_trials | good_visguide_trials;
                       
      good_trial_idx = trial_idx(good_trial & is_within_segmentation(trial_idx)');

                         
      %% Get trial bins (which trial bin # corresponds to each imaging frame)
      good_trial_frames  = ismember(trial_by_im_frame, good_trial_idx);      
      
      trial_by_im_frame = trial_by_im_frame(good_trial_frames);
      trial_out_idx   = unique(trial_by_im_frame); % trials that were both good and segmented
      
      trial_bin_by_im_frame = binarySearch(trial_out_idx, trial_by_im_frame, -1, -1);
 
      %% Get epoch bins 
%       epochEdges       = getEpochEdges(key);
      [standardizedTime, epochEdges] = fetchn(meso_analysis.StandardizedTime & key, 'standardized_time', 'binned_time');
        standardizedTime = standardizedTime{:}(syncinfo.sync_im_frame_global ~=0);
        epochEdges = epochEdges{:};
      epoch_by_frame     = standardizedTime(segmented_frames & good_trial_frames);
      epoch_bin_by_frame = binarySearch(epochEdges, epoch_by_frame, -1, -1);
      
      %% loop through ROIs and trials and bin     
      dff_segmented    = dff(:,segmented_frames & good_trial_frames)';
      
      for iROI = 1:size(dff,1)          
        thisresult                = result;
        thisresult.global_roi_idx = global_idx(iROI);
        
        % bin in nested function
        epochDFF     = bin_trial(dff_segmented(:,iROI), epochEdges, trial_out_idx, epoch_bin_by_frame, trial_bin_by_im_frame); % bins x trials
 
        for iTrial = 1:numel(trial_out_idx)
          thisresult.trial_idx  = trial_out_idx(iTrial);
          thisresult.binned_dff = epochDFF(:,iTrial);
          self.insert(thisresult)
        end
      end
 
    end
  end
end
 
 
% =======================================================================
% function epochEdges = getEpochEdges(key)
%   epochBinning = fetch1(meso_analysis.BinningParameters & key, 'epoch_binning');
%   epochEdges   = accumfun(2, @(x,y,z) butlast(linspace(x,y,z)), ...
%                              0:numel(epochBinning)-1, 1:numel(epochBinning), epochBinning);
% end
 
% =======================================================================
% SUE ANNS averageInBin function, renamed 
% Average data into bins as specified by the bin index.
%
% bin should be an n-by-m matrix where n = size(data,dim) and m = numel(numBins). Each of the m
% columns of bin is assumed to be one indexing dimension. The output will thus replace the dim
% dimension of data with an m-dimensional binned aggregate.
function average = bin_trial(data, epochEdges, trial_id, epochBinByFrame, trialBinByFrame)
 
  dim = 1; % dimension along which to bin
  %% Create dataBins which assigns each segmented frame an epoch bin and a trial
  dataBins     = [epochBinByFrame(:), trialBinByFrame(:)];
  numBins      = [numel(epochEdges), numel(trial_id)];
  
  %% Reshape data so that the desired dimension to aggregate is in a canonical location
  dataSize            = size(data); % f x n
  data                = reshape(data, prod(dataSize(1:dim-1)), [], prod(dataSize(dim+1:end))); % 1 x f x n
  
  %% Compute linearized index for all columns of bin
  dimFactor           = cumprod(numBins(1:end-1)); % = num time bins
  dimFactor           = [1, dimFactor(:)']; % = 1, num time bins
  globalBin           = 1 + sum(bsxfun(@times, dataBins-1, dimFactor), 2);% f x 1
  
  %% Compute aggregate along the desired dimension
  % if an element of data is nan, zero it out and don't include it in
  % averageing
  lastIndex           = prod(numBins);
  hasInfo             = ~isnan(data);% 1 x f x n
  addData             = data;
  addData(~hasInfo)   = 0;
  average             = zeros([size(data,1), lastIndex, size(data,3)]);
  count               = zeros([size(data,1), lastIndex, size(data,3)]);
  for iData = 1:numel(globalBin)
    average(:,globalBin(iData),:)     ...
                      = average(:,globalBin(iData),:) + addData(:,iData,:);
    count(:,globalBin(iData),:)     ...
                      = count(:,globalBin(iData),:) + hasInfo(:,iData,:);
  end
  average             = average ./ count;
  
  %% Reshape output to match input dimensions, except with dim replaced by numBins
  average             = reshape(average, [dataSize(1:dim-1), numBins, dataSize(dim+1:end)]);
  
end

