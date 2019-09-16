local addonName, namespace = ...

local FPS_ABBR = FPS_ABBR
local NewTicker = C_Timer.NewTicker

local NetView = LibStub("AceAddon-3.0"):GetAddon("NetView")
local FPS = NetView:NewModule("FPS")
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
    anchor = "LEFT",
    posx = 7,
    posy = 0,
    text = "%d FPS",

	aboveColor = {r = 0, g = 1, b = 0},
	belowColor = {r = 1, g = 1, b = 0},
	warnColor = {r = 1, g = 0, b = 0},
    textColor = {r = 1, g = 1, b = 1},
    colorThreshold = true,

    useWarnSound = false,
    warnThreshold = "10",
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

function FPS:GetOptions()
return {
  order = 1, type = "group",
  name = L["FPS"],
  get = function(info)
    local key = info[#info]
    local v = db[key]
    if type(v) == "table" and v.r and v.g and v.b then
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
          name = L["Show FPS"],
          get = function() return NetView:GetModuleEnabled("FPS") end,
          set = function(info, value) NetView:SetModuleEnabled("FPS", value) end,
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
          order = 4, type = "color", hasAlpha = false,
          name = L["Text Color"],
          set = function(info, r, g, b)
            local color = db.textColor
            color.r, color.g, color.b = r, g, b
            end,
        },
        colorThreshold = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 5, type = "toggle",
          name = L["Color Threshold"],
          desc = L["Color fps number at certain thresholds"],
          set = function(info, v)
            db.colorThreshold = v
          end,
            },
        text = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 7, type = "input",
          name = L["Custom Text"],
          usage = L["Use %d for the number"],
          set = function(info, v)
            db.text = v
          end,
        },
      },
    },
    position = {
      order = 3,
      name = L["Position"], type = "group", inline = true,
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
        colors = {
          order = 1, type = "group",
          name = L["Colors"],
          args = {
            aboveColor = {
              disabled = function() return (not self:IsEnabled()) or (not db.colorThreshold)  end,
              order = 1, type = "color", hasAlpha = false,
              name = L["Above 60"],
              set = function(info, r, g, b)
                local color = db.aboveColor
                color.r, color.g, color.b = r, g, b
              end,
           },
           belowColor = {
             disabled = function() return (not self:IsEnabled()) or (not db.colorThreshold) end,
             order = 2, type = "color", hasAlpha = false,
             name = L["Below 30"],
             set = function(info, r, g, b)
               local color = db.belowColor
               color.r, color.g, color.b = r, g, b
             end,
           },
           warnColor = {
             disabled = function() return (not self:IsEnabled()) or (not db.colorThreshold) end,
             order = 3, type = "color", hasAlpha = false,
             name = L["Warning < 10"],
             set = function(info, r, g, b)
               local color = db.warnColor
               color.r, color.g, color.b = r, g, b
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
            order = 1, type = "toggle",
            width = "full",
            name = L["Enable"],
            desc = L["Play a sound when fps drops under threshold"], descStyle = "inline",
            set = function(info, v)
              db.useWarnSound = v
            end,
          },
          warnThreshold = {
            disabled = function() return (not db.enabled) or (not db.useWarnSound) end,
            order = 2, type = "input",
            name = L["Warning Threshold"],
            set = function(info, v)
              db.warnThreshold = v
            end,
          },
          warnSound = {
            disabled = function() return (not db.enabled) or (not db.useWarnSound) end,
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

local function ColorFramerate(v)
  if (db.useWarnSound and tonumber(db.warnThreshold) > v) then
    Sounds:PlaySound(db.warnSound)
  end

  if (db.colorThreshold) then
    if (v < 10) then
      return format('|cff%02x%02x%02x%d|r', db.warnColor.r*255, db.warnColor.g*255, db.warnColor.b*255, v)
    elseif (v < 30) then
      return format('|cff%02x%02x%02x%d|r', db.belowColor.r*255, db.belowColor.g*255, db.belowColor.b*255, v)
    else
	  return format('|cff%02x%02x%02x%d|r', db.aboveColor.r*255, db.aboveColor.g*255, db.aboveColor.b*255, v)
    end
  else
    return format("|cffffffff%d|r", v)
  end
end


local function UpdateFPS()
  local NetViewBar = _G.NetViewBar
  db = FPS.db.profile

  local t = db.text
  t = t:gsub("%%d", "%%s")
  t = t:format(ColorFramerate(GetFramerate()))

  NetViewBar.fpstext:SetTextColor(db.textColor.r, db.textColor.g, db.textColor.b)
  NetViewBar.fpstext:SetText(t)
end

function FPS:OnInitialize()
  self:SetEnabledState(NetView:GetModuleEnabled("FPS"))

  self.db = NetView.db:RegisterNamespace("FPS", defaults)
  db = self.db.profile

  local options = self:GetOptions()
  NetView:RegisterModuleOptions("FPS", options, "FPS")
end

function FPS:OnEnable()
  local NetViewBar = _G.NetViewBar

  NetViewBar.fpstext = NetViewBar:CreateFontString(nil, "OVERLAY")
  self:UpdateLayout(true)
  if (not NetView.fpsTimer) or NetView.fpsTimer:IsCancelled() then
    NetView.fpsTimer = NewTicker(1.5, UpdateFPS)
  end
  NetViewBar.fpstext:Show()
end

function FPS:OnDisable()
  local NetViewBar = _G.NetViewBar

  if NetView.fpsTimer then
    NetView.fpsTimer:Cancel()
  end
  NetViewBar.fpstext:Hide()
end

function FPS:UpdateLayout(update)
  local NetViewBar = _G.NetViewBar

  local font = Media and Media:Fetch(Media.MediaType.FONT, db.font) or "Fonts\\FRIZQT__.ttf"
  local size = db.size
  local outline = db.outline
  local shadow = db.shadow and 1 or 0

  NetViewBar.fpstext:SetFont(font, size, outline)
  NetViewBar.fpstext:SetShadowOffset(0, 0)
  NetViewBar.fpstext:SetShadowOffset(shadow, -shadow)
  NetViewBar.fpstext:ClearAllPoints()
  NetViewBar.fpstext:SetPoint(db.anchor, NetViewBar, db.posx, db.posy)

  if update then
    UpdateFPS()
  end
end
