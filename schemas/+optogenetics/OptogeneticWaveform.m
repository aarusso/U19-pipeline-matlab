%{
# Parameters related to laser stimulation
waveform_id             : INT AUTO_INCREMENT
---
waveform_description=''      : varchar(256)     # string that describes waveform
duration=null:               decimal(8,4)       # Duration of "entire" waveform stimulation
waveform=null:               longblob           # Waveform of stimulation
%}

%stim instead laser
%add waveform support

classdef OptogeneticWaveform < dj.Lookup
    properties
        contents = ...
            {1, 'Test sinusoid waveform', 3, sin(0:0.01:6*pi)}
    end
    
end
