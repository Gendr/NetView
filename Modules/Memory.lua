local addonName, namespace = ...

local NewTicker = C_Timer.NewTicker

local NetView = LibStub("AceAddon-3.0"):GetAddon("NetView")
local Memory = NetView:NewModule("Memory")
local L = LibStub("AceLocale-3.0"):GetLocale("NetView")
local Media = LibStub("LibSharedMedia-3.0")
local Sounds = namespace.Sounds

local db
local defaults = { 
  profile = {
    enabled = true,
    font = "Friz Quadrata TT",
    size = 12,
    outline = "NONE",
    shadow = false,
    anchor = "RIGHT",
    posx = -7,
    posy = 0,
    text = "%d %s",
    textColor = {r = 1, g = .80, b = 0},
    colorThreshold = true,
    mbSuffix = "MB",
    kbSuffix = "KB",

    useMemDump = true,
    memDumpText = "Memory cleaned: %d",
    memDumpChatFrm = "ChatFrame1",

    useWarnSound = false,
    warnThreshold = "100",
    warnSound = "IM",
  }
}

local fontOutlineTbl = {
  NONE = L["NONE"],
  OUTLINE = L["OUTLINE"],
  THICKOUTLINE = L["THICKOUTLINE"],
}

local anchorPosTbl = {
  LEFT = L["LEFT"],
  CENTER = L["CENTER"],
  RIGHT = L["RIGHT"],
}

local chatFrameTbl = {
  ChatFrame1 = L["ChatFrame%d"]:format(1),
  ChatFrame2 = L["ChatFrame%d"]:format(2),
  ChatFrame3 = L["ChatFrame%d"]:format(3),
  ChatFrame4 = L["ChatFrame%d"]:format(4),
  ChatFrame5 = L["ChatFrame%d"]:format(5),
  ChatFrame6 = L["ChatFrame%d"]:format(6),
  ChatFrame7 = L["ChatFrame%d"]:format(7),
  ChatFrame8 = L["ChatFrame%d"]:format(8),
  ChatFrame9 = L["ChatFrame%d"]:format(9),
  ChatFrame10 = L["ChatFrame%d"]:format(10),
}

function Memory:GetOptions()
return {
  order = 1, type = "group",
  name = L["Memory"],
  get = function(info)
    local key = info[#info]
    local v = db[key]
    if (type(v) == "table" and v.r and v.g and v.b) then
      return v.r, v.g, v.b
    else
      return v
    end
  end,
  set = function(info, v)
    local key = info[#info]
    db[key] = v
  end,
  args = {
    enable = {
      order = 1, type = "group", inline = true,
      name = L["Enable"],
      args = {
        enabled = {
          order = 1, type = "toggle", width = "full",
          name = L["Show Memory"],
          get = function() return NetView:GetModuleEnabled("Memory") end,
          set = function(info, value) NetView:SetModuleEnabled("Memory", value) end,
        },
      },
    },
    fonts = {
      order = 2, type = "group", inline = true,
      name = L["Text"],
      args = {
        font = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 1, type = "select",
          dialogControl = "LSM30_Font", values = Media:HashTable("font"),
          name = L["Font"],
          set = function(info, v)
            db.font = v
            self:UpdateLayout()
          end,
        },
        outline = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 2, type = "select", values = fontOutlineTbl,
          name = L["Font Outline"],
          set = function(info, v)
            db.outline = v
            self:UpdateLayout()
          end,
        },
        size = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 3, type = "range", min = 4, max = 32, step = 1,
          name = L["Font Size"],
          set = function(info, v)
            db.size = v
            self:UpdateLayout()
          end,
        },
        shadow = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 4, type = "toggle",
          name = L["Font Shadow"],
          set = function(info, v)
            db.shadow = v
            self:UpdateLayout()
          end,
        },
        textColor = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 5, type = "color", hasAlpha = false,
          name = L["Text Color"],
          set = function(info, r, g, b)
            local color = db.textColor
            color.r, color.g, color.b = r, g, b
          end,
        },
        colorThreshold = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 6, type = "toggle",
          name = L["Color Threshold"],
          desc = L["Color memory number at certain thresholds"],
          set = function(info, v)
            db.colorThreshold = v
          end,
        },
        text = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 7, type = "input",
          name = L["Custom Text"],
          usage = format("\n\n%s\n%s", L["Use %d for the number"], L["Use %s for the suffix"]),
          set = function(info, v)
            db.text = v
          end,
        },
        mbSuffix = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 8, type = "input",
          name = L["Megabyte Custom Text"],
          set = function(info, v)
            db.mbSuffix = v
          end,
        },
        kbSuffix = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 9, type = "input",
          name = L["Kilobyte Custom Text"],
          set = function(info, v)
            db.kbSuffix = v
          end,
        },
      },
    },
    position = {
      order = 3, type = "group", inline = true,
      name = L["Position"],
      args = {
        anchor = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 1, type = "select", values = anchorPosTbl,
          name = L["Anchor"],
          set = function(info, v)
            db.anchor = v
            self:UpdateLayout()
          end,
        },
        posx = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 2, type = "range", min = -100, max = 100, step = 1,
          name = L["X Offset"],
          set = function(info, v)
            db.posx = v
            self:UpdateLayout()
          end,
        },
        posy = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 3, type = "range", min = -100, max = 100, step = 1,
          name = L["Y Offset"],
          set = function(info, v)
            db.posy = v
            self:UpdateLayout()
          end,
        },
      },
    },
    opts = {
      order = 4, type = "group", inline = true,
      name = L["Options"],
      args = {
        memdump = {
          order = 1, type = "group",
          name = L["Memory Dump"],
          args = {
            useMemDump = {
              disabled = function() return (not self:IsEnabled()) end,
              order = 1, type = "toggle", width = "full",
              name = L["Enable"],
              desc = L["Output memory cleaned to the chat frame"], descStyle = "inline",
              set = function(info, v)
                db.useMemDump = v
              end,
            },
            memDumpText = {
              disabled = function() return (not self:IsEnabled()) or (not db.useMemDump) end,
              order = 2, type = "input",
              name = L["Custom Text"], usage = L["Use %d for the number"],
              set = function(info, v)
                db.memDumpText  = v
              end,
            },
            memDumpChatFrm= {
              disabled = function() return (not self:IsEnabled()) or (not db.useMemDump) end,
              order = 3, type = "select", values = chatFrameTbl,
              name = L["Channel Output"], desc = L["Set the memory cleaned output chat frame"],
              set = function(info, v)
                db.memDumpChatFrm = v
              end,
            },
          },
        },
        sounds = {
          order = 2, type = "group",
          name = L["Sounds"],
          args = {
            useWarnSound = {
              disabled = function() return (not self:IsEnabled()) end,
              order = 1, type = "toggle", width = "full",
              name = L["Enable"], desc = L["Play a sound when memory rises above threshold"], descStyle = "inline",
              set = function(info, v)
                db.useWarnSound = v
              end,
            },
            warnThreshold = {
              disabled = function() return (not self:IsEnabled()) or (not db.useWarnSound) end,
              order = 2, type = "input",
              name = L["Warning Threshold"],
              set = function(info, v)
              db.warnThreshold = v
              end,
            },
            warnSound = {
              disabled = function() return (not self:IsEnabled()) or (not db.useWarnSound) end,
              order = 3, type = "select",
              dialogControl = "LSM30_Sound", values = Media:HashTable("sound"),
              name = L["Sound"],
              set = function(info, v)
                db.warnSound = v
              end,
            },
          },
        },
      },
    },
  },
}
end

local function MemFormat(v, opt)
  db = Memory.db.profile

  if opt then
    if (v > 999) then
      return format("|cff00ff00%.1f %s|r", v / 1024, L["MB"])
    else
      return format("|cff00ff00%.0f %s|r", v, L["KB"])
    end
  else
    if (v > 999) then
    local t = "%%.%df %s"
      local acc = tonumber(db.tooltip.accuracy) or 1
      t = t:format(acc, L["MB"])
    return t:format(v / 1024)
    else
    local t = "%%.%df %s"
      local acc = tonumber(db.tooltip.accuracy) or 1
      t = t:format(acc, L["KB"])
    return t:format(v)
    end
  end

  if (v > 999) then
    return format("%.1f %s", v / 1024, L["MB"])
  else
    return format("%.0f %s", v, L["KB"])
  end
end

function Memory:CleanMemory()
  db = self.db.profile

  local t = db.memDumpText
  UpdateAddOnMemoryUsage()
  local memBefore = gcinfo()
  collectgarbage("collect")
  UpdateAddOnMemoryUsage()
  local memAfter = gcinfo()
  t = t:gsub("%%d", "%%s")
  t = t:format(MemFormat(memBefore - memAfter, true))
  return t
end

local function ColorMemory(v)
  db = Memory.db.profile

  if (db.useWarnSound and tonumber(db.warnThreshold) > v) then
    PlaySound(db.warnSound)
  end

  if (v < 50) then
    if (db.colorThreshold) then
      return format("|cff00ff00%d|r", v)
    else
      return format("|cffffffff%d|r", v)
    end
  elseif (v < 100) then
    if (db.colorThreshold) then
      return format("|cffffff00%d|r", v)
    else
      return format("|cffffffff%d|r", v)
    end
  else
    if (db.colorThreshold) then
      return format("|cffff0000%d|r", v)
    else
      return format("|cffffffff%d|r", v)
    end
  end
end

local function UpdateMemory()
  local NetViewBar = _G.NetViewBar
  db = Memory.db.profile

  if InCombatLockdown() then return end

  UpdateAddOnMemoryUsage()
  local total = 0
  for i=1, GetNumAddOns() do
    total = total + GetAddOnMemoryUsage(i)
  end

  local suffix
  local value = 0
  if (total > 999) then
    value = format("%.0f", total / 1024)
    suffix = db.mbSuffix
  else
    value = format("%.0f", total)
    suffix = db.kbSuffix
  end

  local t = db.text
  t = t:gsub("%%s", suffix)
  t = t:gsub("%%d", "%%s")
  t = t:format(ColorMemory(tonumber(value)))
  NetViewBar.memorytext:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
  NetViewBar.memorytext:SetText(t)
end

function Memory:OnInitialize()
  self:SetEnabledState(NetView:GetModuleEnabled("Memory"))

  self.db = NetView.db:RegisterNamespace("Memory", defaults)
  db = self.db.profile

  local options = Memory:GetOptions()
  NetView:RegisterModuleOptions("Memory", options, "Memory")
end

function Memory:OnEnable()
  local NetViewBar = _G.NetViewBar

  NetViewBar.memorytext = NetViewBar:CreateFontString(nil, "OVERLAY")
  self:UpdateLayout(true)
  if (not NetView.memoryTimer) or NetView.memoryTimer:IsCancelled() then
    NetView.memoryTimer = NewTicker(20, UpdateMemory)
  end
  NetViewBar.memorytext:Show()
end

function Memory:OnDisable()
  local NetViewBar = _G.NetViewBar

  if NetView.memoryTimer then
    NetView.memoryTimer:Cancel()
  end
  NetViewBar.memorytext:Hide()
end

function Memory:UpdateLayout(update)
  local NetViewBar = _G.NetViewBar
  db = self.db.profile

  local font = Media and Media:Fetch(Media.MediaType.FONT, db.font) or "Fonts\\FRIZQT__.ttf"
  local size = db.size
  local outline = db.outline
  local shadow = db.shadow and 1 or 0

  NetViewBar.memorytext:SetFont(font, size, outline)
  NetViewBar.memorytext:SetShadowOffset(0, 0)
  NetViewBar.memorytext:SetShadowOffset(shadow, -shadow)
  NetViewBar.memorytext:ClearAllPoints()
  NetViewBar.memorytext:SetPoint(db.anchor, NetViewBar, db.posx, db.posy)

  if update then
    UpdateMemory()
  end
end
