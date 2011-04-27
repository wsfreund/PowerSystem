function readPowerSystem(ps, file)

  psFile = fopen(file,'r');

  tLine = fgetl(psFile);
  lineC = 1;
  while (ischar(tLine))
    % Initialize BUS connections
    firstBUS = -1;
    secondBUS = -1;
    % Here tWords is an cell array containing two strings and 3 doubles. See textscan help.
    [tWords] = textscan(tLine,'%s %s %f64 %f64 %f64');
    % Search for first BUS info
    if isempty(tWords{2}) || isempty(tWords{1})
      display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    if strfind(tWords{1}{1},'BUS')
      firstBUS = strread(tWords{1}{1},'BUS %d');
    elseif strfind(tWords{1}{1},'GROUND')
      firstBUS = strread(tWords{2}{1},'BUS %d');
      secondBUS = firstBUS;
    end
    % Search for second BUS info
    if strfind(tWords{2}{1},'BUS')
      secondBUS = strread(tWords{2}{1},'BUS %d');
    % is second word GROUND? 
    elseif strfind(tWords{2}{1},'GROUND')
      secondBUS = 0; % ...than set it to zero
    % Checking for Sources:
    elseif strcmp(tWords{2}{1},'CURRENT') % Current Sources
      tCurrent = tWords{3};
      if (isempty(tCurrent))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      lastWord = textscan(tLine,'%*s %*s %*f64 %s');
      if isempty(lastWord{1}) || strcmp(lastWord{1}{1},'STEP')
        tCurrentSource = Source(firstBUS, SourceTypes.Current,'step',tCurrent);
        ps.sysCurrentSources = [ps.sysCurrentSources; tCurrentSource];
      elseif strcmp(lastWord{1}{1},'SINOIDAL') 
        tCurrentSource = Source(firstBUS, SourceTypes.Current,'sinoidal',tCurrent);
        ps.sysCurrentSources = [ps.sysCurrentSources; tCurrentSource];
      else
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    elseif strcmp(tWords{2}{1},'VOLTAGE') % Voltage Sources
      tVoltage = tWords{3};
      if (isempty(tVoltage))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      lastWord = textscan(tLine,'%*s %*s %*f64 %s');
      if isempty(lastWord{1}) || strcmp(lastWord{1}{1},'STEP')
        tVoltageSource = Source(firstBUS, SourceTypes.Voltage,'step',tVoltage);
        ps.sysVoltageSources = [ps.sysVoltageSources; tVoltageSource];
      elseif strcmp(lastWord{1}{1},'SINOIDAL')
        tVoltageSource = Source(firstBUS,SourceTypes.Voltage,'sinoidal',tVoltage);
        ps.sysVoltageSources = [ps.sysVoltageSources; tVoltageSource];
      else
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    % I want the second BUS index always lesser than firstBUS (is this necessary?)
    if (firstBUS > secondBUS)
      temp = firstBUS;
      firstBUS = secondBUS;
      secondBUS = temp;
    end
    if ( ( firstBUS<0 || secondBUS<0 ) ) % Did someone write on the file any negative index? 
      display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    % Resistence is supposed to be the third word
    tResistence = tWords{3};
    if (isempty(tResistence)) % Third word is not a double! Let's try reading it as a string.
      tWords = textscan(tLine,'%*s %*s %s %s'); % read third and fourth word as strings, ignoring first and second words.
      if strcmp(tWords{1}{1},'SWITCH') % is third word SWITCH?
        if (firstBUS == 0) % it shouldnt be a switch to the ground... as far as I know.
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        end
        if ~isempty(tWords{2}) && strfind(tWords{2}{1},'CLOSE')
          tSwitch = Switch(firstBUS,secondBUS,SwitchStatus.Closed);
          ps.sysSwitches = [ps.sysSwitches; tSwitch];
          addlistener(tSwitch,'NewPosition',@ps.updateSwitch);
        else 
          tSwitch = Switch(firstBUS,secondBUS,SwitchStatus.Open);
          ps.sysSwitches = [ps.sysSwitches; tSwitch];
          addlistener(tSwitch,'NewPosition',@ps.updateSwitch);
        end
      else % can't read this line
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    % If we got this far, then we can fill the Y matrix...
    tInductance = 0.;
    tCapacitance = 0.;
    % Inductance is supposed to be the forth word
    if (~isempty(tWords{4}))
      tInductance = tWords{4}/(2*pi*60); % Inputs should be on frequency domain
    end
    % Capacitance is supposed to be the fifth word
    if (~isempty(tWords{5}))
      tCapacitance = 1/(2*pi*60*tWords{5});% Inputs should be on frequency domain
    end
    if (firstBUS == 0) % Shunt element
      if (tInductance ~= 0 || tCapacitance ~= 0)
        tPassiveElement = PassiveElement(ps.sysStep,firstBUS,secondBUS,tResistence,tInductance,tCapacitance);
        ps.sysYmodif(secondBUS,secondBUS) = ps.sysYmodif(secondBUS,secondBUS) + tPassiveElement.Gseries;
        ps.sysPassiveElements = [ps.sysPassiveElements; tPassiveElement];
      else
        ps.sysYmodif(secondBUS,secondBUS) = ps.sysYmodif(secondBUS,secondBUS) + 1/tResistence;
      end
    else % firstBUS to secondBUS connection
      if (tInductance ~= 0 || tCapacitance ~= 0)
        tPassiveElement = PassiveElement(ps.sysStep,firstBUS,secondBUS,tResistence,tInductance,tCapacitance);
        ps.sysYmodif(firstBUS,secondBUS) = -tPassiveElement.Gseries;
        ps.sysYmodif(secondBUS,firstBUS) = -tPassiveElement.Gseries;
        ps.sysYmodif(firstBUS,firstBUS) = ps.sysYmodif(firstBUS,firstBUS) + tPassiveElement.Gseries;
        ps.sysYmodif(secondBUS,secondBUS) = ps.sysYmodif(secondBUS,secondBUS) + tPassiveElement.Gseries;
        ps.sysPassiveElements = [ps.sysPassiveElements; tPassiveElement];
      else
        ps.sysYmodif(firstBUS,secondBUS) = -1/tResistence;
        ps.sysYmodif(secondBUS,firstBUS) = -1/tResistence;
        ps.sysYmodif(firstBUS,firstBUS) = ps.sysYmodif(firstBUS,firstBUS) + 1/tResistence;
        ps.sysYmodif(secondBUS,secondBUS) = ps.sysYmodif(secondBUS,secondBUS) + 1/tResistence;
      end
    end
    tLine = fgetl(psFile);
    lineC = lineC + 1;
  end

  ps.sysNumberOfBuses = size(ps.sysYmodif,1);

  for k=1:ps.sysNumberOfBuses
      ps.sysVariablesDescr(k) = {sprintf('VOLTAGE ON %d',k)};
  end

  % Sort Voltage Sources
  for k=1:(length(ps.sysVoltageSources))
    for m=k:length(ps.sysVoltageSources)
      if (ps.sysVoltageSources(k).busK > ps.sysVoltageSources(m).busK )
        tempSource = ps.sysVoltageSources(k);
        ps.sysVoltageSources(k) = ps.sysVoltageSources(m);
        ps.sysVoltageSources(m) = tempSource;
      end
    end
  end

  % Sort Current Sources
  for k=1:(length(ps.sysCurrentSources))
    for m=k:length(ps.sysCurrentSources)
      if (ps.sysCurrentSources(k).busK > ps.sysCurrentSources(m).busK )
        tempSource = ps.sysCurrentSources(k);
        ps.sysCurrentSources(k) = ps.sysCurrentSources(m);
        ps.sysCurrentSources(m) = tempSource;
      end
    end
  end

  % Sort Switches 
  for k=1:(length(ps.sysSwitches))
    for m=k:length(ps.sysSwitches)
      if (ps.sysSwitches(k).busK > ps.sysSwitches(m).busK )
        tempSwitch = ps.sysSwitches{k};
        ps.sysSwitches(k) = ps.sysSwitches(m);
        ps.sysSwitches(m) = tempSwitch;
      end
    end
  end
  for k=1:(length(ps.sysSwitches))
    for m=k:length(ps.sysSwitches)
      if ( (ps.sysSwitches(k).busK == ps.sysSwitches(m).busK) && ( ps.sysSwitches(k).busM > ps.sysSwitches(m).busM ) )
        tempSwitch = ps.sysSwitches(k);
        ps.sysSwitches(k) = ps.sysSwitches(m);
        ps.sysSwitches(m) = tempSwitch;
      else
        continue;
      end
    end
  end

  svSize = length(ps.sysVoltageSources);
  sswitchSize = length(ps.sysSwitches);

  % Expand matrix
  ps.sysYmodif(end+svSize+sswitchSize,end+svSize+sswitchSize)=0; 

  % Fill sV
  for k=1:length(ps.sysVoltageSources)
    ps.sysYmodif(ps.sysNumberOfBuses+k,ps.sysNumberOfBuses+k-1) = 1;
    ps.sysYmodif(ps.sysNumberOfBuses+k-1,ps.sysNumberOfBuses+k) = 1;
    ps.sysVariablesDescr(ps.sysNumberOfBuses+k) = {sprintf('CURRENT ON %d',ps.sysVoltageSources.busK)};
  end

  % Fill sSwitch
  for k=1:length(ps.sysSwitches)
    if ( ps.sysSwitches(k).status == SwitchStatus.Closed)
      ps.sysYmodif(ps.sysNumberOfBuses+svSize+k,ps.sysNumberOfBuses+svSize+k) = 1;
    else
      ps.sysYmodif(ps.sysNumberOfBuses+svSize+k,ps.sysSwitches(k).busK) = 1;
      ps.sysYmodif(ps.sysNumberOfBuses+svSize+k,ps.sysSwitches(k).busM) = 1;
      ps.sysYmodif(ps.sysSwitches(k).busK,ps.sysNumberOfBuses+svSize+k) = 1;
      ps.sysYmodif(ps.sysSwitches(k).busM,ps.sysNumberOfBuses+svSize+k) = 1;
    end
    ps.sysVariablesDescr(ps.sysNumberOfBuses+svSize+k) = {sprintf('CURRENT ON SWITCH %d-%d',ps.sysSwitches(k).busK,ps.sysSwitches(k).busM)};
  end

  % Initialize:
  ps.sysInjectionMatrix = zeros(size(ps.sysYmodif,2),length(ps.timeVector));
  ps.sysVariablesMatrix = zeros(size(ps.sysYmodif,2),length(ps.timeVector));
  time_idx = 1;
  thisTime = ps.timeVector(time_idx);
  % Fill injection for initial time
  for k=1:length(ps.sysCurrentSources)
    ps.sysCurrentSources(k).update(thisTime);
    ps.sysInjectionMatrix(ps.sysCurrentSources(k).busK,time_idx) = ... 
      ps.sysInjectionMatrix(ps.sysCurrentSources(k).busK,time_idx) + ps.sysCurrentSources(k).injection;
  end
  for k=1:length(ps.sysVoltageSources)
    ps.sysVoltageSources(k).update(thisTime);
    ps.sysInjectionMatrix(ps.sysNumberOfBuses+k,time_idx) = ...
      ps.sysInjectionMatrix(ps.sysNumberOfBuses+k,time_idx) + ps.sysVoltageSources(k).injection;
  end
  % TODO Review this!  Add passive element current injections:
  for k=1:length(ps.sysPassiveElements)
    if ps.sysPassiveElements(k).busK % not connected to the ground?
      ps.sysInjectionMatrix(ps.sysPassiveElements(k).busK,time_idx) = ...
        ps.sysInjectionMatrix(ps.sysPassiveElements(k).busK,time_idx) - ps.sysPassiveElements(k).injection; % flow from k to m
      ps.sysInjectionMatrix(ps.sysPassiveElements(k).busM,time_idx) = ...
        ps.sysInjectionMatrix(ps.sysPassiveElements(k).busM,time_idx) + ps.sysPassiveElements(k).injection; % flow from k to m
    else
      ps.sysInjectionMatrix(ps.sysPassiveElements(k).busM,time_idx) = ...
        ps.sysInjectionMatrix(ps.sysPassiveElements(k).busM,time_idx) + ps.sysPassiveElements(k).injection; % flow from k to m
    end
  end
  % Determine variables for initial time:
  ps.sysInvYmodif=inv(ps.sysYmodif);
  ps.sysVariablesMatrix(:,time_idx) = ps.sysInvYmodif * ps.sysInjectionMatrix(:,time_idx);

  fclose(psFile);

end
