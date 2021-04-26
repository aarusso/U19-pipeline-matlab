%{
# Defined optogenetic protocols for training
optogenetic_protocol_id           : INT AUTO_INCREMENT
---
protocol_description=''           : varchar(256)            # String that describes stimulation protocol
-> [nullable] optogenetics.OptogeneticStimulationParameter  # Stimulation parameters associated with this stim protocol
-> [nullable] optogenetics.OptogeneticWaveform              # Stimulation waveform associated with protocol (if any)
%}

classdef OptogeneticProtocol < dj.Manual    
end
