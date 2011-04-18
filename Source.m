classdef Source < handle
%
%   Source class is implemented for the PowerSystem Package and used for all active sources. It constructor may be used with two different ways:
%
%    Source( type,injection_function)
%     type: Must be a SourceTypes object (Voltage/Current)
%     injection_function: Unnamed function depend on time used to calculate the injection: @(t) 3*sin(2*pi*60*t+29/180*pi)
%
%    Source( type, signal_type, amp, phase, frequency )
%     type: Must be a SourceTypes object (Voltage/Current)
%     signal_type: String containing the source signal type (Sinoidal/Step)
%     amp: signal amplitude
%     phase: Phase For wave forms only 
%     frequency: Frequency For wave forms only 
%
% TODO: Update Source Help 

  properties(GetAccess = public, SetAccess = protected) % Only Source and it childs can set these properties, but everyone can read them
    injection = 0.;                             % injection: The source injection on the system;
    injection_function = @(t) 1*sin(2*pi*60*t); % injection_function: Unnamed function depend on time used to calculate the injection: @(t) 3*sin(2*pi*60*t+29/180*pi)
  end

  properties(GetAccess = public, SetAccess = private) % Only Source can set these properties, but everyone can read them
    type = SourceTypes.Voltage                  % type: Must be a SourceTypes object (Voltage/Current)
  end

  methods
    function src = Source( arg1, arg2, arg3, arg4, arg5 )
      if nargin > 0
        if ~isa(arg1,'SourceTypes')
          error('PowerSystemPkg:Source','Type must be a SourceTypes class.');
        end
        src.type = type;
        if (isa(arg2,'function_handle'))
          if( ~nargin(arg2 == 1)) % we want only time dependent functions
            error('PowerSystemPkg:Source','The injection_function must only be depent on time.');
          end
          src.injection_function = injection_function; 
        elseif (isa(arg2,'char')
          if (strcmp('sinoidal',lower(arg1)))
            if nargin == 5
              amp=arg3;
              freq=arg5;
              phase=arg4;
            elseif nargin == 4
              amp=arg3;
              freq=60.;
              phase=arg4;
            elseif nargin == 3
              amp=arg3;
              freq=60.;
              injection_function = @(t) amp*sin(2*pi*freq);
              return
            end % if nargin == 2
            injection_function = @(t) amp*sin(2*pi*freq + phase);
            return
          elseif (strcmp('step',lower(arg1)))
            injection_function = @(t) arg2;
            return
          end % if strcmp('sinoidal',lower(arg1)))
        end % if (isa(arg1,'function_handle')
      end % nargin > 0
    end % Constructor

    function update(pe)
      % TODO: Implement to use discrete time
      pe.injection = injection_function(time);
    end % update
    % Limit signalType to sinoidal, impulse and step.
    function
  end % methods

end
