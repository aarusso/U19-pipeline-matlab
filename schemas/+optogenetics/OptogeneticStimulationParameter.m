%{
# Parameters related to laser stimulation
stim_parameter_set_id             : INT AUTO_INCREMENT
---
stim_parameter_description=''      : varchar(256)     # string that describes parameter set
stim_wavelength		               : DECIMAL(5,1)                    # (nm)
stim_power                         : DECIMAL(4,1)                    # (mW)
stim_frequency			           : DECIMAL(6,2)                    # (Hz)
stim_pulse_width			       : DECIMAL(5,1)                    # (ms)
%}

classdef OptogeneticStimulationParameter < dj.Lookup
    properties
        contents = ...
            {1, 'stim Parameters for airpuff task', ...,
            472, 10, 20, 10;
            2, 'stim Parameters for context task', ...,
            565, 10, 30, 15;
            }
    end
    
end
