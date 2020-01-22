local frame = WBCFrame or CreateFrame("FRAME", "WBCFrame")
local frame2 = WBCFrame2 or CreateFrame("FRAME", "WBCFrame2")
local frame3 = WBCFrame3 or CreateFrame("FRAME", "WBCFrame3")
local frame4 = WBCFrame4 or CreateFrame("FRAME", "WBCFrame4")


frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("CHAT_MSG_WHISPER");
WBCboss = "none"
WBCbossZone = "none"
taxiService = "offline"
WBCBroadCastCounter = 0
WBCDrill = "no"
local realm = "-ZandalarTribe"

local function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

local function registerMe()
  local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player")
  if guildName ~= nil then
    local name, realm = UnitName("player")
    local guildRepName = name .. " " .. guildName .. " active"
    if not has_value(GuildReps, guildRepName) then
      table.insert(GuildReps, guildRepName)
      C_ChatInfo.SendAddonMessage("wbcrep", guildRepName, "GUILD")
      C_ChatInfo.SendAddonMessage("wbcrep", guildRepName, "SAY")
    end
  end
end

local function removeRepFromDB(playerName)
  for player = 1, #GuildReps do
    local name, guild, status = strsplit(" ", GuildReps[player], 3)
    if name == playerName then
      print("removing " .. playerName .. " from " .. "reps")
      local removeName = name .. " " .. guild .. "inactive"
      table.remove(GuildReps, player)
      table.insert(GuildReps, removeName)
      C_ChatInfo.SendAddonMessage("wbcrep", removeName, "GUILD")
      C_ChatInfo.SendAddonMessage("wbcrep", removeName, "SAY")
    end
  end
end

local function removeTaxiFromDB(playerName)
  for player = 1, #WBCTaxis do
    local name, guild, boss, status = strsplit(" ", WBCTaxis[player], 4)
    if name == playerName then
      print("removing " .. playerName .. " from " .. "taxis")
      local removeName = name .. " " .. guild .. " " .. boss .. " inactive"
      table.remove(WBCTaxis, player)
      table.insert(WBCTaxis, removeName)
      C_ChatInfo.SendAddonMessage("wbctaxisync", removeName, "GUILD")
      C_ChatInfo.SendAddonMessage("wbctaxisync", removeName, "SAY")
    end
  end
end

local function shortName(playerName)
  playerShortName = string.gsub(playerName, realm, "");
  return playerShortName;
end

local function getRaidInfo()
  local raid = {}
  for i = 1, 40 do
    name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
    table.insert(raid, name)
  end
  return raid
end

local function getMyGuildies()
  local readyPlayers = {}
  for i = 1, GetNumGuildMembers() do
    name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
    if (zone == WBCbossZone or zone == WBCbossZoneFR) and isOnline and level == 60 then
      table.insert(readyPlayers, shortName(name))
    end
  end
  return readyPlayers
end

local function inviteReps()
  local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
  for rep = 1, #GuildReps do
    local repName, repGuild, status = strsplit(" ", GuildReps[rep], 3)
    raid = getRaidInfo()
    if not has_value(raid, repName) and repName ~= UnitName("player") and repGuild ~= guildName and status == "active" then
      InviteUnit(repName)
      PromoteToAssistant(repName)
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
  frame2:SetScript("OnUpdate", frame2.onUpdate)
end

local function inviteTaxis()
  for taxi = 1, #WBCTaxis do
    taxiName, taxiGuild, taxiBoss, status = strsplit(" ", WBCTaxis[taxi], 4)
    raid = getRaidInfo()
    if #raid >= 3 then
      taxiService = "online"
    end
    if not has_value(raid, taxiName) and taxiBoss == WBCboss and status == "active" then
      InviteUnit(taxiName)
    end
    if not IsInRaid("LE_PARTY_CATEGORY_HOME") then
      ConvertToRaid()
    end
  end
  frame3:SetScript("OnUpdate", frame3.onUpdate)
end

local function guildBroadcast()
  local guildBroadcastMessage = ""
  local taxiAvailable = ""
  if taxiService == "online" then
    taxiAvailable = "\{rt1\}Taxi service is online\{rt1\}\nwhisper me wbcinv to get invited to taxi raid"
  elseif taxiService == "offline" then
    taxiAvailable = "\{rt7\}Taxi service is offline\{rt7\}"
  end
  if WBCboss == "kazzak" then
    guildBroadcastMessage = "\{rt8\} Kazzak is up! head to Blasted Lands asap \{rt8\}"
  end
  if WBCboss == "azuregos" then
    guildBroadcastMessage = "\{rt8\} Azuregos is up! head to Azshara asap \{rt8\}"
  end
  SendChatMessage(guildBroadcastMessage, "GUILD", nil, nil)
  SendChatMessage(taxiAvailable, "GUILD", nil, nil)
end

function frame2:onUpdate(sinceLastUpdate)
  self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
  if ( self.sinceLastUpdate >= 10 ) then -- in seconds
    inviteReps()
    invitePlayers()
    if IsInRaid("LE_PARTY_CATEGORY_HOME") then
      for rep = 1, #GuildReps do
        C_ChatInfo.SendAddonMessage("wbcrep", GuildReps[rep], "RAID")
      end
      C_ChatInfo.SendAddonMessage("wbcboss", WBCboss, "RAID")
    end
    self.sinceLastUpdate = 0;
  end
end

function frame3:onUpdate(sinceLastUpdate)
  self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate
  if ( self.sinceLastUpdate >= 10 ) then -- in seconds
    inviteTaxis()
    WBCBroadCastCounter = WBCBroadCastCounter + 1
    local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
    if WBCBroadCastCounter >= 6 then
      print("broadcasting for " .. guildName)
      C_ChatInfo.SendAddonMessage("wbcguildbroadcast", guildName, "RAID")
      -- guildBroadcast()
      WBCBroadCastCounter = 0
      for taxi = 1, #WBCTaxis do
        C_ChatInfo.SendAddonMessage("wbctaxisync", WBCTaxis[taxi], "RAID")
      end
      C_ChatInfo.SendAddonMessage("wbctaxiinv", WBCboss, "RAID")
      self.sinceLastUpdate = 0
    end
  end
end

function frame4:onUpdate(sinceLastUpdate)
  self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
  if ( self.sinceLastUpdate >= 10 ) then -- in seconds
    print("syncing databases")
    for taxi = 1, #WBCTaxis do
      print("syncing taxis " .. WBCTaxis[taxi])
      C_ChatInfo.SendAddonMessage("wbctaxisync", WBCTaxis[taxi], "GUILD")
      C_ChatInfo.SendAddonMessage("wbctaxisync", WBCTaxis[taxi], "SAY")
    end
    for rep = 1, #GuildReps do
      print("syncing reps " .. GuildReps[rep])
      C_ChatInfo.SendAddonMessage("wbcrep", GuildReps[rep], "GUILD")
      C_ChatInfo.SendAddonMessage("wbcrep", GuildReps[rep], "SAY")
    end
    self.sinceLastUpdate = 0;
  end
end

local function wbc(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  if event == "ADDON_LOADED" and arg1 == "WBC" then
    print("WBC loaded")
    C_ChatInfo.RegisterAddonMessagePrefix("wbcboss")
    C_ChatInfo.RegisterAddonMessagePrefix("wbcrep")
    C_ChatInfo.RegisterAddonMessagePrefix("wbctaxisync")
    C_ChatInfo.RegisterAddonMessagePrefix("wbctaxiinv")
    C_ChatInfo.RegisterAddonMessagePrefix("wbcguildbroadcast")
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
    if WBCTaxis == nil then
      WBCTaxis = {}
    end
    if WBCTaxi == nil then
      WBCTaxi = "no"
    end
    if GuildReps == nil then
      GuildReps = {}
      GuildRoster()
    end
    if WBCSync == nil then
      WBCSync = 0
    end
  elseif event == "CHAT_MSG_ADDON" then
    prefix, msg = arg1, arg2
    if prefix == "wbcrep" and not has_value(GuildReps, msg) then
      local name, guild, status = strsplit(" ", msg)
      if status == "inactive" then
        removeRepFromDB(name)
      elseif status == "active" then
        print("adding " .. msg .. " to db")
        table.insert(GuildReps, msg)
      end
    end
    if prefix == "wbcboss" and WBCboss == "none" then
      WBCboss = msg
      inviteReps()
      startRaid()
    end
    if prefix == "wbctaxisync" and not has_value(WBCTaxis, msg) then
      local name, guild, status = strsplit(" ", msg)
      if status == "inactive" then
        removeRepFromDB(name)
      elseif status == "active" then
        print("adding " .. msg .. " to db")
        table.insert(WBCTaxis, msg)
      end
    end
    if prefix == "wbctaxiinv" and WBCTaxi == "yes" then
      WBCboss = msg
      inviteTaxis()
    end
    if prefix == "wbcguildbroadcast" and WBCTaxi == "yes" then
      local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
      if msg == guildName then
        WBCBroadCastCounter = 0
      end
    end
  elseif event == "CHAT_MSG_WHISPER" and WBCTaxi == "yes" then
    if arg1 == "wbcinv" then
      InviteUnit(arg2)
    end
  elseif event == "GUILD_ROSTER_UPDATE" then
    registerMe()
  end
end

SLASH_WBC1 = "/wbc"
SlashCmdList["WBC"] = function(functionName)
  local command, arg1, arg2 = strsplit(" ", functionName, 3)
  if command == "boss" then
    if arg1 == nil then
      print("please specify which WBCboss or use \" / wbc WBCboss off\" to cancel the raid")
      return
    end
    WBCboss = arg1
    startRaid()
  end

  if command == "off" then
    WBCboss = "none"
    taxiService = "offline"
    frame2:SetScript("OnUpdate", nil)
    frame3:SetScript("OnUpdate", nil)
  end

  if command == "remove" then
    if arg1 == nil then
      print("need to know if you want to remove a rep or a taxi ex: \"/wbc remove taxi <player name>\"")
      return
    elseif arg1 == "taxi" then
      if arg2 == nil then
        print("need to know who you want to remove ex: \"/wbc remove taxi <player name>\"")
        return
      else
        removeTaxiFromDB(arg2)
      end
    elseif arg1 == "rep" then
      if arg2 == nil then
        print("need to know who you want to remove ex: \"/wbc remove taxi <player name>\"")
        return
      else
        removeRepFromDB(arg2)
      end
    end
  end

  if command == "taxi" then
    if arg1 == "register" then
      local name, realm = UnitName("player")
      local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
      if arg2 == nil then
        print("please specify for what zone you are a taxi ex \" / wbc taxi register kazzak\"")
        return
      end
      local taxiName = name .. " " .. guildName .. " " .. arg2 .. " active"
      table.insert(WBCTaxis, taxiName)
      WBCTaxi = "yes"
      print("registered you as a taxi for " .. arg2)
    elseif arg1 == "kazzak" or arg1 == "azuregos" then
      WBCboss = arg1
      inviteTaxis()
      -- guildBroadcast()
    end
  end
end

frame:SetScript("OnEvent", wbc)
frame4:SetScript("OnUpdate", frame4.onUpdate)
