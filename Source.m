classdef Source < handle
%
%   Source class is implemented for the PowerSystem Package and it's used for all active sources. 
%
%   Its constructor may be used by two different ways:
%
%    Source( busK, type,injection_function)
%     busK: Source bus connection
%     type: Must be a SourceTypes object SourceTypes.(Voltage/Current)
%     injection_function: Unnamed function depend on time used to calculate the injection: @(t) 3*sin(2*pi*60*t+29/180*pi)
%
%    Source( busK, type, signal_type, amp, phase, frequency )
%     busK: Source bus connection
%     type: Must be a SourceTypes object: SourceTypes.(Voltage/Current)
%     signal_type: String containing the source signal type (Sinoidal/Step)
%     amp: signal amplitude
%     phase: Phase For wave forms only 
%     frequency: Frequency For wave forms only 
%
% TODO: update functions
%

  properties(Access = public) % Use these parameters to control sinoidal amp/freq/phase or step amp values.
    freq = 60.;                                 % freq: The source frequency;
    amp  = 1.;                                  % amp: The source amplitude;
    phase = 0.;                                 % phase: The source phase;
  end

  properties(GetAccess = public, SetAccess = protected) % Only Source and it childs can set these properties, but everyone can read them
    injection = 0.;                                    % injection: The source injection on the system;
    injection_function = @(t) sin(2*pi*60*t);          % injection_function: Unnamed function depend on time used to calculate the injection: @(t) 3*sin(2*pi*60*t+29/180*pi)
  end

  properties(GetAccess = public, SetAccess = private) % Only Source can set these properties, but everyone can read them
    busK;                                              % busK: Source bus connection    
    type = SourceTypes.Voltage;                        % type: Must be a SourceTypes object (Voltage/Current)
  end

  methods

    function src = Source( busK, arg1, arg2, arg3, arg4, arg5 )
      if nargin > 0
        src.busK = busK;
      end
      if nargin > 1
        src.type = arg1;
      end
      if nargin > 2
        if ~isa(arg1,'SourceTypes')
          error('PowerSystemPkg:Source','Type must be a SourceTypes class.');
        end
        if (isa(arg2,'function_handle'))
          if( ~nargin(arg2 == 1)) % we want only time dependent functions
            error('PowerSystemPkg:Source','The injection_function must only be depent on time.');
          end
          src.injection_function = arg2; 
        elseif (isa(arg2,'char')) % is the second argument a string?
          if (strcmpi('sinoidal',arg2)) % is it sinoidal?
            if nargin == 6
              src.amp=arg3;
              src.freq=arg5;
              src.phase=arg4;
            elseif nargin == 5
              src.amp=arg3;
              src.freq=60.;
              src.phase=arg4;
            elseif nargin == 4
              src.amp=arg3;
              src.freq=60.;
              src.phase=0.;
            else % if nargin == 3
              src.amp=1.;
              src.freq=60.;
              src.phase=0.;
            end
            src.injection_function = @(t) src.amp*sin(2*pi*src.freq*t + src.phase);
            return;
          elseif (strcmpi('step',arg2)) % or step?
            src.amp = arg3;
            src.injection_function = @(t) src.amp;
          else % if not... error:
            error('PowerSystemPkg:Source','Signal type \"%s\" it not defined, use: sinoidal/step.',arg2);
          end 
        end
      end % nargin > 3
    end % Constructor

    function update(src,t)
      src.injection = src.injection_function(t);
    end % update

  end % methods

end
