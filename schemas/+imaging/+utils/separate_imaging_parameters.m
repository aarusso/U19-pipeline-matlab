function [chunk_cfg, cnmf_cfg, gof_cfg] = separate_imaging_parameters(params)
%SEPARATE_IMAGING_PARAMETERS Summary of this function goes here

% separate params for cmnf method from imaging.SegParameterSetParameter table into 3 categories
%chunk_cfg, cnmf_cfg and gof_cfg.
%
% INPUT:
% params:       cell with parameters from imaging.SegParameterSetParameter
%
% OUTPUT:
% chunk_cfg:    selectFileChunks params
% cnmf_cfg:     cnmf, general params
% gof_cfg:      cnmf, goodness of fit params
%
% selectFileChunks params

chunk_cfg.auto_select_behav    = params.chunks_auto_select_behav;
chunk_cfg.auto_select_bleach   = params.chunks_auto_select_bleach;
chunk_cfg.filesPerChunk        = params.cnmf_files_per_chunk;
chunk_cfg.T11_minNtrials       = params.chunks_towers_min_n_trials;
chunk_cfg.T11_perfTh           = params.chunks_towers_perf_thresh;
chunk_cfg.T11_biasTh           = params.chunks_towers_bias_thresh;
chunk_cfg.T11_fracBad          = params.chunks_towers_max_frac_bad;
chunk_cfg.T12_minNtrials       = params.chunks_visguide_min_n_trials;
chunk_cfg.T12_perfTh           = params.chunks_visguide_perf_thresh;
chunk_cfg.T12_biasTh           = params.chunks_visguide_bias_thresh;
chunk_cfg.T12_fracBad          = params.chunks_visguide_max_frac_bad;
chunk_cfg.min_NconsecBlocks    = params.chunks_min_num_consecutive_blocks;
chunk_cfg.breakNonConsecBlocks = params.chunks_break_nonconsecutive_blocks;

% cnmf, general
cnmf_cfg.K                     = params.cnmf_num_components;
cnmf_cfg.tau                   = params.cnmf_tau;
cnmf_cfg.p                     = params.cnmf_p;
cnmf_cfg.iterations            = params.cnmf_num_iter;
cnmf_cfg.filesPerChunk         = params.cnmf_files_per_chunk;
cnmf_cfg.protoNumChunks        = params.cnmf_proto_num_chunks;
cnmf_cfg.zeroIsMinimum         = params.cnmf_zero_is_minimum;
cnmf_cfg.defaultTimeScale      = params.cnmf_default_timescale;
cnmf_cfg.timeResolution        = 1000/params.frameRate;
cnmf_cfg.dFFRectification      = params.cnmf_dff_rectification;
cnmf_cfg.minROISignificance    = params.cnmf_min_roi_significance;
cnmf_cfg.frameRate             = params.frameRate;
cnmf_cfg.minNumFrames          = params.cnmf_min_num_frames;
cnmf_cfg.maxCentroidDistance   = params.cnmf_max_centroid_dist;
cnmf_cfg.minDistancePixels     = params.cnmf_min_dist_pixels;
cnmf_cfg.minShapeCorr          = params.cnmf_min_shape_corr;
cnmf_cfg.pixelsSurround        = params.cnmf_pixels_surround;

% cnmf, goodness of fit
gof_cfg.containEnergy          = params.gof_contain_energy;
gof_cfg.coreEnergy             = params.gof_core_energy;
gof_cfg.noiseRange             = params.gof_noise_range;
gof_cfg.maxBaseline            = params.gof_max_baseline;
gof_cfg.minActivation          = params.gof_min_activation;
gof_cfg.highActivation         = params.gof_high_activation;
gof_cfg.minTimeSpan            = params.gof_min_time_span;
gof_cfg.bkgTimeSpan            = params.gof_bkg_time_span;
gof_cfg.minDeltaFoverF         = params.gof_min_dff;

end

