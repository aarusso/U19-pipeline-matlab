%{
-> tutorial.Neuron
-----
mean: float    # mean activity
stdev: float   # standard deviation of activity
max: float     # maximum activity
%}

classdef ActivityStatistics < dj.Computed

	methods(Access=protected)

		function makeTuples(self, key)
            activity = fetch1(tutorial.Neuron & key, 'activity');
            
            % compute various statistics on activity
            key.mean = mean(activity);
            key.stdev = std(activity);
            key.max = max(activity);
			self.insert(key)
		end
	end

end