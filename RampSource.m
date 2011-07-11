classdef RampSource < Source & dynamicprops
%
% TODO : Update Class Help
%
%


  properties(GetAccess = public, SetAccess = private) % Only RampSource can set these properties, but everyone can read them
    riseTime = 0.05;                          % riseTime: The ramp rising time
  end

  properties(Access = private) % Only RampSource can set and see these properties
    riseFactor                                % riseFactor: The ramp rising factor
  end

  methods
    function src = RampSource( ps, busK, type, signal_type, maxAmp, phase, frequency, riseTime );
      if nargin < 5
        error('PowerSystemPkg:RampSource','RampSource must be initialized with at least 4 arguments.');
      end
      if nargin < 6
        if ps.topology == SysTopo.Monophasic
          phase = 0.;
        elseif ps.topology == SysTopo.Triphasic
          phase = [0.;-120*pi/180;+120*pi/180];
        end
      end
      if nargin < 7
        frequency = 60.*ones(ps.topology,1);
      end
      if nargin < 8
        riseTime = 0.05.*ones(ps.topology,1);
      end
      src@Source( ps, busK, type, signal_type, zeros(ps.topology,1), phase, frequency);
      if (riseTime < 0)
        riseTime = 0;  
      end
      src.riseTime = riseTime;
      src.riseFactor = maxAmp./src.riseTime;
      src.addprop('timeListener'); % add a property so that we can reach the listener and delete it when it is not necessary anymore
      src.timeListener = addlistener(src.ps,'currentTime','PostSet',@src.adjustAmp);
    end % RampSource Constructor

    function adjustAmp(src, void, void2)
%    function adjustAmp(src)
%   
%     This function updates the source Amplitude 
%
      if ~isempty(find(src.ps.currentTime<=src.riseTime))
        src.amp = src.riseFactor.*src.ps.currentTime;
      else
        delete(src.timeListener); % delete listener
        delete(src.findprop('timeListener')); % delete listener property
      end
    end % adjustAmp 

  end % methods

end % RampSource

