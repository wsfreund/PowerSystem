classdef PowerSystem < handle
%
% Beta version sub zero
%
%   PowerSystem class is the main class from the PowerSystem Package. It is used to determine
% in real time unknown voltages and currents for the Power System buses.
%   It can be used to study transitories on the system, such as the system startup or changes
% on switches.
%   It uses discrete time method to calculate the variables for a constant step defined by 
% user.
%
% PowerSystem (readFile,step)
%
%   readFile: ASCII format file used to build the Power System. 
%
%       One line for each element, if there are more than two elements in a line, 
%       will cause either the second element or the whole line to be ignored. 
%
%       Words should always be separated by space and on CAPITAL LETTERS.
%
%       - Series passive element: The first two words should be the connection
%       between BUSES, followed by: resistence, inductance and capacitance.
%       
%       - Source Connection: First word is the source connection, second word
%       source type (CURRENT/VOLTAGE), and on the third word its magnetude.
%
%       - Switch Connection: First and second words are the switch BUSES
%       connection, and the third word must be SWITCH. A fourth word can be used
%       to inform the switch initial status (OPEN/CLOSED), if not informed it is OPEN by 
%       default.
%
%       - TODO: Transmission line
%
%     example:
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
% TODO: Update class help

  properties(GetAccess = public, SetAccess = private) % Only PowerSystem can set these properties, but everyone can read them
    sysYmodif             %   sysYmodif: Matrix with admitances and nodes connections
    sysSwitches           %   sysSwitches: Vector containing the system switches
    sysSources            %   sysSources: Vector containing the system current/voltage sources
    sysPassiveElements    %   sysPassiveElements: Vector containing the passive elements
    sysVariablesDescr     %   variablesDescr: Cell array containing the description for the output variables
    sysStep = 1e-4;       %   sysStep: The time step
  end

  events
    %Update                %   Update: PowerSystem is updating the sources injection values and switches status, if any switch has changed position
    %Run                   %   Run: PowerSystem is determing the output variables
    %Wait                  %   Wait: PowerSystem is waiting for next time step
    %Hold                  %   Hold: PowerSystem is on hold
    IncreasedTimeStep     %   IncreasedTimeStep: PowerSystem was forced to increase time step value, becouse the processor wasnt able to run with specified time
    % TODO Maybe this event should be set as a postSet from time step, and sysStep should be observable
  end

  methods( Access = public )
    function ps = PowerSystem(readFile, step)
      if nargin > 0
        % TODO GUI?
        ps.readPowerSystem(readFile)
        ps.step = step;
        for i=1:length(switches)
          lisSwitches(i) = addlistener(sysSwitches(i),'NewPosition',@ps.updateSwitch) % listen to all switches
        end
      else
        error('PowerSystemPkg:PowerSystem','PowerSystem must be initialized with a file.');
      end
      %ps.update % Only to test ( TODO: Add run and hold functions )
    end % Constructor
  end % public methods

  methods( Access = private )
    function readPowerSystem(ps,file)
    function addSource(ps,source)
    function addPassiveElement(ps,pe)
    function update(ps)
      for k=1:length(ps.sysSources)
        ps.sysSources(k).update()
      end
      for k=1:length(ps.sysPassiveElements)
        ps.sysPassiveElements(k).update()
      end
      % TODO: Update the b vector
      ps.Run;
    end % function update
    function updateSwitch()
      % TODO Did any switch change its status? Update here...
    end
    function run(ps)
      % Ax = b;
      ps.update;
    end % function run
  end % private methods
end


