addpath('/home/pu.win.princeton.edu/shans/MATLAB Add-Ons/Toolboxes/mym/distribution/mexa64');

addpath(genpath('../../pipelines'))
addpath('~/datajoint-matlab-3.4.1')
setenv('DB_PREFIX', 'u19_')

host = env('DJ_HOST');
user = env('DJ_USER');
pw = env('DJ_PASSWORD');
dj.conn(host, user, pw)
