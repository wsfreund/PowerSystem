classdef(Enumeration) SwitchStatus < Simulink.IntEnumType
  enumeration % Possible ways that a switch can be
    Open(0), Closed(1)
  end
end
