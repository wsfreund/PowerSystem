function [psMatrix, psSources, psCurrentHist, psElementDetDescr] = readPowerSystem(file, step)
%     function [psMatrix, psSources, psCurrentHist, psElementDetDescr] = readPowerSystem(file, step)
%
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
%   step: The time step (h), default = 1e-3
%   
% Outputs:
%
%   psMatrix: Matrix with admitances and nodes connections
%   psSources: Vector containing the current/voltage generation values
%   psElementDetDescr: Cell containing the description for the outputs variables


  if (nargin == 1)
    step = 1e-3;
  end
  psFile = fopen(file,'r');
  psMatrix = [];
  psSources = [];
  psCurrentHist = [];
  switchConnections = {};
  voltageSources = {};
  psElementDetDescr= {};

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
      psSources(firstBUS,1) = tCurrent;
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
          switchConnections(end+1) = {[firstBUS, secondBUS, 1]};
        else 
          switchConnections(end+1) = {[firstBUS, secondBUS, 0]};
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
          psMatrix(firstBUS,firstBUS) = psMatrix(firstBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step + step/(2*tCapacitance));
        else
          psMatrix(firstBUS,firstBUS) = psMatrix(firstBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step);
        end
      elseif (tCapacitance ~= 0)
        psMatrix(firstBUS,firstBUS) = psMatrix(firstBUS,firstBUS) + 1/(tResistence + step/(2*tCapacitance));
      else
        psMatrix(firstBUS,firstBUS) = psMatrix(firstBUS,firstBUS) + 1/tResistence;
      end
    else
      if (tInductance ~= 0)
        if (tCapacitance ~= 0)
          psMatrix(firstBUS,secondBUS) = -psMatrix(firstBUS,secondBUS) + 1/(tResistence + (2*tInductance)/step + step/(2*tCapacitance));
          psMatrix(secondBUS,firstBUS) = -psMatrix(secondBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step + step/(2*tCapacitance));
          psCurrentHist(firstBUS) = 0;
          psCurrentHist(secondBUS) = -0;
        else
          psMatrix(firstBUS,secondBUS) = -psMatrix(firstBUS,secondBUS) + 1/(tResistence + (2*tInductance)/step);
          psMatrix(secondBUS,firstBUS) = -psMatrix(secondBUS,firstBUS) + 1/(tResistence + (2*tInductance)/step);
          psCurrentHist(firstBUS) = 0;
          psCurrentHist(secondBUS) = -0;
        end
      elseif (tCapacitance ~= 0)
        psMatrix(firstBUS,secondBUS) = -psMatrix(firstBUS,secondBUS) + 1/(tResistence + step/(2*tCapacitance));
        psMatrix(secondBUS,firstBUS) = -psMatrix(secondBUS,firstBUS) + 1/(tResistence + step/(2*tCapacitance));
        psCurrentHist(firstBUS) = 0;
        psCurrentHist(secondBUS) = -0;
      else
        psMatrix(firstBUS,secondBUS) = -1/tResistence;
        psMatrix(secondBUS,firstBUS) = -1/tResistence;
        psCurrentHist(firstBUS) = 0;
        psCurrentHist(secondBUS) = -0;
      end
    end
    tLine = fgetl(psFile);
    lineC = lineC + 1;
  end

  lastRow = size(psMatrix,1);
  if ( length(psSources < lastRow ))
    psSources(lastRow) = 0;
  end

  for k=1:lastRow
      psElementDetDescr(k) = {sprintf('VOLTAGE ON %d',k)};
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

  for k=1:(length(switchConnections))
    for m=k:length(switchConnections)
      if (switchConnections{k}(1) > switchConnections{m}(1) )
        tempCell = switchConnections{k};
        switchConnections{k} = switchConnections{m};
        switchConnections{m} = tempCell;
      end
    end
  end

  for k=1:(length(switchConnections))
    for m=k:length(switchConnections)
      if ( (switchConnections{k}(1) == switchConnections{m}(1)) & (switchConnections{k}(2) > switchConnections{m}(2)) )
        tempCell = switchConnections{k};
        switchConnections{k} = switchConnections{m};
        switchConnections{m} = tempCell;
      else
        continue;
      end
    end
  end


  for k=1:length(voltageSources)
    newRow = size(psMatrix,1)+1;
    psMatrix(newRow:end+1,:) = psMatrix(newRow-1:end,:);
    psMatrix(newRow-1,newRow) = 1;
    psMatrix(newRow,newRow-1) = 1;
    psSources(newRow:end+1) = psSources(newRow-1,end);
    psSources(newRow) = voltageSources{k}(2);
    psElementDetDescr(newRow) = {sprintf('CURRENT ON %d',voltageSources{k}(1))};
  end

  for k=1:length(switchConnections)
    newRow = size(psMatrix,1)+1;
    switchStatus = switchConnections{k}(3);
    if switchStatus
      psMatrix(newRow,switchConnections{k}(2)) = switchStatus;
      psMatrix(newRow,switchConnections{k}(1)) = switchStatus;
      psMatrix(switchConnections{k}(2),newRow) = switchStatus;
      psMatrix(switchConnections{k}(1),newRow) = switchStatus;
    else
      psMatrix(newRow,newRow) = 1;
    end
    psSources(newRow) = 0;
    psElementDetDescr(newRow) = {sprintf('CURRENT ON SWITCH %d-%d',switchConnections{k}(1),switchConnections{k}(2))};
  end

  fclose(psFile);

end
