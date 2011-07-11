classdef PowerSystem < handle 
%
%   PowerSystem is the main class from the PowerSystem Package. It is used to determine
% unknown voltages and currents for the Power System buses and may be used to study 
% transitories on the system, such as the system startup or status changes
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
% Use PowerSystem.run(timeLimit) to run the PowerSystem until timeLimit
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
    sysYmodif = []               %   sysYmodif: Matrix with admitances and nodes connections;
    sysInvYmodif = []            %   sysInvYmodif: Matrix with admitances and nodes connections;
    sysSwitches  = []            %   sysSwitches: Vector containing the system switches;
    sysCurrentSources = []       %   sysCurrentSources: Vector containing the system current sources;
    sysVoltageSources = []       %   sysVoltageSources: Vector containing the system voltage sources;
    sysPassiveElements = []      %   sysPassiveElements: Vector containing the passive elements;
    sysVariablesDescr = {}       %   sysVariablesDescr: Cell array containing the description for the output variables;
    sysStep = 100e-6;            %   sysStep: The time step;
    sysInjectionMatrix = []      %   sysInjectionMatrix: Vector containing all bus known (current and voltage) injections;
    sysVariablesMatrix = []      %   sysVariablesMatrix: Vector containing all bus variables (current and voltage) injections;
    sysNumberOfBuses = 0;        %   sysNumberOfBuses: Total number of buses in the system;
    timeVector                   %   timeVector: vector containing all time steps;
    topology = SysTopo.Monophasic%   topology: System topology, from SysTopo enumeration (Monophasic, Triphasic);
  end

  properties(GetAccess = public, SetAccess = private, SetObservable) % Only PowerSystem can set these properties, but everyone can read them. It is observable
    currentTime = 0;          %   currentTime: the power system current time;
  end

  methods( Access = public )
    function ps = PowerSystem(readFile, step)
      if nargin == 2
        ps.sysStep = step;
        % Read and fill the powerSystem:
        ps.readPowerSystem(readFile);
        % And then Initialize:
        ps.sysInjectionMatrix = zeros(size(ps.sysYmodif,2),1);
        ps.sysVariablesMatrix = zeros(size(ps.sysYmodif,2),1);
        ps.currentTime = 0;
        ps.timeVector = 0;
        % Fill injection for initial time
        for k=1:length(ps.sysCurrentSources)
          ps.sysCurrentSources(k).update;
          ps.sysInjectionMatrix(...
            ps.topology*(ps.sysCurrentSources(k).busK-1)+1:ps.topology*(ps.sysCurrentSources(k).busK-1)+ps.topology,...
            1 ...
          ) = ps.sysInjectionMatrix(...
            ps.topology*(ps.sysCurrentSources(k).busK-1)+1:ps.topology*(ps.sysCurrentSources(k).busK-1)+ps.topology,...
            1 ...
          ) + ps.sysCurrentSources(k).injection;
        end
        for k=1:length(ps.sysVoltageSources)
          ps.sysVoltageSources(k).update;
          ps.sysInjectionMatrix(...
            ps.topology*(ps.sysNumberOfBuses+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+(k-1))+ps.topology,...
            1 ...
          ) = ps.sysInjectionMatrix(...
            ps.topology*(ps.sysNumberOfBuses+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+(k-1))+ps.topology,...
            1 ...
          ) + ps.sysVoltageSources(k).injection;
        end
        % Determine variables for initial time:
        ps.sysInvYmodif=inv(ps.sysYmodif);
        ps.sysVariablesMatrix(:,1) = ps.sysInvYmodif * ps.sysInjectionMatrix(:,1);
      else
        error('PowerSystemPkg:PowerSystem','PowerSystem must be initialized with a file and its step: PowerSystem(readFile, step).');
      end
    end % Constructor

    run(ps, timeLimit) % see @PowerSystem/run.m

    function plot_bars(ps,bars)
      if nargin == 1
        bars = 1:ps.sysNumberOfBuses;
      end
      if ps.topology == SysTopo.Monophasic
        for k=bars
          figure
          plot(ps.timeVector,ps.sysInjectionMatrix(k,:));
          hold on;
          plot(ps.timeVector,ps.sysVariablesMatrix(k,:),'r');
          legend('Current', 'Voltage');
          title(sprintf('BUS %d',k),'FontSize',20)
          xlabel('Time (s)','FontSize',20);
          ylabel('Injections (V,A)','FontSize',20);
          set(gca,'FontSize',16);
          set(gcf,'Color','w');
          grid
        end
      elseif ps.topology == SysTopo.Triphasic
        for k=bars
          figure
          for phase=1:3
            subplot(3,1,phase), plot(ps.timeVector,ps.sysInjectionMatrix(3*(k-1)+phase,:));
            hold on;
            subplot(3,1,phase), plot(ps.timeVector,ps.sysVariablesMatrix(3*(k-1)+phase,:),'r');
            legend('Current', 'Voltage');
            title(sprintf('BUS %d, Phase %s',k,char(phase+64)),'FontSize',20)
            xlabel('Time (s)','FontSize',20);
            ylabel('Injections (V,A)','FontSize',20);
            set(gca,'FontSize',16);
            set(gcf,'Color','w');
            grid
          end
        end
      end
    end % plot_bars

    function plot_switches(ps,switches)
      if nargin == 1
        switches = (ps.sysNumberOfBuses+length(ps.sysVoltageSources)+1):(ps.sysNumberOfBuses+length(ps.sysVoltageSources)+length(ps.sysSwitches));
      else
        switches = switches + (ps.sysNumberOfBuses+length(ps.sysVoltageSources));
      end
      if ps.topology == SysTopo.Monophasic
        for k=switches
          figure
          hold on;
          plot(ps.timeVector,ps.sysVariablesMatrix(k,:));
          title(sprintf('SWITCH BUS %d to %d',...
              ps.sysSwitches(k-(ps.sysNumberOfBuses+length(ps.sysVoltageSources))).busK,...
              ps.sysSwitches(k-(ps.sysNumberOfBuses+length(ps.sysVoltageSources))).busM),'FontSize',20);
          xlabel('Time (s)','FontSize',20);
          ylabel('Current on Switch (A)','FontSize',20);
          set(gca,'FontSize',16);
          set(gcf,'Color','w');
          grid
        end
      elseif ps.topology == SysTopo.Triphasic
        for k=switches
          figure
          for phase=1:3
            subplot(3,1,phase), plot(ps.timeVector,ps.sysVariablesMatrix(3*(k-1)+phase,:));
            hold on;
            title(sprintf('SWITCH BUS %d to %d %s',...
                ps.sysSwitches(k-(ps.sysNumberOfBuses+length(ps.sysVoltageSources))).busK,...
                ps.sysSwitches(k-(ps.sysNumberOfBuses+length(ps.sysVoltageSources))).busM),...
                char(64+phase),'FontSize',20);
            xlabel('Time (s)','FontSize',20);
            ylabel('Current on Switch (A)','FontSize',20);
            set(gca,'FontSize',16);
            set(gcf,'Color','w');
            grid
          end
        end
      end
    end % plot_switches

    function plot_system(ps)
      ps.plot_bars
      ps.plot_switches
    end % plot_system

  end % public methods

  methods( Access = private )
    function updateSwitch(ps,src,~)
      swichIdx = find( ps.sysSwitches == src ) + (ps.sysNumberOfBuses+length(ps.sysVoltageSources));
      if src.isOpen
        tempLine = zeros(1,ps.sysNumberOfBuses+length(ps.sysVoltageSources)+length(ps.sysSwitches));
        tempLine(swichIdx) = 1;
        ps.sysYmodif(swichIdx,:) = tempLine;
        ps.sysYmodif(:,swichIdx) = tempLine';
        ps.sysInvYmodif = inv(ps.sysYmodif);
      else
        tempLine = zeros(1,ps.sysNumberOfBuses+length(ps.sysVoltageSources)+length(ps.sysSwitches));
        tempLine(src.busK) = 1;
        tempLine(src.busM) = -1;
        ps.sysYmodif(swichIdx,:) = tempLine;
        ps.sysYmodif(:,swichIdx) = tempLine';
        ps.sysInvYmodif = inv(ps.sysYmodif);
      end
    end % updateSwitch
    readPowerSystem(ps,file) % see @PowerSystem/readPowerSystem.m
  end % private methods

  methods( Access = private, Static )
  end % private and Static methods

end


