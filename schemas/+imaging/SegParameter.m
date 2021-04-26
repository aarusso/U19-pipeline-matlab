%{
# segmentation method parameter
-> imaging.SegmentationMethod
seg_parameter_name:        varchar(64)   # parameter name of segmentation parameter
---
seg_parameter_description: varchar(255)  # description of this parameter
%}

classdef SegParameter < dj.Lookup
    properties
        contents = {
            'cnmf' , 'chunks_auto_select_behav' , 'boolean # select chunks automaticaly based on good behavioral performance';
            'cnmf' , 'chunks_auto_select_bleach' , 'boolean # select chunks automaticaly based on bleaching';
            'cnmf' , 'chunks_towers_min_n_trials' , 'int # min number of towers task trials to include a block';
            'cnmf' , 'chunks_towers_perf_thresh' , 'float # min performance (fraction correct) of towers task to include a block';
            'cnmf' , 'chunks_towers_bias_thresh' , 'float # max side bias (fraction trials) of towers task to include a block';
            'cnmf' , 'chunks_towers_max_frac_bad' , 'float # max fraction of bad motor trials of towers task to include a block';
            'cnmf' , 'chunks_visguide_min_n_trials' , 'int # min number of towers task trials to include a block';
            'cnmf' , 'chunks_visguide_perf_thresh' , 'float # min performance (fraction correct) of towers task to include a block';
            'cnmf' , 'chunks_visguide_bias_thresh' , 'float # max side bias (fraction trials) of towers task to include a block';
            'cnmf' , 'chunks_visguide_max_frac_bad' , 'float # max fraction of bad motor trials of towers task to include a block';
            'cnmf' , 'chunks_min_num_consecutive_blocks' , 'int  # min good consecuitve blocks to select session';
            'cnmf' , 'chunks_break_nonconsecutive_blocks' , 'boolean # set true to break non consecuitve behavior blocks into separate segmentation chunks';
            'cnmf' , 'cnmf_num_components' , 'int # number of components to be found, for initialization purposes';
            'cnmf' , 'cnmf_tau' , 'float # std of gaussian kernel (size of neuron)';
            'cnmf' , 'cnmf_p' , 'tinyint # order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)';
            'cnmf' , 'cnmf_num_iter' , 'tinyint # number of iterations';
            'cnmf' , 'cnmf_files_per_chunk' , 'int # max allowed files per segmentation chunk';
            'cnmf' , 'cnmf_proto_num_chunks' , 'int # how many chunks to use when initializing morphological segmentation';
            'cnmf' , 'cnmf_zero_is_minimum' , 'boolean # allow min fluorescence to be higher than zero';
            'cnmf' , 'cnmf_default_timescale' , 'float # ? (ask Sue Ann)';
            'cnmf' , 'cnmf_time_resolution' , 'float # time resolution in ms, if different than frame rate results in downsampling';
            'cnmf' , 'cnmf_dff_rectification' , 'float # deemphasize dF/F values below this magnitude when computing component correlations';
            'cnmf' , 'cnmf_min_roi_significance' , 'float # minimum significance for components to retain; at least some time points must be above this threshold';
            'cnmf' , 'cnmf_frame_rate' , 'float # imaging frame rate in fps';
            'cnmf' , 'cnmf_min_num_frames' , 'int # min required number of frames for segmentation';
            'cnmf' , 'cnmf_max_centroid_dist' , 'float # maximum fraction of diameter within which to search for a matching template';
            'cnmf' , 'cnmf_min_dist_pixels' , 'int # allow searching within this many pixels even if the diameter is very small';
            'cnmf' , 'cnmf_min_shape_corr' , 'float # minimum shape correlation for global registration';
            'cnmf' , 'cnmf_pixels_surround' , 'blob  # number of pixels considered to be the roi''s surround';
            'cnmf' , 'gof_contain_energy' , 'float # goodness of fit, fractional amount of energy used to specify spatial support';
            'cnmf' , 'gof_core_energy' , 'float # fractional amount of energy used to specify core of component';
            'cnmf' , 'gof_noise_range' , 'float # range in which to search for modal (baseline) activation';
            'cnmf' , 'gof_max_baseline' , 'float # number of factors below the data noise to consider as (unambiguously) baseline';
            'cnmf' , 'gof_min_activation' , 'int # number of factors above the data noise to consider activity as significant';
            'cnmf' , 'gof_high_activation' , 'int # number of factors above the data noise to consider activity as significant with reduced time span';
            'cnmf' , 'gof_min_time_span' , 'int # number of timeScale chunks to require activity to be above threshold';
            'cnmf' , 'gof_bkg_time_span' , 'int # number of timeScale chunks for smoothing the background activity level in order to determine its baseline';
            'cnmf' , 'gof_min_dff' , 'float # minimum dF/F to be considered as a significant transient';
            'cnmf' , 'gof_min_activation' , 'int # number of factors above the data noise to consider activity as significant';
            'cnmf' , 'gof_high_activation' , 'int # number of factors above the data noise to consider activity as significant with reduced time span';
            'cnmf' , 'gof_min_time_span' , 'int # number of timeScale chunks to require activity to be above threshold';
            'cnmf' , 'gof_bkg_time_span' , 'int # number of timeScale chunks for smoothing the background activity level in order to determine its baseline';
            'cnmf' , 'gof_min_dff' , 'float # minimum dF/F to be considered as a significant transient';
            }
    end
end