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

## Development

The repo ships a small CC: Tweaked emulator so the scripts can be tested and
previewed without launching Minecraft. You need a normal Lua 5.4 interpreter
(`winget install DEVCOM.Lua`).

```
lua tests/run.lua                    # 72 tests across the dashboard and manager
lua tests/preview.lua stock 121 18   # render a view in your terminal, in colour
lua tests/preview.lua movers|vaults|detail [width] [height]
```

`tests/cc_mock.lua` fakes peripherals, monitors, the event queue, `fs` and
`http`, and captures every `blit` so tests can assert on what was drawn —
layout rules, touch handling, the palette being restored on exit, and the
manager's install/update/startup behaviour against a fake GitHub.

## Repo layout

```
vaults.lua        the package manager (installed as vaults.lua)
manifest.txt      name | file | version | description, one script per line
scripts/stock.lua the dashboard (installed as stock.lua)
tests/            CC emulator, test suites, terminal preview tool
```
