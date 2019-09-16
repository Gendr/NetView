local addonName, namespace = ...

local NetView = LibStub("AceAddon-3.0"):GetAddon("NetView")
local L = LibStub("AceLocale-3.0"):GetLocale("NetView")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local buttonTbl = {
  None = L["None"],
  LeftButton = L["LeftButton"],
  MiddleButton = L["MiddleButton"],
  RightButton = L["RightButton"],
  Button4 = L["Mouse Button %d"]:format(4),
  Button5 = L["Mouse Button %d"]:format(5),
  Button6 = L["Mouse Button %d"]:format(6),
  Button7 = L["Mouse Button %d"]:format(7),
  Button8 = L["Mouse Button %d"]:format(8),
  Button9 = L["Mouse Button %d"]:format(9),
  Button10 = L["Mouse Button %d"]:format(10),
  Button11 = L["Mouse Button %d"]:format(11),
  Button12 = L["Mouse Button %d"]:format(12),
  Button13 = L["Mouse Button %d"]:format(13),
  Button14 = L["Mouse Button %d"]:format(14),
  Button15 = L["Mouse Button %d"]:format(15),
}

local run_once
local moduleOptions = {}
local options = nil
local function SetupOptions()
  if (not options) then
    options = {
      type = "group",
      name = "NetView",
      args = {
        info = {
          order = 1, type = "group", inline = true,
          name = L["Info"],
          args = {
            version = {
              order = 1, type = "description",
              name = format("v%.1f", GetAddOnMetadata(addonName, "Version")),
            },
            reset = {
              order = 2, type = "execute", func = function() wipe(NetViewDB); ReloadUI() end, confirm = true,
              name = L["Reset"],
              desc = format("|cffff0000%s", L["This will wipe all settings and reload the user interface"]),
            },
            spacer = {
              order = 2.5, type = "description",
              name = "",
            },
            feedback = {
              order = 3, type = "input", width = "double",
              name = L["Feedback"],
              get = function() return "https://github.com/Gendr/NetView/issues" end,
            },
          },
        },
        frame = {
          order = 2, type = "group",
          name = L["Layout Frame"],
          get = function(info)
            local key = info[#info]
            local v = NetView.db.profile[key]
            return v
          end,
          set = function(info, v)
            local key = info[#info]
            NetView.db.profile[key] = v
          end,
          args = {
            bar = {
              order = 1, type = "group", inline = true,
              name = L["Bar"],
              args = {
                locked = {
                  order = 1, type = "toggle",
                  name = function()
				    if NetView.db.profile.locked then
					  return L["Unlock Bar"]
                    else
					  return L["Lock Bar"]
					end
			      end,
                  set = function(info, v)
                    NetView.db.profile.locked = v
                    local point, _, _, x, y = NetViewBar:GetPoint()
                    NetView.db.point, NetView.db.posX, NetView.db.posY = point, x, y
                  end,
                },
                clamped = {
                  order = 2, type = "toggle",
                  name = function()
				    if NetView.db.profile.clamped then
					  return L["Clamped To Screen"]
                    else
					  return L["Clamp To Screen"]
					end
			      end,
                  set = function(info, v)
                    NetView.db.profile.clamped = v
                    NetView:UpdateLayout()
                  end,
                },
                strata = {
                  order = 3, type = "select", values = {
                    BACKGROUND = L["BACKGROUND"],
                    LOW = L["LOW"],
                    MEDIUM = L["MEDIUM"],
                    HIGH = L["HIGH"],
                    DIALOG = L["DIALOG"],
                    FULLSCREEN = L["FULLSCREEN"],
                    FULLSCREEN_DIALOG = L["FULLSCREEN_DIALOG"],
                    TOOLTIP = L["TOOLTIP"],
                  },
                  name = L["Bar Strata"],
                  set = function(info, v)
                    NetView.db.profile.strata = v
                    NetView:UpdateLayout()
                  end,
                },
                width = {
                  order = 5, type = "range", min = 10, max = 600, step = 1,
                  name = L["Width"],
                  set = function(info, v)
                    NetView.db.profile.width = v
                    NetView:UpdateLayout()
                  end,
                },
                height = {
                  order = 6, type = "range", min = 10, max = 200, step = 1,
                  name = L["Height"],
                  set = function(info, v)
                    NetView.db.profile.height = v
                    NetView:UpdateLayout()
                  end,
                },
                scale = {
                  order = 7, type = "range", min = 0.1, max = 2.0, step = 0.05,
                  name = L["Scale"],
                  set = function(info, v)
                    NetView.db.profile.scale = v
                    NetView:UpdateLayout()
                  end,
                },
                spacer = {
                  order = 8, type = "description",
                  name = '\n',
                },
                headerDesc = {
                  order = 9, type = "description",
                  name = L["Set what the different clicks do"],
                },
                memClrBtn = {
                  order = 10, type = "select", values = buttonTbl,
                  name = L["Memory Clear"],
                  set = function(info, v)
                    NetView.db.profile.memClrBtn = v
                  end,
                },
                showGameMenuBtn = {
                  order = 11, type = "select", values = buttonTbl,
                  name = L["Show Game Menu"],
                  set = function(info, v)
                    NetView.db.profile.showGameMenuBtn = v
                  end,
                },
                openOptionsBtn = {
                  order = 12, type = "select", values = buttonTbl,
                  name = L["Open Options"],
                  set = function(info, v)
                    NetView.db.profile.openOptionsBtn = v
                  end,
                },
              },
            },
          },
        },
        layout = {
          order = 3, type = "group",
          name = L["Layout Background"],
          get = function(info)
            local key = info[#info]
            local v = NetView.db.profile[key]
            if (type(v) == "table" and v.r and v.g and v.b and v.a) then
              return v.r, v.g, v.b, v.a
            else
              return v
            end
          end,
          set = function(info, v)
            local key = info[#info]
            NetView.db.profile[key] = v
          end,
          args = {
            background = {
              order = 1, type = "group", inline = true,
              name = L["Background"],
              args = {
                backgroundColor = {
                  order = 1, type = "color", hasAlpha = true,
                  name = L["Background Color"],
                  set = function(info, r, g, b, a)
                    local color = NetView.db.profile.backgroundColor
                    color.r, color.g, color.b, color.a = r, g, b, a
                    NetView:UpdateLayout()
                  end,
                },
                backgroundTexture = {
                  order = 2, type = "select",
                  dialogControl = "LSM30_Background", values = Media:HashTable("background"),
                  name = L["Background Texture"],
                  set = function(info, v)
                    NetView.db.profile.backgroundTexture = v
                    NetView:UpdateLayout()
                  end,
                },
              },
            },
            border = {
              order = 2, type = "group", inline = true,
              name = L["Border"],
              args = {
                borderColor = {
                  order = 1, type = "color", hasAlpha = true,
                  name = L["Border Color"],
                  set = function(info, r, g, b, a)
                    local color = NetView.db.profile.borderColor
                    color.r, color.g, color.b, color.a = r, g, b, a
                    NetView:UpdateLayout()
                  end,
                },
                borderTexture = {
                  order = 2, type = "select",
                  dialogControl = "LSM30_Border", values = Media:HashTable("border"),
                  name = L["Border Texture"],
                  set = function(info, v)
                    NetView.db.profile.borderTexture = v
                    NetView:UpdateLayout()
                  end,
                },
                borderSize = {
                  order = 3, type = "range", min = 1, max = 64, step = 1,
                  width = 1.4,
                  name = L["Border Size"],
                  set = function(info, v)
                    NetView.db.profile.borderSize = v
                    NetView:UpdateLayout()
                  end,
                },
                borderInset = {
                  order = 4, type = "range", min = 0, max = 32, step = 1,
                  width = 1.4,
                  name = L["Border Inset"],
                  set = function(info, v)
                    NetView.db.profile.borderInset = v
                    NetView:UpdateLayout()
                  end,
                },
              },
            },
          },
        },
      },
    }
    for k,v in pairs(moduleOptions) do
      options.args[k] = type(v) == "function" and v() or v
	  options.args[k].order = -2
    end
    options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(NetView.db)
	options.args.profiles.order = -1
  end
  return options
end

function NetView:SetupOptions()
  if (not run_once) then
    ACR:RegisterOptionsTable("NetView", SetupOptions)
    ACD:AddToBlizOptions("NetView", "NetView")
    run_once = true
  end
end

function NetView:RegisterModuleOptions(name, optionTbl, displayName)
  moduleOptions[name] = optionTbl
end
