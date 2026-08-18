<!-- fetched from https://tweaked.cc/module/window.html -->
# module / window

# window

A terminal redirect occupying a smaller area of an existing terminal. This allows for easy definition of spaces within the display that can be written/drawn to, then later redrawn/repositioned/etc as need be. The API itself contains only one function, `window.create`, which returns the windows themselves.

Windows are considered terminal objects - as such, they have access to nearly all the commands in the term API (plus a few extras of their own, listed within said API) and are valid targets to redirect to.

Each window has a "parent" terminal object, which can be the computer's own display, a monitor, another window or even other, user-defined terminal objects. Whenever a window is rendered to, the actual screen-writing is performed via that parent (or, if that has one too, then that parent, and so forth). Bear in mind that the cursor of a window's parent will hence be moved around etc when writing a given child window.

Windows retain a memory of everything rendered "through" them (hence acting as display buffers), and if the parent's display is wiped, the window's content can be easily redrawn later. A window may also be flagged as invisible, preventing any changes to it from being rendered until it's flagged as visible once more.

A parent terminal object may have multiple children assigned to it, and windows may overlap. For example, the Multishell system functions by assigning each tab a window covering the screen, each using the starting terminal display as its parent, and only one of which is visible at a time.

### Changes

- New in version 1.6

| create(parent, nX, nY, nWidth, nHeight [, bStartVisible]) | Returns a terminal object that is a space within the specified parent terminal object. |

### create(parent, nX, nY, nWidth, nHeight [, bStartVisible])
Returns a terminal object that is a space within the specified parent terminal object. This can then be used (or even redirected to) in the same manner as eg a wrapped monitor. Refer to the term API for a list of functions available to it.

`term` itself may not be passed as the parent, though `term.native` is acceptable. Generally, `term.current` or a wrapped monitor will be most suitable, though windows may even have other windows assigned as their parents.

### Parameters

- parent `term.Redirect` The parent terminal redirect to draw to.
- nX `number` The x coordinate this window is drawn at in the parent terminal
- nY `number` The y coordinate this window is drawn at in the parent terminal
- nWidth `number` The width of this window
- nHeight `number` The height of this window
- bStartVisible? `boolean` Whether this window is visible by default. Defaults to `true`.

### Returns

- `Window` The constructed window

### Usage

-

Create a smaller window, fill it red and write some text to it.

```lua
local my_window = window.create(term.current(), 1, 1, 20, 5)
my_window.setBackgroundColour(colours.red)
my_window.setTextColour(colours.white)
my_window.clear()
my_window.write("Testing my window!")
```

-

Create a smaller window and redirect to it.

```lua
local my_window = window.create(term.current(), 1, 1, 25, 5)
term.redirect(my_window)
print("Writing some long text which will wrap around and show the bounds of this window.")
```

### Changes

- New in version 1.6

### Types

### Window

The window object. Refer to the module's documentation for a full description.

### See also

- `term.Redirect`

### Window.write(sText)
### Parameters

- sText

### Window.blit(sText, sTextColor, sBackgroundColor)
### Parameters

- sText
- sTextColor
- sBackgroundColor

### Window.clear()
### Window.clearLine()
### Window.getCursorPos()
### Window.setCursorPos(x, y)
### Parameters

- x
- y

### Window.setCursorBlink(blink)
### Parameters

- blink

### Window.getCursorBlink()
### Window.isColor()
### Window.isColour()
### Window.setTextColor(color)
### Parameters

- color

### Window.setTextColour(color)
### Parameters

- color

### Window.setPaletteColour(colour, r, g, b)
### Parameters

- colour
- r
- g
- b

### Window.setPaletteColor(colour, r, g, b)
### Parameters

- colour
- r
- g
- b

### Window.getPaletteColour(colour)
### Parameters

- colour

### Window.getPaletteColor(colour)
### Parameters

- colour

### Window.setBackgroundColor(color)
### Parameters

- color

### Window.setBackgroundColour(color)
### Parameters

- color

### Window.getSize()
### Window.scroll(n)
### Parameters

- n

### Window.getTextColor()
### Window.getTextColour()
### Window.getBackgroundColor()
### Window.getBackgroundColour()
### Window.getLine(y)
Get the buffered contents of a line in this window.

### Parameters

- y `number` The y position of the line to get.

### Returns

- `string` The textual content of this line.
- `string` The text colours of this line, suitable for use with `term.blit`.
- `string` The background colours of this line, suitable for use with `term.blit`.

### Throws

-

If `y` is not between 1 and this window's height.

### Changes

- New in version 1.84.0

### Window.setVisible(visible)
Set whether this window is visible. Invisible windows will not be drawn to the screen until they are made visible again.

Making an invisible window visible will immediately draw it.

### Parameters

- visible `boolean` Whether this window is visible.

### Window.isVisible()
Get whether this window is visible. Invisible windows will not be drawn to the screen until they are made visible again.

### Returns

- `boolean` Whether this window is visible.

### See also

- `Window:setVisible`

### Changes

- New in version 1.94.0

### Window.redraw()
Draw this window. This does nothing if the window is not visible.

### See also

- `Window:setVisible`

### Window.restoreCursor()
Set the current terminal's cursor to where this window's cursor is. This does nothing if the window is not visible.

### Window.getPosition()
Get the position of the top left corner of this window.

### Returns

- `number` The x position of this window.
- `number` The y position of this window.

### Window.reposition(new_x, new_y [, new_width, new_height [, new_parent]])
Reposition or resize the given window.

This function also accepts arguments to change the size of this window. It is recommended that you fire a `term_resize` event after changing a window's, to allow programs to adjust their sizing.

### Parameters

- new_x `number` The new x position of this window.
- new_y `number` The new y position of this window.
- new_width? `number` The new width of this window.
- new_height `number` The new height of this window.
- new_parent? `term.Redirect` The new redirect object this window should draw to.

### Changes

- Changed in version 1.85.0: Add `new_parent` parameter.
