classdef PowerSystem < handle
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
%       source type (CURRENT/VOLTAGE), the third word its magnetude, and, finally
%       forth word is the signalType (STEP/SINOIDAL), default: sinoidal.
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
%     BUS1 CURRENT 1 STEP
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
    sysYmodif = []            %   sysYmodif: Matrix with admitances and nodes connections
    sysSwitches  = []         %   sysSwitches: Vector containing the system switches
    sysCurrentSources = []    %   sysCurrentSources: Vector containing the system current sources
    sysVoltageSources = []    %   sysVoltageSources: Vector containing the system voltage sources
    sysPassiveElements = []   %   sysPassiveElements: Vector containing the passive elements
    sysVariablesDescr = {}    %   sysVariablesDescr: Cell array containing the description for the output variables
    sysStep = 1e-4;           %   sysStep: The time step
  end

  methods( Access = public )
    function ps = PowerSystem(readFile, step, timeLimit)
      if nargin > 0
        ps.sysStep = step;
        ps.readPowerSystem(readFile);
        % TODO: Set b vector as annonymous function dependent on sources injections
      else
        error('PowerSystemPkg:PowerSystem','PowerSystem must be initialized with a file.');
      end
    end % Constructor
  end % public methods

  methods( Access = private )
    readPowerSystem(ps,file)
    function updateSwitch( src )
      % TODO Did any switch change its status? Update here...
    end
    function run(ps)
      %while(0:sysStep:timeLimit)
      % TODO: inv (sysYmodif)
      % Ax = b;
      % TODO: Update Sources
      %end
    end % function run
  end % private methods

end


