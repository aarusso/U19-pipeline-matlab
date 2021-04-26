%{
# pre-saved parameter values
-> imaging.SegParameterSet
-> imaging.SegParameter
---
seg_parameter_value         : blob     # value of parameter
%}

classdef SegParameterSetParameter < dj.Part
    properties(SetAccess=protected)
        master   = imaging.SegParameterSet
    end
    methods
        function structParam = get_segSetParameter(self, key)
            
            %Get all names of parameters for given method
            paramKey.seg_method = key.seg_method;
            query = imaging.SegParameter & paramKey;
            parameters = query.fetchn('seg_parameter_name');
            
            %Predefined cell with param values for set
            tableParam  = cell2table({
                'cnmf' , 'chunks_auto_select_behav' , false;
                'cnmf' , 'chunks_auto_select_bleach' , true;
                'cnmf' , 'chunks_towers_min_n_trials' , 30;
                'cnmf' , 'chunks_towers_perf_thresh' , 0.6;
                'cnmf' , 'chunks_towers_bias_thresh' , 0.4;
                'cnmf' , 'chunks_towers_max_frac_bad' , 0.2;
                'cnmf' , 'chunks_visguide_min_n_trials' , 10;
                'cnmf' , 'chunks_visguide_perf_thresh' , 0.8;
                'cnmf' , 'chunks_visguide_bias_thresh' , 0.4;
                'cnmf' , 'chunks_visguide_max_frac_bad' , 0.2;
                'cnmf' , 'chunks_min_num_consecutive_blocks' , 2;
                'cnmf' , 'chunks_break_nonconsecutive_blocks' , true;
                'cnmf' , 'cnmf_num_components' , 400;
                'cnmf' , 'cnmf_tau' , 4;
                'cnmf' , 'cnmf_p' , 2;
                'cnmf' , 'cnmf_num_iter' , 2;
                'cnmf' , 'cnmf_files_per_chunk' , 16;
                'cnmf' , 'cnmf_proto_num_chunks' , 1;
                'cnmf' , 'cnmf_zero_is_minimum' , false;
                'cnmf' , 'cnmf_default_timescale' , 10;
                'cnmf' , 'cnmf_time_resolution' , 1000/12.3;
                'cnmf' , 'cnmf_dff_rectification' , 2;
                'cnmf' , 'cnmf_min_roi_significance' , 3;
                'cnmf' , 'cnmf_frame_rate' , 12.3;
                'cnmf' , 'cnmf_min_num_frames' , 2000;
                'cnmf' , 'cnmf_max_centroid_dist' , 1;
                'cnmf' , 'cnmf_min_dist_pixels' , 1;
                'cnmf' , 'cnmf_min_shape_corr' , 0.85;
                'cnmf' , 'cnmf_pixels_surround' , [3 13];
                'cnmf' , 'gof_contain_energy' , 0.9;
                'cnmf' , 'gof_core_energy' , 0.7;
                'cnmf' , 'gof_noise_range' , 2;
                'cnmf' , 'gof_max_baseline' , 1.5;
                'cnmf' , 'gof_min_activation' , 3;
                'cnmf' , 'gof_high_activation' , 5;
                'cnmf' , 'gof_min_time_span' , 1;
                'cnmf' , 'gof_bkg_time_span' , 3;
                'cnmf' , 'gof_min_dff' , 0.3;
                
                }, 'VariableNames',{'seg_method' 'seg_parameter_name' 'seg_parameter_value'});
            
            %Transform text columns to categorical (easier to compare == )
            tableParam.seg_method = categorical(tableParam.seg_method);
            tableParam.seg_parameter_name = categorical(tableParam.seg_parameter_name);
            
            %Filter current key parameters
            tableParam = tableParam(tableParam.seg_method == key.seg_method, :);
            
            %Transform parameters into struct
            structParam = cell2struct(tableParam.seg_parameter_value, cellstr(tableParam.seg_parameter_name));
            
            %Check if all parameter declared for this method are present in param definition
            for i=1:length(parameters)
                key.seg_parameter_name = parameters{i};
                value_cell = tableParam{tableParam.seg_parameter_name == key.seg_parameter_name, 'seg_parameter_value'};
                
                if size(value_cell,1) > 1
                    warning('More than one value for this key found: %s %d %s',key.seg_method, key.seg_parameter_set_id, key.seg_parameter_name)
                elseif size(value_cell,1) == 0
                    warning('No value for this key found: : %s %d %s',key.seg_method, key.seg_parameter_set_id, key.seg_parameter_name)
                end
                
            end
            
        end
    end
end
