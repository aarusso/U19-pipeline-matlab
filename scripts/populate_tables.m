[keys_dir, errors_dir] = populate(behavior.DataDirectory, 'session_date>"2021-01-01"');
[keys_session_block, errors_session_block] = populate(acquisition.SessionBlock)
[keys_towers_session, errors_towers_session] = populate(behavior.TowersSession);
[keys_block, errors_block] = populate(behavior.TowersBlock);
[keys_session_psych, errors_session_psych] = populate(behavior.TowersSessionPsych);
[keys_subject_psych, errors_subject_psych] = populate(behavior.TowersSubjectCumulativePsych);
[keys_psych_level, errors_psych_level] = populate(behavior.TowersSubjectCumulativePsychLevel);
