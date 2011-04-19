classdef PassiveElement < handle & Source
%
%   PassiveElement class is implemented for the PowerSystem Package and it's 
%     used for all passive elements containing series capacitor and/or inductors with or without resistences. 
%
%   Its constructor is defined as following:
%
%    PassiveElement(step,busK,busM,R,L,C,initial_injection)
%
%     step: system time step
%     busK: Current incoming BUS 
%     busM: Current destination BUS
%     R: PassiveElement Resistence
%     L: PassiveElement Inductance
%     C: PassiveElement Capacitance
%     initial_injection: Source initial injection (if any passive element was charged)
%

  properties(GetAccess = public, SetAccess = private) % Only I can set these properties, but everyone can read them
    Gseries = 0.;                               % Gseries: Total admitance for Passive Element;
    R = 0.;                                     % R: Passive Element Resistence;
    L = 0.;                                     % L: Passive Element Inductance;
    C = 0.;                                     % C: Passive Element Capacitance;
    busM = uint32(0);                           % busM: Source destination bus;
  end


  properties(Access = private, Hidden) % Only PassiveElement can set and see these properties
    Vc = 0.;                                    % Vc: Capacitor Voltage;
    update_vC;                                  % update_vC : Unnamed function depend on system step used to calculate the capacitor voltage: 
    old_injection;                              % old_injection: injection for (t-1)
  end

  methods
    function pe = PassiveElement(step,busK,busM,R,L,C,initial_injection)
      if ( (nargin < 5) & (nargin > 0) ) % It is not possible to initialize without at least 5 arguments.
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
        if nargin == 6
          initial_injection = 0.;
        end
        if nargin == 5
          C = 0.;
        end
        pe.R = R;
        pe.L = L;
        pe.C = C; 
        pe.injection = initial_injection;
        if ( C ~= 0 ) % With Capacitor:
          pe.Gseries = 1 / (R + 2*L/step + step/(2*C));
          pe.update_vC = @() pe.Vc + (step/(2*ps.C)) * (pe.injection_function+pe.old_injection);
          pe.injection_function = @(prev_injection, vbus1, vbus2) ...
            pe.Gseries*( (2*pe.L/step - pe.R - step/(2*ps.C))*prev_injection ...
            + vbus1 - vbus2 - 2*pe.Vc );
        else % Without capacitor:
          pe.injection_function = @(prev_injection, vbus1, vbus2) ...
            pe.Gseries*( (2*pe.L/step - pe.R)*prev_injection + vbus1 - vbus2 );
          pe.Gseries = 1 / ( R + 2*L/step );
        end
      end
    end % Constructor

    function update(pe,vbus1,vbus2)
      % Update injection with the series formula
      if pe.C ~= 0
        pe.old_injection = pe.injection; % Save old injection
        pe.injection = pe.injection_function(pe.injection,vbus1,vbus2); % Update injection
        pe.Vc = pe.update_vC(); % Calculate new capacitor voltage
      else
        pe.injection = pe.injection_function(pe.injection,vbus1,vbus2); % If no C, only update injection.
      end
    end % update

  end % methods

end

