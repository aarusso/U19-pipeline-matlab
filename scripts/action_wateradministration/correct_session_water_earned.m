
clearvars
towers_session   = behavior.TowersSession;                  
reward_session   = towers_session.aggr(behavior.TowersBlock, 'sum(reward_mil)->reward_session');
water_admin_info = proj(action.WaterAdministration, 'administration_date->session_date', 'earned');


final_comparison = (reward_session * water_admin_info);
final_comparison2 = proj(final_comparison, 'abs(reward_session-earned)->diff', 'reward_session', 'earned');

extra_info = final_comparison2 * proj(acquisition.SessionStarted, 'remote_path_behavior_file');

session_struct = fetch( extra_info & 'diff>0.001', 'remote_path_behavior_file', 'reward_session', 'earned', 'ORDER BY session_date desc')
                    
                    
                   
for j=1:length(session_struct)
    
    [j length(session_struct)]
    
    key = struct();
    key.subject_fullname = session_struct(j).subject_fullname;
    key.session_date     = session_struct(j).session_date
    
    [~, acqsession_file] = lab.utils.get_path_from_official_dir(session_struct(j).remote_path_behavior_file);
    
    %Load behavioral file & update water eanred
    try
        disp(acqsession_file)
        data = load(acqsession_file,'log');
        log = data.log;
        updateWaterEarnedFromFile(action.WaterAdministration, key, log);
    catch err 
        disp('Could not open file');
    end
    
end