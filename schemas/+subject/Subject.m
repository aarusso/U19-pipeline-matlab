%{
# subject information
subject_fullname            : varchar(64)                   # <username>_<subject_nickname>
---
subject_nickname            : varchar(16)                   # nickname
-> lab.User
genomics_id=null            : int                           # number from the facility
sex="Unknown"               : enum('Male','Female','Unknown') # sex
dob=null                    : date                          # birth date
head_plate_mark=null        : blob                          # little drawing on the head plate for mouse identification
-> lab.Location
-> lab.Protocol
-> subject.Line
subject_description=''      : varchar(255)                  # description
initial_weight=null         : float                         # initial weight of the animal before the training start.
%}

classdef Subject < dj.Manual
end
