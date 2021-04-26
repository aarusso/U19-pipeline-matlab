%{
-> subject.Subject
administration_date:	    date		    # date time
---
earned=null:    float			# water administered
supplement=null: float
received=null: float
-> action.WaterType                         # unknown now
%}

classdef WaterAdministration < dj.Manual
    
    methods
        
        function updateWaterEarnedFromFile(self, key, log)
            
            % Check if earned water was already on the database
            water_key.subject_fullname    = key.subject_fullname;
            water_key.administration_date = key.session_date;
            past_water = fetch(action.WaterAdministration & water_key);
            
            %Earned water from behavioral file
            earned     = sum([log.block(:).rewardMiL]);
            
            %If not insert it
            if isempty(past_water)
                insertWaterEarned(self, water_key, earned);
                
                %If it was already there, update it
            else
                updateWaterEarned(self, water_key, earned);
            end
            
            
            
        end
        
        
        function   insertWaterEarned(self, key, earned)
            % insertWaterEarned, insert record for waterAdministration table (earned in training)
            % Inputs
            % key     = structure with fields (subject_fullname, administration_date)
            % earned  = amount of ml earned during training
            
            % insert water administration information
            key.watertype_name = 'Unknown';
            key.earned    = earned;
            key.supplement = 0;
            key.received = key.earned + key.supplement;
            insert(action.WaterAdministration, key)
            
            
        end
        
        function  updateWaterEarned(self, key, earned)
            % updateWaterEarned, update record for waterAdministration table (earned in training)
            % Inputs
            % key     = structure with fields (subject_fullname, administration_date)
            % earned  = amount of ml earned during training
            
            
            %Get supplement water in database
            supplement_water = fetch1(action.WaterAdministration & key, 'supplement');
            
            % update water administration information
            received = earned + supplement_water;
            update(action.WaterAdministration & key, 'earned', earned)
            update(action.WaterAdministration & key, 'received', received)
            
            
        end
        
    end
    
end