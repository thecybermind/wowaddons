local addonName, ns = ...
local L = ns.L

-- don't load if player isn't a hunter
local _, myclass = UnitClass("player")
if myclass ~= "HUNTER" then return end

-- maps pet family icons to english pet family names (eliminates need for translations)
local petIconMap = {
  [236195] = "Aqiri",
  [877476] = "Basilisk",
  [132182] = "Bat",
  [132183] = "Bear",
  [133570] = "Beetle",
  [132192] = "Bird of Prey",
  [1687702] = "Blood Beast",
  [132184] = "Boar",
  [454771] = "Camel",
  [2011146] = "Carapid",
  [132200] = "Carrion Bird",
  [132185] = "Cat",
  [236190] = "Chimaera",
  [1044794] = "Clefthoof",
  [236191] = "Core Hound",
  [2143073] = "Courser",
  [132186] = "Crab",
  [877479] = "Crane",
  [132187] = "Crocolisk",
  [236192] = "Devilsaur",
  [877480] = "Direhorn",
  [132188] = "Dragonhawk",
  [929300] = "Feathermane",
  [458223] = "Fox",
  [132189] = "Gorilla",
  [877477] = "Gruffhorn",
  [877481] = "Hound",
  [463493] = "Hydra",
  [132190] = "Hyena",
  [2027936] = "Lizard",
  [132254] = "Mammoth",
  [132247] = "Mechanical",
  [877482] = "Monkey",
  [236193] = "Moth",
  [616693] = "Oxen",
  [1624590] = "Pterrordax",
  [132193] = "Raptor",
  [132194] = "Ravager",
  [132191] = "Ray",
  [1044490] = "Riverbeast",
  [644001] = "Rodent",
  [646378] = "Scalehide",
  [132195] = "Scorpid",
  [136040] = "Serpent",
  [877478] = "Shale Beast",
  [132196] = "Spider",
  [236165] = "Spirit Beast",
  [132197] = "Sporebat",
  [1044501] = "Stag",
  [625905] = "Stone Hound",
  [132198] = "Tallstrider",
  [804969] = "Toad",
  [132199] = "Turtle",
  [132201] = "Warp Stalker",
  [236196] = "Wasp",
  [643423] = "Water Strider",
  [132202] = "Wind Serpent",
  [132203] = "Wolf",
  [236197] = "Worm",
}

-- which classes are exotic-only
local exotics = {
  ["Aqiri"] = L["+30% Movement"],
  ["Carapid"] = L["Physical Damage Reduction"],
  ["Chimaera"] = L["AOE"],
  ["Clefthoof"] = L["Armor & +Healing"],
  ["Core Hound"] = L["Thorns"],
  ["Devilsaur"] = L["Feast (Heal)"],
  ["Feathermane"] = L["Slow Fall"],
  ["Pterrordax"] = L["Unknown"],
  ["Shale Beast"] = L["Magic Damage Reduction"],
  ["Spirit Beast"] = L["Heal"],
  ["Stone Hound"] = L["Self Res"],
  ["Water Strider"] = L["Waterwalking"],
  ["Worm"] = L["AOE"],
}

-- what passives/abilities each family has
local buffs = {
  ["Aqiri"] = L["Wing Clip"],
  ["Basilisk"] = L["Wing Clip"],
  ["Bat"] = L["Self-Cleanse"],
  ["Bear"] = L["Low HP Shield Wall"],
  ["Beetle"] = L["Shield Wall"],
  ["Bird of Prey"] = L["Wing Clip"],
  ["Boar"] = L["Shield Wall"],
  ["Camel"] = L["Low HP Shield Wall"],
  ["Carapid"] = L["Low HP Shield Wall"],
  ["Cat"] = L["Prowl"]..", "..L["Dodge"],
  ["Carrion Bird"] = L["Mortal Strike"],
  ["Chimaera"] = L["Wing Clip"],
  ["Clefthoof"] = L["Low HP Shield Wall"],
  ["Core Hound"] = L["Shield Wall"],
  ["Courser"] = L["Dodge"],
  ["Crab"] = L["Wing Clip"],
  ["Crane"] = L["Self-Cleanse"],
  ["Crocolisk"] = L["Wing Clip"],
  ["Devilsaur"] = L["Mortal Strike"],
  ["Direhorn"] = L["Mortal Strike"],
  ["Dragonhawk"] = L["Dodge"],
  ["Feathermane"] = L["Dodge"],
  ["Fox"] = L["Dodge"],
  ["Gorilla"] = L["Low HP Shield Wall"],
  ["Gruffhorn"] = L["Low HP Shield Wall"],
  ["Hound"] = L["Wing Clip"],
  ["Hydra"] = L["Mortal Strike"],
  ["Hyena"] = L["Mortal Strike"],
  ["Lizard"] = L["Mortal Strike"],
  ["Mammoth"] = L["Wing Clip"],
  ["Mechanical"] = L["Shield Wall"],
  ["Monkey"] = L["Dodge"],
  ["Moth"] = L["Self-Cleanse"],
  ["Oxen"] = L["Low HP Shield Wall"],
  ["Pterrordax"] = L["Low HP Shield Wall"],
  ["Raptor"] = L["Mortal Strike"],
  ["Ravager"] = L["Mortal Strike"],
  ["Ray"] = L["Self-Cleanse"],
  ["Riverbeast"] = L["Mortal Strike"],
  ["Rodent"] = L["Mortal Strike"],
  ["Scalehide"] = L["Shield Wall"],
  ["Scorpid"] = L["Mortal Strike"],
  ["Serpent"] = L["Dodge"],
  ["Shale Beast"] = L["Shield Wall"],
  ["Spider"] = L["Wing Clip"],
  ["Spirit Beast"] = L["Self-Cleanse"]..", "..L["Prowl"],
  ["Sporebat"] = L["Self-Cleanse"],
  ["Stag"] = L["Self-Cleanse"],
  ["Stone Hound"] = L["Low HP Shield Wall"],
  ["Tallstrider"] = L["Wing Clip"],
  ["Turtle"] = L["Shield Wall"],
  ["Warp Stalker"] = L["Wing Clip"],
  ["Wasp"] = L["Mortal Strike"],
  ["Water Strider"] = L["Self-Cleanse"],
  ["Wind Serpent"] = L["Dodge"],
  ["Wolf"] = L["Wing Clip"],
  ["Worm"] = L["Wing Clip"],
}

-- maps call pet spellid to petslot index (for adding info to Call Pet tooltips)
local callPetSpells = {
  [883] = 1,
  [83242] = 2,
  [83243] = 3,
  [83244] = 4,
  [83245] = 5,
}

-- returns new tooltip information for a given pet stable slot
local function AddPetTooltip(tooltip, petSlot)
  -- is there actually a pet in this slot?
  local icon, _, _, family, talent = GetStablePetInfo(petSlot)
  if not icon or not family or not talent then return end
  
  local englishfamily = petIconMap[icon]
  if not englishfamily then englishfamily = L["Unknown"] end
  
  -- prepend color to buff line
  if not buffs[englishfamily] then
    buffs[englishfamily] = "|cFFFF0000"..L["No abilities"]
  else
    buffs[englishfamily] = "|cFF2288FF"..buffs[englishfamily]
  end

  -- add " (Exotic)" to pet family display
  if exotics[englishfamily] then
    family = family.." |cFFFFFF20("..L["Exotic"]..")|cFFFFFFFF"
  end

  -- default tooltip now only has level and family, and level is meaningless
  tooltip:AddLine("|cFFFFFFFF"..family)

  -- add passives/abilities
  tooltip:AddLine("|cFFFFFFFF"..L["Abilities"]..": "..buffs[englishfamily])
  
  -- add exotic ability if available
  if exotics[englishfamily] then
    tooltip:AddLine("|cFFFFFFFF"..L["Exotic"]..": |cFFFFFF20"..exotics[englishfamily])
  end
end

-- add info to stabled pet tooltips
hooksecurefunc("PetStable_UpdateSlot", function (button, petSlot)
  -- is there actually a pet in this slot?
  local icon, _, _, family, talent = GetStablePetInfo(petSlot)
  if not icon or not family or not talent then return end

  -- only hook button:OnEnter once per button
  if button.stableHelperHooked then return end  
 
  -- hook OnEnter and write out modified tooltip
  button:HookScript("OnEnter", function (self)
    -- only bother if the current tooltip is from this button
    if not GameTooltip:IsOwned(self) then return end
    
    -- is there actually a pet in this slot?
    local icon, _, _, family, talent = GetStablePetInfo(self.petSlot)
    if not icon or not family or not talent then return end
    
    -- modified code from PetStable.xml\PetStableSlotTemplate\Scripts\OnEnter
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tooltip)
    AddPetTooltip(GameTooltip, self.petSlot)
    GameTooltip:Show()
  end)  
  
  button.stableHelperHooked = true
end)

-- add info to Call Pet # tooltips
GameTooltip:HookScript("OnTooltipSetSpell", function (self)
  local spellName, spellID = self:GetSpell()
  if not spellName then return end  
  
  -- is this a "call pet" spell?
  local petSlot = callPetSpells[spellID]
  if not petSlot then return end
  
  -- is there actually a pet in this slot?
  local icon, _, _, family, talent = GetStablePetInfo(petSlot)
  if not icon or not family or not talent then return end

  -- add to spell tooltip
  self:AddLine(" ")
  AddPetTooltip(self, petSlot)
  self:Show()
end)
