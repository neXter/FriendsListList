# FriendsListList – Konzept (WoW Forever Add-on)

Stand: 2026-11-08 · Pieter Walsweer

## Produktziel & Scope

FriendsListList ist eine schlanke Liste ohne Rahmen. Sie zeigt nur die Freunde, die gerade online sind und WoW Retail oder WoW Forever spielen. Das Add-on läuft ausschließlich im WoW-Forever-Client.

**Drin:**

- Battle.net-Freunde (RealID/BattleTag), deren aktives Spiel Retail oder Forever ist
- Optional per Befehl `/fll chars` (Standard: aus): Charakterfreunde der klassischen Freundesliste (nur Forever, da gleicher Client)
- Klick-Whisper, Lock/Unlock, frei verschiebbar, Position wird gespeichert
- Tooltip beim Hover mit Ort (Zone/Dungeon) und Notiz zum Freund (die Notiz hilft bei BattleTag-Freunden ohne RealID, deren Namen nichts verraten)

**Nicht drin:** Offline-Freunde, andere Spiele (Diablo, Overwatch, Classic Era usw.), Optionsmenü, Notizen bearbeiten, Gruppen, Sortier-Einstellungen, Minimap-Button.

## Mini-Mock

![Mini-Mock: gesperrt vs. entsperrt, 2 Forever- + 2 Retail-Freunde](assets/mock.svg)

Von oben nach unten stehen erst die Retail-Freunde (Lena, Tobi), dann die Forever-Freunde (Jonas, Mara), jeweils alphabetisch. Alle haben ein Fraktionswappen. Ein türkises F markiert Forever, ein goldenes R markiert Retail. Rechts zeigt der Tooltip Ort und Notiz zu Mara. Die Wappen sind im Mock vereinfacht nachgezeichnet. Alle Namen sind Beispiele.

## Anzeige-Regeln

Eine Zeile pro Freund. Die Felder werden nur durch Leerzeichen getrennt, ohne Spaltenköpfe, Rahmen oder Hintergrund. Damit der Text auf der bunten Spielwelt lesbar bleibt, hat jede Zeile eine dünne schwarze Kontur und einen schwarzen Schatten.

| Feld | Forever-Freund | Retail-Freund | Darstellung |
| --- | --- | --- | --- |
| Spiel-Marker | F in Türkis (`#3FB8AF`) | R in Gold (`#E8B83A`) | fetter Buchstabe am Zeilenanfang |
| Freundesname | ja | ja | weiß. RealID-Freunde: Name wie im Spiel (geschützter Token, der Client zeigt in der Liste den echten Namen). Reine BattleTag-Freunde: BattleTag ohne `#Nummer`. Mit `/fll names` immer der BattleTag |
| Fraktion | ja | ja | Horde- bzw. Allianz-Wappen, 14 px, direkt vor dem Charakternamen |
| Charaktername | ja | ja | Klassenfarbe |
| Level | ja | ja | grau, in Klammern hinter dem Charakternamen |
| Ort (Zone/Dungeon) | Tooltip | Tooltip | nicht in der Zeile, damit die Liste schmal bleibt |

```
R  Lena   [Allianz-Wappen] Sylvarin (90)
R  Tobi   [Horde-Wappen] Grimhold (88)
F  Jonas  [Allianz-Wappen] Brightwen (47)
F  Mara   [Horde-Wappen] Kaelthor (60)   ← Anker unten
```

**Sortierung:** Gelesen von oben nach unten stehen erst alle Retail-Freunde (R), dann alle Forever-Freunde (F). Innerhalb jeder Gruppe wird alphabetisch nach BattleTag sortiert, weil der echte Name eines RealID-Freundes ein geschützter Wert ist und sich nicht sortieren lässt. Die Liste wächst von unten nach oben: Der Anker sitzt unten, neue Zeilen schieben die Liste nach oben. Die letzte Zeile der Sortierung liegt deshalb direkt am Anker. Technisch bekommt die letzte Zeile der sortierten Liste `rows[1]`, die erste Zeile den höchsten Index.

**Charakterfreunde** (klassische Freundesliste, ohne Battle.net) erscheinen nur nach `/fll chars`, Standard ist aus. Sie zeigen F, Charaktername und Level, aber keinen Freundesnamen. Der Ort steht wie bei allen im Tooltip. Die Fraktion fehlt, weil die klassische Freundesliste sie nicht liefert.

**Tooltip:** Beim Hover über eine Zeile erscheint ein Tooltip mit bis zu vier Zeilen:

1. Freundesname (weiß, fett)
2. Ort des Charakters: Zone, Dungeon oder Schlachtfeld, ungekürzt (hellgrau)
3. Server (hellblau): bei Retail-Freunden Servername und, wenn bekannt, Realm-Typ, z. B. `Ravencrest (RP-PvE)`. Bei Forever-Freunden nur der Realm-Typ (`PvP`, `PvE`, `RP`, `RP-PvP`, `RP-PvE`). Der Typ wird aus der Rich Presence gelesen (`Forever - PvP - The Barrens`), ersatzweise aus dem Realm-Namen (`CAMWOW EU5 Realm 3 PvE`), der Servername aus `realmName`/`realmDisplayName`. Der Typ ist farbig: PvE grün, PvP rot, RP-PvE dunkelgrün, RP-PvP dunkelrot (`RP` allein zählt als RP-PvE). Fehlt eine Angabe, entfällt die Zeile.
4. Notiz aus der Freundesliste (gelb), nur wenn eine gepflegt ist

Die Notiz wird in WoW gepflegt, das Add-on liest sie nur.

**Leere Liste:** Gesperrt ist nichts zu sehen. Entsperrt ist nur der Verschiebe-Griff sichtbar.

## Interaktion

| Aktion | Wo | Ergebnis |
| --- | --- | --- |
| Linksklick | Zeile | Öffnet einen Whisper: Battle.net-Whisper für BNet-Freunde, Charakter-Whisper für Charakterfreunde |
| Hover | Zeile | Tooltip mit Ort und Notiz zum Freund |
| Rechtsklick | beliebige Zeile | Wechselt zwischen gesperrt und entsperrt |
| Rechtsklick | Griff | Sperrt wieder |
| Ziehen | Griff (nur entsperrt) | Verschiebt die Liste, die Position wird gespeichert |
| `/fll` | Chat | Wechselt Lock/Unlock (Notlösung, wenn die Liste leer ist) |
| `/fll chars` | Chat | Zeigt zusätzlich die Charakterfreunde der klassischen Freundesliste oder blendet sie wieder aus (Standard: aus) |
| `/fll reset` | Chat | Setzt die Position auf die Bildschirmmitte zurück |
| `/fll names` | Chat | Wechselt den Freundesnamen zwischen Spielname (Standard) und BattleTag |
| `/fll debug` | Chat | Schaltet die Debug-Ausgabe im Chat um (standardmäßig aus) |
| `/fll dump` | Chat | Gibt die Rohdaten aller Online-Freunde aus, für Fehlerberichte |
| `/fll icon <n>` | Chat | Wählt eine Variante des Fraktions-Icons (0 = automatisch) |

Gesperrt ist die Liste reiner Text. Klicks gehen nur an die Zeilen, die Fläche dazwischen ist durchklickbar. Entsperrt erscheint links unten am Anker ein Griff von 12×12 px, und die Zeilen bekommen einen sehr schwachen Hover-Hintergrund.

## Technisches Konzept

Forever nutzt laut Community-Berichten dieselbe Add-on-API wie Retail (Mainline 12.x), inklusive der Midnight-Einschränkungen ([Kami Labs](https://kami-labs.fr/en/wow-classic/wow-forever-addons-restreints-comme-sur-midnight/)). Freundesliste und Chat sind davon nach heutigem Stand nicht betroffen. Das Add-on besteht aus einer Lua-Datei mit geschätzt 200 Zeilen, ohne Libraries.

**Dateien**

```
FriendsListList/
  FriendsListList.toc   -- ## Interface: 16001, SavedVariables: FriendsListListDB
  FriendsListList.lua   -- gesamte Logik
```

**Datenquellen**

- Battle.net: `BNGetNumFriends()` → `C_BattleNet.GetFriendAccountInfo(i)` → `C_BattleNet.GetFriendNumGameAccounts(i)` und `C_BattleNet.GetFriendGameAccountInfo(i, j)`.
- Filter: `isOnline`, `clientProgram == BNET_CLIENT_WOW`, dann Unterscheidung über `wowProjectID`: gleich der eigenen `WOW_PROJECT_ID` = Forever (so muss die Forever-ID nicht bekannt sein), gleich `WOW_PROJECT_MAINLINE` = Retail. Alles andere (Classic Era, andere Spiele) wird übersprungen und im Debug-Log vermerkt.
- Felder: `accountName` bzw. `battleTag` (Freundesname), `characterName`, `characterLevel`, `className`, `areaName`, `factionName`.
- Notiz BNet: `accountInfo.note` aus `C_BattleNet.GetFriendAccountInfo(i)`. Funktioniert für RealID- und BattleTag-Freunde.
- Charakterfreunde (nur wenn per `/fll chars` aktiviert): `C_FriendList.GetNumOnlineFriends()` → `C_FriendList.GetFriendInfoByIndex(i)` (`name`, `level`, `className`, `area`, `notes`).
- Klassenfarbe: `className` ist lokalisiert. Über eine invertierte `LocalizedClassList()` wird der `classFile` ermittelt, dann `C_ClassColor.GetClassColor(classFile)`.

**Events** (alle lösen ein gedrosseltes Refresh aus, max. 1× pro 0,5 s via `C_Timer.After`)

- `PLAYER_LOGIN` (Init, DB laden, Position setzen)
- `BN_FRIEND_ACCOUNT_ONLINE`, `BN_FRIEND_ACCOUNT_OFFLINE`, `BN_FRIEND_INFO_CHANGED`
- `FRIENDLIST_UPDATE`
- Zusätzlich `C_FriendList.ShowFriends()` beim Login, aber nur wenn Charakterfreunde aktiviert sind.

**Frame-Aufbau**

1. `anchor`: unsichtbarer Frame, `SetMovable(true)`, `SetClampedToScreen(true)`, Ankerpunkt `BOTTOMLEFT`.
2. `rows[i]`: Button-Pool, Zeile *i* hängt an `rows[i-1]` per `BOTTOMLEFT → TOPLEFT`. So wächst die Liste nach oben. Jede Zeile hat einen FontString (`GameFontHighlightSmall`, Flag OUTLINE, dazu `SetShadowColor(0, 0, 0, 1)` und `SetShadowOffset(1, -1)`), Höhe 14 px. `RegisterForClicks("LeftButtonUp", "RightButtonUp")`. `OnEnter`: `GameTooltip:SetOwner(row, "ANCHOR_RIGHT")`, Freundesname als Titel, dann `areaName` bzw. `area`, dann die Notiz mit Umbruch, falls vorhanden. `OnLeave`: `GameTooltip:Hide()`.
3. `handle`: 12×12-px-Button am `anchor`, nur entsperrt sichtbar. `RegisterForDrag("LeftButton")`, `OnDragStart` → `anchor:StartMoving()`, `OnDragStop` → `StopMovingOrSizing()` und Position speichern.
4. Fraktionswappen inline im Text per `|T...|t` (14 px) direkt vor dem Charakternamen. Dafür werden die Horde- und Allianz-Wappen genutzt, die schon im Spiel-Client liegen, etwa `Interface\TargetingFrame\UI-PVP-Horde` / `UI-PVP-Alliance` (PvP-Flaggen-Icons, brauchen Texturkoordinaten-Zuschnitt) oder ein entsprechendes Atlas-Icon. Der genaue Pfad wird im Spiel per Texture-Browser geprüft. Die Wappen werden nur referenziert und nicht mitgeliefert. Wenn keine passende Client-Textur taugt, gibt es als Ausweichlösung eine eigene, stark vereinfachte 16-px-Textur in Rot bzw. Blau. Der Spiel-Marker ist eingefärbter Text am Zeilenanfang: `|cff3FB8AFF|r` für Forever (Türkis) und `|cffE8B83AR|r` für Retail (Gold). Die Farben lehnen sich an die beiden Spiel-Logos an. Die Logos selbst werden aus rechtlichen Gründen nicht verwendet. Falls später ein Icon gewünscht ist, kommt eine eigene 12-px-Textur in Frage, etwa ein Kreis mit F bzw. R in diesen Farben.

**Whisper**

- BNet: `ChatFrame_SendBNetTell(accountName)`. Ab 12.x eventuell nur noch über `ChatFrameUtil`, das wird beim Bau geprüft.
- Charakter: `ChatFrame_SendTell(name)`.

**SavedVariables**

```lua
FriendsListListDB = {
  locked = true,
  showCharFriends = false,
  debug = false,  -- Debug-Ausgabe im Chat, per /fll debug
  icon = 0,       -- 0 = automatisch, sonst Variante 1-4
  point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 40, y = 300,
}
```

**Nur Forever:** In der TOC steht Interface 16001, die Nummer, mit der auch EmoteBar unter Forever läuft. Ein Abbruch bei falscher Projekt-ID ist in 1.0 nicht eingebaut, weil die Forever-ID unbekannt ist. Stattdessen schreibt das Debug-Log beim Login `WOW_PROJECT_ID` und die Interface-Nummer in den Chat.

**Konventionen aus EmoteBar:** Installationspfad `World of Warcraft\_forever_\Interface\AddOns\FriendsListList`. Texte in Deutsch und Englisch, gewählt per `GetLocale()` (deDE = Deutsch, sonst Englisch). Chat-Befehle mit kurzem Kürzel (`/fll`). TOC mit `Notes` und `Notes-deDE`.

## Offene Fragen & Risiken

- [ ] Welche `wowProjectID` liefert ein Forever-Freund? Im Client mit `/dump` an einem Forever-Freund prüfen.
- [ ] Liefert die BNet-API für Retail-Freunde aus dem Forever-Client Charaktername, Level, Fraktion (`factionName`) und Ort (`areaName`)? Projektübergreifend können Felder leer sein. Dann zeigen Zeile und Tooltip nur, was ankommt, ohne Wappen, wenn die Fraktion fehlt.
- [ ] Ist `ChatFrame_SendBNetTell` in 12.x noch global, oder nur über `ChatFrameUtil` erreichbar?
- [ ] Welche Client-Textur bzw. welches Atlas-Icon zeigt Horde- und Allianz-Wappen sauber in 14 px? Im Spiel per Texture-Browser prüfen. Kandidaten: `Interface\TargetingFrame\UI-PVP-Horde` / `UI-PVP-Alliance`.

- Risiko: Weitere Secret-Value-Einschränkungen aus Midnight könnten auch Freundesdaten treffen. Bisher gibt es dafür keinen Hinweis.

## Quellen

- [Kami Labs: WoW Forever Addons – As Restricted As Midnight](https://kami-labs.fr/en/wow-classic/wow-forever-addons-restreints-comme-sur-midnight/) (Sekundärquelle, keine Blizzard-Doku)
- EmoteBar (eigenes Forever-Add-on, lokal): Interface 16001, Installationspfad, Lokalisierung, Slash-Konventionen
