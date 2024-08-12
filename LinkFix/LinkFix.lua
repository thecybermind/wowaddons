--if true then return end

local function BuildLinkString(...)
  local text = ...;
  if ( not text ) then
    return nil;
  end
  local string = text;
  for i=2, select("#", ...) do
    text = select(i, ...);
    if ( text ) then
      string = string..":"..text;
    end
  end
  return string;
end

local function GetFollowerName(id)
  local t = C_Garrison.GetFollowerInfo(id)
  return t.name or "Unknown Follower"
end

local function GetFollowerColor(quality)
  local _, _, _, color = GetItemQualityColor(quality)
  return color or "ffffffff"
end

local frame = CreateFrame("Frame")

local function chatfilter(self, event, msg, ...)
  if not msg:find("garrfollower") then return false end
 
  local function fixlink(link)
    local _, color, linkstring = strsplit("|", link)
    local _,id,quality,lvl,ilvl,a1,a2,a3,a4,t1,t2,t3,t4 = strsplit(":", linkstring)
    if tonumber(quality) > 4 then quality = "4" end

    ----|cffffffff|Hgarrfollower:179:5:100:600:0:0:0:0:0:0:0:0|h[|T"..text..":0|t]|h|r
    local replace = "|c"..GetFollowerColor(quality)
    replace = replace.."|H"..BuildLinkString("garrfollower",id,quality,lvl,ilvl,a1,a2,a3,a4,t1,t2,t3,t4).."|h"
    replace = replace.."["..GetFollowerName(id).."]|h|r"
    return replace
  end
  
  msg = msg:gsub("(|c.*|r)", fixlink)
  
  return false, msg, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", chatfilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", chatfilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", chatfilter)

