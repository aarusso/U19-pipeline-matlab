function time_event = get_time_from_iter(trial_time, iter_event)
% Function to transform iteration # to time
%Inputs
% trial_time   = vector with time for each iteration
% iter_event   = event based on iteration # (can be an array as well)
% Outputs
% time_event   = time translation of iteration #

time_event = [];

for i=1:length(iter_event)
    
    if ~isempty(iter_event(i)) && iter_event(i) < length(trial_time) && iter_event(i) ~= 0
        time_event(i)     =   trial_time(iter_event(i));
    end
    
end

end