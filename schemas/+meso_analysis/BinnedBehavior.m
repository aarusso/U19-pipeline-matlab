%{
# time binned behavior by trial
-> meso_analysis.Trialstats
-> meso_analysis.StandardizedTime
---

binned_position_x             : blob  # 1 row per trial
binned_position_y             : blob  # 1 row per trial
binned_position_theta         : blob  # 1 row per trial
binned_dx                     : blob  # 1 row per trial
binned_dy                     : blob  # 1 row per trial
binned_dtheta                 : blob  # 1 row per trial
binned_cue_l=NULL             : blob  # 1 row per trial
binned_cue_r=NULL             : blob  # 1 row per trials

%}


classdef BinnedBehavior < dj.Computed
    methods(Access=protected)
        function makeTuples(self, key)
            result = key;
            
            %bin_size       = fetch(meso_analysis.BinParamSet & key, 'bin_size');
            behav          = fetch(meso_analysis.Trialstats & key,'*');
            [standardizedTime, epochEdges]    = fetchn(meso_analysis.StandardizedTime & key,'standardized_time','binned_time');
            standardizedTime = standardizedTime{:};
            epochEdges = epochEdges{:};
            %
            epoch_by_frame = standardizedTime(behav.meso_frame_unique_ids);
            %result.binned_dff = bin_trial(dff,bin_size);
            epoch_bin_by_frame = binarySearch(epochEdges, epoch_by_frame, -1, -1);
            
            inParams  = {'position_x_by_meso_frame', 'position_y_by_meso_frame', 'position_theta_by_meso_frame',...
                            'dx_by_meso_frame',         'dy_by_meso_frame',         'dtheta_by_meso_frame' };
            outParams = {'binned_position_x',         'binned_position_y',        'binned_position_theta',...
                             'binned_dx',                   'binned_dy'   ,             'binned_dtheta'};
            
            for param = 1:numel(inParams)
                data = behav.(inParams{param});
                data_binned      = bin_trial(data, epochEdges, epoch_bin_by_frame); % bins x 1
                result.(outParams{param}) = data_binned;
            end
            
            %% leave binned cue counts as count, don't average
            inParams  = {'cues_by_meso_frame_right','cues_by_meso_frame_left'};
            outParams  = {'binned_cue_r',            'binned_cue_l'};
            for param = 1:numel(inParams)
                data = behav.(inParams{param});
                data_binned      = bin_trial(data, epochEdges, epoch_bin_by_frame, false); % bins x 1
                result.(outParams{param}) = data_binned;
            end
            
            self.insert(result)
        end
    end
end


%% adapted from meso_analysis.BinnedTrace
function average = bin_trial(data, epochEdges, epochBinByFrame, varargin)
if nargin == 4
    do_average = varargin{:};
else
    do_average = true;
end

trialBinByFrame = ones(size(epochBinByFrame));
trial_id = 1;
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

if ~do_average % for most variables, average but leave cue counts raw
    count = count>0;
end

average             = average ./ count;
%% Reshape output to match input dimensions, except with dim replaced by numBins
average             = reshape(average, [dataSize(1:dim-1), numBins, dataSize(dim+1:end)]);

end
