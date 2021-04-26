classdef TestBehaviorPopulate < Prep
    methods(Test)
        function TestBehaviorPopulate_testPopulate(testCase)

            populate(acquisition.SessionBlock)
            populate(behavior.TowersSession)
            populate(behavior.TowersBlock)

            testCase.verifyEqual(length(fetch(behavior.TowersBlock)), 12);
            testCase.verifyEqual(length(fetch(behavior.TowersBlockTrial)), 420)

        end
    end
end
