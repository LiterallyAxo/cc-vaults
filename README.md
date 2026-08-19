# cc-vaults

ComputerCraft (CC: Tweaked) scripts for a Create factory, with a tiny package
manager to install and update them.

```
wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vaults.lua
vaults install
```

That fetches everything in [`manifest.txt`](manifest.txt) and drops each script
in the computer root, so you run it by name:

```
stock
```

## Scripts

| Name | What it is |
| --- | --- |
| [`stock`](scripts/stock.lua) | Live Create Item Vault dashboard on a monitor |
| [`rail`](scripts/rail.lua) | UK style train information displays for Create trains |
| [`warn`](scripts/warn.lua) | Scrolling hazard sign for a long line of monitors |
| [`vaults`](vaults.lua) | The package manager itself — it is in the manifest too, so it updates itself |

More are coming; adding one is a single line in `manifest.txt`, no installer
change needed.

## vaults — the package manager

| Command | What it does |
| --- | --- |
| `vaults install [name ...]` | install everything in the manifest, or just the named scripts |
| `vaults update [name ...]` | update what is installed, `vaults` included |
| `vaults list` | what is available, what is installed, what is out of date |
| `vaults run <name> [args]` | run a script, installing it first if missing |
| `vaults remove <name>` | delete one script |
| `vaults startup <name> on\|off` | run a script when the computer boots (`vaults startup off` clears it) |
| `vaults version` | this manager against the manifest |
| `vaults uninstall` | remove every installed script |

Installed versions are recorded in `.vaults-state` on the computer, so `list`
and `update` can tell you what actually moved.

---

# stock — Vault Network dashboard

```
| VAULT NETWORK                                                             06:00
  29.8K items  16 types  4 vaults                                 +448 last scan
  SLOTS  |||||||||||                18/189  10%                     next scan 3s
   STOCK   MOVERS   VAULTS                                          SORT: COUNT
| Sand                  ||||||||||||||||||||  12.8K | Oak Log      |||      448
| Cobblestone           ||||||||||             6,400 | Brass Ingot  ||       384
| Andesite Alloy        ||||                   2,492 | Copper Ingot ||       320
| Redstone Dust         ||||                   2,304 | Gold Ingot   |        192
  < PREV                              PAGE 1/1                            NEXT >
```

## Wiring

```
computer ── wired modem ── networking cable ── modem on each Item Vault
                                └─ monitor (or attach the monitor directly)
```

Right-click every modem so it turns red and says *"Peripheral … attached"* — an
un-activated modem means the computer cannot see that vault. A multiblock vault
is one peripheral, so one modem per vault structure is enough.

Use an **Advanced Monitor**: the dashboard repaints the 16 colour palette into a
dark theme, which basic monitors cannot do (they still work, just in grey). Any
size works — the layout re-flows into two or three columns on wide monitors,
balances them, shortens the sort button before it can touch the tabs, and drops
the capacity gauge on very short screens.

## Views

Three tabs, switched by tapping the monitor or pressing `Tab`:

- **STOCK** — every item across every vault, with a share bar and the total.
  Once something moves, a change column appears next to the counts.
- **MOVERS** — only what changed since the last scan, biggest swing first.
  This is the view to leave up while a factory is running.
- **VAULTS** — one row per vault with a fill gauge, slots used and item count.
  An unresponsive vault is flagged in red here and counted on the title bar.

Tap any item for a **breakdown panel**: its id, total, stack count and how it is
spread across the vaults. Tap again to dismiss.

## Controls

| Action | Monitor | Keys |
| --- | --- | --- |
| Switch view | tap `STOCK` / `MOVERS` / `VAULTS` | `Tab` |
| Change sort (count / name / change) | tap the sort button | `S` |
| Previous / next page | tap the left / right third of the footer | ← → ↑ ↓ PgUp PgDn |
| Item breakdown | tap an item row | — |
| Close the breakdown | tap anywhere | `Esc` |
| Force a rescan | tap the title bar | `R` |
| Quit | — | `Q` |

## Configuration

At the top of `scripts/stock.lua` (or `stock.lua` once installed):

| Option | Default | What it does |
| --- | --- | --- |
| `refresh` | `5` | Seconds between rescans |
| `textScale` | `0.5` | Monitor text scale — smaller means more rows |
| `vaultPattern` | `"vault"` | Peripheral type must contain this string |
| `includeAll` | `false` | Set `true` to count **every** inventory (chests, barrels, …) |
| `detailBudget` | `40` | `getItemDetail` calls per scan — each costs a server tick, so new item names resolve over a few refreshes |
| `colWidth` | `40` | Target width of one item column |
| `usePalette` | `true` | Recolour the palette; set `false` to keep vanilla colours |

## How it draws

Three CC: Tweaked features do the heavy lifting:

- **`setPaletteColour`** redefines all 16 colour slots on an advanced monitor,
  so the dashboard uses a real dark theme instead of Minecraft's default 16.
  The original palette is captured at startup and restored on exit.
- **`blit`** writes a whole row of text plus per-character colours in one call.
  The renderer builds each frame in memory and only blits the rows that
  actually changed, so refreshes do not flicker.
- **`\149`**, one of the sub-character block glyphs, fills half a cell — that is
  what gives the bars half-character precision instead of whole blocks.

Scanning runs `list()` on every vault in parallel (in batches of 50), so a
network of dozens of vaults still refreshes in a single tick's worth of calls.

---

# rail — train information displays

Boards for a Create railway, in the style of the ones on the British network.
One script, several modes; you pick the mode that suits the screen you have
just built.

**New to it? [RAIL-SETUP.md](RAIL-SETUP.md) is the whole thing from nothing**,
in order, with the blocks to place and what to type. What follows here is the
reference.

```
 >>      CREATE CENTRAL            Departures                             15:26
 Time  Destination                                             Plat  Expected
 ------------------------------------------------------------------------------
 15:30 London Euston  via Coventry                             3      On time
 15:35 Manchester Piccadilly                                   5        15:42
 15:39 Cardiff Central                                         -    Cancelled
 15:44 Nottingham                                              8      On time
 15:48 Leamington Spa  via Solihull                            2      On time
 15:53 Liverpool Lime Street                                   4        15:56
                                                            +2 later services
 ------------------------------------------------------------------------------
 See it. Say it. Sorted. Text the British Transport Police on 61016.
```

```
rail                  departures board (the default)
rail arrivals         arrivals board
rail platform [n]     the big board at the end of a platform
rail summary [n]      one line "next train" dot matrix
rail onboard          in-carriage passenger information
rail route            in-carriage route diagram
rail concourse        station clock over the next departures
rail stats            back-office screen: mesh and data health
rail flap             push the next departure onto Create displays
rail hub              the mesh database; reads the stations, serves them
                      by rednet, and is the only computer that checks for
                      updates. With a monitor attached it draws a touchable
                      engineering console instead of a departure board
rail stations         list what this computer can see, and why
rail times            the hop times it has measured, and how sure
rail link             check the modems and listen for hubs
rail setup            write a starter rail.cfg you can edit

rail departures arrivals platform      one mode per monitor, in
                                       peripheral-name order
```

A computer with several monitors attached drives them all: pass one mode per
screen and they are handed out in peripheral-name order, so the mapping is
stable across reboots. Fewer modes than screens and the last one repeats.

`rail stations` is the one to run first, and the one to run when a board comes
up empty:

```
2 station(s) visible from here:

create:track_station_0
  called: Create Central Platform 3
  platform 3  [ours]
  train standing, train 1A23
  calls at: Coventry, Rugby, London Euston

create:track_station_1
  called: Create Central Platform 5
  platform 5  [ours]
  train enroute, train 1M14

2 of them count as Create Central
```

No stations listed means a wired modem is not switched on. `[not ours]` means
`station` in `rail.cfg` does not match what the stations are called in game.

## The modes

| Mode | What it is on the real railway | Monitor it wants |
| --- | --- | --- |
| `departures` | the summary board over the concourse: Time / Destination / Plat / Expected, with a scrolling notice along the bottom | wide, 4×3 or bigger |
| `arrivals` | the same board for trains coming in, listing where each one has come from | wide, 4×3 or bigger |
| `platform` | the board at the platform end: the next train in full, its calling points scrolling underneath, then the ones after it | wide, 3×2 upwards |
| `summary` | the little dot matrix over a doorway or on a platform post: one line, rotating between the train, its calling points and its formation | 2×1, even 1×1 |
| `onboard` | the screen in the carriage — "This train is for … The next station is …" — rotating with the calling list and the welcome message | 3×2 |
| `route` | the strip of dots in the vestibule showing where the train is along its route, with a list of stops and times | 3×3 or taller |
| `concourse` | the station clock in big digits with the next few departures under it | 4×3 |
| `flap` | not a monitor at all: writes the next departure onto Create flap displays, nixie tubes or a sign through CC:C Bridge | — |
| `hub` | no display; reads every station on its network and broadcasts what it sees to the other computers | — |
| `stations` | no display; prints every Train Station this computer can see, what stops there and whether it counts as ours | — |
| `link` | no display; lists the modems, opens rednet and prints every hub broadcast it hears for fifteen seconds | — |

Every mode re-flows to whatever size it finds, and drops columns rather than
overflowing: the platform column goes below 46 characters wide, the expected
column below 34, and anything under three rows falls back to the one line
layout. Press `Tab` on the computer to cycle the display modes while you decide
which one you want.

## What you need

| Block | Why |
| --- | --- |
| Advanced Computer | runs the script; advanced so it can recolour the palette |
| Advanced Monitor ×N | the board itself — basic monitors work, in grey |
| Wired Modem (one per Train Station, one on the computer) | lets the computer read the stations |
| Networking Cable | joins them up |
| Create Train Station | the block that actually knows about the trains |
| Ender Modem *(optional)* | for `rail hub`, if running cable to every board is a pain |
| CC:C Bridge Source Block + Display Link *(optional)* | for `rail flap` |

## Wiring

```
                      ┌── modem ── Train Station (platform 1)
computer ── modem ────┼── modem ── Train Station (platform 2)
    │   networking    └── modem ── Train Station (platform 3)
    │   cable
    └── monitor (placed against the computer, or on the same cable)
```

Right-click every modem until it turns red and says *"Peripheral … attached"* —
an un-activated modem means the computer cannot see that station. Name each
Train Station in game with its platform in the name (`Create Central Platform
3`) and `rail` works the platform numbers out for itself. **A station with no
platform in its name is platform 1**; otherwise map them in
`rail.cfg`.

## rail.cfg

`rail setup` writes a commented starter config to the computer. Everything you
leave out keeps its default.

| Option | Default | What it does |
| --- | --- | --- |
| `mode` | `nil` | what to show when `rail` is run with no argument, so a board comes back by itself after a reboot |
| `station` | `"Create Central"` | the station this display belongs to; also picks which Train Stations count as ours |
| `code` | `"CRC"` | three letter station code |
| `operator` | `"Create Rail"` | named on the onboard displays |
| `theme` | `"dot"` | `"dot"` amber dot matrix, `"lcd"` the modern navy screens |
| `clock` | `"mc"` | `"mc"` in-game time, `"real"` your own clock |
| `platform` | `nil` | which platform a `platform` / `summary` display serves |
| `refresh` | `1` | seconds between peripheral scans |
| `scroll` | `0.4` | seconds per column of scrolling text |
| `rows` | `0` | departures to list; `0` means as many as fit |
| `dwell` / `legRun` | `10` / `45` | **real seconds** a train stands, and a leg takes; converted to in-game minutes (1s = 1.2m) |
| `memory` | `900` | **real seconds** a platform stays on the board after its train has gone; the calling pattern itself is never forgotten |
| `master` | `false` | this computer is the mesh database; `rail hub` sets it anyway. Only the master polls GitHub, and it pushes new versions to everybody else |
| `autoUpdate` | `60` | seconds between update checks on the master; `0` turns it off |
| `platforms` | `{}` | Train Station peripheral (or in-game name) to platform number |
| `timetable` | `{}` | the booked services; see below |
| `train` / `route` | `nil` | onboard and route displays: the Create train name and the stations it works through |
| `messages` | safety notices | the scrolling line along the bottom |
| `demo` | `true` | invent a timetable when nothing is wired up; ignored once a station is visible |

A timetable entry looks like a line out of a real one:

```lua
timetable = {
  { depart = "15:26", platform = 3, coaches = 9, via = "Coventry",
    origin = "Wolverhampton", operator = "Create West Coast",
    calls = { "Coventry", "Rugby", "Milton Keynes Central", "London Euston" } },
  { depart = "15:41", platform = 5, delay = 7,
    calls = { "Stafford", "Crewe", "Manchester Piccadilly" } },
  { depart = "15:52", platform = 10, cancelled = true,
    calls = { "Newport", "Cardiff Central" } },
}
```

`calls` ends with the final destination, which is what the board advertises.
`delay` in minutes turns the Expected column into a time; `cancelled = true`
greys the service out and takes its platform away.

## Where the numbers come from

In order of preference:

1. **A timetable in `rail.cfg`.** Booked times are the skeleton. What the
   stations report is laid over the top: the train standing at platform 3
   becomes *that* service, and a booked train that has not turned up starts
   running late by itself, which is the entire point of an Expected column.
2. **The Train Stations alone.** A station peripheral only gives up its
   schedule while a train is actually standing there, so `rail` reads the
   calling points then and remembers them against that platform — after one
   visit it can advertise the destination for every later train.
   `create:destination` filters like `Kings Cross *` are matched properly, and
   a cyclic schedule is followed round until it comes back here, which gives
   the calling list and, backwards, the origin.
3. **A `rail hub` on the network**, broadcasting what it can see to displays
   that have no station of their own.
4. **A demonstration timetable**, so a fresh computer still shows you a board.

## Going wireless

Networking cable to a station on the far side of the map is no fun. Put a
computer at the station instead, and let it read the stations locally and shout
what it sees:

```
station end                              board end
  computer  ── wired modem ── stations     computer ── monitor
      └── ender modem                          └── ender modem
  rail hub                                 rail departures
```

Nothing is paired, addressed or channelled. Every `rail` computer opens **all**
of its modems on the rednet protocol `rail`; a hub broadcasts what it can see
every `refresh` seconds; a display keeps the broadcasts whose `station` matches
the `station` in its own `rail.cfg` and ignores the rest. So the only thing
that has to line up is that one string, and two stations with different names
happily share the air.

A hub usually has two modems — a wired one for the Train Stations and an ender
one for the boards — which is why `rail` opens every modem it finds rather than
the first one.

`rail link` is the check: it lists the modems with which of them are wireless,
opens rednet, and prints every hub broadcast that arrives, flagging any whose
station name does not match this display.

```
ender_modem_1  wireless
modem_0  wired
rednet open on 2 modem(s)
this display answers to: Create Central

listening for hubs, press a key to stop
computer 12: Create Central, 6 services
```

Ender modems have unlimited range and work between dimensions. Plain Wireless
Modems work too, but only out to a few hundred blocks, and less underground.

## Onboard displays

Blocks on a moving Create contraption are not ticked, so a computer bolted
inside an assembled train stops running until the train is taken apart. Run the
onboard modes on a static carriage mock-up, on a platform, or in a waiting
room; point them at a `hub` and set `train` in the config, and they follow the
real train around the network as the stations report it.

## Create flap displays

`rail flap` writes to every CC:C Bridge **Source Block** on the network, which
Create then paints onto a flap display, nixie tubes, a sign or a lectern
through a Display Link. It sizes itself to the target: eight characters or
fewer gets just the departure time, anything wider gets time, destination and
status, with the platform and calling points on the second line.

---

# warn — the hazard sign

Built for a long thin line of monitors over a doorway — a **1x7 strip** is what
it was written on — and aimed squarely at the sort of blast doors that close
whether or not you are still standing in them.

```
###    ####    ####    ####    ####    ####    ####    ####    ####    ####
##    ####    ####    ####    ####    ####    ####    ####    ####    ####
#    ####    ####    ####    ####    ####    ####    ####    ####    ####

#  #   #       #   #  ###  #   # ####         #### ##### ##### ####
 # #   #       #   # #   # #   # #   #       #       #   #     #   #
   #   #        # #  #   # #   # #   #       #       #   #     #   #
   #####         #   #   # #   # ####         ###    #   ####  ####
   #   #         #   #   # #   # # #             #   #   #     #
 # #   #         #   #   # #   # #  #            #   #   #     #
#  #   #         #    ###   ###  #   #       ####    #   ##### #

   ####    ####    ####    ####    ####    ####    ####    ####    ####    #
  ####    ####    ####    ####    ####    ####    ####    ####    ####    ##
 ####    ####    ####    ####    ####    ####    ####    ####    ####    ###
```

Every monitor on the network is treated as **one continuous ribbon**, in
peripheral-name order, so the text scrolls off one screen and onto the next.
A 1x7 line of monitor blocks merges into a single monitor and is just the one
screen as far as `warn` is concerned; separate screens in a row work too, as
long as you hang them in the same order the computer names them. `warn size`
prints that order.

The letters are a 5x7 dot matrix drawn with CC's 2x3 block glyphs, which gives
the strip three times the vertical resolution the character grid has, and they
are sized to whatever height the monitor turns out to be. Below five rows the
chevrons are dropped; below the height of one letter it falls back to ordinary
scrolling text, so it still says something on a one-block sign.

| Command | What it does |
| --- | --- |
| `warn` | scroll the built in messages |
| `warn <text...>` | scroll your own text instead — `\|` splits it into several messages |
| `warn size` | what each monitor measures, and the order they read in |
| `warn setup` | write a starter `warn.cfg` |
| `warn help` | the list |

Tap a monitor, or press `n`, to skip to the next message; `q` stops it.
`vaults startup warn on` brings it back after a server restart.

## What it says

`WATCH YOUR STEP` is the headline, and it comes back round between every other
message. The rest are about the doors:

> MIND THE DOORS. THE DOORS DO NOT MIND YOU. · THESE DOORS WEIGH 400 TONNES.
> YOU WEIGH SIX PORK CHOPS. · DAYS SINCE THE LAST DOOR RELATED INCIDENT: 0 ·
> IF THE DOOR IS CLOSING, IT IS CLOSING WITH OR WITHOUT YOU. · IN THE EVENT OF
> A CREEPER THE DOORS WILL BE FINE. YOU WILL NOT. · NO RUNNING. NO PUSHING. NO
> BECOMING PART OF THE DOOR. · THE DOOR HAS RIGHT OF WAY. THE DOOR HAS ALWAYS
> HAD RIGHT OF WAY. · IRON DOORS: UNBEATEN IN 1,247 CONSECUTIVE ARGUMENTS. ·
> STAND CLEAR OF THE THRESHOLD. IT IS NOT A PHOTO OPPORTUNITY. · THE DOORS OPEN
> AT WALKING PACE. SO SHOULD YOU.

## warn.cfg

`warn setup` writes a template; it is a Lua table and every field is optional.

| Field | Default | What it is |
| --- | --- | --- |
| `headline` | `"WATCH YOUR STEP"` | shown again between every other message |
| `messages` | the ten above | your own list, replacing them |
| `theme` | `"amber"` | `"amber"` or `"red"`; basic monitors go white |
| `speed` | `3` | letters per second the ribbon moves |
| `scroll` | `0.15` | seconds between frames |
| `stripes` | `true` | hazard chevrons along the top and bottom |
| `scale` | `0` | letter size in pixels, `0` fits the screen |
| `maxScale` | `4` | how big "fits the screen" is allowed to get |
| `textScale` | `0.5` | monitor text scale |

## Development

The repo ships a small CC: Tweaked emulator so the scripts can be tested and
previewed without launching Minecraft. You need a normal Lua 5.4 interpreter
(`winget install DEVCOM.Lua`).

```
lua tests/run.lua                    # 192 tests across the scripts and the manager
lua tests/preview.lua stock 121 18   # render a view in your terminal, in colour
lua tests/preview.lua movers|vaults|detail [width] [height]
lua tests/preview.lua departures|arrivals|platform|summary|onboard|route|concourse
lua tests/preview.lua warn 108 10    # the hazard sign, mid-scroll
```

`tests/cc_mock.lua` fakes peripherals (vaults, Create train stations, CC:C
Bridge display sources, modems), monitors, the event queue, `rednet`, `fs` and
`http`, and captures every `blit` so tests can assert on what was drawn —
layout rules, touch handling, the palette being restored on exit, and the
manager's install/update/startup behaviour against a fake GitHub.

## Repo layout

```
vaults.lua          the package manager (installed as vaults.lua)
manifest.txt        name | file | version | description, one script per line
scripts/stock.lua   the dashboard (installed as stock.lua)
scripts/rail.lua    the train displays (installed as rail.lua)
scripts/warn.lua    the hazard sign (installed as warn.lua)
RAIL-SETUP.md       step by step guide to setting the train displays up
tests/              CC emulator, test suites, terminal preview tool
docs/               offline CC: Tweaked + CC:C Bridge reference (docs/README.md)
tools/fetch_docs.py refreshes docs/ from the upstream sites
CLAUDE.md           notes for working in this repo
```
