function play_motion_correction_results(session_key,local_data, video_num)


%By default get local video data and video # 1
if nargin < 2
    local_data = true;
    video_num = 1;
elseif nargin < 3
    video_num = 1;
end

% Get video
video = get_tif_video(session_key,local_data, video_num);
min_video = min(video(:));
max_video = max(video(:));


%Get shifts from motion correction tables
mcorr_within_file_key = session_key;
mcorr_within_file_key.file_number = 1;
shifts = fetch(imaging.MotionCorrectionWithinFile & mcorr_within_file_key, 'within_file_x_shifts', 'within_file_y_shifts'); 


%Plot first frame to center figure
frame = (video(:,:,1));
frame = padarray(frame,[3 3],max_video,'both');
f = figure('units','normalized','outerposition',[0 0 1 1]);
hold on
imshow([frame frame], 'InitialMagnification', 200);
movegui(f, 'center')


%Plot original frame and shifted corrected one side by side
 for i=1:size(video,3)

     frame = (video(:,:,i));
     frame_corr = imtranslate(frame,[shifts.within_file_x_shifts(i,2), shifts.within_file_y_shifts(i,2)]);
     
     frame = padarray(frame,[3 3],max_video,'both');
     frame_corr = padarray(frame_corr,[3 3],max_video,'both');
     
     frame_final = [frame frame_corr];
     frame_final = (frame_final-min_video) / (max_video-min_video);
     
     imshow(frame_final, 'InitialMagnification', 200)

 end
