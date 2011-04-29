classdef Switch < handle
%
%   Switch class is implemented for the PowerSystem Package and it's 
%     used for all switches on the circuit.
%
%   Its constructor is defined as following:
%
%   Switch(busK, busM, status)
%    busK: defines first bus connection from the switch
%    busM: defines second bus connection from the switch
%    status: defines switch initial status. It must be a SwitchStatus object: SwitchStatus.Open/Closed (default Open)
%

  properties(GetAccess = public, SetAccess = private) % Only Switch can set these properties, but everyone can read them
    busK = 0;                     % bus1: System first Switch connection
    busM = 0;                     % bus2: System second Switch connection
    status = SwitchStatus.Open;   % status: The switch status
  end

  events
    NewPosition
  end

  methods
    function sw = Switch(busK, busM, status)
      if nargin > 0
        if nargin == 2
          status = SwitchStatus.Open
        end
        sw.busK = busK;
        sw.busM = busM;
        if isa(sw.status,'SwitchStatus')
          sw.status = status;
        else
          error('PowerSystemPkg:Switch', 'status must be a SwitchStatus object: SwitchStatus.Open/Closed');
        end
      end
    end % Constructor

    function bool = isOpen(sw)
%    function bool = isOpen(sw)
%
%   This function returns true if the switch is open and false otherwise.
%
      bool = (SwitchStatus.Open == sw.status);
    end % function isOpen

    function bool = isClosed(sw)
%    function bool = isClosed(sw)
%
%   This function returns true if the switch is closed and false otherwise.
%
      bool = (SwitchStatus.Closed == sw.status);
    end % function isClosed

    function changePosition(sw,position)
%    function changePosition(sw,position)
%
%   This function changes the switch position into input position. 
%
%    function changePosition(sw)
%   Another way to use the changePosition function is not to specify the position. By using this way you just force the switch to changes it position.
%
      if nargin == 1
        if (sw.status == SwitchStatus.Open)
          sw.status = SwitchStatus.Closed;
        else
          sw.status = SwitchStatus.Open;
        end
        notify(sw,'NewPosition');
      elseif nargin == 2
        if(isa(position,'SwitchStatus'))
          if (sw.status ~= position)
            sw.status = position;
            notify(sw,'NewPosition');
          end
        else
          error('PowerSystemPkg:Switch','Position must be a SwitchStatus object (SwitchStatus.Open/Closed).');
        end
      end
    end % function changePosition

  end % methods

end

