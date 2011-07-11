classdef Switch < handle & dynamicprops
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

  properties(Access = private)
    timedChanges                  % timedChanges: Switch changing Times
  end

  properties(Access = private) % Only Source and it childs can set and see these properties
    ps;                           % PowerSystem pointer
  end

  events
    NewPosition
  end

  methods
    function sw = Switch(ps, busK, busM, status)
      if nargin > 0
        sw.ps = ps;
        if nargin == 3
          status = repmat(SwitchStatus.Open,sw.ps.topology,1);
        end
        sw.busK = busK;
        sw.busM = busM;
        if isa(sw.status,'SwitchStatus')
          if ( size(status,1) == 1)
            sw.status = repmat(status,sw.ps.topology,1);
          else
            sw.status = status;
          end
        else
          error('PowerSystemPkg:Switch', 'status must be a SwitchStatus object: SwitchStatus.Open/Closed');
        end
      end
    end % Constructor

    function bool = isOpen(sw,phase)
%    function bool = isOpen(sw,phase)
%
%   This function returns true if the switch is open and false otherwise.
%
      if nargin == 1
        phase = 1:sw.ps.topology;
      end
      bool = (SwitchStatus.Open == sw.status(phase));
    end % function isOpen

    function bool = isClosed(sw,phase)
%    function bool = isClosed(sw,phase)
%
%   This function returns true if the switch is closed and false otherwise.
%
      if nargin == 1
        phase = 1:sw.ps.topology;
      end
      bool = (SwitchStatus.Closed == sw.status(phase));
    end % function isClosed

    function changePosition(sw,position,phase)
%    function changePosition(sw,position,phase)
%
%   This function changes the switch position into input position. 
%
%    function changePosition(sw)
%   Another way to use the changePosition function is not to specify the position. By using this way you just force the switch to changes it position.
%
      if nargin == 1
        if nargin == 2
          phase = 1:sw.ps.topology;
        end
        if (sw.status(phase) == SwitchStatus.Open)
          sw.status(phase) = SwitchStatus.Closed;
        else
          sw.status(phase) = SwitchStatus.Open;
        end
        notify(sw,'NewPosition');
      elseif nargin == 2
        if(isa(position,'SwitchStatus'))
          if (sw.status(phase) ~= position)
            sw.status(phase) = position;
            notify(sw,'NewPosition');
          end
        else
          error('PowerSystemPkg:Switch','Position must be a SwitchStatus object (SwitchStatus.Open/Closed).');
        end
      end
    end % function changePosition

    function addTimedChange(sw, time)
      if sw.ps.currentTime < time % We will change the time only if it hasnt passed
        sw.timedChanges = [time, sw.timedChanges];
        [sw.timedChanges, idx] = sort(sw.timedChanges);
        if (isempty(sw.findprop('timeListener'))) % We need to add a listener to the PowerSystem time
          sw.addprop('timeListener'); % add a property so that we can reach the listener and delete it when it is not necessary anymore
          sw.timeListener = addlistener(sw.ps,'currentTime','PostSet',@sw.changeOnTime);
        end
      else
        display(sprintf('ATTEMPTED TO SET A SWITCH CHANGE ON SYSTEM PAST TIME %f, POWER SYSTEM CURRENT TIME IS %f', time, ps.currentTime));
      end
    end % addTimedChange
  end % methods

  methods (Access = private)
    function changeOnTime(sw, src, evt)
      if ( sw.timedChanges(1) <= sw.ps.currentTime)
        sw.changePosition
        if (length(sw.timedChanges)>1) % Is there more timed changes?
          sw.timedChanges = sw.timedChanges(2:end); % Update them
        else % otherwise
          sw.timedChanges = []; % clear timedChanges
          delete(sw.timeListener); % delete listener
          delete(sw.findprop('timeListener')); % delete listener property
        end
      end
    end
  end % private methods


end

