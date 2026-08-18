# Reference docs

Offline copies of the documentation these scripts are written against, so an
API question can be answered by grepping this folder instead of guessing.

Refresh (overwrites in place):

```
python tools/fetch_docs.py            # everything
python tools/fetch_docs.py cc         # just CC: Tweaked
python tools/fetch_docs.py cccbridge  # just CC:C Bridge
```

## cc-tweaked/ — [tweaked.cc](https://tweaked.cc)

The whole CC: Tweaked manual, 94 pages, mirroring the site's layout.

| Path | What is in it |
| --- | --- |
| `module/` | the Lua APIs: `peripheral`, `term`, `os`, `fs`, `http`, `parallel`, `textutils`, `colors`, `keys`, `window`, `paintutils`, `rednet`, `settings`, `shell`, … |
| `peripheral/` | the built-in peripherals: `monitor`, `modem`, `speaker`, `drive`, `printer`, `computer` |
| `generic_peripheral/` | how any inventory / tank / energy block is exposed — **`inventory.md` is the one Create vaults use** (`list`, `size`, `getItemDetail`, `pushItems`, `pullItems`) |
| `event/` | every event: `monitor_touch`, `mouse_click`, `timer`, `peripheral`, `key`, `term_resize`, … |
| `library/` | bundled Lua libraries: `cc.pretty`, `cc.strings`, `cc.expect`, `cc.image.nft`, … |
| `guide/` | startup files, `require`, GPS setup, speaker audio |

Most useful for this repo: `module/peripheral.md`, `generic_peripheral/inventory.md`,
`module/term.md` (`blit`), `peripheral/monitor.md`, `event/monitor_touch.md`,
`module/parallel.md`.

## cccbridge/ — [cccbridge.kleinbox.dev](https://cccbridge.kleinbox.dev)

CC:C Bridge, the mod that wires ComputerCraft into Create. Installed on this
server, so these peripherals are fair game for future scripts.

| Peripheral | Attach name | What it does |
| --- | --- | --- |
| Source Block | `create_source` | terminal-like API whose text is pushed onto any Create display target — flap displays, nixie tubes, signs, lecterns |
| Target Block | `create_target` | the reverse: reads what a Create Display Source (stress, speed, item counts…) is sending |
| Scroller Pane | `scroller` | a physical number input the player can scroll, with events |
| RedRouter Block | `redrouter` | redstone in and out over one long cable |
| Animatronic | | poseable puppet with body and face control |

The guides folder covers the charset the displays accept and how to pose
animatronics.

## Not mirrored here

- **Create itself** exposes some peripherals of its own; see the Create wiki.
- **Create: Connected** (hlysine) is a separate quality-of-life Create addon —
  it adds blocks (kinetic bridge/battery, rotated vaults) but no CC API.
