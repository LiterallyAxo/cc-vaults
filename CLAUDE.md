# cc-vaults

ComputerCraft (CC: Tweaked) Lua scripts for a Minecraft Create factory, plus a
small package manager that installs them onto in-game computers.

Repo: https://github.com/LiterallyAxo/cc-vaults (public, branch `main`).
The in-game computers fetch from the raw URLs on `main`, so **work only counts
once it is committed and pushed** — do that at the end of every change, without
being asked, and confirm the raw URL serves the new content.

## Layout

```
vaults.lua          package manager; installed on the computer as vaults.lua
manifest.txt        name | file | version | description, one line per script
scripts/stock.lua   Create vault dashboard; installed as stock.lua, run as `stock`
scripts/rail.lua    UK style train boards for Create trains; run as `rail [mode]`
                    (`rail.dat` on the computer holds the timings it learned)
RAIL-SETUP.md       player facing setup walkthrough for rail (README is reference)
docs/               offline CC: Tweaked and CC:C Bridge docs (see docs/README.md)
tests/              CC emulator, test suites, terminal preview tool
tools/fetch_docs.py refreshes docs/
```

## Commands

Lua 5.4 lives at `~/AppData/Local/Microsoft/WinGet/Links` (installed with
`winget install DEVCOM.Lua`); add it to `PATH` before running these.

```
lua tests/run.lua                      # whole suite, must be green before pushing
luac -p vaults.lua scripts/*.lua       # syntax check
lua tests/preview.lua stock 121 18     # render a view in the terminal, in colour
lua tests/preview.lua movers|vaults|detail [w] [h]
lua tests/preview.lua departures|arrivals|platform|summary|onboard|route|concourse
python tools/fetch_docs.py             # refresh docs/
```

## Adding a script

1. Write `scripts/<name>.lua`.
2. Add one line to `manifest.txt`: `<name> | scripts/<name>.lua | 0.1.0 | description`.
   That is the whole registration — `vaults` reads the manifest at runtime and
   needs no code change.
3. Add `tests/test_<name>.lua` and list the suite in `tests/run.lua`.
4. Document it in the README's script table.

Bump the version in `manifest.txt` whenever a script's content changes, so
`vaults list` / `vaults update` can tell users something moved. `vaults.lua`
carries its own `VERSION` constant that must match its manifest line, and
`scripts/stock.lua` repeats its version in the header comment.

## Testing conventions

`tests/cc_mock.lua` emulates CC: Tweaked — peripherals, monitors, the event
queue, `fs`, `http`, `shell` — and captures every `blit`.

- `mock.newEnv{ vaults=…, stations=…, sources=…, modem=…, time=…, files=…,
  urls=…, events=…, width=, height=, color=, noHttp= }` then
  `H.runOk(env, script, ...args)`.  `stations` fakes Create Train Stations,
  `sources` fakes CC:C Bridge Source Blocks (read back with `env.sourceText`),
  `modem` turns `rednet` on (sends land in `env.rednetSent`), `time` is
  `os.time()` in Minecraft hours.
- Scripts run to completion: the event queue is drained, then the mock feeds one
  `key q` to break the main loop.
- An `events` entry may be a **function**, which is called with `env` so a test
  can mutate the world mid-run; use `env.pushNext{…}` (not `env.push`) to inject
  an event that must be consumed next.
- Assert drawn output against **`env.frame`** (the last painted frame — programs
  clear the display on exit), and use `env.screen` only for live coordinates
  inside an events function, or for counters like `env.screen.blits`.
- Scripts expose internals for tests through an inert `if _G.__VAULT_TEST then`
  hook near the end; reach them via `env.internals`.

## CC: Tweaked constraints worth remembering

Full docs are in `docs/` — grep there before guessing. The ones that bite:

- `getItemDetail` costs a server tick per call. `stock` caps it (`detailBudget`)
  and resolves names across several refreshes; never call it per item per scan.
- `list()` on many vaults must run through `parallel.waitForAll` in batches
  (50 at a time) or a big network stalls.
- `blit(text, fg, bg)` needs all three strings the same length, and colours are
  the hex chars `0`-`f`, not colour constants.
- Monitors only emit `monitor_touch` — there is no mouse-scroll or drag on them.
- `setPaletteColour` is per-display and persists after the program exits, so
  capture and restore the original palette.
- `\149` is the left-half block glyph, which is what gives bars half-character
  precision. Other sub-character glyphs live in 128-159.
- Peripheral names look like `create:item_vault_0`; `peripheral.getType` can
  return several types, so iterate them.
- Create's Train Station peripheral (`Create_Station`) only answers
  `getSchedule()` while a train is actually standing there, and the schedule's
  `create:destination` entries are *filters*, so `Kings Cross *` matches every
  platform there. `rail` caches the calling pattern per platform because of it.
- Create gives no distance, speed or arrival estimate -- only present /
  imminent / enroute flags and the train name. `rail` therefore *times* the
  railway: it records when a train leaves one station and reaches the next,
  averages that over a few trips (`state.legs`, kept in `rail.dat`) and
  predicts from the measurement. Every computer with a modem gossips
  sightings, hop times and whole schedules over rednet, so one can use hops
  and calling patterns it could never observe alone; only `rail hub` also
  broadcasts `services`, which is the one station-addressed field.
- One computer can drive every monitor on its network: `rail dep arrivals`
  hands a mode to each, in peripheral-name order. `canvas` and `state.mode`
  are upvalues the drawers close over, so `draw()` just repoints them per
  screen -- do not capture either into a local inside a drawer.
- Only the master (`master = true`, which `rail hub` sets) polls GitHub for
  updates; it then broadcasts the new script over rednet and reboots, and
  everyone else installs what they were sent. Boards must never poll.
- A Create station block with no "Platform N" in its name is platform 1. The
  trailing number on the peripheral name is Create's load order, not a
  platform, so it must never reach the board.
- The in-game clock runs 72x, so one real second is 1.2 in-game minutes.
  Anything the player can time with a stopwatch (`dwell`, `legRun`) is
  configured in real seconds and converted with `minutesFor`.
- Blocks on a moving Create contraption are not ticked, so a computer inside an
  assembled train is dead until it is disassembled — onboard displays have to
  be driven from the lineside.

The server also runs **CC:C Bridge**, so `create_source`, `create_target`,
`scroller`, `redrouter` and animatronic peripherals are available — that is the
route to putting data on Create flap displays and nixie tubes.

## Style

Match the existing code: locals over globals, a section banner comment
(`----- name`) per area, comments that explain *why* rather than restating the
line, and British/US spelling wherever CC's own API uses it (`setPaletteColour`,
`isColour`). Terminal output the player sees stays terse and lower case.
