function os = get_OS()

if ispc
    os = 'windows';
    return
elseif ismac
    os = 'mac';
else
    os = 'linux';
end