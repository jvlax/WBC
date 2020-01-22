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
WBCDebug = "off"
WBCDebugLevel = "off"
local realm = "-ZandalarTribe"

local function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

local function get_index(tab, val)
  local index={}
  for k,v in ipairs(tab) do
   index[v]=k
  end
  return index[val]
end

local function debug(msg, debugLevel)
  if WBCDebug == "on" and debugLevel <= WBCDebugLevel then
    print(msg)
  end
end

local function registerMe()
  local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player")
  if guildName ~= nil then
    local name, realm = UnitName("player")
    local guildRepName = name .. " " .. guildName .. " active"
    if not has_value(GuildReps, guildRepName) then
      table.insert(GuildReps, guildRepName)
      debug("registered " .. guildRepName, 1)
      C_ChatInfo.SendAddonMessage("wbcrep", guildRepName, "GUILD")
      C_ChatInfo.SendAddonMessage("wbcrep", guildRepName, "SAY")
      debug("sent wbcrep sync message for " .. guildRepName, 1)
    end
  end
end

local function syncDB(msg, role)
  -- todo check if there is pointers available in lua and if so rewrite using that DRY!
  debug("syncing db for " .. role, 2)
  if role == "taxi" then
    for player = 1, #WBCTaxis do
      debug("syncing " .. msg, 2)
      local name, guild, boss, status = strsplit(" ", msg, 4)
      local lName, lGuild, lBoss, lStatus = strsplit(" ", WBCTaxis[player], 4)
      if not has_value(WBCTaxis, name .. " " .. guild .. " " .. boss .. " inactive") and not has_value(WBCTaxis, name .. " " .. guild .. " " .. boss .. " active") then
        table.insert(WBCTaxis, msg)
      end
      if name == lName and status == "active" then
        debug("checking to see if I should change status to active", 1)
        if not has_value(WBCTaxis, msg) then
          debug("yes I should", 1)
          debug("adding active taxi " .. msg, 1)
          table.insert(WBCTaxis, msg)
          if has_value(WBCTaxis, name .. " " .. guild .. " " .. boss .. " inactive") then
            debug("changing " .. msg .. " to active", 1)
            table.remove(WBCTaxis, get_index(WBCTaxis, name .. " " .. guild .. " " .. boss .. " inactive"))
          end
          C_ChatInfo.SendAddonMessage("wbctaxisync", msg, "GUILD")
          C_ChatInfo.SendAddonMessage("wbctaxisync", msg, "SAY")
          debug("sent sync for taxi " .. msg, 2)
        end
      debug("checking to see if I should change status to inactive", 1)
      elseif name == lName and status == "inactive" then
        if not has_value(WBCTaxis, msg) then
          debug("yes I should", 1)
          debug("removing inactive taxi " .. msg, 1)
          table.insert(WBCTaxis, msg)
          if has_value(WBCTaxis, name .. " " .. guild .. " " .. boss .. " active") then
            debug("changing " .. msg .. " to inactive", 1)
            table.remove(WBCTaxis, get_index(WBCTaxis, name .. " " .. guild .. " " .. boss .. " active"))
          end
          C_ChatInfo.SendAddonMessage("wbctaxisync", msg, "GUILD")
          C_ChatInfo.SendAddonMessage("wbctaxisync", msg, "SAY")
          debug("sent sync for taxi " .. msg, 2)
        end
      end
    end
  elseif role == "rep" then
    for player = 1, #GuildReps do
      local name, guild, status = strsplit(" ", msg, 3)
      local lName, lGuild, lStatus = strsplit(" ", GuildReps[player], 3)
      if not has_value(GuildReps, name .. " " .. guild .. " inactive") and not has_value(GuildReps, name .. " " .. guild .. " active") then
        table.insert(GuildReps, msg)
      end
      if name == lName and status == "active" then
        if not has_value(GuildReps, msg) then
          debug("adding active rep " .. msg, 1)
          table.insert(GuildReps, msg)
          if has_value(GuildReps, name .. " " .. guild .. " " .. " inactive") then
            debug("changing " .. msg .. " to active", 1)
            table.remove(GuildReps, get_index(GuildReps, name .. " " .. guild .. " " .. " inactive"))
          end
          C_ChatInfo.SendAddonMessage("wbcrep", msg, "GUILD")
          C_ChatInfo.SendAddonMessage("wbcrep", msg, "SAY")
          debug("sent sync for rep " .. msg, 2)
        end
      elseif name == lName and status == "inactive" then
        if not has_value(GuildReps, msg) then
          debug("removing inactive rep " .. msg, 1)
          table.insert(GuildReps, msg)
          if has_value(GuildReps, name .. " " .. guild .. " " .. " active") then
            debug("changing " .. msg .. " to inactive", 1)
            table.remove(GuildReps, get_index(GuildReps, name .. " " .. guild .. " " .. " active"))
          end
          C_ChatInfo.SendAddonMessage("wbcrep", msg, "GUILD")
          C_ChatInfo.SendAddonMessage("wbcrep", msg, "SAY")
          debug("sent sync for rep " .. msg, 2)
        end
      end
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
    local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
    table.insert(raid, name)
  end
  return raid
end

local function getMyGuildies()
  local readyPlayers = {}
  for i = 1, GetNumGuildMembers() do
    local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
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
  print("starting raid for " .. WBCboss)
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
      debug("taxi service is online", 1)
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
    taxiAvailable = "\{rt1\}Taxi service is online\{rt1\}\nwhisper me \"wbcinv\" to get invited to taxi raid"
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
      debug("broadcasting for " .. guildName, 1)
      C_ChatInfo.SendAddonMessage("wbcguildbroadcast", guildName, "RAID")
      guildBroadcast()
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
    debug("syncing databases", 2)
    for taxi = 1, #WBCTaxis do
      debug("syncing taxis " .. WBCTaxis[taxi], 2)
      C_ChatInfo.SendAddonMessage("wbctaxisync", WBCTaxis[taxi], "GUILD")
      C_ChatInfo.SendAddonMessage("wbctaxisync", WBCTaxis[taxi], "SAY")
    end
    for rep = 1, #GuildReps do
      debug("syncing reps " .. GuildReps[rep], 2)
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
    if prefix == "wbcrep" then
      debug("incomming wbcrep message " .. msg, 2)
      syncDB(msg, "rep")
    end
    if prefix == "wbcboss" and WBCboss == "none" then
      debug("I should be in the kill raid now, will invite guild reps if needed")
      WBCboss = msg
      inviteReps()
      startRaid()
    end
    if prefix == "wbctaxisync" then
      debug("incomming wbctaxisync message " .. msg, 2)
      syncDB(msg, "taxi")
    end
    if prefix == "wbctaxiinv" and WBCTaxi == "yes" then
      debug("got wbctaxiinv message for " .. msg, 1)
      WBCboss = msg
      inviteTaxis()
    end
    if prefix == "wbcguildbroadcast" and WBCTaxi == "yes" then
      debug("got wbcguildbroadcast message", 1)
      local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
      if msg == guildName then
        debug("guild broadcast sent from my guildie I will reset my counter", 1)
        WBCBroadCastCounter = 0
      end
    end
  elseif event == "CHAT_MSG_WHISPER" and WBCTaxi == "yes" then
    if arg1 == "wbcinv" then
      debug("got invite request from " .. arg2 .. " inviting to taxi raid", 1)
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
        for player = 1, #WBCTaxis do
          local name, guild, boss, status = strsplit(" ", WBCTaxis[player])
          if name == arg2 then
            debug("trying to remove player " .. "---" .. name .. "---", 1)
            syncDB(name .. " " .. guild .. " " .. boss .. " inactive", "taxi")
          end
        end
      end
    elseif arg1 == "rep" then
      if arg2 == nil then
        print("need to know who you want to remove ex: \"/wbc remove taxi <player name>\"")
        return
      else
        for player = 1, #GuildReps do
          local name, guild, status = strsplit(" ", GuildReps[player])
          if name == arg2 then
            syncDB(name .. " " .. guild .. " inactive", "rep")
          end
        end
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
      syncDB(taxiName, "taxi")
      WBCTaxi = "yes"
      print("registered you as a taxi for " .. arg2)
    elseif arg1 == "kazzak" or arg1 == "azuregos" then
      WBCboss = arg1
      inviteTaxis()
      -- guildBroadcast()
    end
  end

  if command == "debug" then
    if WBCDebug == "off" then
      WBCDebug = "on"
      WBCDebugLevel = tonumber(arg1)
      print("enabled debugging with level " .. arg1)
    elseif WBCDebug == "on" then
      WBCDebug = "off"
      WBCDebugLevel = "off"
    end
  end
end

frame:SetScript("OnEvent", wbc)
frame4:SetScript("OnUpdate", frame4.onUpdate)
