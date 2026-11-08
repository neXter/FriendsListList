# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-11-08

First release. Debug output is on by default so that early feedback is easy; switch it off with `/fll debug`.

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
