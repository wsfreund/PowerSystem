classdef PassiveElement < handle & Source
%
%   PassiveElement class is implemented for the PowerSystem Package and it's 
%     used for all passive elements containing series capacitor and/or inductors with or without resistences. 
%
%   Its constructor is defined as following:
%
%    PassiveElement(step,busK,busM,R,L,C)
%
%     step: system time step
%     busK: Current incoming BUS 
%     busM: Current destination BUS
%     R: PassiveElement Resistence
%     L: PassiveElement Inductance
%     C: PassiveElement Capacitance
%

  properties(GetAccess = public, SetAccess = private) % Only I can set these properties, but everyone can read them
    Gseries = 0.;                               % Gseries: Total admitance for Passive Element;
    R = 0.;                                     % R: Passive Element Resistence;
    L = 0.;                                     % L: Passive Element Inductance;
    C = 0.;                                     % C: Passive Element Capacitance;
    busM = 0;                                   % busM: Source destination bus;
    ikm = 0.;                                   % ikm: Current flowing from bus k to bus m;
  end


  properties(Access = private, Hidden) % Only PassiveElement can set and see these properties
    Vc = 0.;                                    % Vc: Capacitor Voltage;
    prev_ikm = 0.;                              % prev_ikm: Current flowing from bus k to bus m on t - Delta_t;
    L2DivStep = 0.;                             % L/step;
    stepDiv2C = 0.;                             % step/C;
  end

  methods
    function pe = PassiveElement(step,busK,busM,R,L,C)
      if ( (nargin < 5) && (nargin > 0) ) % It is not possible to initialize without at least 5 arguments.
        error('PowerSystemPkg:PassiveElement', 'You must specify at least 5 args to construct a PassiveElement PassiveElement(ps,bus1,bus2,R,L,C,initial_injection)');
      end
      if nargin == 0
        busK=0;
      end
      pe@Source(busK, SourceTypes.Current);
      if nargin > 2
        pe.busM = busM;
      end
      if nargin > 3
        if nargin == 5
          C = 0.;
        end
        pe.R = R;
        pe.L = L;
        pe.L2DivStep = (L*2)/step;
        pe.C = C; 
        if C
          pe.stepDiv2C= step/(2*C);
        end
        if ( C ~= 0 ) % With Capacitor:
          pe.Gseries = 1 / (pe.R + pe.L2DivStep + pe.stepDiv2C);
          pe.injection_function = @( prev_ikm, prev_vbusK, prev_vbusM ) ...
            pe.Gseries*( (pe.L2DivStep - pe.R - pe.stepDiv2C)*( prev_ikm ) ...
            + prev_vbusK - prev_vbusM - 2*pe.Vc ); % Since pe.Vc is only updated after pe.injection this pe.Vc is on t-Deltat
        else % Without capacitor:
          pe.Gseries = 1 / ( pe.R + pe.L2DivStep );
          pe.injection_function = @(prev_ikm, prev_vbusK, prev_vbusM) ...
            pe.Gseries*( (pe.L2DivStep - pe.R)*(prev_ikm) + prev_vbusK - prev_vbusM );
        end
      end
    end % Constructor

    function update_injection(pe,prev_vbusK,prev_vbusM)
%    function update_injection(pe,prev_vbusK,prev_vbusM)
%
%     This function is used to update the Passive Element historical current injection
%       
%   Inputs:
%     prev_vbusK: previous voltage on bus K;
%     prev_vbusM: previous voltage on bus M;
%
      pe.prev_ikm = pe.ikm; % save previous ikm
      % Update injection
      if pe.C
        pe.injection = pe.injection_function(pe.prev_ikm,prev_vbusK,prev_vbusM); % Update source injection (hist current)
      else
        pe.injection = pe.injection_function(pe.prev_ikm,prev_vbusK,prev_vbusM); % Update source injection (hist current)
      end
    end % update

    function update_ikm(pe,vbusK,vbusM)
%    function update_ikm(pe,vbusK,vbusM)
%
%     This function is used to update the Passive Element total current flowing from bus K to M.
%   If the Passive Element contains a capacitor it also updates the capacitor voltage.
%       
%   Inputs:
%     vbusK: voltage on bus K;
%     vbusM: voltage on bus M;
%
      pe.ikm = pe.injection + pe.Gseries*(vbusK-vbusM); % update ikm
      if pe.C
        pe.Vc = pe.Vc + (pe.stepDiv2C) * ( pe.ikm + pe.prev_ikm );
      end
    end % update_ikm
  end % methods

end

