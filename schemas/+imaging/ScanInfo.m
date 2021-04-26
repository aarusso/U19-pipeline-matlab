%{
# metainfo about imaging session
-> imaging.Scan
---
file_name_base            : varchar(255)  # base name of the file
scan_width                : int           # width of scanning in pixels
scan_height               : int           # height of scanning in pixels
acq_time                  : datetime      # acquisition time
n_depths                  : tinyint       # number of depths
scan_depths               : blob          # depth values in this scan
frame_rate                : float         # imaging frame rate
inter_fov_lag_sec         : float         # time lag in secs between fovs
frame_ts_sec              : longblob      # frame timestamps in secs 1xnFrames
power_percent             : float         # percentage of power used in this scan
channels                  : blob          # is this the channer number or total number of channels
cfg_filename              : varchar(255)  # cfg file path
usr_filename              : varchar(255)  # usr file path
fast_z_lag                : float         # fast z lag
fast_z_flyback_time       : float         # time it takes to fly back to fov
line_period               : float         # scan time per line
scan_frame_period         : float         #
scan_volume_rate          : float         #
flyback_time_per_frame    : float         #
flyto_time_per_scan_field : float         #
fov_corner_points         : blob          # coordinates of the corners of the full 5mm FOV, in microns
nfovs                     : int           # number of field of view
nframes                   : int           # number of frames in the scan
nframes_good              : int           # number of frames in the scan before acceptable sample bleaching threshold is crossed
last_good_file            : int           # number of the file containing the last good frame because of bleaching
%}


classdef ScanInfo < dj.Imported
    
    properties (Constant)
        
        % Acquisition types for 2,3 photon and mesoscope
        photon_micro_acq       = {'2photon' '3photon'};
        mesoscope_acq          = {'mesoscope'};
        
        date_fmt               = 'yyyy mm dd HH:MM:SS.FFF';
        tif_number_fmt         = '_[0-9]{5}.tif';
        tif_gz_number_fmt      = '_[0-9]{5}.tif.gz';
        
        patt_acq_number        = '_[0-9]{5}_';
        patt_file_number       = '_[0-9]{5}\.';
        
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % ingestion triggered by the existence of Scan
            % runs a modified version of mesoscopeSetPreproc
            generalTimer   = tic;
            curr_dir       = pwd;
            scan_dir_db    = fetch1(imaging.Scan & key,'scan_directory');
            scan_directory = lab.utils.format_bucket_path(fetch1(imaging.Scan & key,'scan_directory'));

            %Check if directory exists in system
            lab.utils.assert_mounted_location(scan_directory)
            
            % get acquisition type of session (differentiate mesoscope and 2_3 photon
            acq_type             = fetch1(proj(acquisition.Session, 'session_location->location') * ...
                lab.Location & key, 'acquisition_type');
            
            cd(scan_directory)
            
            %Check if it is mesoscope or 2photon
            isMesoscope = any(contains(self.mesoscope_acq, acq_type));
            is2Photon   = any(contains(self.photon_micro_acq, acq_type));
            
            fprintf('------------ preparing %s --------------\n',scan_directory)
            
            if isMesoscope
                originalStacksdir = fullfile(scan_directory, 'originalStacks');
                if (isempty(dir('*tif*')) && exist(originalStacksdir,'dir'))
                    tif_dir = fullfile(scan_directory, 'originalStacks');
                    cd originalStacks
                    skipParsing = true;
                else
                    tif_dir = scan_directory;
                    if ~exist(originalStacksdir,'dir')
                        mkdir('originalStacks');
                    end
                    skipParsing = false;
                end
            else
                tif_dir = scan_directory;
            end
            
            %% loop through files to read all image headers
            [fl, basename, isCompressed] = self.check_tif_files(tif_dir);
            
            % get header with parfor loop
            fprintf('\tgetting headers...\n')
            [imheader, parsedInfo] = self.get_parsed_info(fl, isMesoscope);
            
            %Get recInfo field
            [recInfo, framesPerFile] = self.get_recording_info(fl, imheader, parsedInfo);
            
            %get nfovs field
            recInfo.nfovs = self.get_nfovs(recInfo, isMesoscope);
            
            %Get last "good" file because of bleaching
            [lastGoodFile, cumulativeFrames] = self.get_last_good_frame(framesPerFile, tif_dir);
            recInfo.nframes_good              = cumulativeFrames(lastGoodFile);
            recInfo.last_good_file            = lastGoodFile;
            
            % check acqTime is valid, and if not, correct it
            recInfo.AcqTime = self.check_acqtime(recInfo.AcqTime, scan_directory);
            
            %If original files where compressed
            if isCompressed
                disp('it started as compressed files, removing compressed')
                imaging.utils.remove_compressed_videos(fl, scan_directory);
            end
            
            %% Insert to ScanInfo
            self.insert_scan_info(key, recInfo, scan_dir_db)
            
            %% FOV ROI Processing for mesoscope
            if isMesoscope
                self.insert_fov_mesoscope(fl, key, skipParsing, imheader, recInfo, basename, cumulativeFrames, scan_dir_db)
                
                % Just insertion of fov and fov fiels for 2 and 3 photon
            elseif is2Photon
                self.insert_fov_photonmicro(key, scan_dir_db)
                self.insert_fovfile_photonmicro(key, fl, imheader)
            else
                error('Not a valid acquisition for this pipeline, how did you get here ??')
            end
            
            cd(curr_dir)
            fprintf('\tdone after %1.1f min\n',toc(generalTimer)/60)
            
        end
        
        %% Check if tif or tif.gz files exist
        function [fl, basename, is_compressed] = check_tif_files(self, tif_dir)
            
            is_compressed = 0;
            
            %Save current directory and enter tif directory
            cd(tif_dir);
            
            %Check for tif files (or tif.gz if there are not tif)
            fl       = dir('*tif'); % tif file list
            
            if isempty(fl)
                
                fl_gz       = dir('*tif.gz'); % check for compressed videos
                
                if ~isempty(fl_gz)
                    is_compressed = 1;
                    % unzip gz videos
                    gunzip({fl_gz(:).name});
                    fl       = dir('*tif'); % tif file list
                else
                    error('There are no tif or tif.gz files in scan directory')
                end
            end
            
            %Check for base name
            fl       = {fl(:).name};
            stridx   = regexp(fl{1},self.tif_number_fmt);
            
            if isempty(stridx)
                error(['Files are not in correct format ' fl{1} ' ~= ' fmt_cmp])
            end
            
            basename = fl{1}(1:stridx);
            
        end
        
        function [imheader, parsedInfo] = get_parsed_info(self, fl, isMesoscope)
            
            if isempty(gcp('nocreate'))
                
                c = parcluster('local'); % build the 'local' cluster object
                num_workers = min(c.NumWorkers, 16);

                parpool('local', num_workers, 'IdleTimeout', 120);
                
            end
            
            parfor iF = 1:numel(fl)
                [imheader{iF},parsedInfo{iF}] = imaging.utils.parse_tif_header(fl{iF});
                %If is mesoscope get also roi info from header
                if isMesoscope
                    parsedROI{iF} = imaging.utils.parse_roi_info_tif_header(imheader{iF});
                end
            end
            
            %Complete parsedInfo structure with parsedROI if this is mesoscope
            if isMesoscope
                for iF = 1:numel(fl)
                    parsedInfo{iF} = u19_dj_utils.cat_struct(parsedInfo{iF}, parsedROI{iF});
                end
            end
            
            
            
        end
        
        %% get nfovs depending of acquisition type
        function nfovs = get_nfovs(self, recInfo, isMesoscope)
            
            if isMesoscope
                nfovs = sum(cell2mat(cellfun(@(x)(numel(x)),{recInfo.ROI(:).Zs},'uniformoutput',false)));
            else
                nfovs = 1;
            end
            
        end
        
        %% get recording info to recinfo var
        function [recInfo, framesPerFile] = get_recording_info(self, fl, imheader, parsedInfo)
            
            % get recording info from headers
            framesPerFile = zeros(numel(fl),1);
            for iF = 1:numel(fl)
                if iF == 1
                    recInfo = parsedInfo{iF};
                else
                    if parsedInfo{iF}.Timing.Frame_ts_sec(1) == 0
                        parsedInfo{iF}.Timing.Frame_ts_sec = parsedInfo{iF}.Timing.Frame_ts_sec + recInfo.Timing.Frame_ts_sec(end) + 1/recInfo.frameRate;
                    end
                    recInfo.Timing.Frame_ts_sec = [recInfo.Timing.Frame_ts_sec; parsedInfo{iF}.Timing.Frame_ts_sec];
                    recInfo.Timing.BehavFrames  = [recInfo.Timing.BehavFrames;  parsedInfo{iF}.Timing.BehavFrames];
                end
                framesPerFile(iF) = numel(imheader{iF});
            end
            recInfo.nFrames     = numel(recInfo.Timing.Frame_ts_sec);
            
        end
        
        function AcqTime = check_acqtime(self, AcqTime, scan_directory)
            
            isRealDate = true;
            isSameDate = true;
            %Check if acqtime is real date
            try
                %convert to date and reconvert to string ..
                AcqTime = datetime_scanImage2sql(AcqTime);
                checkacqTime = datestr(datenum(AcqTime,self.date_fmt),self.date_fmt);
                %check date strings, should be the same
                if ~strcmp(AcqTime, checkacqTime)
                    isSameDate = false;
                end
            catch
                isRealDate = false;
                isSameDate = false;
            end
            
            % if acqtime is not valid, generate a new one
            if ~isRealDate || ~isSameDate
                
                %get date from directory
                [~,thisdate]    = mouseAndDateFromFileName(scan_directory);
                
                AcqTime = [thisdate(1:4) ' ' thisdate(5:6) ' ' thisdate(7:8) ' 00 00 00.000'];
                AcqTime = datetime_scanImage2sql(AcqTime);
            end
        end
        
        %% find out last good frame based on bleaching
        function [lastGoodFile, cumulativeFrames] = get_last_good_frame(self, framesPerFile, scan_directory)
            
            lastGoodFile        = selectFilesFromMeanF(scan_directory);            
            cumulativeFrames    = cumsum(framesPerFile);
            
        end
        
        function insert_scan_info(self, key, recInfo, bucket_dir)
            
            %Correct full filename for mac & windows system
            [~, filename, ext] = fileparts(recInfo.Filename);
            full_filename = spec_fullfile('/', bucket_dir, [filename ext]);
            
            
            originalkey                   = key;
            key_data                      = fetch(imaging.Scan & originalkey);
            key                           = key_data;
            key.file_name_base            = full_filename;
            key.scan_width                = recInfo.Width;
            key.scan_height               = recInfo.Height;
            key.acq_time                  = recInfo.AcqTime;
            key.n_depths                  = recInfo.nDepths;
            key.scan_depths               = recInfo.Zs;
            key.frame_rate                = recInfo.frameRate;
            key.inter_fov_lag_sec         = recInfo.interROIlag_sec;
            key.frame_ts_sec              = recInfo.Timing.Frame_ts_sec;
            key.power_percent             = recInfo.Scope.Power_percent;
            key.channels                  = recInfo.Scope.Channels;
            key.cfg_filename              = recInfo.Scope.cfgFilename;
            key.usr_filename              = recInfo.Scope.usrFilename;
            key.fast_z_lag                = recInfo.Scope.fastZ_lag;
            key.fast_z_flyback_time       = recInfo.Scope.fastZ_flybackTime;
            key.line_period               = recInfo.Scope.linePeriod;
            key.scan_frame_period         = recInfo.Scope.scanFramePeriod;
            key.scan_volume_rate          = recInfo.Scope.scanVolumeRate;
            key.flyback_time_per_frame    = recInfo.Scope.flybackTimePerFrame;
            key.flyto_time_per_scan_field = recInfo.Scope.flytoTimePerScanfield;
            key.fov_corner_points         = recInfo.Scope.fovCornerPoints;
            
            key.nfovs                     = recInfo.nfovs;
            key.nframes                   = recInfo.nFrames;
            key.nframes_good              = recInfo.nframes_good;
            key.last_good_file            = recInfo.last_good_file;
            self.insert(key)
            
        end
        
        %% Fov and Fov file tables for mesoscope imaging
        function insert_fov_mesoscope(self, fl, key_data, skipParsing, imheader, recInfo, basename, cumulativeFrames, scan_directory)
            
            nROI                          = recInfo.nROIs;
            % scan image concatenates FOVs (ROIs) by adding rows, with padding between them.
            % This part parses and write tifs individually for each FOV
            
            %Get stridx again
            stridx   = regexp(fl{1},self.tif_number_fmt);
            
            if ~skipParsing
                if isempty(gcp('nocreate'))
                
                    c = parcluster('local'); % build the 'local' cluster object
                    num_workers = min(c.NumWorkers, 16);

                    parpool('local', num_workers, 'IdleTimeout', 120);
                
                end
                
                fieldLs = {'ImageLength','ImageWidth','BitsPerSample','Compression', ...
                    'SamplesPerPixel','PlanarConfiguration','Photometric'};
                fprintf('\tparsing ROIs...\n')
                
                ROInr       = arrayfun(@(x)(x.pixelResolutionXY(2)),recInfo.ROI);
                ROInc       = arrayfun(@(x)(x.pixelResolutionXY(1)),recInfo.ROI);
                interROIlag = recInfo.interROIlag_sec;
                Depths      = recInfo.nDepths;
                
                % make the folders in advance, before the parfor loop
                for iROI = 1:nROI
                    for iDepth = 1:Depths
                        mkdir(sprintf('ROI%02d_z%d',iROI,iDepth));
                    end
                end
                
                tagNames = Tiff.getTagNames();
                parfor iF = 1:numel(fl)
                    fprintf('%s\n',fl{iF})
                    
                    % read image and header
                    %         if iF <= lastGoodFile % do not write frames beyond last good frame based on bleaching
                    readObj    = Tiff(fl{iF},'r');

                    current_header = struct();
                    for i = 1:length(tagNames)
                        try
                            current_header.(tagNames{i}) = readObj.getTag(tagNames{i});
                        catch
                            %warning([tagNames{i} 'does not exist on tif'])
                        end
                    end

                    thisstack  = zeros(imheader{iF}(1).Height,imheader{iF}(1).Width,numel(imheader{iF}),'uint16');
                    for iFrame = 1:numel(imheader{iF})
                        readObj.setDirectory(iFrame);
                        thisstack(:,:,iFrame) = readObj.read();
                    end
                    
                    % number of ROIs and blank pixels from beam travel
                    [nr,nc,~]  = size(thisstack);
                    padsize    = (nr - sum(ROInr)) / (nROI - 1);
                    rowct      = 1;
                    
                    
                    
                    % create a separate tif for each ROI
                    for iROI = 1:nROI
                        
                        thislag  = interROIlag*(iROI-1);
                        
                        for iDepth = 1:Depths
                            
                            % extract correct frames
                            zIdx       = iDepth:Depths:size(thisstack,3);
                            substack   = thisstack(rowct:rowct+ROInr(iROI)-1,1:ROInc(iROI),zIdx); % this square ROI, depths are interleaved
                            thisfn     = sprintf('./ROI%02d_z%d/%sROI%02d_z%d_%s',iROI,iDepth,basename,iROI,iDepth,fl{iF}(stridx+1:end));
                            writeObj   = Tiff(thisfn,'w');
                            thisheader = struct([]);
                            
                            % set-up header
                            for iField = 1:numel(fieldLs)
                                switch fieldLs{iField}
                                    case 'TIFF File'
                                        thisheader(1).(fieldLs{iField}) = thisfn;
                                        
                                    case 'ImageLength'
                                        thisheader(1).(fieldLs{iField}) = nc;
                                        
                                    otherwise
                                        thisheader(1).(fieldLs{iField}) = readObj.getTag(fieldLs{iField});
                                end
                            end
                            thisheader(1).ImageDescription        = imheader{iF}(zIdx(1)).ImageDescription;
                            %strrep(thisheader(1).Software,'hRoiManager.mroiEnable = 1', 'hRoiManager.mroiEnable = 0');
                            
                            thisheader(1).Artist                  = current_header.Artist;
                            thisheader(1).Software                = current_header.Software;
                            thisheader(1).Software = strrep(thisheader(1).Software,'hRoiManager.mroiEnable = 1', 'hRoiManager.mroiEnable = 0');
                            fovum = strfind(thisheader(1).Software,'SI.hRoiManager.imagingFovUm');
                            if ~isempty(fovum)
                                idx_new = regexp(thisheader(1).Software(fovum:end), newline, 'once');
                                thisheader(1).Software(fovum:fovum+idx_new-1) = [];
                            end
                            
                            % write first frame
                            writeObj.setTag(thisheader);
                            writeObj.setTag('SampleFormat',Tiff.SampleFormat.UInt);
                            writeObj.write(substack(:,:,1));
                            
                            % write frames
                            for iZ = 2:size(substack,3)
                                %                 % do not write frames beyond last good frame based on bleaching
                                %                 if iF == lastGoodFile && iZ > lastFrameInFile; continue; end
                                
                                % account for ROI lags in new time stamps
                                imdescription = imheader{iF}(zIdx(iZ)).ImageDescription;
                                old           = cell2mat(regexp(cell2mat(regexp(imdescription,'frameTimestamps_sec = [0-9]+.[0-9]+','match')),'\d+.\d+','match'));
                                new           = num2str(thislag + str2double(old));
                                imdescription = replace(imdescription,old,new);
                                % write image and hedaer
                                thisheader(1).ImageDescription = imdescription;
                                thisheader(1).Artist           = current_header.Artist;
                                thisheader(1).Software         = current_header.Software;
                                thisheader(1).Software = strrep(thisheader(1).Software,'hRoiManager.mroiEnable = 1', 'hRoiManager.mroiEnable = 0');
                                fovum = strfind(thisheader(1).Software,'SI.hRoiManager.imagingFovUm');
                                if ~isempty(fovum)
                                    idx_new = regexp(thisheader(1).Software(fovum:end), newline, 'once');
                                    thisheader(1).Software(fovum:fovum+idx_new-1) = [];
                                end
                                writeObj.writeDirectory();
                                writeObj.setTag(thisheader);
                                writeObj.setTag('SampleFormat',Tiff.SampleFormat.UInt);
                                write(writeObj,substack(:,:,iZ));
                            end
                            
                            % close tif stack object
                            writeObj.close();
                            
                            %clear substack
                        end
                        
                        % update first row index
                        rowct    = rowct+padsize+ROInr(iROI);
                    end
                    
                    readObj.close();
                    % now move file
                    movefile(fl{iF},sprintf('originalStacks/%s',fl{iF}));
                end
            end
            
            %% write to FieldOfView and FieldOfViewFile tables
            ct               = 1;
            cumulativeFrames = [0; cumulativeFrames];
            
            for iROI = 1:nROI
                ndepths = numel(recInfo.ROI(iROI).Zs);
                for iZ = 1:ndepths
                    
                    % FieldOfView
                    fov_key               = key_data;
                    fov_key.fov           = ct;
                    fov_key.fov_directory = sprintf('%s/ROI%02d_z%d/',scan_directory,iROI,iZ);
                    
                    if ~isempty(recInfo.ROI(iROI).name)
                        thisname        = sprintf('%s_z%d',recInfo.ROI(iROI).name,iZ);
                    else
                        thisname        = sprintf('ROI%02d_z%d',iROI,iZ);
                    end
                    
                    fov_key.fov_name                = thisname;
                    fov_key.fov_depth               = recInfo.ROI(iROI).Zs(iZ);
                    fov_key.fov_center_xy           = recInfo.ROI(iROI).centerXY;
                    fov_key.fov_size_xy             = recInfo.ROI(iROI).sizeXY;
                    fov_key.fov_rotation_degrees    = recInfo.ROI(iROI).rotationDegrees;
                    fov_key.fov_pixel_resolution_xy = recInfo.ROI(iROI).pixelResolutionXY;
                    fov_key.fov_discrete_plane_mode = recInfo.ROI(iROI).discretePlaneMode;%boolean(recInfo.ROI(iROI).discretePlaneMode);
                    
                    ct = ct+1;
                    insert(imaging.FieldOfView,fov_key)
                    
                    % FieldOfViewFiles
                    file_entries                    = key_data;
                    file_entries.fov                = fov_key.fov;
                    file_entries.file_number        = [];
                    file_entries.fov_filename       = '';
                    file_entries.file_frame_range   = '';
                    
                    fov_directory                   = fov_key.fov_directory;
                    fov_directory                   = lab.utils.format_bucket_path(fov_directory);
                    fl                              = dir(sprintf('%s*.tif',fov_directory));
                    file_entries                    = repmat(file_entries,[1 numel(fl)]);
                    for iF = 1:numel(fl)
                        file_entries(iF).file_number       = iF;
                        file_entries(iF).fov_filename      = fl(iF).name;
                        file_entries(iF).file_frame_range  = [cumulativeFrames(iF)+1 cumulativeFrames(iF+1)];
                        
                    end
                    insert(imaging.FieldOfViewFile, file_entries)
                end
            end
        end
        
        %% Insert FOV table for 2 and 3photon
        function insert_fov_photonmicro(self, key, scan_directory)
            
            fovkey = key;
            fovkey.fov = 1;
            fovkey.fov_directory = scan_directory;
            fovkey.fov_depth = 0;
            fovkey.fov_center_xy = 0;
            fovkey.fov_size_xy = 0;
            fovkey.fov_rotation_degrees = 0;
            fovkey.fov_pixel_resolution_xy = 0;
            fovkey.fov_discrete_plane_mode = 0;
            
            insert(imaging.FieldOfView, fovkey)
            
        end
        
        %% Inser FOV file field tables for 2 and 3photon
        function insert_fovfile_photonmicro(self, key, fl, imheader)
            
            
            filekeys                    = key;
            filekeys.fov                = 1;
            filekeys.file_number        = [];
            filekeys.fov_filename       = '';
            filekeys.file_frame_range   = '';
            filekeys                    = repmat(filekeys,[1 numel(fl)]);
            
            % If there is at least one tif file in directory
            if(~isempty(fl))
                prefile_frame_range = 0;
                for iF = 1:numel(fl)
                    
                    % check for files to have this structure: 'E84_20190614_40per_00001_00001.tif'
                    acq_string = regexp(fl{iF}, self.patt_acq_number, 'match');
                    number_string = regexp(fl{iF}, self.patt_file_number, 'match');
                    
                    %If regexp of file is there ..
                    if (length(acq_string) == 1 && length(number_string) == 1)
                        %Get file number
                        
                        filekeys(iF).file_number   = str2double(number_string{1}(2:end-1));
                        filekeys(iF).fov_filename   = fl{iF};
                        
                        %Calculate file frame range for this file
                        filekeys(iF).file_frame_range = [prefile_frame_range+1 prefile_frame_range+numel(imheader{iF})];
                        prefile_frame_range = filekeys(iF).file_frame_range(2);
                        
                    end
                    
                end
                insert(imaging.FieldOfViewFile, filekeys)
            end
            
            
        end
        
    end
    
end
