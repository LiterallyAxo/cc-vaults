<!-- fetched from https://tweaked.cc/module/paintutils.html -->
# module / paintutils

# paintutils

Utilities for drawing more complex graphics, such as pixels, lines and images.

### Changes

- New in version 1.45

| parseImage(image) | Parses an image from a multi-line string |
| loadImage(path) | Loads an image from a file. |
| drawPixel(xPos, yPos [, colour]) | Draws a single pixel to the current term at the specified position. |
| drawLine(startX, startY, endX, endY [, colour]) | Draws a straight line from the start to end position. |
| drawBox(startX, startY, endX, endY [, colour]) | Draws the outline of a box on the current term from the specified start position to the specified end position. |
| drawFilledBox(startX, startY, endX, endY [, colour]) | Draws a filled box on the current term from the specified start position to the specified end position. |
| drawImage(image, xPos, yPos) | Draw an image loaded by `paintutils.parseImage` or `paintutils.loadImage`. |

### parseImage(image)
Parses an image from a multi-line string

### Parameters

- image `string` The string containing the raw-image data.

### Returns

- `table` The parsed image data, suitable for use with `paintutils.drawImage`.

### Usage

-

Parse an image from a string, and draw it.

```lua
local image = paintutils.parseImage([[
 e e

e e
 eeee
]])
paintutils.drawImage(image, term.getCursorPos())
```

### Changes

- New in version 1.80pr1

### loadImage(path)
Loads an image from a file.

You can create a file suitable for being loaded using the `paint` program.

### Parameters

- path `string` The file to load.

### Returns

- `table` | nil The parsed image data, suitable for use with `paintutils.drawImage`, or `nil` if the file does not exist.

### Usage

-

Load an image and draw it.

```lua
local image = paintutils.loadImage("data/example.nfp")
paintutils.drawImage(image, term.getCursorPos())
```

### drawPixel(xPos, yPos [, colour])
Draws a single pixel to the current term at the specified position.

##### ⚠ warning

This function may change the position of the cursor and the current background colour. You should not expect either to be preserved.

### Parameters

- xPos `number` The x position to draw at, where 1 is the far left.
- yPos `number` The y position to draw at, where 1 is the very top.
- colour? `number` The color of this pixel. This will be the current background colour if not specified.

### drawLine(startX, startY, endX, endY [, colour])
Draws a straight line from the start to end position.

##### ⚠ warning

This function may change the position of the cursor and the current background colour. You should not expect either to be preserved.

### Parameters

- startX `number` The starting x position of the line.
- startY `number` The starting y position of the line.
- endX `number` The end x position of the line.
- endY `number` The end y position of the line.
- colour? `number` The color of this pixel. This will be the current background colour if not specified.

### Usage

-

```lua
paintutils.drawLine(2, 3, 30, 7, colors.red)
```

### drawBox(startX, startY, endX, endY [, colour])
Draws the outline of a box on the current term from the specified start position to the specified end position.

##### ⚠ warning

This function may change the position of the cursor and the current background colour. You should not expect either to be preserved.

### Parameters

- startX `number` The starting x position of the line.
- startY `number` The starting y position of the line.
- endX `number` The end x position of the line.
- endY `number` The end y position of the line.
- colour? `number` The color of this pixel. This will be the current background colour if not specified.

### Usage

-

```lua
paintutils.drawBox(2, 3, 30, 7, colors.red)
```

### drawFilledBox(startX, startY, endX, endY [, colour])
Draws a filled box on the current term from the specified start position to the specified end position.

##### ⚠ warning

This function may change the position of the cursor and the current background colour. You should not expect either to be preserved.

### Parameters

- startX `number` The starting x position of the line.
- startY `number` The starting y position of the line.
- endX `number` The end x position of the line.
- endY `number` The end y position of the line.
- colour? `number` The color of this pixel. This will be the current background colour if not specified.

### Usage

-

```lua
paintutils.drawFilledBox(2, 3, 30, 7, colors.red)
```

### drawImage(image, xPos, yPos)
Draw an image loaded by `paintutils.parseImage` or `paintutils.loadImage`.

##### ⚠ warning

This function may change the position of the cursor and the current background colour. You should not expect either to be preserved.

### Parameters

- image `table` The parsed image data.
- xPos `number` The x position to start drawing at.
- yPos `number` The y position to start drawing at.

### Usage

-

Load an image and draw it.

```lua
local image = paintutils.loadImage("data/example.nfp")
paintutils.drawImage(image, term.getCursorPos())
```
