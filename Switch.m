classdef Switch < handle
% TODO: Switch Help
  properties(GetAccess = public, SetAccess = private) % Only Switch can set these properties, but everyone can read them
    bus1 = uint32(0);   % bus1 = System Bus 1
    bus2 = uint32(0);   % bus2 = System Bus 2
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
  end
end

