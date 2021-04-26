function animal_list = get_live_animals_list()

%get_liveAnimals_list get a full list of live subjects only
%Outputs
% animal_list = cell with list of all live subjects

%Get only subjects that are not dead
subject_table = subject.Subject;
%Get last status of subject
max_status_date = subject_table.aggr(action.SubjectStatus, 'max(effective_date)->effective_date');
subject_status_table = action.SubjectStatus * max_status_date;

%Filter dead as last status
key.subject_status = 'Dead';
subject_status_table_live = subject_status_table - key;

animal_list = fetch(subject_status_table_live, 'subject_fullname');
 
animal_list = {animal_list.subject_fullname};

end



