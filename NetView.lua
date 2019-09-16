local addonName, namespace = ...

local NetView = LibStub("AceAddon-3.0"):NewAddon("NetView")
local L = LibStub("AceLocale-3.0"):GetLocale("NetView")
local Media = LibStub("LibSharedMedia-3.0")

local db
local defaults = {
  profile = {
    point = 'CENTER',
	posX = 0,
	posY = 0,
    locked = false,
    clamped = true,
    strata = "MEDIUM",
    width = 200,
    height = 32,
    scale = 1,

    memClrBtn = "LeftButton",
    showGameMenuBtn = "RightButton",
    openOptionsBtn = "MiddleButton",

    backgroundColor = {r = 0, g = 0, b = 0, a = 1},
    backgroundTexture = "Blizzard Tooltip",
    borderColor = {r = 1, g = 1, b = 1, a = 1},
    borderTexture = "Blizzard Tooltip",
    borderSize = 16,
    borderInset = 4,

    modules = {
      ["*"] = true,
    },
  },
}

function NetView:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("NetViewDB", defaults, true)
  db = self.db.profile

  self.db.RegisterCallback(self, "OnProfileChanged", "UpdateLayout")
  self.db.RegisterCallback(self, "OnProfileCopied", "UpdateLayout")
  self.db.RegisterCallback(self, "OnProfileReset", "UpdateLayout")

  SLASH_NetView1 = "/netview"
  SlashCmdList["NetView"] = function()
    if InCombatLockdown() then return end
    self:SetupOptions()
    InterfaceOptionsFrame_OpenToCategory(addonName)
    InterfaceOptionsFrame_OpenToCategory(addonName)
  end
end

function NetView:OnEnable()
  if (not self.frame) then
    self:CreateBar()
  end
  self:UpdateLayout()
  self:UpdateModules()
end

function NetView:OnDisable()
end

function NetView:CreateBar()
  local bg = { 
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
  }

  local f = CreateFrame("Frame", "NetViewBar", UIParent)
  f:SetBackdrop(bg)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if (not db.locked) and (not InCombatLockdown()) then
      self:ClearAllPoints()
      self:StartMoving()
    end
  end)
  f:SetScript("OnDragStop", function(self)
    if (not db.locked) then
      self:StopMovingOrSizing()
      local point, _, _, x, y = self:GetPoint()
      db.point, db.posX, db.posY = point, x, y
    end
  end)
  wipe(bg)

  self.frame = f
end

function NetView:UpdateLayout()
  db = self.db.profile

  self.frame:SetWidth(db.width)
  self.frame:SetHeight(db.height)
  self.frame:SetScale(db.scale)
  self.frame:SetClampedToScreen(db.clamped)
  self.frame:SetFrameStrata(db.strata)

  self.frame:ClearAllPoints()
  self.frame:SetPoint(db.point, UIParent, db.point, db.posX, db.posY)

  local backdrop = self.frame:GetBackdrop()
  backdrop.bgFile = Media and Media:Fetch(Media.MediaType.BACKGROUND, db.backgroundTexture) or 'Interface\\Tooltips\\UI-Tooltip-Background'
  backdrop.edgeFile = Media and Media:Fetch(Media.MediaType.BORDER, db.borderTexture) or 'Interface\\Tooltips\\UI-Tooltip-Border'
  backdrop.edgeSize = db.borderSize
  backdrop.insets.left = db.borderInset
  backdrop.insets.right = db.borderInset
  backdrop.insets.top =  db.borderInset
  backdrop.insets.bottom = db.borderInset

  self.frame:SetBackdrop(backdrop)
  self.frame:SetBackdropBorderColor(db.borderColor.r, db.borderColor.g, db.borderColor.b, db.borderColor.a)
  self.frame:SetBackdropColor(db.backgroundColor.r, db.backgroundColor.g, db.backgroundColor.b, db.backgroundColor.a)

  self.frame:Show()
end

function NetView:GetModuleEnabled(module)
  return db.modules[module]
end

function NetView:SetModuleEnabled(module, value)
  local old = db.modules[module]
  db.modules[module] = value
  if (old ~= value) then
    if value then
      self:EnableModule(module)
    else
      self:DisableModule(module)
    end
  end
end

function NetView:UpdateModules()
  for k,v in self:IterateModules() do
    if self:GetModuleEnabled(k) and not v:IsEnabled() then
      self:EnableModule(k)
    elseif not self:GetModuleEnabled(k) and v:IsEnabled() then
      self:DisableModule(k)
    end
  end
end
