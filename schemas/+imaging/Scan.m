%{
-> acquisition.Session
---
scan_directory      : varchar(255)
%}

classdef Scan < dj.Imported
    
    properties (Constant)
        
        % Acquisition types for 2,3 photon and mesoscope
        photon_micro_acq       = {'2photon' '3photon'};
        mesoscope_acq          = {'mesoscope'};
        
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            % find subject and date from acquisition.Session table
            subj                 = lower(fetch1(subject.Subject & key, 'subject_nickname'));
            session_info         = fetch(acquisition.Session & key, 'session_location', 'session_date');
            session_date         = erase(session_info.session_date, '-');
            
            % get acquisition type of session & base dir location (differentiate mesoscope and 2_3 photon)
            location_info        = lab.utils.check_location(session_info.session_location);
            acq_type             = location_info.acquisition_type;
            base_dir             = location_info.imaging_bucket_default_path;
                        
            %If is mesoscope
            if any(contains(self.mesoscope_acq, acq_type))
                %Get mesoscope scan_directory if exists
                [status, scan_directory]   = self.get_mesoscope_scan(subj, session_date, base_dir);
              
            %If is 2photon or 3photon
            elseif any(contains(self.photon_micro_acq, acq_type))
                %Get user nickname to locate scan_directory
                user_nick = fetch1(subject.Subject * lab.User & key, 'user_nickname');
                %Get imaging directory if exists
                [status, scan_directory] = self.get_photonmicro_scan(subj, session_date, user_nick, base_dir);
              
            %If no real "acquisition" was made
            else
                disp(key)
                warning(['This session with acquisition_type: ' acq_type ' should not be processed in this pipeline'])
                return
            end
            
            %If a non empty scan directory was found
            if status
                fprintf('directory with files %s found !!\n',scan_directory)
                key.scan_directory = scan_directory;
            else
                fprintf('directory %s not found\n',scan_directory)
                return
            end
            
            %Insert key in Scan table
            self.insert(key)
        end
        
        function [status, scan_directory] = get_mesoscope_scan(self, subj, session_date, mesoscope_base_dir)
            % get mesoscope scan directory
            %
            % Inputs
            % subj           = subject nickname
            % session_date   = date from the acquisition in format YYYYMMDD
            %
            % Outputs
            % status         = true if scan_directory found false otherwise
            % scan_directory = directory with tiff imaging files
            
            %get main dir for acquisition files
            [bucket_path, local_path] = lab.utils.get_path_from_official_dir(mesoscope_base_dir);
            
            %If running locally, check if it is connected
            if ~u19_dj_utils.is_this_spock()
                lab.utils.assert_mounted_location(local_path);
            end
            
            %complete local and bucket path for scan directory
            local_path = fullfile(local_path, subj, session_date);
            scan_directory = spec_fullfile('/',bucket_path, subj, session_date);
            
            %Check if directory exists and is not empty
            if isempty(dir(local_path))

            %complete local and bucket path for scan directory with upper case
            subj = upper(subj);
            local_path = fullfile(local_path, subj, session_date);            
            scan_directory = spec_fullfile('/',bucket_path, subj, session_date);

                if isempty(dir(local_path))
                    status = false;
                else
                    status = true;
                end
            
            else
                status = true;
            end
           
        end
        
        
        function [status, scan_directory] = get_photonmicro_scan(self, subj, session_date, user_nick, photon_micro_base_dir)
            % get 2photon or 3photon scan directory
            %
            % Inputs
            % subj           = subject nickname
            % session_date   = date from the acquisition in format YYYYMMDD
            % user_nick      = user nickname (parent folder for scan dir)
            %
            % Outputs
            % status         = true if scan_directory found false otherwise
            % scan_directory = directory with tiff imaging files
            
            status = true;
            scan_directory = '';
            
            %get main dir for acquisition files
            [bucket_path, local_path] = lab.utils.get_path_from_official_dir(photon_micro_base_dir);
            
            %If running locally, check if it is connected
            if ~u19_dj_utils.is_this_spock()
                lab.utils.assert_mounted_location(local_path);
            end
            
            %Parent folder starts with user nicknames
            userDir        =  fullfile(local_path, user_nick);
             
            %Get all child directories from user
            disp(['Get all paths from Directory: ' userDir])
            dirInfo = genpath(userDir);
            dirInfo = split(dirInfo,':');
            
            % For matlab 2016 change string to cell
            if isstring(dirInfo)
                dirInfo = cellstr(dirInfo);
            end
            
            %Remove final entry (0x0 char)
            dirInfo = dirInfo(1:end-1);
            
            %Search directories that "end" with subject nickname
            indexSubjDir = cellfun(@(x) strcmpi(x(end-length(subj)+1:end),subj),...
                dirInfo, 'UniformOutput',true);
            
            % If only one path "ends" with subject nickname
            if sum(indexSubjDir) == 1
                dirSubj = dirInfo{indexSubjDir};
                dirSession = fullfile(dirSubj, session_date);
                
            % If no path "ends" with subject nickname    
            elseif sum(indexSubjDir) == 0
                status = false;
                return
            
            % If more than one path "ends" with subject nickname 
            else
                dirInfo = dirInfo(indexSubjDir);
                
                %Check every path, first directory with files will make it stop
                for j=1:length(dirInfo)
                    dirSubj = dirInfo{j};
                    dirSession = fullfile(dirSubj, session_date);
                    
                    if ~isempty(dir(dirSession))
                        break
                    end
                end
            end
            
            %Check if "candidate" directory is empty
            if ~isempty(dir(dirSession))
                %Get scan directory from bucket
                scan_directory = lab.utils.get_path_from_official_dir(dirSession);
            else
                status = false;
            end
            
            
        end
    end
    
end



