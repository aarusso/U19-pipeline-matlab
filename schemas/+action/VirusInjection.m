%{
-> action.Surgery
-> reference.Virus
---
injection_volume:		float   		# injection volume
rate_of_injection:		float           # rate of injection
virus_dilution:         float           # x dilution of the original virus 
-> reference.BrainLocation
%}

classdef VirusInjection < dj.Manual
end