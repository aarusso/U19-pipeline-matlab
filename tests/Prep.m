classdef Prep < matlab.unittest.TestCase
    % Setup and teardown for tests.
    properties (Constant)
        CONN_INFO = struct(...
            'host', dj.config('databaseHost'), ...
            'user', dj.config('databaseUser'), ...
            'password', dj.config('databasePassword'));
        PREFIX = 'u19_test_';
        test_root = dj.config('root_dir');
    end
    methods (TestClassSetup)
        function init(testCase)
            disp('---------------INIT---------------');
            clear functions;
            dj.config('safemode', false);
            curr_conn = dj.conn(testCase.CONN_INFO.host, ...
                testCase.CONN_INFO.user, testCase.CONN_INFO.password,'',true);
            setenv('DB_PREFIX', testCase.PREFIX)

            disp('----------Creating schemas--------');
            dj.createSchema('lab', [testCase.test_root '/schemas'], ...
                [testCase.PREFIX 'lab']);

            dj.createSchema('task', [testCase.test_root, '/schemas'], ...
                [testCase.PREFIX 'task']);

            dj.createSchema('subject', [testCase.test_root, '/schemas'], ...
                [testCase.PREFIX 'subject']);

            dj.createSchema('acquisition', [testCase.test_root, '/schemas'], ...
                [testCase.PREFIX 'acquisition']);

            dj.createSchema('behavior', [testCase.test_root, '/schemas'], ...
                [testCase.PREFIX 'behavior']);

            load([testCase.test_root '/tests/test_data/testmeta.mat'])

            inserti(lab.Lab, lab_data)
            inserti(lab.Path, path_data)
            inserti(lab.AcquisitionType, acquisition_type_data)
            inserti(lab.Location, location_subject_data)
            inserti(lab.Location, location_session_data)
            inserti(lab.Protocol, protocol_subject_data)
            inserti(lab.User, user_subject_data)
            inserti(task.Task, task_data)
            inserti(task.TaskLevelParameterSet, task_level_parameter_set_data)
            inserti(subject.Line, line_data)
            inserti(subject.Subject, subject_data)
            inserti(acquisition.SessionStarted, session_started_data)
            inserti(acquisition.Session, session_data)

        end
    end
    methods (TestClassTeardown)
        function dispose(testCase)
            disp('---------------DISP---------------');
            dj.config('safemode', false);
            curr_conn = dj.conn(testCase.CONN_INFO.host, ...
                testCase.CONN_INFO.user, testCase.CONN_INFO.password, '',true);

            % remove databases
            curr_conn.query('SET FOREIGN_KEY_CHECKS=0;');
            res = curr_conn.query(['SHOW DATABASES LIKE "' testCase.PREFIX '%";']);
            for i = 1:length(res.(['Database (' testCase.PREFIX '%)']))
                curr_conn.query(['DROP DATABASE ' ...
                    res.(['Database (' testCase.PREFIX '%)']){i} ';']);
            end
            curr_conn.query('SET FOREIGN_KEY_CHECKS=1;');
            curr_conn.close();
        end
    end
end
