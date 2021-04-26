%{
# Information of a optogenetic trial
-> acquisition.SessionBlockTrial
-> optogenetics.OptogeneticSession
---
stim_epoch			              : varchar(32)	 # Which epoch of the trial stimulation was on
stim_on			                  : tinyint	     # 1 if stimulation was turned on 0 otherwise
t_stim_on			              : TINYBLOB	 # times when laser was turned on
t_stim_off			              : TINYBLOB	 # times when laser was turned off
%}


classdef OptogeneticTrial < dj.Imported
    methods(Access=protected)
        function makeTuples(self, key)
            
        end
    end
end
