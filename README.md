# cc-vaults — Create Vault Stock Monitor

A ComputerCraft (CC: Tweaked) script that scans every **Create Item Vault** on the
computer's peripheral network, totals up the contents, and displays the stock on an
attached monitor.

## Install

On the in-game computer:

```
wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vault_stock.lua vault_stock.lua
```

Then run it:

```
vault_stock
```

## Update

`wget` refuses to overwrite an existing file, so delete it first:

```
rm vault_stock.lua
wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vault_stock.lua vault_stock.lua
```

Or as a single line you can paste into the shell:

```
rm vault_stock.lua && wget https://raw.githubusercontent.com/LiterallyAxo/cc-vaults/main/vault_stock.lua vault_stock.lua && vault_stock
```

## Run on boot

```
edit startup.lua
```

and put this in it:

```lua
shell.run("vault_stock")
```

## Wiring

```
computer ── wired modem ── networking cable ── modem on each Item Vault
                                └─ monitor (or attach the monitor directly)
```

Right-click every modem so it turns red and says *"Peripheral … attached"* — an
un-activated modem means the computer cannot see that vault. Multi-block vaults
count as one peripheral, so one modem per vault structure is enough.

Use an **Advanced Monitor** for colour. Any size works; the script re-flows into
multiple columns on wide monitors and pages when the list does not fit.

## Controls

The monitor is touch-enabled; the computer terminal accepts keys.

| Action | Monitor | Keys |
| --- | --- | --- |
| Previous / next page | tap left / right third of the footer | ← → / ↑ ↓ / PgUp PgDn |
| Change sort (count ⇄ name) | tap the middle of the footer | `S` |
| Force a rescan | tap the title bar | `R` |
| Quit | — | `Q` |

## Configuration

At the top of `vault_stock.lua`:

| Option | Default | What it does |
| --- | --- | --- |
| `refresh` | `5` | Seconds between rescans |
| `textScale` | `0.5` | Monitor text scale — smaller means more rows |
| `vaultPattern` | `"vault"` | Peripheral type must contain this string |
| `includeAll` | `false` | Set `true` to count **every** inventory (chests, barrels, …), not just vaults |
| `minColWidth` | `24` | Minimum column width before dropping to fewer columns |
| `detailBudget` | `40` | `getItemDetail` lookups per scan — this call costs a server tick, so new item names resolve over a few refreshes |

## Notes

- Items are aggregated by item id across all vaults, so NBT variants (e.g. damaged
  tools) are summed under one entry.
- A vault that fails to respond is counted in the red `!n` marker on the title bar
  rather than taking the whole display down.
- The script reacts to `peripheral` / `peripheral_detach` events, so plugging a new
  vault into the network refreshes the list immediately.
