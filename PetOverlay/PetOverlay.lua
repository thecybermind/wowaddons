--PetOverlay v2.2.1

--v2.2.1
-- wrong TOC version
--v2.2
-- TOC bump
--v2.1-beta1
-- re-added support for Bartender4 (haven't tested)
-- TOC bump
--v2.0
-- added #petstance support
--v1.9
-- TOC bump
-- Minor housecleaning
--v1.8
-- Fixed a possible taint issue
-- Cleaned up code
--v1.7
-- Bumped TOC for wow 5.0.5
--v1.6
-- Bumped TOC for wow 4.3
--v1.5.3
-- Bumped TOC
-- Changed GetSpellName -> GetSpellBookItemName
--v1.5.2
-- Bumped TOC for 3.3.0
--v1.5.1
-- Added a list of action buttons that use a pet macro and only updates those buttons (instead of all of them)
--v1.4
-- Added support for macro modifiers with the #pet command
--v1.3
-- Added support for nUI bars and bartender4
-- Updated toc for patch 3.2
--v1.2
-- Now utilizes WoW API for autocast overlay
--v1.1
-- Modified texture system to work on any button
--v1.0
-- Original macro code by Xelron @ Feathermoon ( http://forums.worldofwarcraft.com/thread.html?topicId=10971909982&postId=109708938639 )
-- Fixed and converted to addon by Cybermind @ Stormrage
-- Sparkle code (to replace non-existent autocast overlay) from VendorBait by Tekkub @ http://tekkub.net/addons/VendorBait


-- our frame
local PetOverlay_Frame = CreateFrame("Frame")


-- list of action buttons that contain pet macros
local pet_macro_list = {}
-- list of action buttons that contain pet stance macros
local petstance_macro_list = {}


-- pet stance textures
local stancetextures = {
  [PET_MODE_AGGRESSIVE] = PET_AGGRESSIVE_TEXTURE,
  [PET_MODE_ASSIST] = PET_ASSIST_TEXTURE,
  [PET_MODE_DEFENSIVE] = PET_DEFENSIVE_TEXTURE,
  [PET_MODE_PASSIVE] = PET_PASSIVE_TEXTURE,
  [PET_ACTION_ATTACK] = PET_ATTACK_TEXTURE,
  [PET_ACTION_FOLLOW] = PET_FOLLOW_TEXTURE,
  [PET_ACTION_MOVE_TO] = PET_MOVE_TO_TEXTURE,
  [PET_ACTION_WAIT] = PET_WAIT_TEXTURE,
}


-- ShowAutocastOverlay
--
-- shows/hides the 2 components of autocast overlays
--
-- button:       an individual action button object
-- autocastable: should autocastable corners be displayed?
-- enabled:      should autocast shine be displayed?
local function ShowAutocastOverlay(button, autocastable, enabled)
  if not button then return end
  
  -- if allowed to autocast (meaning pet), show corners
  if autocastable then
    button.corners = button.corners or PetOverlay_GetAutoCastableCorners()
    button.corners:SetParent(button)
    button.corners:SetPoint("CENTER", button, "CENTER")
    button.corners:Show()
  else
    PetOverlay_ReleaseAutoCastableCorners(button.corners)
    button.corners = nil
  end

  -- if autocast is enabled, show overlay sparkle textures
  if enabled then
    button.shine = button.shine or SpellBook_GetAutoCastShine()
    button.shine:SetParent(button)
    button.shine:SetPoint("CENTER", button, "CENTER")
    button.shine:Show()
    AutoCastShine_AutoCastStart(button.shine)
  else
    SpellBook_ReleaseAutoCastShine(button.shine)
    button.shine = nil
  end
end


-- PetOverlay_ActionButton_SetTooltip
--
-- show proper stance tooltip for stance macros
--
-- button:  an individual action button object
local function PetOverlay_ActionButton_SetTooltip(button)
  -- if not currently a stance macro, cancel
  local buttonname = button:GetName()
  if not petstance_macro_list[buttonname] then return end
  
  GameTooltip:ClearLines()
  
  -- are we supposed to be showing a stance?
  local slot = button.stanceslot
  if slot then
    -- show matching spellbook slot tooltip
    button.UpdateTooltip = GameTooltip:SetSpellBookItem(slot, BOOKTYPE_PET) and ActionButton_SetTooltip or nil
  else    
    -- no stance now, show macro name tooltip
    local _, actioninfo = GetActionInfo(button.action)
    button.UpdateTooltip = GameTooltip:SetText(GetMacroInfo(actioninfo), 1.0, 1.0, 1.0) and ActionButton_SetTooltip or nil
  end
end


-- PetOverlay_ActionButton_Update
--
-- called after ActionButton_Update, this is where we show/hide the overlays
--
-- this should now work for any button that uses the default ActionButton_Update function
--
-- button:  an individual action button object
local function PetOverlay_ActionButton_Update(button)
  if not button then return end
  
  local action = button.action  
  local actiontype, actioninfo = GetActionInfo(action)
  
  local buttonname = button:GetName()

  -- hide and don't bookmark by default
  pet_macro_list[buttonname] = nil
  petstance_macro_list[buttonname] = nil
  
  -- if this button is a macro
  if HasAction(action) and actiontype == "macro" then
    local found1, _, str1 = string.find(GetMacroBody(actioninfo), "#pet ([^\n]*)")
    local found2, _, str2 = string.find(GetMacroBody(actioninfo), "#petstance ([^\n]*)")
    
    -- check for "#pet" line in macro
    if found1 then
      local str = SecureCmdOptionParse(str1)
      
      local slot = PetOverlay_GetPetSpellIndex(str)
      ShowAutocastOverlay(button, GetSpellAutocast(slot, BOOKTYPE_PET))
      
      -- bookmark for updates
      pet_macro_list[buttonname] = true

    -- check for "#petstance" line in macro
    elseif found2 then
      local str = SecureCmdOptionParse(str2)
      
      local slot = PetOverlay_GetPetSpellIndex(str)
      button:SetChecked(IsSelectedSpellBookItem(slot or 0, BOOKTYPE_PET))  --IsSelectedSpellBookItem silently fails with 0, but not nil
      
      -- change macro's texture to stance's texture (or "?")
      local texture = slot and stancetextures[str] or "Interface/Icons/INV_MISC_QUESTIONMARK"
      button.icon:SetTexture(texture)
      button.stanceslot = slot  -- saved for tooltip function
      
      -- hide green equipped item border
      if button.Border then button.Border:Hide() end
      
      -- bookmark for updates
      petstance_macro_list[buttonname] = true
    end
  end
  
  if not pet_macro_list[buttonname] then
    ShowAutocastOverlay(button, false, false)
  end
  
  if not petstance_macro_list[buttonname] then
    button:SetChecked(nil)
    button.stanceslot = nil
  end
end


-- PetOverlay_GetPetSpellIndex
--
-- helper function to get spell id for a pet spell name
--
-- s:       string corresponding to a pet spell name
-- returns: spell id
function PetOverlay_GetPetSpellIndex(spellName)
  if not spellName or spellName == "" then return end
  local i = 1

  while true do
    local spellBookName = GetSpellBookItemName(i, BOOKTYPE_PET)
    if not spellBookName then
      return
    elseif spellName == spellBookName then
      return i
    end

    i = i + 1
  end
end


-- used by PetOverlay_GetAutoCastableCorners and PetOverlay_ReleaseAutoCastableCorners
local PetOverlay_maxCorners = 1
local PetOverlay_cornersGet = {}

-- PetOverlay_GetAutoCastableCorners
--
-- helper function to get a corner texture
-- (modeled after SpellBook_GetAutoCastShine)
--
-- returns: a "new" corners texture
function PetOverlay_GetAutoCastableCorners()
  local corners = PetOverlay_cornersGet[1]
  
  if (corners) then
    tremove(PetOverlay_cornersGet, 1)
  else
    corners = PetOverlay_Frame:CreateTexture("AutocastableCorners"..PetOverlay_maxCorners, "OVERLAY")
    corners:SetTexture("Interface/Buttons/UI-AutoCastableOverlay")
    corners:SetWidth(58)
    corners:SetHeight(58)
    PetOverlay_maxCorners = PetOverlay_maxCorners + 1
  end
  
  return corners
end


-- PetOverlay_ReleaseAutoCastableCorners
--
-- helper function to release a corner texture
-- (modeled after SpellBook_ReleaseAutoCastShine)
function PetOverlay_ReleaseAutoCastableCorners(corners)
  if (not corners) then
    return
  end
  
  corners:Hide()
  tinsert(PetOverlay_cornersGet, corners)
end


-- register an event handler to update whenever pet spells change
PetOverlay_Frame:SetScript("OnEvent", function(self, event, arg1)
  -- if actionbutton changes, update Bartender4 buttons
  -- this will also save them in our list for later when PET_BAR_UPDATE fires
  if event == "ACTIONBAR_SLOT_CHANGED" then
    -- 0 for arg1 means all buttons changed
    if arg1 == 0 then
      for i = 1, 120 do
        local btn = "BT4Button"..i
        if _G[btn] then PetOverlay_ActionButton_Update(_G[btn]) end
      end
    -- otherwise just a single button
    else
      local btn = "BT4Button"..arg1
      if _G[btn] then PetOverlay_ActionButton_Update(_G[btn]) end
    end
    return
  end
  
  -- update #pet macro buttons
  for i,_ in pairs(pet_macro_list) do
    PetOverlay_ActionButton_Update(_G[i])
  end
  -- update #petstance macro buttons
  for i,_ in pairs(petstance_macro_list) do
    PetOverlay_ActionButton_Update(_G[i])
  end
end)
PetOverlay_Frame:RegisterEvent("PET_BAR_UPDATE")
PetOverlay_Frame:RegisterEvent("UNIT_PET")
-- only register this event if Bartender4 is loaded
if Bartender4 then PetOverlay_Frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED") end


-- also update stance macros regularly
local total = 0
PetOverlay_Frame:SetScript("OnUpdate", function(self, elapsed)
  total = total + elapsed
  if total > 0.1 then
    for i,_ in pairs(petstance_macro_list) do
      PetOverlay_ActionButton_Update(_G[i])
    end
    total = 0
  end
end)


-- register a hook for the action button update function
hooksecurefunc("ActionButton_Update", PetOverlay_ActionButton_Update)
-- show proper tooltip when hovering over a pet stance macro
hooksecurefunc("ActionButton_SetTooltip", PetOverlay_ActionButton_SetTooltip)

