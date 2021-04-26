function [status,data] = read_behavior_file(key)
%READ_BEHAVIORAL_FILE, read information from behavioral file

data = [];
status = 0;
data_dir = fetch(acquisition.SessionStarted & key, 'task', 'remote_path_behavior_file');

%Load behavioral file
try
    [~, filepath] = lab.utils.get_path_from_official_dir(data_dir.remote_path_behavior_file);
    if data_dir.task == "Towers"
        data = load(filepath,'log');
        status = 1;
    else
        data = load(filepath);
        status = 1;
    end
catch
    disp(['Could not open behavioral file: ', filepath])
end

end

