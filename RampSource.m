classdef RampSource < Source
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
    function src = RampSource( busK, type, signal_type, maxAmp, phase, frequency, riseTime );
      if nargin < 4
        error('PowerSystemPkg:RampSource','RampSource must be initialized with at least 4 arguments.');
      end
      if nargin < 5
        phase = 0.;
      end
      if nargin < 6
        frequency = 60.;
      end
      if nargin < 7
        riseTime = 0.05;
      end
      src@Source( busK, type, signal_type, 0, phase, frequency);
      src.riseTime = riseTime;
      src.riseFactor = maxAmp/src.riseTime;
    end % RampSource Constructor

    function update(src,t)
%    function update(src,t)
%   
%     This function updates the source injection for the input time t    
%
%     t: Time;
%
      if (t<=src.riseTime)
        src.amp = src.riseFactor*t;
      end
      src.injection = src.injection_function(t);
    end % update

  end % methods

end % RampSource

