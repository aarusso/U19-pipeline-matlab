%{
-> lab.Location                         # in which rig was performed io test
io_test_date:            date           # date IO test
io_test_time:            time           # time IO test 
-----
io_type:                 varchar(64)    # string that correspond to a certain combination of input and outputs tested
rig_test_parameters:     BLOB           # structure that contains parameters of test (e.g. laser power)
%}

classdef RigIOTest < dj.Manual
end