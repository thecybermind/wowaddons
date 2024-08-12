-- don't load if player isn't a hunter
local _, myclass = UnitClass("player")
if myclass ~= "HUNTER" then return end

HandyNotes_EagleFlightNetwork = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_EagleFlightNetwork", "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes", true)
if not HandyNotes then return end

--HandyNotes_EagleFlightNetwork = HandyNotes:NewModule("HandyNotes_EagleFlightNetwork", "AceConsole-3.0", "AceEvent-3.0")
local db
local iconDefault = "Interface\\Addons\\HandyNotes_EagleFlightNetwork\\greenboot.tga"
local textDefault = "Eagle Flight Network"

HandyNotes_EagleFlightNetwork.nodes = {}
local nodes = HandyNotes_EagleFlightNetwork.nodes

nodes["Azsuna"] = {
  [51007960] = { "Isle of Watchers, Azsuna", textDefault },
  [24404260] = { "Faronaar, Azsuna", textDefault },
}
nodes["Valsharah"] = {
  [44001510] = { "The Dreamgrove, Val'Sharah", textDefault },
}
nodes["Highmountain"] = {
  [33904950] = { "Trueshot Lodge, Highmountain", textDefault },
  [56406750] = { "Eastern Highmountain, Highmountain", textDefault },
}
nodes["TrueshotLodge"] = {
  [39202800] = { "Trueshot Lodge, Highmountain", textDefault },
}
nodes["Stormheim"] = {
  [45903550] = { "Nastrondir, Stormheim", textDefault },
  [37907920] = { "Thorim's Peak, Stormheim", textDefault },
}
nodes["Suramar"] = {
  [70007070] = { "Eastern Suramar, Suramar", textDefault },
  [41208260] = { "Western Suramar, Suramar", textDefault },
}

function HandyNotes_EagleFlightNetwork:OnEnter(mapFile, coord)
  if (not nodes[mapFile][coord]) then return end

  local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
  if ( self:GetCenter() > UIParent:GetCenter() ) then
    tooltip:SetOwner(self, "ANCHOR_LEFT")
  else
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
  end

  local text = nodes[mapFile][coord][1] or textDefault
  tooltip:SetText(text)
  local text2 = nodes[mapFile][coord][2] or textDefault
  tooltip:AddLine(text2, nil, nil, nil, true)
  tooltip:Show()
end

function HandyNotes_EagleFlightNetwork:OnLeave(mapFile, coord)
  if self:GetParent() == WorldMapButton then
    WorldMapTooltip:Hide()
  else
    GameTooltip:Hide()
  end
end

local options = {
  type = "group",
  name = "HandyNotes_EagleFlightNetwork",
  desc = "Locations of RareElites on Timeless Isle.",
  get = function(info) return db[info.arg] end,
  set = function(info, v) db[info.arg] = v; HandyNotes_EagleFlightNetwork:Refresh() end,
  args = {
    desc = {
      name = "These settings control the look and feel of the icon.",
      type = "description",
      order = 0,
    },
    icon_scale = {
      type = "range",
      name = "Icon Scale",
      desc = "The scale of the icons",
      min = 0.25, max = 3, step = 0.01,
      arg = "icon_scale",
      order = 10,
    },
    icon_alpha = {
      type = "range",
      name = "Icon Alpha",
      desc = "The alpha transparency of the icons",
      min = 0, max = 1, step = 0.01,
      arg = "icon_alpha",
      order = 20,
    },
    trueshotlodge = {
      type = "toggle",
      arg = "trueshotlodge",
      name = "Trueshot Lodge",
      desc = "Show Trueshot Lodge flight path icon",
      order = 30,
      width = "normal",
    },
    showonminimap = {
      type = "toggle",
      arg = "showonminimap",
      name = "Show on Minimap",
      desc = "Show icons on minimap in addition to world map",
      order = 30,
      width = "normal",
    },
  },
}

function HandyNotes_EagleFlightNetwork:OnInitialize()
  local defaults = {
    profile = {
      icon_scale = 1.0,
      icon_alpha = 1.0,
      trueshotlodge = false,
      showonminimap = false,
    },
  }

  db = LibStub("AceDB-3.0"):New("HandyNotes_EagleFlightNetworkDB", defaults, true).profile
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "WorldEnter")
end

function HandyNotes_EagleFlightNetwork:WorldEnter()
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  self:ScheduleTimer("RegisterWithHandyNotes", 10)
end

function HandyNotes_EagleFlightNetwork:RegisterWithHandyNotes()
  do
    local function iter(t, prestate)
      if not t then return nil end
      local state, value = next(t, prestate)
      while state do
        if (value[1]) and (state ~= 33904950 or db.trueshotlodge) then
          local icon = value[3] or iconDefault
          return state, nil, icon, db.icon_scale * 2.33, db.icon_alpha
        end
        state, value = next(t, state)
      end
    end
    function HandyNotes_EagleFlightNetwork:GetNodes(mapFile, isMinimapUpdate, dungeonLevel)
      if isMinimapUpdate and not db.showonminimap then return function() end end
      return iter, nodes[mapFile], nil
    end
  end
  HandyNotes:RegisterPluginDB("HandyNotes_EagleFlightNetwork", self, options)
end
 

function HandyNotes_EagleFlightNetwork:Refresh()
  self:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes_EagleFlightNetwork")
end