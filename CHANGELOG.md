# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.2.0] - 2026-11-08

### Added

- Realm types in the tooltip are colored: PvE green, PvP red, RP-PvE dark green, RP-PvP dark red.
- `/fll names` switches the friend name between the name shown in game (default) and the BattleTag.

### Fixed

- Friends who are only BattleTag friends (no RealID) are shown with their BattleTag without the `#number` instead of a hidden name.
- The realm type is also read from the realm name (for example `... Realm 3 PvE`), because the rich presence only carries it for some realms.

### Changed

- The list is sorted by BattleTag within each group, because the real name of a RealID friend is a protected value and cannot be sorted.
- Debug lines and `/fll dump` show `btFriend` and the raw account name to help with name problems. Friend names are protected values by the game, so they cannot be copied from the chat.

## [1.1.0] - 2026-11-08

### Added

- Tooltip shows the realm type (PvP, PvE, RP, RP-PvP, RP-PvE) and, for Retail friends, the server name.

### Fixed

- Friends whose Battle.net name is hidden (`???`) are shown with their BattleTag without the `#number`.

### Changed

- Debug output in chat is now off by default (`/fll debug` switches it on). The welcome line no longer mentions it.
- Debug output summarizes friends that are online but not in WoW (App, mobile app) in one line.

## [1.0.0] - 2026-11-08

First release. Debug output in chat is on by default in this version; switch it off with `/fll debug`.

### Added

- Minimal borderless list of online Battle.net friends playing WoW Retail (`R`, gold) or WoW Forever (`F`, teal).
- Per row: game marker, friend name, faction crest, character name in class color, level in parentheses.
- Sorting from top to bottom: Retail first, then Forever, each by friend name. The list grows from the bottom up.
- Tooltip on hover with friend name, location (zone/dungeon) and the Battle.net note.
- Left click opens a whisper, right click locks/unlocks the list.
- Drag handle (visible only while unlocked), position is saved.
- Optional character friends of the classic friends list (`/fll chars`, off by default).
- Slash commands: `/fll`, `/fll chars`, `/fll reset`, `/fll debug`, `/fll dump`, `/fll icon <n>`, `/fll help`.
- Debug output in chat: client and API availability at login, what each refresh found and why friends were skipped.
- Faction icon variants (`/fll icon`) because the exact client texture is not yet verified.
- English and German texts.
- Add-on list icon (`Icons/icon.tga`).
