classdef Switch < handle
% TODO: Switch Help
  properties(GetAccess = public, SetAccess = private) % Only Switch can set these properties, but everyone can read them
    bus1 = uint32(0);   % bus1 = System Bus 1
    bus2 = uint32(0);   % bus2 = System Bus 2
  end

  properties(Access = private) % Only Switch can set and read these properties
    status = SwitchStatus.Open;
  end

  methods
    function bool = isOpen(sw)
      bool = (SwitchStatus.Open == sw.status);
    end % function isOpen

    function bool = isClosed(sw)
      bool = (Switch.Closed == sw.status);
    end % function isClosed

    function changePosition(sw)
      if (sw.status == SwitchStatus.Open)
        sw.status = Switchstatus.Closed;
      else
        sw.status = Switchstatus.Open;
      end
      notify(sw,'NewPosition');
    end % function changePosition

    function changePosition(sw,position)
      if(isa(position,'SwitchStatus')
        if (sw.status ~= position)
          sw.status = position;
          notify(sw,'NewPosition');
        end
      else
        error('PowerSystemPkg:Switch','Position must be a SwitchStatus object (SwitchStatus.Open/Closed).');
      end
    end % function changePosition
  end % methods

  events
    NewPosition
  end

end

