--[[
local tooltip = CreateFrame("GameTooltip")
tooltip:SetOwner(NetViewBar, "ANCHOR_NONE")
]]

local addonName, namespace = ...

local modf, tsort = math.modf, table.sort

local NetView = LibStub("AceAddon-3.0"):GetAddon("NetView")
local Tooltip = NetView:NewModule("Tooltip")
local L = LibStub("AceLocale-3.0"):GetLocale("NetView")
local Media = LibStub("LibSharedMedia-3.0")
local Memory = NetView:GetModule("Memory")
local Print = namespace.Print

local db
local defaults = { 
  profile = {
    enabled = true,
    anchor = "TOPLEFT",
    posx = 0,
    posy = 0,
    accuracy = 1,
    hideInCombat = true,
    showStats = true,
    showTips = true,
    numAddons = 25,
  }
}

function Tooltip:GetOptions()
return {
  order = 1, type = "group",
  name = L["Tooltip"],
  get = function(info)
    local key = info[#info]
    local v = db[key]
    return v
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
          order = 1, type = "toggle",
          width = "full",
          name = L["Show Tooltip"],
          get = function() return NetView:GetModuleEnabled("Tooltip") end,
          set = function(info, value) NetView:SetModuleEnabled("Tooltip", value) end,
        },
      },
    },
    tooltip = {
      order = 2, type = "group", inline = true,
      name = L["Position"],
      args = {
        anchor = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 1, type = "select", values = {
            BOTTOMLEFT  = L["BOTTOMLEFT"],
            BOTTOMRIGHT = L["BOTTOMRIGHT"],
            CURSOR = L["CURSOR"],
            LEFT = L["LEFT"],
            RIGHT = L["RIGHT"],
            TOPLEFT = L["TOPLEFT"],
            TOPRIGHT = L["TOPRIGHT"],
          },
          name = L["Display Anchor"], desc = L["Position to anchor the tooltip display on mouseover"],
          set = function(info, v)
            db.anchor = v
          end,
        },
        posx = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 2, type = "range", min = -100, max = 100, step = 1,
          name = L["X Offset"],
          set = function(info, v)
            db.posx = v
          end,
        },
        posy = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 3, type = "range", min = -100, max = 100, step = 1,
          name = L["Y Offset"],
          set = function(info, v)
            db.posy = v
          end,
        },
      },
    },
    option = {
      order = 3, type = "group", inline = true,
      name = L["Options"],
      args = {
        hideInCombat = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 1, type = "toggle",
          name = L["Hide In Combat"], desc = L["Hide tooltip display when your in combat"],
          set = function(info, v)
            db.hideInCombat = v
          end,
        },
        showStats = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 2, type = "toggle",
          name = L["Show Statistics"], desc = L["Show statistics on the tooltip display"],
          set = function(info, v)
            db.showStats = v
          end,
        },
        showTips = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 3, type = "toggle",
          name = L["Show Tips"], desc = L["Show tips on the tooltip display"],
          set = function(info, v)
            db.showTips = v
          end,
        },
        headerDesc = {
          order = 4, type = "description",
          name = L["Set the number of addons to show on the tooltip display"],
        },
        numAddons = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 5, type = "range", min = 1, max = 50, step = 1,
          name = "",
          set = function(info, v)
            db.numAddons = v
          end,
        },
        headerDescTwo = {
          order = 6, type = "description",
          name = L["Control the accuracy of the number on the tooltip display"],
        },
        accuracy = {
          disabled = function() return (not self:IsEnabled()) end,
          order = 7, type = "range", min = 0, max = 2, step = 1,
          name = "",
          set = function(info, v)
            db.accuracy = v
          end,
        },
      },
    },
  },
}
end

function Tooltip:OnInitialize()
  self:SetEnabledState(NetView:GetModuleEnabled("Tooltip"))

  self.db = NetView.db:RegisterNamespace("Tooltip", defaults)
  db = self.db.profile

  local options = self:GetOptions()
  NetView:RegisterModuleOptions("Tooltip", options, "Tooltip")
end

function Tooltip:OnEnable()
  self:UpdateLayout()
end

function Tooltip:OnDisable()
  NetViewBar:SetScript("OnEnter",nil)
  NetViewBar:SetScript("OnLeave", nil)
  NetViewBar:SetScript("OnMouseUp", nil)
end

local function ColorGradient(perc, ...)
  if (perc > 1) then
    local r, g, b = select(select('#', ...) - 2, ...)
    return r, g, b
  elseif (perc < 0) then
    local r, g, b = ...
    return r, g, b
  end
  local num = select('#', ...) / 3
  local segment, relperc = modf(perc*(num-1))
  local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)
  return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function MemFormat(v, opt)
  if (opt) then
    if (v > 999) then
      return format("|cff00ff00%.1f %s|r", v / 1024, L["MB"])
    else
      return format("|cff00ff00%.0f %s|r", v, L["KB"])
    end
  else
    if (v > 999) then
	  local t = "%%.%df %s"
      local acc = tonumber(db.accuracy) or 1
      t = t:format(acc, L["MB"])
	  return t:format(v / 1024)
    else
	  local t = "%%.%df %s"
      local acc = tonumber(db.accuracy) or 1
      t = t:format(acc, L["KB"])
	  return t:format(v)
    end
  end
end

local function OnEnter(this)
  db = Tooltip.db.profile

  if (not db.enabled) or (db.hideInCombat and InCombatLockdown()) then return end

  local memTbl, sortTbl = {}, {}
  GameTooltip:ClearLines()
  GameTooltip:SetOwner(this, "ANCHOR_"..db.anchor, db.posx, db.posy)

  local total, grandtotal = 0, collectgarbage("count")
  collectgarbage("collect")
  UpdateAddOnMemoryUsage()
  for i=1, GetNumAddOns() do
    local memused = GetAddOnMemoryUsage(i)
    if (memused > 0) then
      total = total + memused
      memTbl[memused] = GetAddOnInfo(i)
      sortTbl[#sortTbl+1] = memused
    end
  end

  tsort(sortTbl, function(a, b) return a > b end)
  for i=1, #sortTbl do
    local val = sortTbl[i]
    local r, g, b = ColorGradient((val/1024), 0, 1, 0, 1, 1, 0, 1, 0, 0)
    GameTooltip:AddDoubleLine(memTbl[val], MemFormat(val, false), 1, 1, 0, r, g, b)
    if (i >= db.numAddons) then break end
  end
  wipe(memTbl)
  wipe(sortTbl)

  if (db.showStats) then
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(format("|cffffffff%s|r", L["Total"]), MemFormat(total, false))
    GameTooltip:AddDoubleLine(format("|cffffffff%s|r", L["Total + Blizzard"]), MemFormat(grandtotal, false))
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(format("|cffffffff%s|r", L["Home Latency"]), select(3, GetNetStats()).." MS")
    GameTooltip:AddDoubleLine(format("|cffffffff%s|r", L["World Latency"]), select(4, GetNetStats()).." MS")
  end
  if (db.showTips) then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(format("|cffffffff%s|r %s", L[NetView.db.profile.memClrBtn], L["to clean memory"]))
    GameTooltip:AddLine(format("|cffffffff%s|r %s", L[NetView.db.profile.showGameMenuBtn], L["to open game menu"]))
    GameTooltip:AddLine(format("|cffffffff%s|r %s", L[NetView.db.profile.openOptionsBtn], L["to open options"]))
  end
  GameTooltip:Show()
end

local function OnLeave(this)
  GameTooltip:Hide()
end

local function OnMouseUp(this, button)
  db = Tooltip.db.profile

  if (button == NetView.db.profile.memClrBtn) then
    if Memory.db.profile.useMemDump then
       Print:prtFrame(Memory.db.profile.memDumpChatFrm, Memory:CleanMemory())
    end
    GameTooltip:Hide()
  elseif (button == NetView.db.profile.showGameMenuBtn) then
    if GameMenuFrame:IsShown() then
      GameMenuFrame:Hide()
    else
      GameMenuFrame:Show()
    end
  elseif (button == NetView.db.profile.openOptionsBtn) then
    NetView:SetupOptions()
    InterfaceOptionsFrame_OpenToCategory("NetView")
    InterfaceOptionsFrame_OpenToCategory("NetView")
  end
end

function Tooltip:UpdateLayout()
  local NetViewBar = _G.NetViewBar

  NetViewBar:SetScript("OnEnter", OnEnter)
  NetViewBar:SetScript("OnLeave", OnLeave)
  NetViewBar:SetScript("OnMouseUp", OnMouseUp)
end
