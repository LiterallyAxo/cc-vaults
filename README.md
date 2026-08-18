# cc-vaults — Vault Network

A live stock dashboard for **Create Item Vaults**, written for ComputerCraft
(CC: Tweaked). It scans every vault on the computer's peripheral network and
paints a touch-driven dashboard on an attached monitor.

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

## Install

On the in-game computer, grab the installer and let it do the rest:

```
wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vaults.lua
vaults install
vault_stock
```

## Update

```
vaults update
```

That re-downloads the monitor **and the installer itself**, and reports what
changed. `vaults version` shows the installed version against the latest one on
GitHub.

## All installer commands

| Command | What it does |
| --- | --- |
| `vaults install` | download the monitor (add `--startup` to also autorun it) |
| `vaults update` | pull the latest version, including `vaults` itself |
| `vaults run` | start the monitor, installing it first if it is missing |
| `vaults startup on\|off` | run the monitor when the computer boots |
| `vaults version` | installed vs. available version |
| `vaults uninstall` | remove everything it installed |

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
balances the columns, and drops the capacity gauge on very short screens.

## Views

Three tabs, switched by tapping the monitor or pressing `Tab`:

- **STOCK** — every item across every vault, with a share bar and the total.
  Once something moves, a change column appears next to the counts.
- **MOVERS** — only what changed since the last scan, biggest swing first.
  This is the view to leave up while a factory is running.
- **VAULTS** — one row per vault with a fill gauge, slots used and item count.
  An unresponsive vault is flagged in red here and counted on the title bar.

Tap any item to open a **breakdown panel** showing its id, total, stack count
and how it is spread across the vaults. Tap again to dismiss.

## Controls

| Action | Monitor | Keys |
| --- | --- | --- |
| Switch view | tap `STOCK` / `MOVERS` / `VAULTS` | `Tab` |
| Change sort (count / name / change) | tap `SORT:` | `S` |
| Previous / next page | tap the left / right third of the footer | ← → ↑ ↓ PgUp PgDn |
| Item breakdown | tap an item row | — |
| Close the breakdown | tap anywhere | `Esc` |
| Force a rescan | tap the title bar | `R` |
| Quit | — | `Q` |

## Configuration

At the top of `vault_stock.lua`:

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
lua tests/run.lua                    # 56 tests across the monitor and installer
lua tests/preview.lua stock 121 18   # render a view in your terminal, in colour
lua tests/preview.lua movers|vaults|detail [width] [height]
```

`tests/cc_mock.lua` fakes peripherals, monitors, the event queue, `fs` and
`http`, and captures every `blit` so tests can assert on what was drawn —
including layout rules, touch handling and the palette being restored on exit.
