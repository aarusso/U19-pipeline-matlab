
addpath(genpath('../../../U19-pipeline-matlab'))
setenv('DB_PREFIX', 'u19_')

host = 'datajoint00.pni.princeton.edu';

dj.conn(host)