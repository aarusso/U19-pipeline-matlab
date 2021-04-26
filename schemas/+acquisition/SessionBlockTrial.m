%{
-> acquisition.SessionBlock
trial_idx:          int     # trial index, keep the original number in the file
---
%}

%     'CREATE TABLE `u19_behavior`.`_test_towers_block__trial` (
%      `subject_fullname` varchar(64) NOT NULL COMMENT "username_mouse_nickname",
%      `session_date` date NOT NULL COMMENT "date of experiment",
%      `session_number` int NOT NULL COMMENT "number",
%      `block` tinyint NOT NULL COMMENT "block number",
%      `trial_idx` int NOT NULL COMMENT "trial index, keep the original number in the file",
%      PRIMARY KEY (`subject_fullname`,`session_date`,`session_number`,`block`,`trial_idx`),
%      CONSTRAINT `uC0SFtta` FOREIGN KEY (`subject_fullname`,`session_date`,`session_number`,`block`) REFERENCES `u19_behavior`.`_towers_block` (`subject_fullname`,`session_date`,`session_number`,`block`) ON UPDATE CASCADE ON DELETE RESTRICT
%      ) ENGINE = InnoDB, COMMENT ""'

classdef SessionBlockTrial < dj.Part
    properties(SetAccess=protected)
        master = acquisition.SessionBlock
    end
end