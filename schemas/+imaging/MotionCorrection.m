%{
-> imaging.FieldOfView
-> imaging.McParameterSet                    # meta file, frameMCorr-method
---
mc_results_directory       : varchar(255)    # directory where motion correction results are stored
%}

classdef MotionCorrection < dj.Imported
    methods (Access=protected)
        function makeTuples(self, key)
            
            
            %Get Parameters from McParameterSetParameter table
            params        = imaging.utils.getParametersFromQuery(imaging.McParameterSetParameter & key, ...
                                                                'mc_parameter_value');
            
            %Correct mc_black_tolerance parameter
            if params.mc_black_tolerance < 0
                params.mc_black_tolerance = nan;
            end
            
            %Define cfg.mcorr with parameters (as in meso pipeline)
            if contains(key.mc_method,'NonLinear')
                cfg.mcorr    = {params.mc_max_shift, params.mc_max_iter, params.mc_stop_below_shift, ...
                    params.mc_black_tolerance, params.mc_median_rebin};
            else
                cfg.mcorr    = {params.mc_max_shift, params.mc_max_iter, params.mc_extra_param, ...
                    params.mc_stop_below_shift, params.mc_black_tolerance, params.mc_median_rebin};
            end
                        
            %Get scan directory
            bucket_fov_directory  = fetch1(imaging.FieldOfView & key,'fov_directory');
            fov_directory = lab.utils.format_bucket_path(bucket_fov_directory);
            
            %Check if directory exists in system
            lab.utils.assert_mounted_location(fov_directory)
            mc_results_bucket_directory = imaging.utils.get_mc_save_directory(bucket_fov_directory, key,'/');
            mc_results_directory        = imaging.utils.get_mc_save_directory(fov_directory, key,filesep);
            
            %Create motion correciton results directory
            if ~exist(mc_results_directory, 'dir')
                mkdir(mc_results_directory)
            end
            

            %% call functions to compute motioncorrectionWithinFile and AcrossFiles and insert into the tables
            fprintf('==[ PROCESSING ]==   %s\n', fov_directory);
            
            % Determine whether or not we need to use frame skipping to select only the first channel
            [order,movieFiles]            = fetchn(imaging.FieldOfViewFile & key, 'file_number', 'fov_filename');
            movieFiles                    = cellfun(@(x)(fullfile(fov_directory,x)),movieFiles(order),'uniformoutput',false); % full path

            info                          = cv.imfinfox(movieFiles{1}, true);
            if numel(info.channels) > 1
                cfg.mcorr{end+1}            = [0, numel(info.channels)-1];
            end
            
            % run motion correction
            if isempty(gcp('nocreate'))
                
                c = parcluster('local'); % build the 'local' cluster object
                num_workers = min(c.NumWorkers, 16);
                parpool('local', num_workers, 'IdleTimeout', 120);
                
            end
            
            [frameMCorr, fileMCorr]       = getMotionCorrection(movieFiles, false, 'off', 'SaveDir', mc_results_directory, cfg.mcorr{:});
            
            %% insert within file correction meso.motioncorrectionWithinFile
            within_key                        = key;
            within_key.file_number            = [];
            within_key.within_file_x_shifts   = [];
            within_key.within_file_y_shifts   = [];
            within_key.within_reference_image = [];
            within_key                        = repmat(within_key,[1 numel(frameMCorr)]);
            
            for iFile = 1:numel(frameMCorr)
                within_key(iFile).file_number                   = iFile;
                within_key(iFile).within_file_x_shifts          = frameMCorr(iFile).xShifts;
                within_key(iFile).within_file_y_shifts          = frameMCorr(iFile).yShifts;
                within_key(iFile).within_reference_image        = frameMCorr(iFile).reference;
            end
            
            
            %% insert within file correction meso.motioncorrectionAcrossFile
            across_key                             = key;
            across_key.cross_files_x_shifts        = fileMCorr.xShifts;
            across_key.cross_files_y_shifts        = fileMCorr.yShifts;
            across_key.cross_files_reference_image = fileMCorr.reference;
                        
            %% compute and save some stats as .mat files, intermediate step used downstream in the segmentation code
            movieName                     = stripPath(movieFiles);
            parfor iFile = 1:numel(movieFiles)
                computeStatistics(movieName{iFile}, movieFiles{iFile}, mc_results_directory, frameMCorr(iFile), false);
            end
            
            %% insert key
            key.mc_results_directory = mc_results_bucket_directory;
            self.insert(key);
            insert(imaging.MotionCorrectionWithinFile, within_key)
            insert(imaging.MotionCorrectionAcrossFiles, across_key)
            
        end
    end
end

%%
%---------------------------------------------------------------------------------------------------
function [statsFile, activity] = computeStatistics(movieName, movieFile, mc_results_directory, frameMCorr, recomputeStats)

% Fluorescence activity raw statistics
statsFile                   = regexprep(fullfile(mc_results_directory, movieName), '[.][^.]+$', '.stats.mat');

if recomputeStats ||  ~exist(statsFile, 'file')
    % Load raw data with per-file motion correction
    F                         = cv.imreadsub(movieFile, {frameMCorr,false});
    [stats,metric,tailProb]   = highTailActivityMetric(F);
    clear F;
    
    info                      = cv.imfinfox(movieFile);
    info.movieFile            = stripPath(movieFile);
    outputFile                = statsFile;
    if ~(exist(outputFile, 'file') == 2)
        parsave(outputFile, info, stats, metric, tailProb, '-v7.3');
    end
else
    metric                    = load(statsFile, 'metric');
    tailProb                  = metric.metric.tailProb;
end
activity                    = tailProb;

end