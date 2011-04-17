classdef Source < handle
% TODO: Source Help 
  properties(GetAccess = public, SetAccess = private) % Only I can set these properties, but everyone can read them
    type = 'Current'; % The source type of injection, only Current and Voltage may be accepted (TODO: Test this on set.type function)
    injection = 0.;  % The source injection on the system;
    signalType = 'Sinoidal'; % The source signal type of injection.
  end
  methods
    function src = Source(initialInjection, signalType, type)

    end
  end
end
