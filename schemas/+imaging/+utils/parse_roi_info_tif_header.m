function [parsedInfo] = parse_roi_info_tif_header(header)

% [parsedInfo] = parse_roi_info_tif_header(header)
% parses tif headers saved by scan image in multi-ROI mode
%
% INPUT: 
% tifFn is string with file name;
%
% OUTPUT:
% header is the unprocessed header string, parsedInfo is matlab data structure

%% microscope info
scopeStr                           = header(1).Software;
resolutionFactor                   = mesoscopeParams.xySizeFactor * str2double(cell2mat(regexp(cell2mat(regexp(scopeStr,'SI.objectiveResolution = [0-9]+.[0-9]+','match')),'\d+.\d+','match')));

ROIinfo          = header(1).Artist;
ROImarks         = strfind(ROIinfo,'"scanimage.mroi.Roi"');
parsedInfo.nROIs = numel(ROImarks);

for iROI = 1:numel(ROImarks)
    if iROI ~= numel(ROImarks)
        thisROI = ROIinfo(ROImarks(iROI):ROImarks(iROI+1)-1);
    else
        thisROI = ROIinfo(ROImarks(iROI):end);
    end
    
    thisname                                 = regexp(thisROI,'"name": (""|"\w")','match');
    thisname                                 = regexp(thisname{1},'\w.,','match');
    if isempty(thisname); thisname = ''; else; thisname = cell2mat(thisname); thisname = thisname(1:end-2); end
    parsedInfo.ROI(iROI).name                = thisname;
    try
        parsedInfo.ROI(iROI).Zs                = mesoscopeParams.zFactor .* str2double(cell2mat(regexp(cell2mat(regexp(thisROI,'"zs": (\d|.\d.+)','match')),'(\d|.\d.+)','match')));
    catch
        temp                                   = regexp(thisROI,'"zs": \[.+\]\n','match');
        idx                                    = regexp(temp,',\n');
        temp                                   = temp{1}(1:idx{1}(1)-1);
        parsedInfo.ROI(iROI).Zs                = eval(cell2mat(regexp(temp,'\[.+\]','match')));
    end
    if isnan(parsedInfo.ROI(iROI).Zs)
        parsedInfo.ROI(iROI).Zs = 0;
    end
    try
        parsedInfo.ROI(iROI).centerXY          = resolutionFactor .* cellfun(@eval,regexp(cell2mat(regexp(thisROI,'"centerXY": .{0,2}\d+(|.\d+).{0,2}\d+(|.\d+.).{0,2}\d+(|.\d+).{0,2}\d+(|.\d+.)','match')),'((|-)\d+\.\d+|\d+)','match'));
    catch
        parsedInfo.ROI(iROI).centerXY          = resolutionFactor .* cellfun(@eval,regexp(cell2mat(regexp(thisROI,'"centerXY": .{0,2}\d+(|.\d+).{0,2}\d+(|.\d+.)','match')),'((|-)\d+\.\d+|\d+)','match'));
    end
    parsedInfo.ROI(iROI).sizeXY              = resolutionFactor .* cellfun(@eval,regexp(cell2mat(regexp(thisROI,'"sizeXY": .\d+.\d+.\d+.\d+.','match')),'\d+.\d+','match'));
    parsedInfo.ROI(iROI).rotationDegrees     = str2double(cell2mat(regexp(cell2mat(regexp(thisROI,'"rotationDegrees": (\d+|\d+.\d.+)','match')),'(\d+|\d+.\d.+)','match')));
    parsedInfo.ROI(iROI).pixelResolutionXY   = cellfun(@eval,regexp(cell2mat(regexp(thisROI,'"pixelResolutionXY": .(\d+.\d+|\d+).(\d+.\d+|\d+).','match')),'(\d+.\d{,1}|\d+)','match'));
    parsedInfo.ROI(iROI).discretePlaneMode   = logical(str2double(cell2mat(regexp(cell2mat(regexp(thisROI,'"discretePlaneMode": \d','match')),'\d','match'))));
    
end
end

