# Setting up `rail` from nothing

A complete walkthrough: from an empty computer to a station full of British
style train information displays. No prior ComputerCraft knowledge assumed.

The [README](README.md#rail--train-information-displays) is the reference for
what every option does; this is the order to do things in.

**Contents**

1. [What you are building](#1-what-you-are-building)
2. [Before you start](#2-before-you-start)
3. [Install it](#3-install-it)
4. [See a board straight away](#4-see-a-board-straight-away)
5. [The blocks you need](#5-the-blocks-you-need)
6. [Wire the computer to your Train Stations](#6-wire-the-computer-to-your-train-stations)
7. [Check what the computer can see](#7-check-what-the-computer-can-see)
8. [Name your stations so rail understands them](#8-name-your-stations-so-rail-understands-them)
9. [Write rail.cfg](#9-write-railcfg)
10. [Pick a display for each screen](#10-pick-a-display-for-each-screen)
11. [Where the calling points come from](#11-where-the-calling-points-come-from)
12. [More than one screen](#12-more-than-one-screen)
13. [Stations that are miles away](#13-stations-that-are-miles-away)
14. [Make it start on its own](#14-make-it-start-on-its-own)
15. [Create flap displays and nixie tubes](#15-create-flap-displays-and-nixie-tubes)
16. [Displays on the train itself](#16-displays-on-the-train-itself)
17. [Troubleshooting](#17-troubleshooting)
18. [Appendix: every option, every command](#18-appendix-every-option-every-command)

---

## 1. What you are building

One script, `rail`, which reads your Create Train Stations and draws whichever
kind of railway display you point it at. A station usually ends up with several
of them, each on its own computer and monitor:

```
   CREATE CENTRAL               Departures                          15:00
 Time  Destination                                             Plat  Expected
 ------------------------------------------------------------------------------
 15:04 London Euston  via Coventry                             3      On time
 15:09 Manchester Piccadilly                                   5        15:16
 15:13 Cardiff Central                                         -    Cancelled
 15:18 Nottingham                                              8      On time
 15:22 Leamington Spa  via Solihull                            2      On time
 15:27 Liverpool Lime Street                                   4        15:30
 15:31 Redditch                                                1      On time
 15:36 Manchester Piccadilly  via Stoke-on-Trent               6      On time
 ------------------------------------------------------------------------------
 See it. Say it. Sorted. Text the British Transport Police on 61016.
```

(Amber on black on a real monitor, with the double arrow in the corner.)

You do **not** have to understand the British railway to use this. Section 10
tells you which display goes where.

## 2. Before you start

You need:

- **CC: Tweaked** and **Create** on the server. You have both if you can craft
  an Advanced Computer and a Train Station.
- **The `http` API enabled** in CC's config, which is the default. Without it
  the installer cannot download anything.
- At least one **Create Train Station** block on a piece of track. `rail` reads
  the trains through these; it never touches the track itself.
- Trains with **Create schedules**, ideally. Not essential — see section 11.

Nothing here modifies your railway. `rail` only reads.

## 3. Install it

Place an **Advanced Computer**, right-click it, and type:

```
wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vaults.lua
vaults install rail
```

That fetches the package manager, then `rail` itself. To update later:

```
vaults update rail
```

If `wget` says the domain is not permitted, the server has locked down the
http API and you will need it allowed for `raw.githubusercontent.com`.

## 4. See a board straight away

Before wiring anything, put an **Advanced Monitor** against the computer (any
size; 4 wide by 3 tall is a good first try) and type:

```
rail
```

You should get a departures board running on a demonstration timetable. This
proves the script, the monitor and the palette all work. Press `Tab` to cycle
through the other display types, and `Q` to quit.

The line it prints when it starts tells you the real size of your monitor:

```
display: monitor_0 90x24 chars
```

That number, not the block count, is what the layouts care about. Section 10
lists what each display wants.

## 5. The blocks you need

| Block | How many | What it is for |
| --- | --- | --- |
| **Advanced Computer** | one per display | Runs the script. Advanced, not normal, so it can do colour |
| **Advanced Monitor** | one screen per display | The board. Basic monitors work but come out grey |
| **Wired Modem** | one on the computer, one on each Train Station | How the computer sees the stations |
| **Networking Cable** | as much as it takes | Joins the modems |
| **Create Train Station** | you already have these | The block that knows which train is where |
| **Ender Modem** | optional, one per computer | For stations too far away to cable — section 13 |
| **CC:C Bridge Source Block** | optional | For Create flap displays — section 15 |

A shortcut worth knowing: **a peripheral touching a computer needs no modem at
all**. If a display only ever cares about one Train Station, stand the computer
against the station block and skip the cable entirely.

## 6. Wire the computer to your Train Stations

1. Place the computer where you want it. Put the monitor next to it.
2. Put a **Wired Modem** on the computer.
3. Put a **Wired Modem** on each **Train Station** you want this computer to
   know about.
4. Run **Networking Cable** between all of them. Cable can travel any distance
   and go through walls; the modems are the ends.
5. **Right-click every modem.** It turns red and says
   *"Peripheral … attached"*. A modem that is not red is not connected, and
   this is the single most common reason a board comes up empty.

```
                      +-- modem -- Train Station (platform 1)
computer -- modem ----+-- modem -- Train Station (platform 2)
    |   networking     +-- modem -- Train Station (platform 3)
    |   cable
    +-- monitor
```

Only cable the stations that belong to *this* station complex. A board at Kings
Cross should see the Kings Cross platforms, not the entire network — the same
as the real thing.

## 7. Check what the computer can see

```
rail stations
```

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

This one command answers almost every question you will have:

| What it says | What it means |
| --- | --- |
| `no create train stations` | A modem is not switched on, or not on the cable |
| `called: …` | The name of that station in game |
| `platform 3` | The platform number it worked out from the name |
| `platform -` | It could not guess — map it by hand in section 8 |
| `[ours]` | It counts towards this display |
| `[not ours]` | `station` in `rail.cfg` does not match this name |
| `calls at: …` | The calling points read off the train standing there |
| `no schedule on this train` | That train has no Create schedule |

Run it again whenever a board looks wrong.

## 8. Name your stations so rail understands them

`rail` treats a Train Station as belonging to your display when **the station's
in-game name contains the `station` string from your config**. So the tidiest
approach is to name them in game (right-click the Train Station and edit the
name):

```
Create Central Platform 1
Create Central Platform 2
Create Central Platform 3
```

With `station = "Create Central"` all three match, and the platform numbers are
read straight out of the names. It also makes your Create schedules read
nicely, because `Create Central *` in a schedule then means "any platform
there".

If you would rather not rename anything, map them instead:

```lua
platforms = {
  ["create:track_station_0"] = 1,   -- the peripheral name from `rail stations`
  ["Coal Yard Arrival"]      = 2,   -- or the in-game name
},
```

Anything listed in `platforms` counts as yours regardless of what it is called.

## 9. Write rail.cfg

```
rail setup
edit rail.cfg
```

`rail setup` writes a commented starter file. The smallest useful version:

```lua
return {
  mode    = "departures",       -- what this screen shows when it starts
  station = "Create Central",   -- must match your station names
  code    = "CRC",              -- used when the screen is too narrow for the name
}
```

Save with `Ctrl` then `Save`, quit with `Ctrl` then `Exit`. Then:

```
rail
```

Every display gets its own `rail.cfg` on its own computer. A platform board's
config is the same but with `mode = "platform"` and `platform = 3`.

The full list of options is in [appendix A](#a-every-railcfg-option).

## 10. Pick a display for each screen

Nine kinds of display, each matching something on the real railway. Sizes are
in **characters**, which is what the script prints when it starts. As a rough
guide a monitor at text scale 0.5 gives you roughly ten characters across and
seven rows per block, so a 4x3 monitor lands around 40x20 — but check the
printed number rather than trusting that.

### `departures` — the concourse summary board

The big one everybody stares at. Wants 40 characters or more across.

```
   CREATE CENTRAL               Departures                          15:00
 Time  Destination                                             Plat  Expected
 ------------------------------------------------------------------------------
 15:04 London Euston  via Coventry                             3      On time
 15:09 Manchester Piccadilly                                   5        15:16
 15:13 Cardiff Central                                         -    Cancelled
 15:18 Nottingham                                              8      On time
 ------------------------------------------------------------------------------
 See it. Say it. Sorted. Text the British Transport Police on 61016.
```

`Expected` reads `On time`, a later time if the train is running late, or
`Cancelled`. Below 46 characters wide the platform column drops; below 34 the
expected column goes too.

### `arrivals` — the same thing for trains coming in

Where each train has come *from* rather than where it is going.

```
   CREATE CENTRAL                Arrivals                           15:00
 Time  Origin                                                  Plat  Expected
 ------------------------------------------------------------------------------
 15:03 Wolverhampton                                           3      On time
 15:08 Bournville                                              5        15:16
 15:12 Nuneaton                                                -    Cancelled
 15:17 Redditch                                                8      On time
 ------------------------------------------------------------------------------
```

### `platform` — the board at the end of a platform

One train in detail, its calling points scrolling underneath, then the ones
after it. Set `platform` in the config, or run `rail platform 3`.

```
   CREATE CENTRAL               Departures                          15:00

 1st 15:04 London Euston                                              On time
           via Coventry  o  formed of 9 coaches  o  Create West Coast

 Calling at: Coventry, Rugby, Milton Keynes Central and London Euston
 ----------------------------------------------------------------------------
 2nd 15:09 Manchester Piccadilly                            Plat 5      15:16
 3rd 15:13 Cardiff Central                                 Plat 10  Cancelled
 4th 15:18 Nottingham                                       Plat 8    On time
 ------------------------------------------------------------------------------
```

When a train is on its way in, the second line changes to
*"Approaching - please stand back from the platform edge"*.

### `summary` — the little dot matrix

The strip over a doorway or on a platform post. Works down to a single row,
where it rotates between the train, its calling points and its formation.

```
15:04 London Euston                        On time
Calling at: Coventry, Rugby, Milton Keynes Central
9 coaches  o  Create West Coast
--------------------------------------------------
15:09 Manchester Piccadilly                  15:16
```

On one row:

```
15:04  London Euston  On time
```

### `onboard` — the screen inside a carriage

Rotates between the next station, the calling list and the welcome message.
Read [section 16](#16-displays-on-the-train-itself) before building this one.

```
 Create Rail                                      15:00

                   This train is for
                     LONDON EUSTON
             ----------------------------

                    This station is
                     CREATE CENTRAL
 Please mind the gap between the train and the platform
--------------------------------------------------------
```

### `route` — the line diagram in the vestibule

Where the train is along its journey. Set `route` in the config.

```
   CREATE CENTRAL          to London Euston                     15:00

  o---------------o---------------o---------------o---------------o
  ^                                                   London Euston

  o Create Central                                 15:00  this stop
  o Coventry                                       15:06
  o Rugby                                          15:12
  o Milton Keynes Central                          15:18
  o London Euston                                  15:24
```

### `concourse` — the station clock

Big digits over the next few departures.

```
                 Welcome to Create Central

               ##  ######          ######  ######
               ##  ##        ##    ##  ##  ##  ##
               ##  ######          ##  ##  ##  ##
               ##      ##    ##    ##  ##  ##  ##
               ##  ######          ######  ######

 ----------------------------------------------------------
 Time  Destination                                     Plat
 15:04 London Euston                         On time      3
 15:09 Manchester Piccadilly                   15:16      5
```

### `flap` — Create flap displays and nixie tubes

Not a monitor at all. See [section 15](#15-create-flap-displays-and-nixie-tubes).

### `hub` — no display, just data

Reads the stations and broadcasts what it sees to other computers. See
[section 13](#13-stations-that-are-miles-away).

---

While a board is running: `Tab` cycles the display types, `R` forces a refresh,
`Q` quits, and tapping the monitor refreshes it.

## 11. Where the calling points come from

`rail` uses the best source it has, in this order.

**1. A timetable in `rail.cfg`, if you write one.** Booked times are the
skeleton; what the stations report gets laid over the top. A train standing at
platform 3 becomes that service, and a booked train that has not turned up
starts running late by itself, which is the entire point of an Expected column.

```lua
timetable = {
  { depart = "15:26", platform = 3, coaches = 9, via = "Coventry",
    origin = "Wolverhampton", operator = "Create West Coast",
    calls = { "Coventry", "Rugby", "Milton Keynes Central", "London Euston" } },
  { depart = "15:41", platform = 5, delay = 7,
    calls = { "Stafford", "Crewe", "Manchester Piccadilly" } },
  { depart = "15:52", platform = 10, cancelled = true,
    calls = { "Newport", "Cardiff Central" } },
},
```

`calls` ends with the final destination, which is what the board advertises.
`delay` is in minutes. `cancelled = true` greys the service out and takes its
platform away. Times are in Minecraft hours by default; set `clock = "real"` to
run the railway off your own clock instead.

**2. The Train Stations on their own.** Give your trains normal Create
schedules with destination instructions and you need no timetable at all.
`rail` reads the schedule off whatever train is standing at the platform,
follows it round to the end, and gets the destination, the calling list and the
origin from it. Wildcards like `Create Central *` are matched properly.

One catch, and it is Create's, not this script's: **a station will only hand
over a schedule while a train is physically standing at it**. So a platform
shows nothing until one train has called there. After that `rail` remembers
what stops at that platform and can advertise the next train before it arrives.

**3. A hub over the radio** — section 13.

**4. A demonstration timetable**, so a fresh computer still shows a board. It
disappears the moment any real source appears. Set `demo = false` to turn it
off and get an honest empty board instead.

## 12. More than one screen

Every display is its own computer, monitor and `rail.cfg`. To give one station
a departures board, an arrivals board and three platform boards, build five
computers and cable all of them to the same Train Station modems. Networking
cable is cheap and can branch as much as you like.

Each config differs only in the top few lines:

```lua
-- the concourse board
return { mode = "departures", station = "Create Central" }

-- platform 3
return { mode = "platform", platform = 3, station = "Create Central" }

-- the little sign over the platform 3 stairs
return { mode = "summary", platform = 3, station = "Create Central" }
```

If running cable to all of them is a nuisance, use a hub instead.

## 13. Stations that are miles away

Put a computer at the station and let it broadcast. Everything else listens.

```
FAR STATION                            WHEREVER THE BOARD IS
  computer -- ender modem                computer -- ender modem
      +-- wired modem -- stations            +-- monitor
  rail hub                               rail departures
```

**There is nothing to pair.** Attach an ender modem to a face of the computer
the same way you place any modem — it does not need right-clicking to activate,
that is only wired modems. Every `rail` computer opens all of its modems on the
rednet protocol `rail`. A hub broadcasts what it can see every few seconds, and
a display keeps the broadcasts whose station name matches the `station` in its
own config, ignoring the rest. **That one matching string is the entire
pairing.**

The hub end:

```lua
return { mode = "hub", station = "Create Central" }
```

The board end, with no cable to anything:

```lua
return { mode = "departures", station = "Create Central" }
```

Run as many hubs as you have stations. They all share the air, and each board
picks out its own by name.

Ender Modems have unlimited range and work across dimensions. Plain Wireless
Modems work too, but only for a few hundred blocks, and less underground.

To check the radio, on either computer:

```
rail link
```

```
ender_modem_1  wireless
modem_0  wired
rednet open on 2 modem(s)
this display answers to: Create Central

listening for hubs, press a key to stop
computer 12: Create Central, 6 services
```

| What you get | What it means |
| --- | --- |
| `no modem attached` | The modem is not on a face of the computer |
| `nothing heard` | No hub running, out of range, or its chunk is unloaded |
| `ignored: this display wants X` | The radio is fine; the two `station` strings differ |
| A line naming your station | Working — the board fills in within a few seconds |

**The thing that will actually catch you out:** a computer in an unloaded chunk
is switched off. If the far station is not chunk-loaded, its hub stops
broadcasting whenever nobody is there, and the boards fall back to their own
data after three missed broadcasts. Whatever you normally use to keep
chunks loaded applies to the hub computer too.

## 14. Make it start on its own

Computers stop when their chunk unloads and restart when it comes back. Tell
each one to launch its display at boot:

```
vaults startup rail on
```

The startup file cannot pass arguments, which is why the mode lives in the
config. Make sure each `rail.cfg` has its `mode` line:

```lua
mode = "platform",
platform = 3,
```

`vaults startup off` clears it again.

## 15. Create flap displays and nixie tubes

If the server has **CC:C Bridge**, `rail` can write onto Create's own displays
instead of a monitor.

1. Place a **Source Block** (CC:C Bridge) and attach it to the computer, either
   directly or with a wired modem and cable.
2. Point a Create **Display Link** at the Source Block, and target the flap
   display, nixie tubes, sign or lectern as you normally would.
3. Run `rail flap`.

It writes to every Source Block on the network and sizes itself to each one:
eight characters or fewer gets just the departure time, anything wider gets the
time, destination and status, with the platform and calling points on a second
line if there is one.

The update rate is one second unless you clock the Display Link with redstone.

## 16. Displays on the train itself

Blocks on a moving Create contraption are not ticked. A computer bolted inside
an assembled train **stops running until the train is taken apart** — that is
Create, and no script can work around it.

So run `onboard` and `route` on a computer that stays still: a static carriage
mock-up in a station, a waiting room, or the platform. Give it an ender modem,
point it at a hub, and tell it which train it is following:

```lua
return {
  mode  = "onboard",
  train = "1A23",
  route = { "Create Central", "Coventry", "Rugby", "London Euston" },
}
```

The hub reports where each named train was last seen, and the display walks
along the route as the stations pick it up. With no train name and no hub it
falls back to creeping along the route on the clock, which is enough to make a
display prop look alive.

## 17. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| Board shows an obviously fake timetable | Nothing real is connected yet | Section 6; demo switches itself off once a station is visible |
| `rail stations` finds nothing | A wired modem is not switched on | Right-click each modem until it is red |
| Stations found but `[not ours]` | `station` does not match their names | Section 8 |
| `platform -` in the listing | No number in the station name | Add one, or use `platforms` |
| Board lists nothing at all | No train has stood at a platform yet | Wait for one, or write a timetable |
| No calling points | That train has no Create schedule | Give it one, or use `calls` in a timetable |
| Text runs off the screen | Monitor too small | Check the printed size; add a block or use `summary` |
| Colours look wrong or washed out | Basic rather than Advanced Monitor | Use an Advanced Monitor |
| Board never updates over radio | Wrong modem, or names differ | `rail link` |
| Board goes back to demo data | Hub went quiet, and this display sees no station of its own | Chunk loading, section 13 |
| Everything stops after a reload | Computer restarted with no startup file | `vaults startup rail on` |
| Palette stayed weird after quitting | Program was killed rather than quit | Run it again and press `Q` |

## 18. Appendix: every option, every command

### A. Every `rail.cfg` option

```lua
return {
  mode      = nil,        -- display to start in: "departures", "platform", ...
  station   = "Create Central",  -- this display's station; matches station names
  code      = "CRC",      -- shown instead of the name when the screen is narrow
  operator  = "Create Rail",     -- named on the onboard displays
  theme     = "dot",      -- "dot" amber dot matrix, "lcd" modern colour screen
  clock     = "mc",       -- "mc" Minecraft time, "real" your own clock
  textScale = 0.5,        -- monitor text scale
  refresh   = 5,          -- seconds between peripheral scans
  scroll    = 0.4,        -- seconds per column of scrolling text
  rotate    = 6,          -- seconds a rotating message stays up
  rows      = 0,          -- departures to list, 0 for as many as fit
  platform  = nil,        -- the platform a platform/summary display serves
  dwell     = 10,         -- real seconds a train stands at a platform
  legRun    = 45,         -- real seconds a train takes to reach the next one
  memory    = 30,         -- in-game minutes a platform stays on the board
                          -- after its train has gone
  train     = nil,        -- onboard/route: the Create train name to follow
  coach     = nil,        -- onboard: coach letter for the corner
  route     = nil,        -- onboard/route: station names in order
  platforms = {},         -- station peripheral or in-game name -> platform
  timetable = {},         -- booked services, see section 11
  demo      = true,       -- invent a timetable when nothing is connected
  logo      = true,       -- draw the double arrow where there is room
  messages  = { },        -- the scrolling line along the bottom
}
```

A timetable entry takes: `depart`, `arrive`, `platform`, `calls`, `dest`,
`origin`, `via`, `coaches`, `operator`, `train`, `delay`, `cancelled`.

### B. Every command

| Command | What it does |
| --- | --- |
| `rail` | The departures board, or whatever `mode` says |
| `rail arrivals` | Arrivals board |
| `rail platform [n]` | Platform board, optionally for platform n |
| `rail summary [n]` | One line dot matrix |
| `rail onboard` | In-carriage passenger information |
| `rail route` | In-carriage route diagram |
| `rail concourse` | Station clock over the next departures |
| `rail flap` | Write to Create displays through CC:C Bridge |
| `rail hub` | Headless: read the stations, broadcast them |
| `rail stations` | List what this computer can see, and why |
| `rail link` | List the modems and listen for hubs |
| `rail setup` | Write a starter `rail.cfg` (`-f` overwrites) |
| `rail help` | The list of modes |
| `rail version` | Which version is installed |

Short forms work too: `dep`, `arr`, `plat`, `next`, `pis`, `diagram`, `clock`.

### C. Keys and touches

| Action | How |
| --- | --- |
| Next display type | `Tab` |
| Force a refresh | `R`, or tap the monitor |
| Quit | `Q` |

Quitting with `Q` matters: it puts the monitor's colour palette back the way it
was. Killing the program with `Ctrl-T` leaves the palette as the board left it,
until something else resets it.
