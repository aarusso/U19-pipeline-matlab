function [status] =  check_subject(subject_name)
%CHECK_SUBJECT, check if subject already in the database
%Input
% subject       = name of the subject to check
%Output
% status        = true if exist in the database, false otherwise

% Check for location in db
keysubject.subject_fullname = subject_name;
subject_info = fetch(subject.Subject & keysubject);
if ~isempty(subject_info)
    status = true;
else
    status = false;
end

