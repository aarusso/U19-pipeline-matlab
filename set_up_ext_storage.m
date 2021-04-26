

if ispc
    ext_storage_path = '\\bucket.pni.princeton.edu\u19_dj\external_dj_blobs\';
elseif u19_dj_utils.is_this_spock

    ext_storage_path = '/mnt/bucket/u19_dj/external_dj_blobs/';

elseif isunix
    ext_storage_path = '/Volumes/u19_dj/external_dj_blobs/';
end


u19_storage = struct('protocol', 'file',...
    'location', ext_storage_path);
dj.config('stores.extstorage', u19_storage)

dj.config.saveLocal()
