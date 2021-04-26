session_key = struct('subject_fullname', 'lpinto_SP11', 'session_date', '2020-01-24');

session_query = acquisition.Session & session_key;
session_started_query = acquisition.SessionStarted & session_key;

session_started_data = fetch(acquisition.SessionStarted & session_key, '*');
session_data = fetch(session_query, '*');

task_data = fetch(task.Task & session_started_query, '*')
task_level_parameter_set_data = fetch(task.TaskLevelParameterSet, '*');
location_session_data = fetch(lab.Location & proj(session_query, 'session_location->location'), '*');

subject_query = subject.Subject & session_query;
subject_data = fetch(subject_query, '*');
line_data = fetch(subject.Line & subject_query, '*');
location_subject_data = fetch(lab.Location & subject_query, '*');
protocol_subject_data = fetch(lab.Protocol & subject_query, '*');
user_subject_data = fetch(lab.User & subject_query, '*');

lab_data = fetch(lab.Lab & 'lab="tanklab"', '*');
acquisition_type_data = fetch(lab.AcquisitionType, '*')

path_data = fetch(lab.Path, '*')

save([dj.config('root_dir'), '/tests/test_data/testmeta.mat'])
