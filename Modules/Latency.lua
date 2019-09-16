local addonName, namespace = ...

local NewTicker = C_Timer.NewTicker

local NetView = LibStub("AceAddon-3.0"):GetAddon("NetView")
local Latency = NetView:NewModule("Latency")
local L = LibStub("AceLocale-3.0"):GetLocale("NetView")
local Media = LibStub("LibSharedMedia-3.0")

local db
local defaults = { 
  profile = {
    enabled = true,
    font = "Friz Quadrata TT",
    size = 12,
    outline = "NONE",
    shadow = false,
    anchor = "CENTER",
    posx = 0,
    posy = 0,
    text = "%w%s%h MS",
    textColor = {r = 1, g = 1, b = 1},
    colorThreshold = true,
    showHome = true,
    showWorld = true,
    showSeparator = true,
    textSeparator = "/",
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

function Latency:GetOptions()
return {
  order = 1, type = "group",
  name = L["Latency"],
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
          name = L["Show Latency"],
          get = function() return NetView:GetModuleEnabled("Latency") end,
          set = function(info, value) NetView:SetModuleEnabled("Latency", value) end,
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
          desc = L["Color latency number at certain thresholds"],
          set = function(info, v)
            db.colorThreshold = v
          end,
        },
        text = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 7, type = "input",
          name = L["Custom Text"],
          usage = format("\n\n%s\n%s\n%s", L["Use %w for world latency"], L["Use %h for home latency"], L["Use %s for the separator"]),
          set = function(info, v)
            db.text = v
          end,
        },
        spacer = {
          order = 8, type = "description", fontSize = "medium",
          name = "",
        },
        showWorld = {
          disabled = function() return (not self:IsEnabled()) or not db.showHome end,
          order = 9, type = "toggle",
          name = L["Show World Latency"], 
          set = function(info, v)
            db.showWorld = v
          end,
        },
        showHome = {
          disabled = function() return (not self:IsEnabled()) or not db.showWorld end,
          order = 10, type = "toggle",
          name = L["Show Home Latency"],
          set = function(info, v)
            db.showHome = v
          end,
        },
        showSeparator = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 11, type = "toggle",
          name = L["Show Separator"],
          set = function(info, v)
            db.showSeparator = v
          end,
        },
        textSeparator = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 12, type = "input",
          name = L["Text Separator"],
          desc = L["Set what character is used to separate the home and world values"],
          set = function(info, v)
            db.textSeparator = v
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
  },
}
end

local function ColorLatency(v)
  if (v < 100) then
    if (db.colorThreshold) then
      return format("|cff00ff00%d|r", v)
    else
      return format("|cffffffff%d|r", v)
    end
  elseif (v < 300) then
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

local function UpdateLatency()
  local NetViewBar = _G.NetViewBar
  db = Latency.db.profile

  local t = db.text
  t = t:gsub("%%s",
  function()
    if (db.showSeparator and db.showWorld and db.showHome) then
      return db.textSeparator
    else
      return ""
    end
  end)

  if (db.showWorld and db.showHome) then
    t = t:gsub("%%w", "%%s")
    t = t:gsub("%%h", "%%s")
    t = t:format(ColorLatency(select(4, GetNetStats())), ColorLatency(select(3, GetNetStats())))
    NetViewBar.latencytext:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
    NetViewBar.latencytext:SetText(t)
  elseif db.showWorld and not db.showHome then
    t = t:gsub("%%w", "%%s")
    t = t:gsub("%%h", "")
    t = t:format(ColorLatency(select(4, GetNetStats())))
    NetViewBar.latencytext:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
    NetViewBar.latencytext:SetText(t)
  elseif db.showHome and (not db.showWorld) then
    t = t:gsub("%%h", "%%s")
    t = t:gsub("%%w", "")
    t = t:format(ColorLatency(select(3, GetNetStats())))
    NetViewBar.latencytext:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
    NetViewBar.latencytext:SetText(t)
  end
end

function Latency:OnInitialize()
  self:SetEnabledState(NetView:GetModuleEnabled("Latency"))

  self.db = NetView.db:RegisterNamespace("Latency", defaults)
  db = self.db.profile

  local options = self:GetOptions()
  NetView:RegisterModuleOptions("Latency", options, "Latency")
end

function Latency:OnEnable()
  local NetViewBar = _G.NetViewBar

  NetViewBar.latencytext = NetViewBar:CreateFontString(nil, "OVERLAY")
  self:UpdateLayout(true)
  if (not NetView.latencyTimer) or NetView.latencyTimer:IsCancelled() then
    NetView.latencyTimer = NewTicker(10, UpdateLatency)
  end
  NetViewBar.latencytext:Show()
end

function Latency:OnDisable()
  local NetViewBar = _G.NetViewBar

  if NetView.latencyTimer then
    NetView.latencyTimer:Cancel()
  end
  NetViewBar.latencytext:Hide()
end

function Latency:UpdateLayout(update)
  local NetViewBar = _G.NetViewBar

  local font = Media and Media:Fetch(Media.MediaType.FONT, db.font) or "Fonts\\FRIZQT__.ttf"
  local size = db.size
  local outline = db.outline
  local shadow = db.shadow and 1 or 0

  NetViewBar.latencytext:SetFont(font, size, outline)
  NetViewBar.latencytext:SetShadowOffset(0, 0)
  NetViewBar.latencytext:SetShadowOffset(shadow, -shadow)
  NetViewBar.latencytext:ClearAllPoints()
  NetViewBar.latencytext:SetPoint(db.anchor, NetViewBar, db.posx, db.posy)

  if update then
    UpdateLatency()
  end
end
