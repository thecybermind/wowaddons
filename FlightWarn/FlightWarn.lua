-- FlightWarn v1.4.3

-- v1.4.3
-- * TOC
-- * removed GetUnitPitch checks
-- * changed GetRealSpeed for better speed results while in a vehicle, possession, or taxi
-- v1.4.2
-- * now saves profile data
-- v1.4.1
-- * wrong TOC
-- v1.4
-- * TOC bump
-- v1.3.2
-- * TOC bump
-- v1.3
-- * TOC bump
-- v1.2
-- * Added "Play" button next to sound inputs
-- * Further clarified options
-- v1.1
-- * Clarified options on config screen
-- v1.0
-- * Initial release

FlightWarn = LibStub("AceAddon-3.0"):NewAddon("FlightWarn", "AceConsole-3.0")
FlightWarn.version = GetAddOnMetadata("FlightWarn", "Version")
FlightWarn.date = "2016-10-26"

local options = {
  name = "FlightWarn",
  type = "group",
  get = function(info) return FlightWarn.db.profile[info[#info]] end,
  set = function(info, value) FlightWarn.db.profile[info[#info]] = value end,

  args = {
    General = {
      order = 1,
      type = "group",
      name = "General Settings",
      desc = "General Settings",
      args = {
        desc = {
          type = "description",
          order = 1,
          name = "Addon that plays sounds upon flying too long while alt-tabbed",
        },
        hdr1 = {
          type = "header",
          name = "Straight-line",
          order = 2,
        },
        enableStraightLine = {
          type = "toggle",
          order = 3,
          width = "full",
          name = "Enabled",
          desc = "Enables/disables playing a sound when you've been flying in a straight line for too long",
        },
        delayStraightLine = {
          type = "range",
          width = "full",
          order = 4,
          min = 5,
          max = 180,
          step = 5,
          name = "Delay (sec)",
          desc = "Length of time (in seconds) to fly in a straight line before playing sound",
        },
        soundStraightLine = {
          type = "input",
          order = 5,
          width = "double",
          name = "Pick Sound",
          desc = "Sound file or in-game sound name (http://wowpedia.org/API_PlaySound)",
        },
        playStraightLine = {
          type = "execute",
          order = 6,
          name = "Play",
          width = "half",
          func = function() FlightWarn_PlaySoundHelper(FlightWarn.db.profile.soundStraightLine, "Master") end
        },
        hdr2 = {
          type = "header",
          name = "Fatigue",
          order = 10,
        },
        enableFatigue = {
          type = "toggle",
          order = 11,
          width = "full",
          name = "Enabled",
          desc = "Enables/disables playing a sound when you've been flying into fatigue for too long",
        },
        delayFatigue = {
          type = "range",
          order = 12,
          width = "full",
          min = 1,
          max = 59,
          step = 1,
          name = "Delay (sec)",
          desc = "Length of time (in seconds) to fly into fatigue before playing sound",
        },
        repeatFatigue = {
          type = "range",
          order = 13,
          width = "full",
          min = 1,
          max = 59,
          step = 1,
          name = "Repeat Delay (sec)",
          desc = "Length of time (in seconds) to wait before repeating fatigue warning",
        },
        soundFatigue = {
          type = "input",
          order = 14,
          width = "double",
          name = "Pick Sound",
          desc = "Sound file or in-game sound name (http://wowpedia.org/API_PlaySound)",
        },
        playFatigue = {
          type = "execute",
          order = 15,
          name = "Play",
          width = "half",
          func = function() FlightWarn_PlaySoundHelper(FlightWarn.db.profile.soundFatigue, "Master") end
        },
      },
    },
  },
}
FlightWarn.Options = options
local defaults = {
  profile =  {
    enableStraightLine = true,
    delayStraightLine = 60,
    soundStraightLine = "Interface\\AddOns\\FlightWarn\\Sounds\\blip_8.ogg",
    enableFatigue = true,
    delayFatigue = 5,
    repeatFatigue = 10,
    soundFatigue = "Interface\\AddOns\\FlightWarn\\Sounds\\alarmclockbeeps.ogg",
  },
}

-- function to call appropriately PlaySound* function based on sound string
function FlightWarn_PlaySoundHelper(sound, channel)
  local soundlc = strlower(sound)
  
  if ((string.sub(soundlc, -4) == ".wav") or (string.sub(soundlc, -4) == ".mp3") or (string.sub(soundlc, -4) == ".ogg")) then
    PlaySoundFile(sound, channel)
  else
    PlaySound(sound, channel)
  end
end

local function GetRealSpeed()
  local p = "player"
  if IsPossessBarVisible() then p = "pet" end
  if UnitUsingVehicle("player") or UnitHasVehicleUI("player") then p = "vehicle" end

  return floor((GetUnitSpeed(p) * 100 / BASE_MOVEMENT_SPEED) + 0.5)
end

local startFlightTime = nil
local previousAngle = nil
local previousSpeed = nil
local flightFatigueTimer = nil
local lastFatigueWarn = nil
FlightWarn.frame = CreateFrame("Frame")
FlightWarn.frame:HookScript("OnUpdate", function(self, time)
  --user is flying and moving
  if IsFlying() and GetRealSpeed() > 0 then
    --user was not flying last update
    if not startFlightTime then
      startFlightTime = GetTime()
      previousAngle = GetPlayerFacing()
      previousSpeed = GetRealSpeed()
    --user was flying before
    else
      local newAngle = GetPlayerFacing()
      local newSpeed = GetRealSpeed()
      --user is facing different direction, reset start time
      if newAngle ~= previousAngle or newSpeed ~= previousSpeed then
        startFlightTime = GetTime()
      end
      previousAngle = newAngle
      previousSpeed = newSpeed

      local exhaustionName, _, _, exhaustionScale = GetMirrorTimerInfo(1)
      local exhaustionTime = GetMirrorTimerProgress("EXHAUSTION")
      --if player has been flying into fatigue for 5s, play sound     
      if exhaustionName == "EXHAUSTION" and exhaustionScale == -1 and exhaustionTime > 0 and exhaustionTime < (60000 - (FlightWarn.db.profile.delayFatigue * 1000)) then
        --repeat warning every 10s
        if not lastFatigueWarn or GetTime() - lastFatigueWarn >= FlightWarn.db.profile.repeatFatigue then
          if FlightWarn.db.profile.enableFatigue then
            FlightWarn_PlaySoundHelper(FlightWarn.db.profile.soundFatigue, "Master")
            print("You have been flying into fatigue for at least "..FlightWarn.db.profile.delayFatigue.." seconds!")
          end
          lastFatigueWarn = GetTime()
        end
      end

      --if player has been flying same direction for a minute, play sound
      if GetTime() - startFlightTime >= FlightWarn.db.profile.delayStraightLine then
        if FlightWarn.db.profile.enableStraightLine then
          FlightWarn_PlaySoundHelper(FlightWarn.db.profile.soundStraightLine, "Master")
          print("You have been flying in a straight line for "..FlightWarn.db.profile.delayStraightLine.." seconds!")
        end

        --reset timer
        startFlightTime = GetTime()
      end
    end
  --user is not flying, clear flying time
  elseif startFlightTime then
    startFlightTime = nil
    previousAngle = nil
    previousSpeed = nil
  end
end)

function FlightWarn:OnInitialize()
  FlightWarn.OptionsFrames = {}

  FlightWarn.db = LibStub("AceDB-3.0"):New("FlightWarnDB", defaults, "Default")
  options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(FlightWarn.db)
  options.args.Profiles.cmdHidden = true
  options.args.Profiles.order = -1

  LibStub("AceConfig-3.0"):RegisterOptionsTable("FlightWarn", options)

  FlightWarn.OptionsFrames.General = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FlightWarn", nil, nil, "General")
  FlightWarn.OptionsFrames.Profiles = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FlightWarn", "Profiles", "FlightWarn", "Profiles")
end
