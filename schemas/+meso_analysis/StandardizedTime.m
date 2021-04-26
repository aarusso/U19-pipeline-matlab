%{
# time binned activity by trialStruct
-> imaging.Scan
-> meso_analysis.BinningParameters
---
standardized_time : longblob  # linearly interpolated behavioral epoch ID per imaging frame
binned_time       : blob      #
%}
% start / cue / delay / arm / ITI / extra-ITI (error trials)
 
 
classdef StandardizedTime < dj.Computed
    methods(Access=protected)
        function makeTuples(self, key)
 
            behav =  fetch(behavior.TowersBlockTrial & key, ...
                'trial_idx','trial_type','choice','position');
 
            [frames, frame_span] = fetchn(imaging.SyncImagingBehavior & key, 'sync_im_frame_global','sync_im_frame_span_by_behav_trial');
            frames = frames{:}; frame_span = frame_span{:};
  
            
            %% Get Frame IDs for Key Events
            eventFrames =  fetch(meso_analysis.Trialstats & key, ...
                'trial_start_meso_frame','cue_entry_meso_frame','mem_entry_meso_frame',...
                'arm_entry_meso_frame', 'iti_end_meso_frame',...
                'trial_end_meso_frame','timeout_meso_frame', 'is_correct');
            f_trial_start = [eventFrames.trial_start_meso_frame];
            f_cue_entry   = [eventFrames.cue_entry_meso_frame];
            f_mem_entry   = [eventFrames.mem_entry_meso_frame];
            f_arm_entry   = [eventFrames.arm_entry_meso_frame];
            f_trial_end   = [eventFrames.trial_end_meso_frame];
            
            f_iti_end     = [eventFrames.iti_end_meso_frame];
            f_error_iti   = [eventFrames.timeout_meso_frame];
            
            %% Get standardized time for each trial and deal into 1 x nframe vector 
            Tr = [eventFrames(:).trial_idx];
            behaviorByFrame = nan(size(frames));
            
            for trialNum = 1:numel(Tr) % ends up being easier to still do this in a for loop because of the format for tr.choice
                fEpoch          = [ f_trial_start(trialNum), f_cue_entry(trialNum), f_mem_entry(trialNum), f_arm_entry(trialNum), f_trial_end(trialNum) ];
                % Mdia: Nan's were set to -1 previously. If -1, cummax
                % won't work
                fEpoch(fEpoch == -1) = nan;
                if behav(trialNum).choice ~= behav(trialNum).trial_type
                    fEpoch(end+1) = f_error_iti(trialNum);
                end
                fEpoch(end+1) = f_iti_end(trialNum)+1;
                fEpoch        = cummax(fEpoch); % I think this is SAK dealing with Nans, clever
                
                
                %%%% originally standardizeTime subfunction in getBehaviorPlusImaging_mesoscope()
                fEpoch              = fEpoch - fEpoch(1) + 1;               % start output at 1
                location            = nan(fEpoch(end)-1,1);
                for iEpoch = 1:numel(fEpoch) - 1
                    tRange            = fEpoch(iEpoch):fEpoch(iEpoch + 1) - 1;
                    loc               = linspace(0, 1, numel(tRange)+1);
                    location(tRange)  = iEpoch-1 + loc(1:end-1);
                end
                
                behaviorByFrame(frame_span{Tr(trialNum)}(1):frame_span{Tr(trialNum)}(2)) = location;
                %results.standardize_time = behaviorByFrame;
            end
            %%
            
            epochBinning = fetch1(meso_analysis.BinningParameters & key, 'epoch_binning');
            binned_time   = accumfun(2, @(x,y,z) butlast(linspace(x,y,z)), ...
                                         0:numel(epochBinning)-1, 1:numel(epochBinning), epochBinning);
            
            
            %%
            result = key;
            result.standardized_time = behaviorByFrame;
            result.binned_time = binned_time;
            
            self.insert(result);
        end
        
    end
end
 
 

