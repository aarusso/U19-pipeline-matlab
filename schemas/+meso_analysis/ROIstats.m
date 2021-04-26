%{
# statistics for ROI selection
-> meso.SegmentationRoi
-> meso.ROIstatsParamsSet
---
noise_level                   : float       # noise levels of each ROI
positive_transients           : longblob    # 1 x num_frames boolean indicating significant positive transients
negative_transients           : longblob    # 1 x num_frames boolean indicating significant negative transients
trial_transient_count         : longblob    # 1 x num_trials transient count
mean_transients_per_trial     : float       # average number of transients per trial
mean_transients_per_on_trial  : float       # average number of transientspertrial in which the neuron actually fired
mean_transients_per_min       : float       # average number of transients per minute
fraction_of_trials_on         : float       # fraction of trials when cell was active 
ar_rise_time_constant         : float       # continuous rise time constant given auto-regressive model parameters
ar_decay_time_constant        : float       # continuous decay time constant given auto-regressive model parameters
spike_peak_dff                : blob        # 1 x nChunks, crude estimate of dF/F peak height for amplitude = 1
%}


classdef RoiStats < dj.Computed
  methods(Access=protected)
    function makeTuples(self, key)
     if ~isstruct(key)
        result = fetch(key);
      else
        result = key;
      end
        
    %% fetch and define some extra pars
     [minActiveSecs, minDFF, minSpike, minSignificance]      = ...
            fetchn(meso_analysis.RoiStatsParamsSet & key, 'min_active_seconds', 'min_dff', 'min_spike', 'min_significance');
     frameRate       = fetch1(meso.ScanInfo & key, 'frame_rate'); 
     baselineFrames  = frameRate * 3*60;    % fps * seconds to integrate
     deltaT          = 1/frameRate;
     minActiveImg    = ceil(minActiveSecs / deltaT);
     rebinFactor     = round(fetch1(meso.SegParameterSetParameter, 'cnmf_time_resolution') / (1000/frameRate)); %before it was ceil
    
     %% fetch trial frames
     trialFrames     = fetchn(meso_analysis.Trialstats & key, 'meso_frame_unique_ids');
     %% retrieve data & (if true) select good ROIs based on morphology
     goodMorphoOnly = fetch1(meso_analysis.RoiStatsParamsSet & key, 'good_morpho_only');
     
     if goodMorphoOnly
       morphoKey                        = meso.SegmentationRoiMorphologyManual & key    ...
                                          & 'morphology in ("Doughnut", "Blob")';
       %%%%%%%%%%%%%%%%%need to also load delta and timeChunks here!!!!!
      [dff, selectedROI, isSignificant, timeConstants] = fetchn(meso.Trace & morphoKey,                ...
                                          'dff_roi', 'roi_idx', 'dff_roi_is_significant', 'time_constants');
     else
      %%%%%%%%%%%%%%%%%need to also load delta and timeChunks here!!!!!   
      [dff, selectedROI, isSignificant, timeConstants] = fetchn(meso.Trace & key,                  ...
                                          'dff_roi','roi_idx', 'dff_roi_is_significant', 'time_constants');
     end
     
     dff                       = cell2mat(dff); % neurons by frames 
     isSignificant             = cell2mat(isSignificant);
     
     isallnan                  = sum(isnan(dff),2) == size(dff,2);
     dff(isallnan,:)           = [];
     selectedROI(isallnan)     = [];
     isSignificant(isallnan,:) = [];
     delta(isallnan,:)         = [];  
%% select good ROIs based on activity
         activeCount       = sum(isSignificant & delta > minDFF, 2);
         fracActive        = mean(activeCount > 0, 2);
        [activity,iOrder] = sort(fracActive, 'descend');
        selectedROI       = selectedROI(iOrder);

%% Correct for non-constant baseline 
fprintf('----  Baseline correction and transient detection ... ');
%%%%%%%need timeChunk here!!!%%%%%%
dataDFF           = removeBaselineDrift({dff(selectedROI,:)', 1},   ...  %nFrames x nNeurons
                    baselineFrames, timeChunk);
caDFF             = removeBaselineDrift({delta(selectedROI,:)', 1}, ...  % nFrames x nNeurons
                    baselineFrames, timeChunk);
totalMins         = size(caDFF,1) * rebinFactor / frameRate / 60;
transientDur      = minActiveImg / rebinFactor;

%%  Per-ROI properties
for iROI = 1:numel(selectedROI)
  [positiveTransients, negativeTransients, noise]     ...
                      = detectActivityTransients(dataDFF(:,iROI), minSignificance, transientDur); 
 
  
  trialTransients          = cellfun(@(x)sum(positiveTransients(x)), trialFrames);
  transientsPerMin         = sum(positiveTransients) / totalMins;
  transientsPerTrial       = mean(trialTransients);
  transientsPerOnTrial     = mean(trialTransients(trialTransients > 0));
  fractionOnTrials         = mean(trialTransients > 0);
  [fRise, fDecay]          = arTimeConstants(timeConstants(iROI,:));
% populate                  
     thisresult                              = result;
     thisresult.positive_transients          = positiveTransients;
     thisresult.negative_transients          = negativeTransients;
     thisresult.noise_level                  = noise;
     thisresult.trial_transient_count        = trialTransients;
     thisresult.mean_transients_per_min      = transientsPerMin;
     thisresult.mean_transients_per_trial    = transientsPerTrial;
     thisresult.mean_transients_per_on_trial = transientsPerOnTrial;
     thisresult.fraction_of_trials_on        = fractionOnTrials;
     thisresult.ar_rise_time_constant        = fRise;
     thisresult.ar_decay_time_constant       = fDecay; 
     
     self.insert(thisresult)
end

%% Further remove noise according to negative-going dF/F
%    tRange                = cell(1, size(timeChunk,1));
%    chunkDFF              = cell(1, size(timeChunk,1));
%     for iChunk           = 1:size(timeChunk,1)
%       tRange{iChunk}     = timeChunk(iChunk,1):timeChunk(iChunk,2);
%       chunkDFF{iChunk}   = caDFF(tRange{iChunk},:);
%     end 
% 
%     kernel            = ones(ceil(baselineFrames), 1);
%     chunkDelta        = cell(1, size(timeChunk,1));
%     parfor iChunk = 1:size(timeChunk,1)
%       delta           = chunkDFF{iChunk};
%       isNegative      = delta < 0;
%       dFF2            = (delta.^2) .* isNegative;
%       sumDFF2         = filter(kernel, 1, dFF2      , [], 1);
%       numNegative     = filter(kernel, 1, isNegative, [], 1);
%       sel             = numNegative > 1;
%       noise           = zeros(size(sumDFF2));
%       noise(sel)      = sqrt( 2 * sumDFF2(sel) ./ (numNegative(sel) - 1) );
%       delta( delta < noise * minSignificance )  = 0;
%       chunkDelta{iChunk}  = delta;
%     end
%     
%     delta             = nan(size(caDFF));
%     for iChunk = 1:size(timeChunk,1)
%       delta(tRange{iChunk},:) = chunkDelta{iChunk};
%     end
%     
%      %% Re-derive deconvolved spike estimates to be consistent with the baseline-truncated dF/F
%     % This is the same relationship (auto-regressive model) as used in constrained_foopsi() except
%     % that we perform additional filtering on the spike amplitudes such that the smallest dF/F peak
%     % is within a physiological range for one Ca2+ spike.
%     spiking           = zeros(size(delta));
%     for iChunk = 1:size(timeChunk,1)
%       tRange          = timeChunk(iChunk,1):timeChunk(iChunk,2);
%       testSpike       = sparse(2, 1, 1, numel(tRange), 1);
%     
%       spikePeakDFF = nan(size(timeChunk,1),1);
%       for iROI = 1:numel(selectedROI)
%         g             = timeConstants{selectedROI(iROI),iChunk}(:);
%         if isempty(g)
%           continue;
%         end
%         T             = numel(tRange);
%         G             = spdiags(ones(T,1)*[-g(end:-1:1)',1],-length(g):0,T,T);
%         sp            = G * double(delta(tRange,iROI));
%         spikePeakDFF(iChunk)  = max(G \ testSpike);       % crude estimate of dF/F peak height for amplitude = 1
%         sp(sp < minSpike) = 0;                     % reject spikes with too small of an amplitude
%         
%         spiking(tRange,iROI)  = sp;
%         delta(tRange,iROI)    = G \ sp;
%       end
%     end
    %%
    self.insert(result)
    end
  end
end


% %---------------------------------------------------------------------------------------------------
function [corrected, success] = removeBaselineDrift(quantity, baselineFrames, timeChunk, vetoFrames)

  %% Default arguments
  if nargin < 3
    timeChunk             = [];
  end
  if nargin < 4
    vetoFrames            = [];
  end
  
  %% Parallel pool preferences
  parSettings                   = parallel.Settings;
  origAutoCreate                = parSettings.Pool.AutoCreate;
  parSettings.Pool.AutoCreate   = false;

  
 %% quantities
    minBaseline           = quantity{2};
    quantity              = quantity{1};
 

  %% Default to treating entire time series as homogeneous (not from multiple segmentation rounds)
  if isempty(timeChunk)
    timeChunk             = [1, size(quantity,1)];
  end
  
  % Optionally omit frames from denominator
  corrected               = quantity;
  denom                   = corrected;
  if ~isempty(vetoFrames)
    denom(vetoFrames,:)   = nan;
  end
  
  %% Division for parallelization
  chunkCorr               = cell(1, size(timeChunk,1));
  chunkDenom              = cell(1, size(timeChunk,1));
  tRange                  = cell(1, size(timeChunk,1));
  for iChunk = 1:size(timeChunk,1)
    tRange{iChunk}        = timeChunk(iChunk,1):timeChunk(iChunk,2);
    if all(isnan(denom(tRange{iChunk},:)))
      continue;
    end
    
    chunkDenom{iChunk}    = denom(tRange{iChunk},:);
    chunkCorr{iChunk}     = corrected(tRange{iChunk},:);
  end
  
    
  %% Correct for windowed baseline obeying chunk boundaries
  success                 = false(1, size(timeChunk,1));
  parfor iChunk = 1:size(timeChunk,1)
    if isempty(chunkDenom{iChunk})
      continue;
    end
    
    % Subtract (running) baseline
    norm                  = halfSampleMode(chunkDenom{iChunk}, baselineFrames);
    chunkCorr{iChunk}     = chunkCorr{iChunk} - norm;
    
    % HACK for cases where the baseline is negative when given a positive expectation
    if ~isempty(minBaseline)
      norm                = bsxfun(@minus, norm, min(norm,[],1,'omitnan'))    ...
                          + minBaseline                                       ...
                          ;
    end
    if any(norm <= 0)
      norm                = halfSampleMode(chunkDenom{iChunk});
    end
    
    % Can only divide by a positive denominator
    if all(norm > 0)
      chunkCorr{iChunk}   = chunkCorr{iChunk} ./ norm;
      success(iChunk)     = true;
    end
  end
  
  %% Store in original array
  for iChunk = 1:size(timeChunk,1)
    if ~isempty(chunkCorr{iChunk})
      corrected(tRange{iChunk},:) = chunkCorr{iChunk};
    end
  end
  
  
  %% Restore parallel pool settings
  parSettings.Pool.AutoCreate   = origAutoCreate;
  
end

% %---------------------------------------------------------------------------------------------------
function [positiveTransients, negativeTransients, noise, positiveDuration, positiveSum, negativeDuration, negativeSum]  ...
                          = detectActivityTransients(signal, minSignificance, minDuration, noise, estimateNoise)
                        
  if nargin < 5
    estimateNoise         = true;
  end
  
  %% Define "noise" using full width at half max
  signal                  = signal(:);
  
  if estimateNoise
    [pixBins, dPix]       = freedmanDiaconisBins(signal);  
    if all(isfinite(pixBins))
      pixPDF              = histcounts(signal, pixBins)';
      [~,~,noise]         = halfPDFMode(cumsum(pixPDF), pixPDF);
      noise               = noise * dPix;
    end
  end
  
  % EDWARD: catches an error if noise is zero
  if exist('noise','var')==0
     noise=0; 
  elseif isnan(noise)==1
      noise=0;
  end
  noiseThreshold          = noise * minSignificance;
  
  %% Significant positive vs. negative transients
  [positiveTransients, positiveDuration, positiveSum] = transientOnsets(signal >  noiseThreshold, minDuration, signal);
  [negativeTransients, negativeDuration, negativeSum] = transientOnsets(signal < -noiseThreshold, minDuration, signal);

end

%% 
function [transientOnset, transientDuration, transientSum, isTransient] = transientOnsets(isSignificant, minDuration, signal)

  [value,iTrans,lTrans]         = SplitVec(double(isSignificant), 'equal', 'firstval', 'first', 'length');
  isTransient                   = value > 0 & lTrans >= minDuration;
  iTrans                        = iTrans(isTransient);
  lTrans                        = lTrans(isTransient);
  
  transientOnset                = false(size(isSignificant,1), 1);
  transientDuration             = zeros(size(isSignificant,1), 1);
  transientSum                  = zeros(size(isSignificant,1), 1);
  transientOnset(iTrans)        = true;
  transientDuration(iTrans)     = lTrans;
  for index = 1:numel(iTrans)
    transientSum(iTrans(index)) = sum(signal(iTrans(index):iTrans(index) + lTrans(index) - 1));
  end

end

% %---------------------------------------------------------------------------------------------------
%% Compute equivalent continuous time constants given auto-regressive model parameters
%   https://github.com/epnev/ca_source_extraction/wiki/Interpretation-of-discrete-time-constants
function [tRise, tDecay] = arTimeConstants(g)
  
  if iscell(g)
    tRise             = nan(size(g));
    tDecay            = nan(size(g));
    for iG = 1:numel(g)
      [tRise(iG), tDecay(iG)]     ...
                      = equivalentTimeConstants(g{iG});
    end
    
  else
    [tRise, tDecay]   = equivalentTimeConstants(g);
  end
  
end

%%
function [tRise, tDecay] = equivalentTimeConstants(g)
  
  switch numel(g)
    case 0
      tRise   = nan;
      tDecay  = nan;
      
    case 1
      tRise   = 0;
      tDecay  = -1/log(g);
      
    case 2
      r       = sort(roots([1; -g(:)]), 'descend');
      t1      = -1/log(r(1));
      t2      = -1/log(r(2));
      tRise   = t1 * t2 / (t1 - t2);
      tDecay  = t1;
      
    otherwise
      error('arTimeConstants:ARmodel', 'Unsupported degree of AR model %d.', numel(g));
  end
  
end
