# FriendsListList

**A tiny, borderless list of your online friends for World of Warcraft Forever.**

FriendsListList shows only the friends who are online right now and playing WoW Retail or WoW Forever. No frame, no background, no clutter: just plain text on your screen that grows from the bottom up. Hover a name to see where your friend is and your own note about them. Click to whisper.

*Illustration. Names are examples. The faction crests are simplified here; in game the add-on uses the crests from the game client.*

## Features

- Shows online Battle.net friends playing **Retail** (`R`, gold) or **Forever** (`F`, teal)
- Per row: game marker, friend name, faction crest, character name in class color, level
- Sorted from top to bottom: Retail first, then Forever, each alphabetically by BattleTag
- **Tooltip** on hover: friend name, location (zone or dungeon), realm type in color (PvE green, PvP red, RP-PvE dark green, RP-PvP dark red), the server name for Retail friends, and your Battle.net note, handy for friends whose name does not tell you who they are
- **Other characters:** the add-on remembers the characters a friend has been seen on and lists the others in the tooltip (most recent first, up to 6 shown, 10 saved per friend). It only knows characters it has seen online while it was installed
- **Guild** in the tooltip, per character: the game has no friend API for it, so the add-on looks it up with a throttled `/who` when you hover a Forever friend and remembers the result. The guild line appears about a second after the first hover. Retail friends and offline characters cannot be looked up. Turn it off with `/fll guild`
- **Left click** a row to whisper that friend
- **Right click** to lock or unlock the list. While unlocked, a small handle appears: drag it to move the list. The position is saved
- Text with outline and shadow, so it stays readable on any background
- Optional: also show character friends from the classic friends list (`/fll chars`, off by default)
- English and German (deDE) text

## Installation

1. Download the latest ZIP.
2. Extract it so that the folder `FriendsListList` sits in your AddOns directory:
   `World of Warcraft\_forever_\Interface\AddOns\FriendsListList`
3. Start the game or type `/reload`.

## Getting started

The list is locked by default, and while nobody is online it shows nothing. Type `/fll` to unlock it: a small handle appears. Drag the handle to the place you like, then right-click it (or any row) to lock the list again.

## Commands

| Command | Description |
| --- | --- |
| `/fll` | Lock or unlock the list |
| `/fll chars` | Show or hide character friends (default: hidden) |
| `/fll reset` | Reset the position to the screen center |
| `/fll names` | Friend names: as shown in game (default) or BattleTag |
| `/fll guild` | Turn the guild lookup (`/who` on tooltip hover) on or off (default: on) |
| `/fll forget` | Delete all saved characters and guilds of your friends |
| `/fll debug` | Toggle debug output in chat |
| `/fll dump` | Print raw data of all online friends, useful for bug reports |
| `/fll icon <n>` | Choose a faction crest variant, 0 = automatic |
| `/fll help` | Show the command list |

## Known limitations

- Designed for the WoW Forever client (Interface 16001). Not tested elsewhere.
- Which details the game provides for friends playing another game version can vary. If a field is missing, the row simply shows what is available.
- The faction crest uses textures from the game client. If it looks wrong, try `/fll icon 1` to `/fll icon 4`.
- Notes are read-only: edit them in the game's friends list as usual.
- Debug output in chat is off by default. Turn it on with `/fll debug` when you want to report a problem.

## Troubleshooting and feedback

If something looks wrong (missing friends, wrong crests, empty fields), please report it with:

1. the game client version,
2. the chat lines starting with `FLL dbg:` after you switched debug on with `/fll debug`,
3. the output of `/fll dump`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Copyright (c) 2026 neXter. All Rights Reserved. See [LICENSE](LICENSE).

You may download and use the add-on unmodified for personal, non-commercial use. Any copying, modification, or redistribution requires written permission from the author.

## Disclaimer

FriendsListList is a fan-made add-on and is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment, Inc. The add-on contains no Blizzard artwork. Faction crests are displayed by referencing textures that already ship with the game client.

## Author

neXter
