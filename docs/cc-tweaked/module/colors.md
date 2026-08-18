<!-- fetched from https://tweaked.cc/module/colors.html -->
# module / colors

# colors

Constants and functions for colour values, suitable for working with `term` and `redstone`.

This is useful in conjunction with Bundled Cables from mods like Project Red, and colors on Advanced Computers and Advanced Monitors.

For the non-American English version just replace `colors` with `colours`. This alternative API is exactly the same, except the colours use British English (e.g. `colors.gray` is spelt `colours.grey`).

On basic terminals (such as the Computer and Monitor), all the colors are converted to grayscale. This means you can still use all 16 colors on the screen, but they will appear as the nearest tint of gray. You can check if a terminal supports color by using the function `term.isColor`.

Grayscale colors are calculated by taking the average of the three components, i.e. `(red + green + blue) / 3`.

| Default Colors |
| Color | Value | Default Palette Color |
| Dec | Hex | Paint/Blit | Preview | Hex | RGB | Grayscale |
| `colors.white` | 1 | 0x1 | 0 | | #F0F0F0 | 240, 240, 240 | |
| `colors.orange` | 2 | 0x2 | 1 | | #F2B233 | 242, 178, 51 | |
| `colors.magenta` | 4 | 0x4 | 2 | | #E57FD8 | 229, 127, 216 | |
| `colors.lightBlue` | 8 | 0x8 | 3 | | #99B2F2 | 153, 178, 242 | |
| `colors.yellow` | 16 | 0x10 | 4 | | #DEDE6C | 222, 222, 108 | |
| `colors.lime` | 32 | 0x20 | 5 | | #7FCC19 | 127, 204, 25 | |
| `colors.pink` | 64 | 0x40 | 6 | | #F2B2CC | 242, 178, 204 | |
| `colors.gray` | 128 | 0x80 | 7 | | #4C4C4C | 76, 76, 76 | |
| `colors.lightGray` | 256 | 0x100 | 8 | | #999999 | 153, 153, 153 | |
| `colors.cyan` | 512 | 0x200 | 9 | | #4C99B2 | 76, 153, 178 | |
| `colors.purple` | 1024 | 0x400 | a | | #B266E5 | 178, 102, 229 | |
| `colors.blue` | 2048 | 0x800 | b | | #3366CC | 51, 102, 204 | |
| `colors.brown` | 4096 | 0x1000 | c | | #7F664C | 127, 102, 76 | |
| `colors.green` | 8192 | 0x2000 | d | | #57A64E | 87, 166, 78 | |
| `colors.red` | 16384 | 0x4000 | e | | #CC4C4C | 204, 76, 76 | |
| `colors.black` | 32768 | 0x8000 | f | | #111111 | 17, 17, 17 | |

### See also

- `colours`

| white = 0x1 | White: Written as `0` in paint files and `term.blit`, has a default terminal colour of #F0F0F0. |
| orange = 0x2 | Orange: Written as `1` in paint files and `term.blit`, has a default terminal colour of #F2B233. |
| magenta = 0x4 | Magenta: Written as `2` in paint files and `term.blit`, has a default terminal colour of #E57FD8. |
| lightBlue = 0x8 | Light blue: Written as `3` in paint files and `term.blit`, has a default terminal colour of #99B2F2. |
| yellow = 0x10 | Yellow: Written as `4` in paint files and `term.blit`, has a default terminal colour of #DEDE6C. |
| lime = 0x20 | Lime: Written as `5` in paint files and `term.blit`, has a default terminal colour of #7FCC19. |
| pink = 0x40 | Pink: Written as `6` in paint files and `term.blit`, has a default terminal colour of #F2B2CC. |
| gray = 0x80 | Gray: Written as `7` in paint files and `term.blit`, has a default terminal colour of #4C4C4C. |
| lightGray = 0x100 | Light gray: Written as `8` in paint files and `term.blit`, has a default terminal colour of #999999. |
| cyan = 0x200 | Cyan: Written as `9` in paint files and `term.blit`, has a default terminal colour of #4C99B2. |
| purple = 0x400 | Purple: Written as `a` in paint files and `term.blit`, has a default terminal colour of #B266E5. |
| blue = 0x800 | Blue: Written as `b` in paint files and `term.blit`, has a default terminal colour of #3366CC. |
| brown = 0x1000 | Brown: Written as `c` in paint files and `term.blit`, has a default terminal colour of #7F664C. |
| green = 0x2000 | Green: Written as `d` in paint files and `term.blit`, has a default terminal colour of #57A64E. |
| red = 0x4000 | Red: Written as `e` in paint files and `term.blit`, has a default terminal colour of #CC4C4C. |
| black = 0x8000 | Black: Written as `f` in paint files and `term.blit`, has a default terminal colour of #111111. |
| combine(...) | Combines a set of colors (or sets of colors) into a larger set. |
| subtract(colors, ...) | Removes one or more colors (or sets of colors) from an initial set. |
| test(colors, color) | Tests whether `color` is contained within `colors`. |
| packRGB(r, g, b) | Combine a three-colour RGB value into one hexadecimal representation. |
| unpackRGB(rgb) | Separate a hexadecimal RGB colour into its three constituent channels. |
| rgb8(...) | Either calls `colors.packRGB` or `colors.unpackRGB`, depending on how many arguments it receives. |
| toBlit(color) | Converts the given color to a paint/blit hex character (0-9a-f). |
| fromBlit(hex) | Converts the given paint/blit hex character (0-9a-f) to a color. |

### white = 0x1
White: Written as `0` in paint files and `term.blit`, has a default terminal colour of #F0F0F0.

### orange = 0x2
Orange: Written as `1` in paint files and `term.blit`, has a default terminal colour of #F2B233.

### magenta = 0x4
Magenta: Written as `2` in paint files and `term.blit`, has a default terminal colour of #E57FD8.

### lightBlue = 0x8
Light blue: Written as `3` in paint files and `term.blit`, has a default terminal colour of #99B2F2.

### yellow = 0x10
Yellow: Written as `4` in paint files and `term.blit`, has a default terminal colour of #DEDE6C.

### lime = 0x20
Lime: Written as `5` in paint files and `term.blit`, has a default terminal colour of #7FCC19.

### pink = 0x40
Pink: Written as `6` in paint files and `term.blit`, has a default terminal colour of #F2B2CC.

### gray = 0x80
Gray: Written as `7` in paint files and `term.blit`, has a default terminal colour of #4C4C4C.

### lightGray = 0x100
Light gray: Written as `8` in paint files and `term.blit`, has a default terminal colour of #999999.

### cyan = 0x200
Cyan: Written as `9` in paint files and `term.blit`, has a default terminal colour of #4C99B2.

### purple = 0x400
Purple: Written as `a` in paint files and `term.blit`, has a default terminal colour of #B266E5.

### blue = 0x800
Blue: Written as `b` in paint files and `term.blit`, has a default terminal colour of #3366CC.

### brown = 0x1000
Brown: Written as `c` in paint files and `term.blit`, has a default terminal colour of #7F664C.

### green = 0x2000
Green: Written as `d` in paint files and `term.blit`, has a default terminal colour of #57A64E.

### red = 0x4000
Red: Written as `e` in paint files and `term.blit`, has a default terminal colour of #CC4C4C.

### black = 0x8000
Black: Written as `f` in paint files and `term.blit`, has a default terminal colour of #111111.

### combine(...)
Combines a set of colors (or sets of colors) into a larger set. Useful for Bundled Cables.

### Parameters

- ... `number` The colors to combine.

### Returns

- `number` The union of the color sets given in `...`

### Usage

-

```lua
colors.combine(colors.white, colors.magenta, colours.lightBlue)
-- => 13
```

### Changes

- New in version 1.2

### subtract(colors, ...)
Removes one or more colors (or sets of colors) from an initial set. Useful for Bundled Cables.

Each parameter beyond the first may be a single color or may be a set of colors (in the latter case, all colors in the set are removed from the original set).

### Parameters

- colors `number` The color from which to subtract.
- ... `number` The colors to subtract.

### Returns

- `number` The resulting color.

### Usage

-

```lua
colours.subtract(colours.lime, colours.orange, colours.white)
-- => 32
```

### Changes

- New in version 1.2

### test(colors, color)
Tests whether `color` is contained within `colors`. Useful for Bundled Cables.

### Parameters

- colors `number` A color, or color set
- color `number` A color or set of colors that `colors` should contain.

### Returns

- `boolean` If `colors` contains all colors within `color`.

### Usage

-

```lua
colors.test(colors.combine(colors.white, colors.magenta, colours.lightBlue), colors.lightBlue)
-- => true
```

### Changes

- New in version 1.2

### packRGB(r, g, b)
Combine a three-colour RGB value into one hexadecimal representation.

### Parameters

- r `number` The red channel, should be between 0 and 1.
- g `number` The green channel, should be between 0 and 1.
- b `number` The blue channel, should be between 0 and 1.

### Returns

- `number` The combined hexadecimal colour.

### Usage

-

```lua
colors.packRGB(0.7, 0.2, 0.6)
-- => 0xb23399
```

### Changes

- New in version 1.81.0

### unpackRGB(rgb)
Separate a hexadecimal RGB colour into its three constituent channels.

### Parameters

- rgb `number` The combined hexadecimal colour.

### Returns

- `number` The red channel, will be between 0 and 1.
- `number` The green channel, will be between 0 and 1.
- `number` The blue channel, will be between 0 and 1.

### Usage

-

```lua
colors.unpackRGB(0xb23399)
-- => 0.7, 0.2, 0.6
```

### See also

- `colors.packRGB`

### Changes

- New in version 1.81.0

### rgb8(...)
##### 🛈 Deprecated

Use `packRGB` or `unpackRGB` directly.

Either calls `colors.packRGB` or `colors.unpackRGB`, depending on how many arguments it receives.

### Parameters

- r `number` The red channel, as an argument to `colors.packRGB`.
- g `number` The green channel, as an argument to `colors.packRGB`.
- b `number` The blue channel, as an argument to `colors.packRGB`.

#### Or

- rgb `number` The combined hexadecimal color, as an argument to `colors.unpackRGB`.

### Returns

- `number` The combined hexadecimal colour, as returned by `colors.packRGB`.

#### Or

- `number` The red channel, as returned by `colors.unpackRGB`
- `number` The green channel, as returned by `colors.unpackRGB`
- `number` The blue channel, as returned by `colors.unpackRGB`

### Usage

-

```lua
colors.rgb8(0xb23399)
-- => 0.7, 0.2, 0.6
```

-

```lua
colors.rgb8(0.7, 0.2, 0.6)
-- => 0xb23399
```

### Changes

- New in version 1.80pr1
- Changed in version 1.81.0: Deprecated in favor of colors.(un)packRGB.

### toBlit(color)
Converts the given color to a paint/blit hex character (0-9a-f).

This is equivalent to converting `floor(log_2(color))` to hexadecimal. Values outside the range of a valid colour will error.

### Parameters

- color `number` The color to convert.

### Returns

- `string` The blit hex code of the color.

### Usage

-

```lua
colors.toBlit(colors.red)
-- => "c"
```

### See also

- `colors.fromBlit`

### Changes

- New in version 1.94.0

### fromBlit(hex)
Converts the given paint/blit hex character (0-9a-f) to a color.

This is equivalent to converting the hex character to a number and then 2 ^ decimal

### Parameters

- hex `string` The paint/blit hex character to convert

### Returns

- `number` The color

### Usage

-

```lua
colors.fromBlit("e")
-- => 16384
```

### See also

- `colors.toBlit`

### Changes

- New in version 1.105.0
