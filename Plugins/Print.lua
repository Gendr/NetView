--[[  Print  ]]--

local Print = {}
do
  local _, namespace = ...
  namespace.Print = Print
end

do
  function Print:prt(msg, error)
    if error then
      DEFAULT_CHAT_FRAME:AddMessage('|cffffffccNetView:|r |cffff0000'..msg..'|r')
    end
    DEFAULT_CHAT_FRAME:AddMessage('|cffffffccNetView:|r '..msg)
  end

  function Print:prtFrame(frame, msg)
    local output_frame = _G[frame]
    output_frame:AddMessage('|cffffffccNetView:|r '..msg)
  end
end
