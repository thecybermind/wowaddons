local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function (self, event, ...)
  if event == "BANKFRAME_OPENED" then
    if not IsReagentBankUnlocked() then return end

    if not IsShiftKeyDown() then return end

    BankFrame_ShowPanel(BANK_PANELS[2].name)
  elseif event == "VOID_STORAGE_OPEN" then
    if not CanUseVoidStorage() then return end

    if not IsShiftKeyDown() then return end
    
    VoidStorage_SetPageNumber(2)
  end
end)

frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("VOID_STORAGE_OPEN")
