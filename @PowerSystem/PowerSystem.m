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
%       One line for each element, if there are more than two elements in a line 
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

  properties(GetAccess = public, SetAccess = private) % Only PowerSystem can set these properties, but everyone can read them
    sysYmodif = []            %   sysYmodif: Matrix with admitances and nodes connections;
    sysInvYmodif = []         %   sysInvYmodif: Matrix with admitances and nodes connections;
    sysSwitches  = []         %   sysSwitches: Vector containing the system switches;
    sysCurrentSources = []    %   sysCurrentSources: Vector containing the system current sources;
    sysVoltageSources = []    %   sysVoltageSources: Vector containing the system voltage sources;
    sysPassiveElements = []   %   sysPassiveElements: Vector containing the passive elements;
    sysVariablesDescr = {}    %   sysVariablesDescr: Cell array containing the description for the output variables;
    sysStep = 10e-6;          %   sysStep: The time step;
    sysInjectionMatrix = []   %   sysInjectionMatrix: Vector containing all bus known (current and voltage) injections;
    sysVariablesMatrix = []   %   sysVariablesVector: Vector containing all bus variables (current and voltage) injections;
    sysNumberOfBuses = 0;     %   sysNumberOfBuses: Total number of buses in the system;
    timeVector                %   timeVector: vector containing all time steps
  end

  methods( Access = public )
    function ps = PowerSystem(readFile, step, timeLimit)
      if nargin == 3
        ps.sysStep = step;
        ps.timeVector=0:ps.sysStep:timeLimit;
        ps.readPowerSystem(readFile);
      else
        error('PowerSystemPkg:PowerSystem','PowerSystem must be initialized with a file.');
      end
    end % Constructor

    run(ps) % see @PowerSystem/run.m

  end % public methods

  methods( Access = private )
    readPowerSystem(ps,file) % see @PowerSystem/readPowerSystem.m
    function updateSwitch(ps,src)
      swichIdx = find( ps.sysSwitches == src );
      if src.isOpen
        tempLine = zeros(1,ps.sysNumberOfBuses);
        tempLine(switchIdx) = 1;
        ps.sysYmodif(switchIdx,:) = tempLine;
        ps.sysInvYmodif = inv(ps.sysYmodif);
      else
        tempLine = zeros(1,ps.sysNumberOfBuses);
        tempLine(src.busK) = 1;
        tempLine(src.busM) = -1;
        ps.sysYmodif(switchIdx,:) = tempLine;
        ps.sysInvYmodif = inv(ps.sysYmodif);
      end
    end % updateSwitch
  end % private methods

end


