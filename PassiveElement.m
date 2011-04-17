classdef PassiveElement < handle & Source
% TODO: Passive Element Help
  properties(GetAccess = public, SetAccess = private) % Only I can set these properties, but everyone can read them
    bus1 = uint32(0);
    bus2 = uint32(0);
    Gseries
    R
    L
    C
  end

  methods
    function pe = PassiveElement(ps,bus1,bus2,R,L,C,initialInjection)
      pe@Source(initialInjection, 'special' )
      % Check if bus1 == bus2
      if nargin > 3
        pe.bus1 = bus1;
        pe.bus2 = bus2;
        % etc
        if nargin == 6
          Gseries = 1 / (R + 2*L/ps.step + ps.step/(2*C));
          pe.injection = initialInjection;
          pe.R = R;
          pe.L = L;
          pe.C = C; 
        elseif nargin == 5
          Gseries = 1 / ( R + 2*L/ps.step );
          pe.injection = 0.;
          pe.R = R;
          pe.L = L;
        elseif nargin == 4
          error('PowerSystemPkg:PassiveElement', 'Created')
        elseif nargin == 0
      end
    end % Constructor
  end % methods

  function update(pe)
    % Update injection with the series formula
    pe.injection = Gseries*() pe.injection *...
  end % update
end

