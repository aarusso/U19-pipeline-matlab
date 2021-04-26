%{
-> tutorial.Neuron
-> tutorial.SpikeDetectionParam
-----
spikes: longblob   # detected spikes
count: int         # total number of the detected spikes
%}

classdef Spikes < dj.Computed
    
    properties
        popRel = tutorial.Neuron
    end

	methods(Access=protected)

		function makeTuples(self, key)
            
            activity = fetch1(tutorial.Neuron & key, 'activity');
            [sdp_ids, thresholds] = fetchn(tutorial.SpikeDetectionParam & key, 'sdp_id', 'threshold');
            
            keys = [];
            
            for i_threshold = 1:length(thresholds)
                threshold = thresholds(i_threshold);
                key.sdp_id = sdp_ids(i_threshold);
                above_thres = activity > threshold;
                rising = diff(above_thres) > 0;
                spikes = [0, rising];
                count = sum(spikes);
                % save results and insert
                key.spikes = spikes;
                key.count = count;
                self.insert(key)
            end
            
            self.insert(keys)
            
            
		end
	end

end