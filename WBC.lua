local frame = WBCFrame or CreateFrame("FRAME", "WBCFrame")
frame:RegisterEvent("CHAT_MSG_WHISPER")

local function wbc(self, event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
  print("player: " .. playerName .. " text " .. " languageName " .. languageName .. " zoneChannelID " ..  zoneChannelID )
end


SLASH_WBC = "/wbc"
SlashCmdList["WBC"] = function(functionName)
  local command, arg1, arg2 = strsplit(" ", functionName, 3)
  if command == "test" then
    print("yes works")
  end
end





frame:SetScript("OnEvent", wbc)
