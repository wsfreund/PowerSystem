classdef PowerSystem < handle
% TODO: Update class help
%
% Inputs:
%   file: ASCII format file to take params, example:
%     BUS1 BUS6 6e-3
%     BUS1 CURRENT 1
%     BUS1 BUS2 52e-3
%     BUS1 GROUND 0.8e-3
%     BUS2 BUS4 6e-3
%     BUS2 BUS5 0.5
%     BUS2 CURRENT 1.5
%     BUS2 GROUND 0.8e-6
%     BUS3 BUS5 SWITCH CLOSED
%     BUS3 BUS4 SWITCH 
%     BUS3 GROUND 22.61
%     BUS6 VOLTAGE 1.05
%     (Default value for switches = open)
%   

  properties(GetAccess = public, SetAccess = private) % Only PowerSystem can set these properties, but everyone can read them
    sysYmodif             %   sysYmodif: Matrix with admitances and nodes connections
    sysSwitches           %   sysSwitches: Vector containing the system switches
    sysSources            %   sysSources: Vector containing the system current/voltage sources
    sysPassiveElements    %   sysPassiveElements: Vector containing the passive elements
    sysVariablesDescr     %   variablesDescr: Cell array containing the description for the output variables
    sysStep = 1e-4;       %   sysStep: The time step
  end

  properties

  events
    Update                %   Update: PowerSystem is updating the sources injection values and switches status, if any switch has changed position
    Run                   %   Run: PowerSystem is determing the output variables
    Wait                  %   Wait: PowerSystem is waiting for next time step
    Hold                  %   Hold: PowerSystem is on hold
    IncreasedTimeStep     %   IncreasedTimeStep: PowerSystem was forced to increase time step value, becouse the processor wasnt able to run with specified time
    % TODO Maybe this event should be set as a postSet from time step, and sysStep should be observable
  end

  methods( Access = public )
    function ps = PowerSystem(readFile)
      notify(ps,'Initializing');
      if nargin > 0
        % TODO GUI?
        ps.readPowerSystem(readFile)
        end
        addlistener(ps,'Update',@ps.update)
        addlistener(ps,'Run',@ps.run)
        addlistener(ps,'Wait',@ps.wait)
        for i=1:length(switches)
          lisSwitches(i) = addlistener(sysSwitches(i),'NewPosition',@ps.updateSwitch) % listen to all switches
        end
        lisSwitchers = addlistener
        notify(ps,'UpdateSources'); %Start running
      end
    end
  end % public methods

  methods( Access = private )
    function readPowerSystem(ps,file)
    function addSource(ps,source)
    function addPassiveElement(ps,pe)
  end % private methods

  methods( static )
    function update(src)
      for 1:length(src.sysPassiveElements)
        src.sysPassiveElement.update()
      end
      notify(ps,'Run');
    end % function update
  
    function updateSwitch()
      % TODO Discover switch bar and update to new status
    end

    function run(src)
      % Ax = b;
      notify(ps,'Wait');
    end % function run

    function wait(src)
      if ( src.timer > step)
        step = src.timer * 1.2;
        notify(ps,'IncreasedStep')
      end
      while( src.timer < step )
        % TODO: Probabily there is a better way than doing this!
        % Do nothing, just wait until timer says it's time to run again
      end
      notify(ps,'UpdateSources');
    end % wait
  end % static methods
end


