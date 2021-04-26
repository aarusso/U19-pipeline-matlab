%{
# Relationship between session & manipulation performed
-> acquisition.Session
-> lab.ManipulationType
---
%}

classdef SessionManipulation < dj.Manual
    
     methods
        
        function insertSessionManipulation(self,key,log)
            % Insert session manipulation record from behavioralfile in towersTask
            % Called at the end of training or when populating session
            % Input
            % self         = acquisition.Session instance
            % key          = structure with required fields: (subject_fullname, date, session_no)
            % log          = behavioral file as stored in Virmen
            
            if isfield(log.animal, 'manipulationType') && ~contains(log.animal.manipulationType, 'none')
                key.manipulation_type = log.animal.manipulationType;
                insert(self, key, 'IGNORE');
            end
                      
        end
    
     end
end