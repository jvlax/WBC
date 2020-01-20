local frame = WBCFrame or CreateFrame("FRAME", "WBCFrame")
local frame2 = WBCFrame2 or CreateFrame("FRAME", "WBCFrame2")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_ADDON")
WBCboss = "none"
WBCbossZone = "none"
local realm = "-ZandalarTribe";

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function shortName(playerName)
  playerShortName = string.gsub(playerName, realm, "");
  return playerShortName;
end

local function getRaidInfo()
  local raid = {}
  for i=1,40 do
    name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
    table.insert(raid, name)
  end
  return raid
end

local function getMyGuildies()
  local readyPlayers = {}
  for i=1,GetNumGuildMembers() do
    name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
    if (zone == WBCbossZone or zone == WBCbossZoneFR) and isOnline then
      table.insert(readyPlayers, shortName(name))
    end
  end
  return readyPlayers
end

local function inviteReps()
  for rep = 1, #GuildReps do
    raid = getRaidInfo()
    if not has_value(raid, GuildReps[rep]) and GuildReps[rep] ~= UnitName("player") then
      InviteUnit(GuildReps[rep])
      PromoteToAssistant(GuildReps[rep])
    end
    if not IsInRaid("LE_PARTY_CATEGORY_HOME") then
      ConvertToRaid()
    end
  end
end

local function invitePlayers()
  readyPlayers = getMyGuildies()
  for guildie = 1, #readyPlayers do
    raid = getRaidInfo()
    if not has_value(raid, readyPlayers[guildie]) then
      InviteUnit(readyPlayers[guildie])
    end
    if not IsInRaid("LE_PARTY_CATEGORY_HOME") then
      ConvertToRaid()
    end
  end
end

local function startRaid()
  print("starting raid for")
  print(WBCboss)
  if WBCboss == "kazzak" then
    WBCbossZone = "Blasted Lands"
    WBCbossZoneFR = "Terres foudroyées \(Blasted Lands\)"
  elseif WBCboss == "azuregos" then
    WBCbossZone = "Azshara"
    WBCbossZoneFR = "Azshara"
  end
  frame2:SetScript("OnUpdate",frame2.onUpdate)
end

function frame2:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if ( self.sinceLastUpdate >= 10 ) then -- in seconds
    inviteReps()
    invitePlayers()
    if IsInRaid("LE_PARTY_CATEGORY_HOME") then
      for rep = 1,#GuildReps do
        C_ChatInfo.SendAddonMessage("wbcrep", GuildReps[rep], "RAID")
      end
      C_ChatInfo.SendAddonMessage("wbcboss", WBCboss, "RAID")
    end
		self.sinceLastUpdate = 0;
	end
end


local function wbc(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  if event == "ADDON_LOADED" and arg1 == "WBC" then
    C_ChatInfo.RegisterAddonMessagePrefix("wbcboss")
    C_ChatInfo.RegisterAddonMessagePrefix("wbcrep")
    if GuildReps == nil then
      GuildReps = {}
      local name, realm = UnitName("player")
      table.insert(GuildReps, name)
    end
    if WBCPlayers == nil then
      WBCPlayers = {}
    end
    if WBCGuilds == nil then
      WBCGuilds = {"AFK", "Credendum", "Pertento", "Saga", "Sketchy"}
    end
    if WBCGuildPlayers == nil then
      WBCGuildPlayers = {}
    end
    if WBCboss == nil then
      WBCboss = "none"
    end
  elseif event == "CHAT_MSG_ADDON" then
    prefix, msg = arg1, arg2
    if prefix == "wbcrep" then
      print("got broadcast " .. prefix .. " " .. msg)
    end
    if prefix == "wbcrep" and not has_value(GuildReps, msg) then
      table.insert(GuildReps, msg)
    end
    if prefix == "wbcboss" and WBCboss == "none" then
       WBCboss = msg
       startRaid()
    end
  end
end

SLASH_WBC1 = "/wbc"
SlashCmdList["WBC"] = function(functionName)
  local command, arg1, arg2 = strsplit(" ", functionName, 3)
  if command == "boss" then
    print("WBCboss!!")
    print(arg1)
    local guildBroadcastMessage = ""
    if arg1 == "kazzak" then
      guildBroadcastMessage = "\{rt8\} Kazzak is up! head to Blasted Lands asap \{rt8\}"
    end
    if arg1 == "azuregos" then
      guildBroadcastMessage = "\{rt8\} Azuregos is up! head to Azshara asap \{rt8\}"
    end
    SendChatMessage(guildBroadcastMessage, "GUILD", nil, nil)
    if arg1 == nil then
      print("please specify which WBCboss or use \"/wbc WBCboss off\" to cancel the raid")
      return
    end
    WBCboss = arg1
    startRaid(arg1)
  end
  if command == "off" then
    WBCboss = "none"
    frame2:SetScript("OnUpdate",nil)
  end
  if command == "removerep" then
    for rep = 1, #GuildReps do
      if GuildReps[rep] == arg1 then
        print("removing " .. GuildReps[rep])
        table.remove(GuildReps, rep)
      end
    end
  end
end

frame:SetScript("OnEvent", wbc)
