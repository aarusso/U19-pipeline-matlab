function assert_mounted_location(directory)

if ~exist(directory, 'dir')
    error ([directory ' is not mounted in your system'])
end
