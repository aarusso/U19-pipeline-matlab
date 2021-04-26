function [header,parsedInfo] = parse_tif_header(tifFn,skipBehavSync)

% [header,parsedInfo] = parse_tif_header(tifFn,skipBehavSync)
% parses tif headers saved by scan image in multi-ROI mode
% INPUT: tiffn is string with file name; skipBehavSync boolean to skip I2C
% data
% OUTPUT: header is the unprocessed header string, parsedInfo is matalb
% data structure

%%
if nargin < 2; skipBehavSync = false; end

%% hole header
header                      = imfinfo(tifFn);

%% general image info
if isfield(header(1), 'Software')
    scopeStr                    = header(1).Software;
else
    scopeStr                    = header(1).ImageDescription;
end
parsedInfo.Filename         = header(1).Filename;
parsedInfo.Width            = header(1).Width;
parsedInfo.Height           = header(1).Height;
parsedInfo.AcqTime          = cell2mat(regexp(cell2mat(regexp(header(1).ImageDescription,'epoch = \[[0-9]{4}.+\d\]\n','match')),'[0-9]{4}(.[0-9]+.)+.[0-9]+.[0-9]+','match'));
if ~isempty(regexp(scopeStr,'SI.hFastZ.numFramesPerVolume = [0-9]+','match'))
    parsedInfo.nDepths          = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hFastZ.numFramesPerVolume = [0-9]+','match')),'\d+','match')));
else
    parsedInfo.nDepths          = 0;
end
try
    parsedInfo.Zs             = mesoscopeParams.zFactor .* eval(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hFastZ.userZs =.\[(.\d+.)+\]','match')),'.\[(.\d+.)+\]','match')));
catch
    try
        parsedInfo.Zs           = mesoscopeParams.zFactor .* eval(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hFastZ.userZs = \d+','match')),'\d+','match')));
    catch
        temp                    = regexp(scopeStr,'SI.hFastZ.userZs = \[.+\]\n','match');
        idx_zs = strfind(scopeStr,'SI.hFastZ.userZs')
        if ~isempty(idx_zs)
            disp('se encontro la frase SI.hFastZ.userZs')
            scopeStr(idx_zs(1)-30:idx_zs(1)+50)
        end
        disp('try catch 2 Here for Zs')
        temp
        idx                     = regexp(temp,'\n');
        idx
        temp                    = temp{1}(1:idx{1}(1)-1);
        parsedInfo.Zs           = eval(cell2mat(regexp(temp,'\[.+\]','match')));
    end
end
parsedInfo.frameRate        = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hRoiManager.scanVolumeRate = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
parsedInfo.interROIlag_sec  = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hScan2D.flytoTimePerScanfield = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));

%% time stamps and sync
if ~skipBehavSync
    parsedInfo.Timing.Frame_ts_sec = zeros(numel(header),1);
    parsedInfo.Timing.BehavFrames  = cell(numel(header),1);
    
    for iF = 1:numel(header)
        parsedInfo.Timing.Frame_ts_sec(iF)   = str2double(cell2mat(regexp(cell2mat(regexp(header(iF).ImageDescription,'frameTimestamps_sec = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
        thisdata                             = cell2mat(regexp(header(iF).ImageDescription,'I2CData = {.+}','match'));
        if isempty(thisdata)
            parsedInfo.Timing.BehavFrames{iF}  = {};
        else
            try
                parsedInfo.Timing.BehavFrames{iF}  = eval(cell2mat(regexp(thisdata,'{.+}','match')));
            catch
                parsedInfo.Timing.BehavFrames{iF}  = nan;
            end
            %       % transform commas into spaces for sue anns code compatibility
            %       commaidx                  = regexp(thisdata,',');
            %       thisdata(commaidx(2:end)) = ' ';
            %       hidx                      = regexp(header(iF).ImageDescription,'I2CData = {.+}');
            %       header(iF).ImageDescription(hidx:hidx+numel(thisdata)) ...
            %                                 = sprintf('%s\n',thisdata);
        end
    end
end

%% microscope info
if contains(scopeStr,'objectiveResolution')
    try
    resolutionFactor                   = mesoscopeParams.xySizeFactor * str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.objectiveResolution = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
    catch
    resolutionFactor                   = mesoscopeParams.xySizeFactor * str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.objectiveResolution = \d*','match')),'\d+', 'match')));    
    end
else
    resolutionFactor                   = 1;
end

parsedInfo.Scope.Power_percent         = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hBeams.powers = \d+','match')),'\d+','match')));
parsedInfo.Scope.Channels              = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hChannels.channelSave = \d+','match')),'\d+','match')));
parsedInfo.Scope.cfgFilename           = cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hConfigurationSaver.cfgFilename = .+cfg','match')),' .[A-Z].+cfg','match'));
parsedInfo.Scope.usrFilename           = cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hConfigurationSaver.usrFilename = .+usr','match')),' .[A-Z].+usr','match'));

if contains(scopeStr,'actuatorLag')
    try
    parsedInfo.Scope.fastZ_lag         = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hFastZ.actuatorLag = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
    catch
    parsedInfo.Scope.fastZ_lag         = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hFastZ.actuatorLag = \d*','match')),'\d+', 'match')));    
    end
else
    parsedInfo.Scope.fastZ_lag         = 0;
end
if ~isempty(regexp(scopeStr,'SI.hFastZ.flybackTime = [0-9]+.[0-9]+','match'))
    parsedInfo.Scope.fastZ_flybackTime = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hFastZ.flybackTime = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
else
    parsedInfo.Scope.fastZ_flybackTime = 0;
end
parsedInfo.Scope.linePeriod            = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hRoiManager.linePeriod = [0-9]+.[0-9]+e-[0-9]+','match')),'\d+.\d+e-[0-9]+','match')));
parsedInfo.Scope.scanFramePeriod       = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hRoiManager.scanFramePeriod = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
parsedInfo.Scope.scanFrameRate         = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hRoiManager.scanFrameRate = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
parsedInfo.Scope.scanVolumeRate        = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hRoiManager.scanVolumeRate = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
parsedInfo.Scope.flybackTimePerFrame   = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hScan2D.flybackTimePerFrame = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
parsedInfo.Scope.flytoTimePerScanfield = str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hScan2D.flytoTimePerScanfield = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));
if contains(scopeStr,'fovCornerPoints')
    parsedInfo.Scope.fovCornerPoints   = resolutionFactor .* eval(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.hScan2D.fovCornerPoints = (\[-).{2,80}\]\n','match')),'\[-\d.+\d\]','match')));
else
    parsedInfo.Scope.fovCornerPoints   = 0;
end

end
