db = AnimalDatabase;

users = fetchn(lab.User, 'user_nickname');


for iuser = 1:length(users)
    user = users{iuser};
    animals_nicknames = fetchn(subject.Subject*lab.User & sprintf('user_nickname = "%s"', user), 'subject_nickname');
    animals = fetch(subject.Subject & (lab.User & sprintf('user_nickname = "%s"', user)));
    for ianimal = 1:numel(animals)
        animal = animals(ianimal);
        subject_nickname = animals_nicknames{ianimal};
        
    try
        logs = db.pullDailyLogs(user, subject_nickname);
    catch
        fprintf(sprintf('Animal %s no in the google spreadsheet\n', subject_nickname))
        continue
    end
     
        for log = logs
            %reset all keys to only contain animal information
            key_weigh = animal;
            key_status = animal;
            key_notification = animal;
            key_water_admin = animal;
            key_health = animal;
            key_session = animal;
            key_towers_session = animal;
            
            % ingest weighing
            if ~isempty(log.weight)
                key_weigh.weight = log.weight;
                if ~isempty(log.weighTime)
                    key_weigh.weighing_time = sprintf('%d-%02d-%02d %02d:%02d:00', ...
                        log.date(1), log.date(2), log.date(3), log.weighTime(1), log.weighTime(2));
                else
                    key_weigh.weighing_time = sprintf('%d-%02d-%02d 12:00:00', ...
                        log.date(1), log.date(2), log.date(3));
                end
                if ~isempty(log.weighPerson)
                    key_weigh.weigh_person = fetch1(lab.User & sprintf('user_nickname="%s"', log.weighPerson), 'user_id');
                end
                if ~isempty(log.weighLocation)
                    key_loc.location = log.weighLocation;
                    inserti(lab.Location, key_loc)
                end
                key_weigh.location = log.weighLocation;
                inserti(action.Weighing, key_weigh)
            end
            
            % ingest water administration info
            if ~isempty(log.received)
                key_water_admin.administration_date = sprintf('%d-%02d-%02d', ...
                    log.date(1), log.date(2), log.date(3));
                
                if ~isempty(log.earned)
                    key_water_admin.earned = log.earned;
                end
                if ~isempty(log.supplement)
                    key_water_admin.supplement = log.supplement;
                end
                key_water_admin.received = log.received;
                
                key_water_admin.watertype_name = 'Unknown';
                inserti(action.WaterAdministration, key_water_admin)
            end
            
            % ingest health status
            key_health.status_date = sprintf('%d-%02d-%02d', ...
                    log.date(1), log.date(2), log.date(3));
            if ~isempty(log.normal)
                key_health.normal_behavior = log.normal.strcmp('Yes');
            end
            if ~isempty(log.bcs)
                key_health.bcs = log.bcs;
            end
            if ~isempty(log.activity)
                key_health.activity = log.activity;
            end
            if ~isempty(log.eatDrink)
                key_health.eat_drink = log.eatDrink;
            end
            if ~isempty(log.turgor)
                key_health.turgor = log.turgor;
            end
            if ~isempty(log.posture)
                key_health.posture_grooming = log.posture;
            end
            if ~isempty(log.comments)
                key_health.comments = log.comments;
            end
            inserti(subject.HealthStatus, key_health)
            
            if ~isempty(log.actions)
                for iaction = 1:size(log.actions,1)
                    key_action = animal;
                    key_action.action_date = key_health.status_date;
                    key_action.action_id = iaction;
                    key_action.action = ['[' char(log.actions{iaction, 1}.string) '] ' log.actions{iaction, 2}];
                    inserti(action.ActionRecord, key_action)
                end
            end
            
            % ingest notification
            if ~isempty(log.cageNotice) || ~isempty(log.healthNotice) || ~isempty(log.weightNotice)
                key_notification.notification_date = sprintf('%d-%02d-%02d', ...
                    log.date(1), log.date(2), log.date(3));
                if ~isempty(log.cageNotice)
                    key_notification.cage_notice = log.cageNotice;
                end
                if ~isempty(log.healthNotice)
                    key_notification.health_notice = log.healthNotice;
                end
                if ~isempty(log.weightNotice)
                    key_notification.weight_notice = log.weightNotice;
                end
                inserti(action.Notification, key_notification)
            end
            
            % ingest session
            if ~isempty(log.trainStart) && ~isempty(log.mainMazeID) % TODO: ingest trainings without mainMazeID
                key_session.session_date = sprintf('%d-%02d-%02d', ...
                    log.date(1), log.date(2), log.date(3));
                key_session.session_start_time = sprintf('%d-%02d-%02d %2d:%2d:00', ...
                    log.date(1), log.date(2), log.date(3), log.trainStart(1), log.trainStart(2));
                key_session.session_end_time = sprintf('%d-%02d-%02d %2d:%2d:00', ...
                    log.date(1), log.date(2), log.date(3), log.trainEnd(1), log.trainEnd(2));
                
                % ingest locations
                key_location.location = log.rigName;
                inserti(lab.Location, key_location)           
                key_session.session_location = log.rigName;
                key_session.task = 'Towers';
                key_session.level = log.mainMazeID;
                key_session.set_id = 1;
                key_session.stimulus_bank = log.stimulusBank;
                key_session.session_performance = log.performance;
                if ~isempty(log.behavProtocol)
                    protocol = join(log.behavProtocol);
                    key_session.session_protocol = protocol{1};
                    
                    if ~isempty(log.versionInfo)
                        key_session.session_code_version = log.versionInfo;
                    end
                end
                
                key_towers_session.session_date = key_session.session_date;
                key_towers_session.stimulus_set = log.stimulusSet;
                key_towers_session.ball_squal = log.squal;
                key_towers_session.rewarded_side = log.trialType;
                key_towers_session.chosen_side = log.choice;
                key_towers_session.maze_id = log.mazeID;
                key_towers_session.num_towers_r = log.numTowersR;
                key_towers_session.num_towers_l = log.numTowersL;
                
                inserti(acquisition.Session, key_session)
                inserti(behavior.TowersSession, key_towers_session)
            end
            
        end
    end
end

