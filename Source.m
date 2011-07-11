classdef Source < handle
%
%   Source class is implemented for the PowerSystem Package and it's used for all active sources. 
%
%    Source( ps, busK, type, signal_type, amp, phase, freq )
%     ps: Power System pointer
%     busK: Source bus connection
%     type: Must be a SourceTypes object: SourceTypes.(Voltage/Current)
%     signal_type: String containing the source signal type (Sinoidal/Step)
%     amp: Signal amplitude for all phases (column vector)
%     phase: Phase for wave forms for all phases (column vector)
%     freq: Frequency For wave forms for all phases (column vector)
%
%

  properties(Access = public) % Use these parameters to control sinoidal amp/freq/phase or step amp values.
    freq = 60.;                                 % freq: The source frequency;
    amp  = 1.;                                  % amp: The source amplitude;
    phase = 0.;                                 % phase: The source phase;
  end

  properties(GetAccess = public, SetAccess = protected) % Only Source and it childs can set these properties, but everyone can read them
    injection = 0.;                             % injection: The source injection on the system;
    injection_function = @(t) sin(2*pi*60*t);   % injection_function: Unnamed function depend on time used to calculate the injection: @(t) 3*sin(2*pi*60*t+29/180*pi)
  end

  properties(Access = protected) % Only Source and it childs can set and see these properties
    ps;                                         % PowerSystem pointer
  end

  properties(GetAccess = public, SetAccess = private) % Only Source can set these properties, but everyone can read them
    busK;                                       % busK: Source bus connection    
    type = SourceTypes.Voltage;                 % type: Must be a SourceTypes object (Voltage/Current)
  end 

  methods
    function src = Source( ps, busK, type, signal_type, amp, phase, freq )
      if nargin > 0
        src.ps = ps;
      end
      if nargin > 1
        src.busK = busK;
      end
      if nargin > 2
        src.type = type;
      end
      if nargin > 3
        if (isa(signal_type,'char')) % is the second argument a string?
          if (strcmpi('sinoidal',signal_type)) % is it sinoidal?
            if nargin < 8
              if size(amp,1) == 1
                src.amp=amp*ones(src.ps.topology,1);
              elseif size(amp,1) == 3 & src.ps.topology == SysTopo.Triphasic
                src.amp=amp;
              else
                error('PowerSystemPkg:Source','Problem setting source amplitude');
              end
              if size(freq,1) == 1
                src.freq=freq*ones(src.ps.topology,1);
              elseif size(freq,1) == 3 & src.ps.topology == SysTopo.Triphasic
                src.freq=freq;
              else
                error('PowerSystemPkg:Source','Problem setting source frequency');
              end
              if size(phase,1) == 1 & src.ps.topology == SysTopo.Monophasic
                src.phase=phase;
              elseif size(phase,1) == 1 & src.ps.topology == SysTopo.Triphasic
                src.phase=[phase;phase-120*pi/180;phase+120*pi/180];
              elseif size(phase,1) == 3 & src.ps.topology == SysTopo.Triphasic
                src.phase=phase;
              else
                error('PowerSystemPkg:Source','Problem setting source phase');
              end
            elseif nargin == 6
              if size(amp,1) == 1
                src.amp=amp*ones(src.ps.topology,1);
              elseif size(amp,1) == 3 & src.ps.topology == SysTopo.Triphasic
                src.amp=amp;
              else
                error('PowerSystemPkg:Source','Problem setting source amplitude');
              end
              src.freq=60.*ones(src.ps.topology,1);
              if size(phase,1) == 1 & src.ps.topology == SysTopo.Monophasic
                src.phase=phase;
              elseif size(phase,1) == 1 & src.ps.topology == SysTopo.Triphasic
                src.phase=[phase;phase-120*pi/180;phase+120*pi/180];
              elseif size(phase,1) == 3 & src.ps.topology == SysTopo.Triphasic
                src.phase=phase;
              else
                error('PowerSystemPkg:Source','Problem setting source phase');
              end
            elseif nargin == 5
              if size(amp,1) == 1
                src.amp=amp*ones(src.ps.topology,1);
              elseif size(amp,1) == 3 & src.ps.topology == SysTopo.Triphasic
                src.amp=amp;
              else
                error('PowerSystemPkg:Source','Problem setting source amplitude');
              end
              if src.ps.topology == SysTopo.Triphasic
                src.phase=[0.;-120;+120];
                src.freq=[60.;60.;60.];
              else
                src.phase=0.;
                src.freq=60.;
              end
            else % if nargin == 4
              if src.ps.topology == SysTopo.Triphasic
                src.amp=[1.;1.;1];
                src.phase=[0.;-120;+120];
                src.freq=[60.;60.;60.];
              else
                src.amp=1.;
                src.freq=60.;
                src.phase=0.;
              end
            end % nargin
            src.injection_function = @(t) src.amp.*sin(2*pi.*src.freq.*t + src.phase);
            return;
          elseif (strcmpi('step', signal_type)) % or step?
            src.amp = arg3;
            src.injection_function = @(t) src.amp;
          else % if not... error:
            error('PowerSystemPkg:Source','Signal type \"%s\" it not defined, use: sinoidal/step.',arg2);
          end 
        elseif isa(signal_type,'function_handle');
          src.injection_function = signal_type;
        else
          error('PowerSystemPkg:Source','Signal type input cannot be used.');
        end % what type is the second argument?
      end % nargin > 3
    end % Constructor

    function update(src)
%    function update(src)
%   
%     This function updates the source injection for the system time 
%
      src.injection = src.injection_function(src.ps.currentTime);
    end % update

  end % methods

end
