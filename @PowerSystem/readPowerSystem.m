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
      secondBUS = firstBUS; % ...than set index equal  
    % Checking for Sources:
    elseif strcmp(tWords{2}{1},'CURRENT') % Current Sources
      tCurrent = tWords{3};
      if (isempty(tCurrent))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      tCurrentSource = Source(SourceTypes.Current,'sinoidal',tCurrent);
      ps.sysSources(end+1) = tCurrentSource;
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
      tVoltageSource = Source(SourceTypes.Voltage,'sinoidal',tVoltage);
      ps.sysSources(end+1) = tVoltageSource;
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
    % Resistence is supposed to be the third word
    tResistence = tWords{3};
    if (isempty(tResistence)) % Third word is not a double! Let's try reading it as a string.
      tWords = textscan(tLine,'%*s %*s %s %s'); % read third and fourth word as strings, ignoring first and second words.
      if strcmp(tWords{1}{1},'SWITCH') % is third word SWITCH?
        if (firstBUS == secondBUS) % it shouldnt be a switch to the ground... as far as I know.
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        end
        if length(tWords{2}) ~= 0 & strfind(tWords{2}{1},'CLOSE')
          ps.sysSwitches(end+1) = {[firstBUS, secondBUS, 1]};
        else 
          ps.sysSwitches(end+1) = {[firstBUS, secondBUS, 0]};
        end
      else % can't read this line
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    if ( ( firstBUS<0 | secondBUS<0 ) ) % Did someone write on the file any negative index? 
      display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
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
      tCapacitance = tWords{5}/(2*pi*60);% Inputs should be on frequency domain
    end
    if (firstBUS == secondBUS)
      if (tInductance ~= 0)
        if (tCapacitance ~= 0)
          ps.sysYn(firstBUS,firstBUS) = ps.sysYn(firstBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step + step/(2*tCapacitance));
        else
          ps.sysYn(firstBUS,firstBUS) = ps.sysYn(firstBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step);
        end
      elseif (tCapacitance ~= 0)
        ps.sysYn(firstBUS,firstBUS) = ps.sysYn(firstBUS,firstBUS) + 1/(tResistence + step/(2*tCapacitance));
      else
        ps.sysYn(firstBUS,firstBUS) = ps.sysYn(firstBUS,firstBUS) + 1/tResistence;
      end
    else
      if (tInductance ~= 0)
        if (tCapacitance ~= 0)
          ps.sysYn(firstBUS,secondBUS) = -ps.sysYn(firstBUS,secondBUS) + 1/(tResistence + (2*tInductance)/step + step/(2*tCapacitance));
          ps.sysYn(secondBUS,firstBUS) = -ps.sysYn(secondBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step + step/(2*tCapacitance));
          ps.sysPassiveElements(firstBUS) = 0;
          ps.sysPassiveElements(secondBUS) = -0;
        else
          ps.sysYn(firstBUS,secondBUS) = -ps.sysYn(firstBUS,secondBUS) + 1/(tResistence + (2*tInductance)/step);
          ps.sysYn(secondBUS,firstBUS) = -ps.sysYn(secondBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step);
          ps.sysPassiveElements(firstBUS) = 0;
          ps.sysPassiveElements(secondBUS) = -0;
        end
      elseif (tCapacitance ~= 0)
        ps.sysYn(firstBUS,secondBUS) = -ps.sysYn(firstBUS,secondBUS) + 1/(tResistence + step/(2*tCapacitance));
        ps.sysYn(secondBUS,firstBUS) = -ps.sysYn(secondBUS,firstBUS) + 1/(tResistence + step/(2*tCapacitance));
        ps.sysPassiveElements(firstBUS) = 0;
        ps.sysPassiveElements(secondBUS) = -0;
      else
        ps.sysYn(firstBUS,secondBUS) = -1/tResistence;
        ps.sysYn(secondBUS,firstBUS) = -1/tResistence;
        ps.sysPassiveElements(firstBUS) = 0;
        ps.sysPassiveElements(secondBUS) = -0;
      end
    end
    tLine = fgetl(psFile);
    lineC = lineC + 1;
  end

  lastRow = size(ps.sysYn,1);
  if ( length(ps.sysSources < lastRow ))
    ps.sysSources(lastRow) = 0;
  end

  for k=1:lastRow
      ps.variablesDescr(k) = {sprintf('VOLTAGE ON %d',k)};
  end

  for k=1:(length(voltageSources))
    for m=k:length(voltageSources)
      if (voltageSources{k}(1) > voltageSources{m}(1) )
        tempCell = voltageSources{k};
        voltageSources{k} = voltageSources{m};
        voltageSources{m} = tempCell;
      end
    end
  end

  for k=1:(length(ps.sysSwitches))
    for m=k:length(ps.sysSwitches)
      if (ps.sysSwitches{k}(1) > ps.sysSwitches{m}(1) )
        tempCell = ps.sysSwitches{k};
        ps.sysSwitches{k} = ps.sysSwitches{m};
        ps.sysSwitches{m} = tempCell;
      end
    end
  end

  for k=1:(length(ps.sysSwitches))
    for m=k:length(ps.sysSwitches)
      if ( (ps.sysSwitches{k}(1) == ps.sysSwitches{m}(1)) & (ps.sysSwitches{k}(2) > ps.sysSwitches{m}(2)) )
        tempCell = ps.sysSwitches{k};
        ps.sysSwitches{k} = ps.sysSwitches{m};
        ps.sysSwitches{m} = tempCell;
      else
        continue;
      end
    end
  end


  for k=1:length(voltageSources)
    newRow = size(ps.sysYn,1)+1;
    ps.sysYn(newRow:end+1,:) = ps.sysYn(newRow-1:end,:);
    ps.sysYn(newRow-1,newRow) = 1;
    ps.sysYn(newRow,newRow-1) = 1;
    ps.sysSources(newRow:end+1) = ps.sysSources(newRow-1,end);
    ps.sysSources(newRow) = voltageSources{k}(2);
    ps.variablesDescr(newRow) = {sprintf('CURRENT ON %d',voltageSources{k}(1))};
  end

  for k=1:length(ps.sysSwitches)
    newRow = size(ps.sysYn,1)+1;
    switchStatus = ps.sysSwitches{k}(3);
    if switchStatus
      ps.sysYn(newRow,ps.sysSwitches{k}(2)) = switchStatus;
      ps.sysYn(newRow,ps.sysSwitches{k}(1)) = switchStatus;
      ps.sysYn(ps.sysSwitches{k}(2),newRow) = switchStatus;
      ps.sysYn(ps.sysSwitches{k}(1),newRow) = switchStatus;
    else
      ps.sysYn(newRow,newRow) = 1;
    end
    ps.sysSources(newRow) = 0;
    ps.variablesDescr(newRow) = {sprintf('CURRENT ON SWITCH %d-%d',ps.sysSwitches{k}(1),ps.sysSwitches{k}(2))};
  end

  fclose(psFile);

end
