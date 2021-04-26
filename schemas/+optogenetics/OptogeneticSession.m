%{
# Information of a optogenetic session
->acquisition.Session
---
-> acquisition.SessionManipulation
-> optogenetics.OptogeneticProtocol
-> optogenetics.OptogeneticSoftwareParameter
%}

classdef OptogeneticSession < dj.Imported
    
    properties
        keySource =  acquisition.Session & (acquisition.SessionManipulation & struct('manipulation_type', 'optogenetics'));
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            %Get behavioral file to load
            data_dir = fetch1(acquisition.SessionStarted & key, 'remote_path_behavior_file');
            
            
            %Load behavioral file
            try
                [~, data_dir] = lab.utils.get_path_from_official_dir(data_dir);
                data = load(data_dir,'log');
                log = data.log;
                status = 1;
            catch
                disp(['Could not open behavioral file: ', data_dir])
                status = 0;
            end
            if status
                try
                    %Check if it is a real behavioral file
                    if isfield(log, 'session')
                        %Insert Blocks and trails from BehFile
                        self.insertOptogeneticsSessionFromFile(key, log);
                    else
                        disp(['File does not match expected Towers behavioral file: ', data_dir])
                    end
                catch err
                    disp(err.message)
                    sprintf('Error in here: %s, %s, %d',err.stack(1).file, err.stack(1).name, err.stack(1).line )
                end
            end
            
        end
        
    end
    
    methods
        
        function insertOptogeneticsSessionFromFile(self, key, log)
            %insert Optogenetic session record based on behavioral file
            %Inputs
            % key      = session info structure (subject_fullname, session_date, session_number)
            % log      = loaded information from behavioral file
            
            %Get optogenetic protocol from behavioral file
            key.optogenetic_protocol_id = log.animal.stimulationProtocol.optogenetic_protocol_id;
            
            %Get software params from behavioral file (check if they exist on db)
            curr_software_params = log.animal.softwareParams.software_parameters;
            curr_hash = struct2uuid(curr_software_params);
            
            %Check if uuid already in database
            params_UUID = get_uuid_params_db(optogenetics.OptogeneticSoftwareParameter, 'software_parameter_hash', curr_hash);
            if isempty(params_UUID)
               % If is empty create a new software parameter set based on the current software parameters
               new_soft_params_key.software_parameter_hash          = curr_hash;
               new_soft_params_key.software_parameters              = curr_software_params;
               new_soft_params_key.software_parameter_description   = ['Software Params in: ' key.subject_fullname, ' ' key.session_date];
               
               insert(optogenetics.OptogeneticSoftwareParameter, new_soft_params_key);
               params_UUID = get_uuid_params_db(optogenetics.OptogeneticSoftwareParameter, 'software_parameter_hash', curr_hash);
            end
            
            %Get software params set id
            key.software_parameter_set_id = params_UUID.software_parameter_set_id;
            
            
            insert(self, key);
            
        end
        
    end
    
end
