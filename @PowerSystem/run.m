function run(ps)
% function run(ps)
%   This function runs the PowerSystem.

  for time_idx=2:length(ps.timeVector)
    thisTime = ps.timeVector(time_idx);
    % Update Passive Elements Injection:
    for k=1:length(ps.sysPassiveElements)
      if ps.sysPassiveElements(k).busK % not connected to the ground?
        ps.sysPassiveElements(k).update_injection( ...
          ps.sysVariablesMatrix(ps.sysPassiveElements(k).busK,time_idx-1), ...
          ps.sysVariablesMatrix(ps.sysPassiveElements(k).busM,time_idx-1) ...
        );
      else
        ps.sysPassiveElements(k).update_injection( ...
          0, ...
          ps.sysVariablesMatrix(ps.sysPassiveElements(k).busM,time_idx-1) ...
        );
      end
    end
    % Fill injection for the current time and update independent sources
    for k=1:length(ps.sysCurrentSources)
      ps.sysInjectionMatrix(ps.sysCurrentSources(k).busK,time_idx) = ... 
        ps.sysInjectionMatrix(ps.sysCurrentSources(k).busK,time_idx) + ps.sysCurrentSources(k).injection;
      ps.sysCurrentSources(k).update(thisTime);
    end
    for k=1:length(ps.sysVoltageSources)
      ps.sysInjectionMatrix(ps.sysNumberOfBuses+k,time_idx) = ...
        ps.sysInjectionMatrix(ps.sysNumberOfBuses+k,time_idx) + ps.sysVoltageSources(k).injection;
      ps.sysVoltageSources(k).update(thisTime);
    end
    % Add passive element current injections:
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
    % Determine variables:
    ps.sysVariablesMatrix(:,time_idx) = ps.sysInvYmodif * ps.sysInjectionMatrix(:,time_idx);
    % Update Passive Elements Injection:
    for k=1:length(ps.sysPassiveElements)
      if ps.sysPassiveElements(k).busK % not connected to the ground?
        ps.sysPassiveElements(k).update_ikm( ...
          ps.sysVariablesMatrix(ps.sysPassiveElements(k).busK,time_idx), ...
          ps.sysVariablesMatrix(ps.sysPassiveElements(k).busM,time_idx) ...
        );
      else
        ps.sysPassiveElements(k).update_ikm( ...
          0, ...
          ps.sysVariablesMatrix(ps.sysPassiveElements(k).busM,time_idx) ...
        );
      end
    end
  end
end % function run
