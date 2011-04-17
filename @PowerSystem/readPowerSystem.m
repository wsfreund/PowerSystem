function readPowerSystem(ps, file)
% function readPowerSystem(ps, file)
%


  if (nargin == 1)
    step = 1e-3;
  end
  psFile = fopen(file,'r');
  ps.sysYn = [];
  ps.sysSources = [];
  ps.sysPassiveElements = [];
  ps.sysSwitches = {};
  ps.variablesDescr= {};

  tLine = fgetl(psFile);
  lineC = 1;
  while (ischar(tLine))
    firstBUS = -1;
    secondBUS = -1;
    [tWords] = textscan(tLine,'%s %s %f64 %f64 %f64');
    if strfind(tWords{1}{1},'BUS')
      firstBUS = strread(tWords{1}{1},'BUS %d');
    elseif strfind(tWords{1}{1},'GROUND')
      firstBUS = strread(tWords{2}{1},'BUS %d');
      secondBUS = firstBUS;
    end
    if strfind(tWords{2}{1},'BUS')
      secondBUS = strread(tWords{2}{1},'BUS %d');
    elseif strfind(tWords{2}{1},'GROUND')
      secondBUS = firstBUS;
    elseif strcmp(tWords{2}{1},'CURRENT')
      tCurrent = tWords{3};
      if (isempty(tCurrent))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      ps.sysSources(firstBUS,1) = tCurrent;
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    elseif strcmp(tWords{2}{1},'VOLTAGE')
      tVoltage = tWords{3};
      if (isempty(tVoltage))
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        tLine = fgetl(psFile);
        lineC = lineC + 1;
        continue;
      end
      voltageSources(end+1) = {[firstBUS, tVoltage]};
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    if (firstBUS > secondBUS)
      temp = firstBUS;
      firstBUS = secondBUS;
      secondBUS = temp;
    end
    tResistence = tWords{3};
    if (isempty(tResistence))
      tWords = textscan(tLine,'%*s %*s %s %s');
      if strcmp(tWords{1}{1},'SWITCH')
        if (firstBUS == secondBUS)
          display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
        end
        if length(tWords{2}) ~= 0 & strfind(tWords{2}{1},'CLOSE')
          ps.sysSwitches(end+1) = {[firstBUS, secondBUS, 1]};
        else 
          ps.sysSwitches(end+1) = {[firstBUS, secondBUS, 0]};
        end
      else
        display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      end
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    if ( ( firstBUS<0 | secondBUS<0 ) )
      display(sprintf('IGNORING BADLY FORMATED LINE NUMBER %d', lineC ));
      tLine = fgetl(psFile);
      lineC = lineC + 1;
      continue;
    end
    tInductance = 0.;
    tCapacitance = 0.;
    if (~isempty(tWords{4}))
      tInductance = tWords{4}/(2*pi*60);
    end
    if (~isempty(tWords{5}))
      tCapacitance = tWords{5}/(2*pi*60);
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
