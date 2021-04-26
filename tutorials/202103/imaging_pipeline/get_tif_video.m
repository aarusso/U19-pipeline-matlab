function video_data = get_tif_video(session_key,local_data, video_num)

%By default get local video data and video # 1
if nargin < 2
    local_data = true;
    video_num = 1;
elseif nargin < 3
    video_num = 1;
end

if local_data
    local_scan_directory = fullfile(fileparts(mfilename('fullpath')), 'imaging_data');
else
    scan_data = fetch(imaging.Scan & session_key,'*');
    [~, local_scan_directory] = lab.utils.get_path_from_official_dir(scan_data.scan_directory);

end

tif_videos   = dir(fullfile(local_scan_directory, '*tif')); % tif file list

video_tif = fullfile(local_scan_directory, tif_videos(video_num).name);
video_data = cv.imreadx(video_tif, true);

end

