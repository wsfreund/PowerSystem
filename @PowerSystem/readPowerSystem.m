function readPowerSystem(ps, file)

  psFile = fopen(file,'r');
  tLine = fgetl(psFile);
  lineC = 1;
  while(ischar(tLine))
    % Ignore comments:
    commentIdx = find(tLine=='%');
    if ~isempty(commentIdx)
      tLine = tLine(1:commentIdx-1);
    end
    % Find empty lines and ignore them
    if isempty(find(~(tLine==' ')))
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    [tWords] = textscan(tLine,'%s');
    if (strcmp(tWords{1}{1},'MONOPHASIC'))
      ps.topology = SysTopo.Monophasic;
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      break;
    elseif (strcmp(tWords{1}{1},'TRIPHASIC'))
      ps.topology = SysTopo.Triphasic;
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      break;
    else
      disp('No System Topology entered on the begining of file, assuming it is Triphasic');
      ps.topology = SysTopo.Triphasic;
      break;
    end
    tLine = fgetl(psFile);
    lineC = lineC + 1;  
  end

  while (ischar(tLine))
    % Initialize BUS connections
    firstBUS = -1;
    secondBUS = -1;
    % Ignore comments:
    commentIdx = find(tLine=='%');
    if ~isempty(commentIdx)
      tLine = tLine(1:commentIdx-1);
    end
    % Find empty lines and ignore them
    if isempty(find(~(tLine==' ')))
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    % Here tWords is an cell array containing two strings and 3 doubles. See textscan help.
    [tWords] = textscan(tLine,'%s %s %f64 %f64 %f64');
    if isempty(tWords{2}) || isempty(tWords{1})
      display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
      disp(tLine)
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    % Search for first word info
    if strfind(tWords{1}{1},'BUS') % BUS
      firstBUS = strread(tWords{1}{1},'BUS %d');
    elseif strcmp(tWords{1}{1},'GROUND') % GROUND
      firstBUS = strread(tWords{2}{1},'BUS %d');
      secondBUS = firstBUS;
    elseif strcmp(tWords{1}{1},'TIMED_EVENT') % TIMED_EVENT
      [tWords] = textscan(tLine,'%*s %f64 %s');
      tEventTime = tWords{1};
      if strcmp(tWords{2}{1},'SWITCH') % Switch change
        [tWords] = textscan(tLine,'%*s %*f64 %*s %s %s');
        if strfind(tWords{1}{1},'BUS') % BUS 1 to
          firstBUS = strread(tWords{1}{1},'BUS %d');
        else
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
          disp(tLine)
          tLine = fgetl(psFile);
          lineC = lineC + 1;
          continue;
        end
        if strfind(tWords{2}{1},'BUS') % BUS 2
          secondBUS = strread(tWords{2}{1},'BUS %d');
        else
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
          disp(tLine)
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
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
          disp(tLine)
          tLine = fgetl(psFile);
          lineC = lineC + 1;
          continue;
        end
        switchIdx = find( [ps.sysSwitches.busK] == firstBUS);
        if ~isempty(switchIdx)
          switchIdx = find( [ps.sysSwitches(switchIdx).busM] == secondBUS);
        end
        if ~isempty(switchIdx)
          ps.sysSwitches(switchIdx).addTimedChange(tEventTime);
          tLine = fgetl(psFile);
          lineC = lineC + 1;
          continue;
        else
          display(sprintf('COULD NOT FIND SWITCH FROM TIMED_EVENT ON LINE NUMBER %d:', lineC ));
          disp(tLine)
          tLine = fgetl(psFile);
          lineC = lineC + 1;
          continue;
        end
      end
    end
    % Search for second word info
    if strfind(tWords{2}{1},'BUS') % BUS
      secondBUS = strread(tWords{2}{1},'BUS %d');
    % is second word GROUND? 
    elseif strfind(tWords{2}{1},'GROUND') % Ground
      secondBUS = 0; % ...than set it to zero
    % Checking for Sources:
    elseif strcmp(tWords{2}{1},'CURRENT') % Current Sources
      lastWord = textscan(tLine,'%*s %*s %s %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64');
      tCurrent = [lastWord{2}; lastWord{5}; lastWord{8}];
      if (isempty(tCurrent))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
        disp(tLine)
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      tPhase = [lastWord{3}; lastWord{6}; lastWord{9}]*pi/180;
      tFreq = [lastWord{4}; lastWord{7}; lastWord{10}];
      if isempty(lastWord{1}) || strcmp(lastWord{1}{1},'STEP')
        tCurrentSource = RampSource(ps,firstBUS, SourceTypes.Current,'step',tCurrent);
        ps.sysCurrentSources = [ps.sysCurrentSources; tCurrentSource];
      elseif strcmp(lastWord{1}{1},'SINOIDAL') 
        if(~isempty(tPhase))
          tCurrentSource = RampSource(ps,firstBUS, SourceTypes.Current,'sinoidal',tCurrent,tPhase);
          ps.sysCurrentSources = [ps.sysCurrentSources; tCurrentSource];
        elseif(~isempty(tFreq))
          tCurrentSource = RampSource(ps,firstBUS, SourceTypes.Current,'sinoidal',tCurrent,tPhase,tFreq);
          ps.sysCurrentSources = [ps.sysCurrentSources; tCurrentSource];
        else
          tCurrentSource = RampSource(ps,firstBUS, SourceTypes.Current,'sinoidal',tCurrent);
          ps.sysCurrentSources = [ps.sysCurrentSources; tCurrentSource];
        end
      else
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
        disp(tLine)
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    elseif strcmp(tWords{2}{1},'VOLTAGE') % Voltage Sources
      lastWord = textscan(tLine,'%*s %*s %s %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64 %f64');
      tVoltage = [lastWord{2}; lastWord{5}; lastWord{8}];
      if (isempty(tVoltage))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
        disp(tLine)
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      tPhase = [lastWord{3}; lastWord{6}; lastWord{9}]*pi/180;
      tFreq = [lastWord{4}; lastWord{7}; lastWord{10}];
      if isempty(lastWord{1}) || strcmp(lastWord{1}{1},'STEP')
        tVoltageSource = RampSource(ps,firstBUS, SourceTypes.Voltage,'step',tVoltage);
        ps.sysVoltageSources = [ps.sysVoltageSources; tVoltageSource];
      elseif strcmp(lastWord{1}{1},'SINOIDAL')
        if(~isempty(tPhase))
          tVoltageSource = RampSource(ps,firstBUS, SourceTypes.Voltage,'sinoidal',tVoltage,tPhase);
          ps.sysVoltageSources = [ps.sysVoltageSources; tVoltageSource];
        elseif(~isempty(tFreq))
          tVoltageSource = RampSource(ps,firstBUS, SourceTypes.Voltage,'sinoidal',tVoltage,tPhase,tFreq);
          ps.sysVoltageSources = [ps.sysVoltageSources; tVoltageSource];
        else
          tVoltageSource = RampSource(ps,firstBUS, SourceTypes.Voltage,'sinoidal',tVoltage);
          ps.sysVoltageSources = [ps.sysVoltageSources; tVoltageSource];
        end
      else
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
        disp(tLine)
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    % I want the second BUS index always lesser than firstBUS
    if (firstBUS > secondBUS)
      temp = firstBUS;
      firstBUS = secondBUS;
      secondBUS = temp;
    end
    if ( ( firstBUS<0 || secondBUS<0 ) ) % Did someone write on the file any negative index? 
      display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
      disp(tLine)
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
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
          disp(tLine)
        end
        if ~isempty(tWords{2}) && ~isempty(strfind(tWords{2}{1},'CLOSE'))
          tSwitch = Switch(ps,firstBUS,secondBUS,SwitchStatus.Closed);
          ps.sysSwitches = [ps.sysSwitches; tSwitch];
          addlistener(tSwitch,'NewPosition',@ps.updateSwitch);
        else 
          tSwitch = Switch(ps,firstBUS,secondBUS,SwitchStatus.Open);
          ps.sysSwitches = [ps.sysSwitches; tSwitch];
          addlistener(tSwitch,'NewPosition',@ps.updateSwitch);
        end
      else % can't read this line
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d:', lineC ));
        disp(tLine)
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
    if isempty(ps.sysYmodif)
      ps.sysYmodif(secondBUS,secondBUS) = 0;
    end
    if (firstBUS == 0) % Shunt element
      if (tInductance ~= 0 || tCapacitance ~= 0)
        tPassiveElement = PassiveElement(ps,firstBUS,secondBUS,tResistence,tInductance,tCapacitance);
        ps.sysYmodif(...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) = ps.sysYmodif(...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) + diag(tPassiveElement.Gseries);
        ps.sysPassiveElements = [ps.sysPassiveElements; tPassiveElement];
      else
        ps.sysYmodif(...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) = ps.sysYmodif(...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) + diag(1/tResistence);
      end
    else % firstBUS to secondBUS connection
      if (tInductance ~= 0 || tCapacitance ~= 0)
        tPassiveElement = PassiveElement(ps,firstBUS,secondBUS,tResistence,tInductance,tCapacitance);
        ps.sysYmodif(... % k,m
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) = -diag(tPassiveElement.Gseries);
        ps.sysYmodif(... % m,k
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology...
        ) = -diag(tPassiveElement.Gseries);
        ps.sysYmodif(... % k,k
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology,...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology...
        ) = ps.sysYmodif(...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology,...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology...
        ) + diag(tPassiveElement.Gseries);
        ps.sysYmodif(... % m,m
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) = ps.sysYmodif(...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) + diag(tPassiveElement.Gseries);
        ps.sysPassiveElements = [ps.sysPassiveElements; tPassiveElement];
      else
        ps.sysYmodif(... % k,m
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) = -1/tResistence*eye(uint8(ps.topology));
        ps.sysYmodif(... % m,k
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology...
        ) = -1/tResistence*eye(uint8(ps.topology));
        ps.sysYmodif(... % k,k
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology,...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology...
        ) = ps.sysYmodif(...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology,...
          ps.topology*(firstBUS-1)+1:ps.topology*(firstBUS-1)+ps.topology...
        ) + 1/tResistence*eye(uint8(ps.topology));
        ps.sysYmodif(... % m,m
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) = ps.sysYmodif(...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology,...
          ps.topology*(secondBUS-1)+1:ps.topology*(secondBUS-1)+ps.topology...
        ) + 1/tResistence*eye(uint8(ps.topology));
      end
    end
    tLine = fgetl(psFile);
    lineC = lineC + 1;
  end

  ps.sysNumberOfBuses = size(ps.sysYmodif,1)/ps.topology;
  % Continuar daqui
  
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
  if ( svSize + sswitchSize )
    ps.sysYmodif(end+ps.topology*(svSize+sswitchSize),end+ps.topology*(svSize+sswitchSize))=0; 
  end

  % Fill sV
  for k=1:length(ps.sysVoltageSources)
    ps.sysYmodif(...
      ps.topology*(ps.sysNumberOfBuses+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+(k-1))+ps.topology,...
      ps.topology*(ps.sysNumberOfBuses+(k-2))+1:ps.topology*(ps.sysNumberOfBuses+(k-2))+ps.topology...
    ) = eye(uint8(ps.topology));
    ps.sysYmodif(...
      ps.topology*(ps.sysNumberOfBuses+(k-2))+1:ps.topology*(ps.sysNumberOfBuses+(k-2))+ps.topology,...
      ps.topology*(ps.sysNumberOfBuses+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+(k-1))+ps.topology...
    ) = eye(uint8(ps.topology));
    ps.sysVariablesDescr(ps.sysNumberOfBuses+k) = {sprintf('CURRENT ON %d',ps.sysVoltageSources.busK)};
  end

  % Fill sSwitch
  for k=1:length(ps.sysSwitches)
    if ( ps.sysSwitches(k).status == SwitchStatus.Closed)
      ps.sysYmodif(...
        ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+ps.topology,...
        ps.topology*(ps.sysSwitches(k).busK-1)+1:ps.topology*(ps.sysSwitches(k).busK-1)+ps.topology...
      ) = eye(uint8(ps.topology));
      ps.sysYmodif(...
        ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+ps.topology,...
        ps.topology*(ps.sysSwitches(k).busM-1)+1:ps.topology*(ps.sysSwitches(k).busM-1)+ps.topology...
      ) = -eye(uint8(ps.topology));
      ps.sysYmodif(...
        ps.topology*(ps.sysSwitches(k).busK-1)+1:ps.topology*(ps.sysSwitches(k).busK-1)+ps.topology,...
        ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+ps.topology...
      ) = eye(uint8(ps.topology));
      ps.sysYmodif(...
        ps.topology*(ps.sysSwitches(k).busM-1)+1:ps.topology*(ps.sysSwitches(k).busM-1)+ps.topology,...
        ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+ps.topology...
      ) = -eye(uint8(ps.topology));
    else
      ps.sysYmodif(...
        ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+ps.topology,...
        ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+1:ps.topology*(ps.sysNumberOfBuses+svSize+(k-1))+ps.topology...
      ) = eye(uint8(ps.topology));
    end
    ps.sysVariablesDescr(ps.sysNumberOfBuses+svSize+k) = {sprintf('CURRENT ON SWITCH %d-%d',ps.sysSwitches(k).busK,ps.sysSwitches(k).busM)};
  end

  fclose(psFile);

end
