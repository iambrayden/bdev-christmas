# bdev-christmas

Christmas advent calendar, daily spin wheel and unwrappable presents for FiveM (Qbox + ox_inventory). It works like `bdev-halloween`, plus custom Christmas items.

## Features

- **Advent calendar.** `/christmas` opens a NUI advent board with 25 doors, a live countdown to Christmas morning and a timer for the next door.
- **One spin per door, Dec 1–25.** A door can be opened on its own day plus one grace day (`Config.GraceDays`). After that it expires. Door 25 uses a special Christmas wheel and stays open through Dec 26.
- **The wheel gets better every day.** Odds slide from `weight` to `lateWeight` across the month, cash and stack sizes ramp from x1.0 to x2.0 (x2.5 on Christmas), and a cheer level climbs from Frosty to Christmas.
- **Custom items.** Candy canes, hot chocolate, gingerbread men, sugar cookies and eggnog restore hunger/thirst with an animation. Six collectible ornaments, from Rare to Legendary.
- **Presents are loot boxes.** Four tiers: Wrapped, Silver, Gilded and North Star. Use one from your inventory, or from the Presents tab, to get the unwrap screen: shake it three times and it bursts open, with rays, confetti and sleigh bells scaled to the rarity. Presents can contain other presents.
- **Everything is saved in MySQL:**
  - Each door spin and each unwrap is saved **before** anything is handed over. Players can't reroll by filling or emptying their pockets, disconnecting or crashing.
  - If a player's pockets are full, the prize waits under **Unclaimed gifts** until they make room.
  - The **Ornament collection** tracks which ornaments each character has unwrapped this season.
  - **Recent unwraps** shows rare and better finds from across the server.
  - **Most presents unwrapped** is a leaderboard for the season.
- A chat announcement to everyone when someone unwraps a Legendary (`Config.Announce`).
- Chat message when a character loads, and a server-wide reminder every hour.

## Install

1. Drop `bdev-christmas` into your resources folder.
2. **Add the items to ox_inventory.** Copy the entries from `install/items.lua` into `ox_inventory/data/items.lua`.
3. **Add the item images.** Copy everything in `install/images/` into `ox_inventory/web/images/`.
4. Add `ensure bdev-christmas` to `server.cfg` **after** `ox_lib`, `oxmysql`, `qbx_core` and `ox_inventory`.
5. Restart. The `bdev_christmas_claims` and `bdev_christmas_unwraps` tables are created automatically (`sql/christmas.sql` is there if you'd rather run it by hand).

On start, the server prints a warning for any reward or present item that ox_inventory doesn't recognize. That usually means step 2 was skipped.

To give someone presents for testing: `/giveitem <id> xmas_present 5`.

## Config

Everything lives in `config.lua`:

| Option | Default | What it does |
|---|---|---|
| `Command` | `christmas` | Chat command that opens the calendar |
| `ServerName` | `Last Chance Roleplay` | Small text above the title |
| `GraceDays` | `1` | Extra days a door stays open after its own day (`0` = same day only) |
| `TrackBy` | `citizenid` | `citizenid` = one calendar per character, `license` = one per player |
| `DebugDay` | `nil` | Set to 1–25 to test a specific day. **Leave nil on live.** |
| `Items` | 15 items | Rarity of each custom item, and which ones count as collectible ornaments |
| `Presents` | 4 presents | Loot table for each present: `{ item, min, max, weight }` or `{ money = { min, max }, weight, rarity }` |
| `Feed` | `rare`, 8 rows | Lowest rarity shown in Recent unwraps, and how many rows |
| `Announce` | `legendary` | Lowest rarity announced in chat to everyone (`nil` = off) |
| `Leaderboard` | `5` | Rows on the Most presents unwrapped board (`0` = hide) |
| `Tiers` | 6 tiers | Advent wheel reward pools |
| `Wheel` | 11 segments | Doors 1–24. `weight` (Dec 1) slides to `lateWeight` (Dec 24) |
| `ChristmasWheel` | 6 segments | Door 25 |
| `Intensity` | | Amount multiplier ramp and cheer level names |

Doors unlock at midnight **server time**. Every win and unwrap is logged to the server console.

### Adding your own items

1. Add the item to `ox_inventory/data/items.lua` and drop a PNG in `ox_inventory/web/images/`.
2. Add it to `Config.Items` with a rarity (and `collectible = true` if it should show in the ornament collection).
3. Put it in a present's `rewards` or a wheel tier.

To make a new present tier, add an item with `client = { export = 'bdev-christmas.usePresent' }` and a matching entry in `Config.Presents`. For custom artwork in the menu, add an SVG to `html/art.js` under the item name. Anything without art uses its ox_inventory image.
