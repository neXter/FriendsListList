-- FriendsListList 1.1.0 – minimalistische Online-Freundesliste für WoW Forever (Interface 16001)
-- Autor: neXter
local ADDON = ...
local VERSION = "1.1.0"
local TAG = "|cff3FB8AFFLL|r"

-- Lokalisierung -----------------------------------------------------------
local IS_DE = GetLocale() == "deDE"
local EN = {
  READY = "v%s loaded. /fll help for commands.",
  LOCKED = "List locked.",
  UNLOCKED = "List unlocked – drag the handle, right-click to lock.",
  CHARS_ON = "Character friends: shown.",
  CHARS_OFF = "Character friends: hidden.",
  DEBUG_ON = "Debug output on.",
  DEBUG_OFF = "Debug output off.",
  RESET = "Position reset to screen center.",
  ICON_SET = "Faction icon set: %s",
  ICON_USAGE = "Usage: /fll icon <0-%s>  (0 = auto). Options:",
  HELP = "v%s by neXter – commands:",
  HELP1 = "  /fll  –  lock / unlock",
  HELP2 = "  /fll chars  –  toggle character friends (classic friends list)",
  HELP3 = "  /fll reset  –  reset position",
  HELP4 = "  /fll debug  –  toggle debug output in chat",
  HELP5 = "  /fll dump  –  print raw data of all online friends (for bug reports)",
  HELP6 = "  /fll icon <n>  –  choose faction icon variant",
  NOTE = "Note",
}
local DE = {
  READY = "v%s geladen. /fll help zeigt die Befehle.",
  LOCKED = "Liste gesperrt.",
  UNLOCKED = "Liste entsperrt – Griff ziehen, Rechtsklick zum Sperren.",
  CHARS_ON = "Charakterfreunde: werden angezeigt.",
  CHARS_OFF = "Charakterfreunde: ausgeblendet.",
  DEBUG_ON = "Debug-Ausgabe an.",
  DEBUG_OFF = "Debug-Ausgabe aus.",
  RESET = "Position auf Bildschirmmitte zurückgesetzt.",
  ICON_SET = "Fraktions-Icon gesetzt: %s",
  ICON_USAGE = "Aufruf: /fll icon <0-%s>  (0 = automatisch). Varianten:",
  HELP = "v%s von neXter – Befehle:",
  HELP1 = "  /fll  –  sperren / entsperren",
  HELP2 = "  /fll chars  –  Charakterfreunde (klassische Freundesliste) ein/aus",
  HELP3 = "  /fll reset  –  Position zurücksetzen",
  HELP4 = "  /fll debug  –  Debug-Ausgabe im Chat ein/aus",
  HELP5 = "  /fll dump  –  Rohdaten aller Online-Freunde ausgeben (für Fehlerberichte)",
  HELP6 = "  /fll icon <n>  –  Variante des Fraktions-Icons wählen",
  NOTE = "Notiz",
}
local L = IS_DE and setmetatable(DE, { __index = EN }) or EN

-- Konstanten --------------------------------------------------------------
local GAME_F = "|cff3FB8AFF|r"   -- Forever: Türkis
local GAME_R = "|cffE8B83AR|r"   -- Retail: Gold
local ICON_SIZE = 14
local ROW_HEIGHT = 14
local HANDLE_SIZE = 12
local REFRESH_DELAY = 0.5

local DEFAULTS = {
  locked = true,
  showCharFriends = false,
  debug = false,  -- Debug-Ausgabe im Chat: /fll debug
  icon = 0,       -- 0 = automatisch
  point = "CENTER", relPoint = "CENTER", x = 0, y = 0,
}
local db

-- Ausgabe -----------------------------------------------------------------
local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(TAG .. " " .. tostring(msg))
end

local function Dbg(fmt, ...)
  if not (db and db.debug) then return end
  local n = select("#", ...)
  local args = { ... }
  for i = 1, n do args[i] = tostring(args[i]) end
  local ok, msg = pcall(string.format, fmt, unpack(args, 1, n))
  DEFAULT_CHAT_FRAME:AddMessage(TAG .. "|cff888888 dbg:|r " .. (ok and msg or tostring(fmt)))
end

local function Has(v) return v and "ok" or "MISSING" end

-- Klassenfarben -----------------------------------------------------------
local CLASS_BY_NAME = {}
for _, tbl in ipairs({ LOCALIZED_CLASS_NAMES_MALE or {}, LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
  for file, name in pairs(tbl) do CLASS_BY_NAME[name] = file end
end

local function ClassHex(className)
  local file = className and CLASS_BY_NAME[className]
  local c
  if file then
    c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[file]
    if not c and C_ClassColor and C_ClassColor.GetClassColor then
      c = C_ClassColor.GetClassColor(file)
    end
  end
  if not c then return "|cffffffff" end
  local function byte(v) return math.floor(v * 255 + 0.5) end
  return string.format("|cff%02x%02x%02x", byte(c.r), byte(c.g), byte(c.b))
end

-- Fraktions-Icons ---------------------------------------------------------
-- Mehrere Kandidaten, weil der genaue Client-Pfad noch ungeprüft ist.
-- /fll icon <n> wählt eine Variante, 0 = automatisch.
local function Atlas(name) return string.format("|A:%s:%d:%d|a", name, ICON_SIZE, ICON_SIZE) end
local function Tex(path) return string.format("|T%s:%d:%d:0:0|t", path, ICON_SIZE, ICON_SIZE) end
local function TexCrop(path)
  return string.format("|T%s:%d:%d:0:0:64:64:0:39:0:39|t", path, ICON_SIZE, ICON_SIZE)
end

local ICONS = {
  { name = "atlas communities-icon-faction-*",
    Horde = Atlas("communities-icon-faction-horde"), Alliance = Atlas("communities-icon-faction-alliance"),
    atlases = { "communities-icon-faction-horde", "communities-icon-faction-alliance" } },
  { name = "Interface\\FriendsFrame\\PlusManz-*",
    Horde = Tex("Interface\\FriendsFrame\\PlusManz-Horde"), Alliance = Tex("Interface\\FriendsFrame\\PlusManz-Alliance") },
  { name = "Interface\\TargetingFrame\\UI-PVP-*",
    Horde = TexCrop("Interface\\TargetingFrame\\UI-PVP-Horde"), Alliance = TexCrop("Interface\\TargetingFrame\\UI-PVP-Alliance") },
  { name = "text H / A",
    Horde = "|cffe04040H|r", Alliance = "|cff4a8ae0A|r" },
}

local function AtlasExists(name)
  if C_Texture and C_Texture.GetAtlasInfo then return C_Texture.GetAtlasInfo(name) ~= nil end
  return false
end

local function ActiveIconIndex()
  if db and db.icon and db.icon >= 1 and db.icon <= #ICONS then return db.icon end
  local first = ICONS[1]
  if AtlasExists(first.atlases[1]) and AtlasExists(first.atlases[2]) then return 1 end
  return 2
end

local function FactionKey(faction)
  if not faction or faction == "" then return nil end
  if faction == "Horde" or faction == FACTION_HORDE then return "Horde" end
  if faction == "Alliance" or faction == FACTION_ALLIANCE then return "Alliance" end
  return nil
end

local function FactionIcon(faction)
  local key = FactionKey(faction)
  if not key then return nil end
  return ICONS[ActiveIconIndex()][key]
end

-- Daten sammeln -----------------------------------------------------------
local function Lower(s) return (s or ""):lower() end

-- Realm-Typ steckt in richPresence, z. B. "Forever - PvP - The Barrens".
-- Wir suchen ein Segment, das wie PvP / PvE / RP / RP-PvP / RP-PvE aussieht.
local REALM_TYPES = { ["PVP"] = true, ["PVE"] = true, ["RP"] = true, ["RP-PVP"] = true,
  ["RP-PVE"] = true, ["RPPVP"] = true, ["RPPVE"] = true }

local function ParseRealmType(rich)
  if not rich or rich == "" then return nil end
  for seg in (rich .. " - "):gmatch("(.-) %- ") do
    local norm = seg:gsub("%s", ""):upper()
    if REALM_TYPES[norm] then return seg end
  end
  return nil
end

-- accountName kann leer oder "???" sein (Freund ohne RealID-Namen): dann BattleTag ohne #Nummer
local function UsableName(name)
  if name and name ~= "" and name ~= "???" then return name end
  return nil
end

local function FriendName(acc)
  local name = UsableName(acc.accountName)
  if name then return name end
  local short = acc.battleTag and acc.battleTag:match("^([^#]+)")
  return UsableName(short)
end

local function CollectBNet(out, stats)
  local num = BNGetNumFriends and (BNGetNumFriends()) or 0
  stats.bnetTotal = num
  local wowClient = BNET_CLIENT_WOW or "WoW"
  for i = 1, num do
    local acc = C_BattleNet.GetFriendAccountInfo(i)
    if acc then
      local accounts = {}
      local nga = C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendNumGameAccounts(i) or 0
      if nga > 0 then
        for j = 1, nga do
          local ga = C_BattleNet.GetFriendGameAccountInfo(i, j)
          if ga then accounts[#accounts + 1] = ga end
        end
      elseif acc.gameAccountInfo then
        accounts[1] = acc.gameAccountInfo
      end
      for _, ga in ipairs(accounts) do
        if ga.isOnline then
          stats.bnetOnline = stats.bnetOnline + 1
          local who = acc.battleTag or acc.accountName or "?"
          if ga.clientProgram ~= wowClient then
            local c = tostring(ga.clientProgram)
            stats.otherClients[c] = (stats.otherClients[c] or 0) + 1
          else
            local pid = ga.wowProjectID
            local game
            if pid == WOW_PROJECT_ID then game = "F"
            elseif pid == WOW_PROJECT_MAINLINE then game = "R" end
            if not game then
              stats.notes[#stats.notes + 1] = "skip " .. who .. ": wowProjectID=" .. tostring(pid)
            else
              local area = ga.areaName
              if not area or area == "" then
                -- Fallback: letztes Segment der Rich Presence ("Forever - PvP - The Barrens" -> "The Barrens")
                local rich = ga.richPresence
                if rich and rich ~= "" then area = rich:match("([^%-]+)%s*$") or rich; area = area:gsub("^%s+", "") end
              end
              out[#out + 1] = {
                game = game,
                friend = FriendName(acc),
                sortName = Lower(FriendName(acc) or acc.battleTag),
                bnetName = UsableName(acc.accountName) or acc.battleTag,
                battleTag = acc.battleTag,
                char = ga.characterName,
                level = tonumber(ga.characterLevel),
                class = ga.className,
                faction = ga.factionName,
                area = area,
                realm = UsableName(ga.realmDisplayName) or UsableName(ga.realmName),
                realmType = ParseRealmType(ga.richPresence),
                note = acc.note,
                pid = pid,
              }
            end
          end
        end
      end
    end
  end
end

local function CollectChars(out, stats)
  if not (C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex) then
    stats.notes[#stats.notes + 1] = "char friends: API missing"
    return
  end
  local seen = {}
  for _, e in ipairs(out) do
    if e.char and e.char ~= "" then seen[Lower(e.char)] = true end
  end
  local num = C_FriendList.GetNumFriends() or 0
  stats.charTotal = num
  for i = 1, num do
    local info = C_FriendList.GetFriendInfoByIndex(i)
    if info and info.connected then
      stats.charOnline = stats.charOnline + 1
      if not seen[Lower(info.name)] then
        out[#out + 1] = {
          game = "F",
          sortName = Lower(info.name),
          char = info.name,
          level = tonumber(info.level),
          class = info.className,
          area = info.area,
          note = info.notes,
          isChar = true,
        }
      end
    end
  end
end

local function SortEntries(list)
  table.sort(list, function(a, b)
    if a.game ~= b.game then return a.game == "R" end -- R oben, F unten
    if a.sortName ~= b.sortName then return a.sortName < b.sortName end
    return Lower(a.char) < Lower(b.char)
  end)
end

-- Frames ------------------------------------------------------------------
local anchor = CreateFrame("Frame", "FriendsListListAnchor", UIParent)
anchor:SetSize(HANDLE_SIZE, HANDLE_SIZE)
anchor:SetFrameStrata("MEDIUM")
anchor:SetClampedToScreen(true)
anchor:SetMovable(true)
anchor:RegisterForDrag("LeftButton")
if anchor.SetDontSavePosition then anchor:SetDontSavePosition(true) end

local handleBg = anchor:CreateTexture(nil, "BACKGROUND")
handleBg:SetAllPoints()
handleBg:SetColorTexture(0, 0, 0, 0.5)
local handlePlus = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
handlePlus:SetPoint("CENTER", 0, 0)
handlePlus:SetText("+")

local rows = {}

local function ApplyLock()
  anchor:EnableMouse(not db.locked)
  handleBg:SetShown(not db.locked)
  handlePlus:SetShown(not db.locked)
end

local function ToggleLock()
  db.locked = not db.locked
  ApplyLock()
  Print(db.locked and L.LOCKED or L.UNLOCKED)
end

local function SavePosition()
  local point, _, relPoint, x, y = anchor:GetPoint(1)
  db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
end

local function ApplyPosition()
  anchor:ClearAllPoints()
  anchor:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

anchor:SetScript("OnDragStart", function(self)
  if db.locked then return end
  self.isMoving = true
  self:StartMoving()
end)
anchor:SetScript("OnDragStop", function(self)
  if not self.isMoving then return end
  self.isMoving = false
  self:StopMovingOrSizing()
  SavePosition()
end)
anchor:SetScript("OnMouseUp", function(_, button)
  if button == "RightButton" then ToggleLock() end
end)

-- Whisper -----------------------------------------------------------------
local function Whisper(entry)
  if entry.isChar then
    if ChatFrame_SendTell then ChatFrame_SendTell(entry.char)
    elseif ChatFrameUtil and ChatFrameUtil.SendTell then ChatFrameUtil.SendTell(entry.char)
    else Dbg("whisper: no SendTell API") end
  else
    Dbg("whisper bnet: target=%s", entry.bnetName)
    if ChatFrame_SendBNetTell then ChatFrame_SendBNetTell(entry.bnetName)
    elseif ChatFrameUtil and ChatFrameUtil.SendBNetTell then ChatFrameUtil.SendBNetTell(entry.bnetName)
    else Dbg("whisper: no SendBNetTell API") end
  end
end

-- Zeilen ------------------------------------------------------------------
local function RowText(e)
  local parts = { e.game == "F" and GAME_F or GAME_R }
  if e.friend then parts[#parts + 1] = "|cffffffff" .. e.friend .. "|r" end
  local icon = FactionIcon(e.faction)
  if icon then parts[#parts + 1] = icon end
  if e.char and e.char ~= "" then parts[#parts + 1] = ClassHex(e.class) .. e.char .. "|r" end
  if e.level and e.level > 0 then parts[#parts + 1] = "|cffbbbbbb(" .. e.level .. ")|r" end
  return table.concat(parts, " ")
end

local function ShowTooltip(row)
  local e = row.entry
  if not e then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:AddLine(e.friend or e.char or "?", 1, 1, 1)
  if e.area and e.area ~= "" then GameTooltip:AddLine(e.area, 0.8, 0.8, 0.8) end
  -- Retail-Freunde: Servername (+ Typ), Forever-Freunde: nur Realm-Typ
  local server = e.game == "R" and e.realm or nil
  local serverLine
  if server and e.realmType then serverLine = server .. " (" .. e.realmType .. ")"
  else serverLine = server or e.realmType end
  if serverLine then GameTooltip:AddLine(serverLine, 0.6, 0.8, 1) end
  if e.note and e.note ~= "" then GameTooltip:AddLine(e.note, 1, 0.82, 0, true) end
  GameTooltip:Show()
end

local function GetRow(k)
  local row = rows[k]
  if row then return row end
  row = CreateFrame("Button", nil, anchor)
  row:SetHeight(ROW_HEIGHT)
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  if k == 1 then
    row:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 0)
  else
    row:SetPoint("BOTTOMLEFT", rows[k - 1], "TOPLEFT", 0, 0)
  end
  local hl = row:CreateTexture(nil, "BACKGROUND")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.12)
  hl:Hide()
  row.hl = hl
  local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  local font, size = fs:GetFont()
  fs:SetFont(font, size, "OUTLINE")
  fs:SetShadowColor(0, 0, 0, 1)
  fs:SetShadowOffset(1, -1)
  fs:SetPoint("LEFT", 0, 0)
  fs:SetJustifyH("LEFT")
  row.fs = fs
  row:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      ToggleLock()
    elseif self.entry then
      Whisper(self.entry)
    end
  end)
  row:SetScript("OnEnter", function(self)
    if not db.locked then self.hl:Show() end
    ShowTooltip(self)
  end)
  row:SetScript("OnLeave", function(self)
    self.hl:Hide()
    GameTooltip:Hide()
  end)
  rows[k] = row
  return row
end

local function Render(list)
  local n = #list
  -- list[1] ist die oberste Zeile; die letzte Zeile liegt am Anker (rows[1])
  for k = 1, n do
    local e = list[n - k + 1]
    local row = GetRow(k)
    row.entry = e
    row.fs:SetText(RowText(e))
    row:SetWidth(math.max(row.fs:GetStringWidth(), 1) + 2)
    row:Show()
  end
  for k = n + 1, #rows do
    rows[k].entry = nil
    rows[k]:Hide()
  end
end

-- Refresh -----------------------------------------------------------------
local lastSignature

local function DescribeEntry(e)
  return string.format("  %s %s (%s) | char=%s lvl=%s class=%s faction=%s area=%s realm=%s type=%s pid=%s note=%s",
    e.game, tostring(e.friend or "-"), tostring(e.battleTag or "-"), tostring(e.char), tostring(e.level), tostring(e.class),
    tostring(e.faction), tostring(e.area), tostring(e.realm), tostring(e.realmType), tostring(e.pid),
    (e.note and e.note ~= "") and "yes" or "no")
end

local function DoRefresh()
  local out = {}
  local stats = { bnetTotal = 0, bnetOnline = 0, charTotal = 0, charOnline = 0, notes = {}, otherClients = {} }
  CollectBNet(out, stats)
  local others = {}
  for client, count in pairs(stats.otherClients) do others[#others + 1] = client .. "=" .. count end
  table.sort(others)
  if #others > 0 then
    stats.notes[#stats.notes + 1] = "not in WoW (client=count): " .. table.concat(others, " ")
  end
  if db.showCharFriends then CollectChars(out, stats) end
  SortEntries(out)
  Render(out)

  if db.debug then
    local sig = {}
    for _, e in ipairs(out) do sig[#sig + 1] = DescribeEntry(e) end
    for _, n in ipairs(stats.notes) do sig[#sig + 1] = n end
    local signature = table.concat(sig, "\n")
    if signature ~= lastSignature then
      lastSignature = signature
      local r, f = 0, 0
      for _, e in ipairs(out) do if e.game == "R" then r = r + 1 else f = f + 1 end end
      Dbg("refresh: bnet friends=%s online game accounts=%s | shown R=%s F=%s | chars=%s (online=%s)",
        stats.bnetTotal, stats.bnetOnline, r, f, db.showCharFriends and "on" or "off", stats.charOnline)
      for _, line in ipairs(sig) do DEFAULT_CHAT_FRAME:AddMessage("|cff888888" .. line .. "|r") end
    end
  end
end

local refreshPending = false
local function RequestRefresh()
  if refreshPending then return end
  refreshPending = true
  C_Timer.After(REFRESH_DELAY, function()
    refreshPending = false
    local ok, err = pcall(DoRefresh)
    if not ok then Print("|cffff4040error:|r " .. tostring(err)) end
  end)
end

-- Diagnose ----------------------------------------------------------------
local function DebugBanner()
  local version, build, _, interface = GetBuildInfo()
  Dbg("client %s (build %s), interface %s, locale %s", version, build, interface, GetLocale())
  Dbg("WOW_PROJECT_ID=%s MAINLINE=%s CLASSIC=%s", WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC)
  Dbg("API: GetFriendAccountInfo=%s NumGameAccounts=%s GameAccountInfo=%s FriendList.GetFriendInfoByIndex=%s",
    Has(C_BattleNet and C_BattleNet.GetFriendAccountInfo), Has(C_BattleNet and C_BattleNet.GetFriendNumGameAccounts),
    Has(C_BattleNet and C_BattleNet.GetFriendGameAccountInfo), Has(C_FriendList and C_FriendList.GetFriendInfoByIndex))
  Dbg("API: SendBNetTell=%s SendTell=%s ClassColor=%s GetAtlasInfo=%s",
    Has(ChatFrame_SendBNetTell or (ChatFrameUtil and ChatFrameUtil.SendBNetTell)),
    Has(ChatFrame_SendTell or (ChatFrameUtil and ChatFrameUtil.SendTell)),
    Has(C_ClassColor), Has(C_Texture and C_Texture.GetAtlasInfo))
  local idx = ActiveIconIndex()
  Dbg("faction icon: variant %s (%s)%s | atlas horde=%s alliance=%s", idx, ICONS[idx].name,
    (db.icon or 0) == 0 and " [auto]" or " [manual]",
    tostring(AtlasExists("communities-icon-faction-horde")), tostring(AtlasExists("communities-icon-faction-alliance")))
end

local function Dump()
  local wowClient = BNET_CLIENT_WOW or "WoW"
  local num = BNGetNumFriends and (BNGetNumFriends()) or 0
  Print("dump: " .. num .. " bnet friends (online only)")
  for i = 1, num do
    local acc = C_BattleNet.GetFriendAccountInfo(i)
    if acc then
      local nga = C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendNumGameAccounts(i) or 0
      local list = {}
      for j = 1, nga do
        local ga = C_BattleNet.GetFriendGameAccountInfo(i, j)
        if ga then list[#list + 1] = ga end
      end
      if #list == 0 and acc.gameAccountInfo then list[1] = acc.gameAccountInfo end
      for _, ga in ipairs(list) do
        if ga.isOnline then
          DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff888888  %s client=%s%s pid=%s char=%s lvl=%s class=%s faction=%s area=%s realm=%s/%s rich=%s note=%s|r",
            tostring(acc.battleTag or acc.accountName), tostring(ga.clientProgram),
            ga.clientProgram == wowClient and "" or " (not WoW)", tostring(ga.wowProjectID),
            tostring(ga.characterName), tostring(ga.characterLevel), tostring(ga.className),
            tostring(ga.factionName), tostring(ga.areaName), tostring(ga.realmName),
            tostring(ga.realmDisplayName), tostring(ga.richPresence), tostring(acc.note)))
        end
      end
    end
  end
end

-- Slash-Befehle -----------------------------------------------------------
local function Help()
  Print(L.HELP:format(VERSION))
  for _, k in ipairs({ "HELP1", "HELP2", "HELP3", "HELP4", "HELP5", "HELP6" }) do
    DEFAULT_CHAT_FRAME:AddMessage(L[k])
  end
end

SLASH_FRIENDSLISTLIST1, SLASH_FRIENDSLISTLIST2 = "/fll", "/friendslistlist"
SlashCmdList.FRIENDSLISTLIST = function(msg)
  local cmd, arg = (msg or ""):match("^(%S*)%s*(%S*)")
  cmd = cmd:lower()
  if cmd == "" then
    ToggleLock()
  elseif cmd == "chars" then
    db.showCharFriends = not db.showCharFriends
    Print(db.showCharFriends and L.CHARS_ON or L.CHARS_OFF)
    if db.showCharFriends and C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends() end
    lastSignature = nil
    RequestRefresh()
  elseif cmd == "reset" then
    db.point, db.relPoint, db.x, db.y = "CENTER", "CENTER", 0, 0
    ApplyPosition()
    Print(L.RESET)
  elseif cmd == "debug" then
    db.debug = not db.debug
    Print(db.debug and L.DEBUG_ON or L.DEBUG_OFF)
    if db.debug then lastSignature = nil; DebugBanner(); RequestRefresh() end
  elseif cmd == "dump" then
    Dump()
  elseif cmd == "icon" then
    local n = tonumber(arg)
    if n and n >= 0 and n <= #ICONS then
      db.icon = math.floor(n)
      local idx = ActiveIconIndex()
      Print(L.ICON_SET:format(idx .. " – " .. ICONS[idx].name))
      lastSignature = nil
      RequestRefresh()
    else
      Print(L.ICON_USAGE:format(#ICONS))
      for i, ic in ipairs(ICONS) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d  %s   %s %s", i, ic.name, ic.Horde, ic.Alliance))
      end
    end
  else
    Help()
  end
end

-- Events ------------------------------------------------------------------
local events = CreateFrame("Frame")
local EVENT_LIST = {
  "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_FRIEND_INFO_CHANGED",
  "BN_CONNECTED", "BN_FRIEND_LIST_SIZE_CHANGED", "FRIENDLIST_UPDATE", "PLAYER_ENTERING_WORLD",
}

events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    FriendsListListDB = FriendsListListDB or {}
    db = FriendsListListDB
    for k, v in pairs(DEFAULTS) do
      if db[k] == nil then db[k] = v end
    end
    ApplyPosition()
    ApplyLock()
    for _, ev in ipairs(EVENT_LIST) do
      local ok = pcall(events.RegisterEvent, events, ev)
      if not ok then Dbg("event not available: %s", ev) end
    end
    Print(L.READY:format(VERSION))
    DebugBanner()
    if db.showCharFriends and C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends() end
    RequestRefresh()
    C_Timer.After(3, RequestRefresh) -- Battle.net-Daten kommen beim Login verzögert
  else
    RequestRefresh()
  end
end)
