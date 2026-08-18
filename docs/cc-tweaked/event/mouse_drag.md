<!-- fetched from https://tweaked.cc/event/mouse_drag.html -->
# event / mouse drag

# mouse_drag

This event is fired every time the mouse is moved while a mouse button is being held.

## Return values

- `string`: The event name.
- `number`: The mouse button that is being pressed.
- `number`: The X-coordinate of the mouse.
- `number`: The Y-coordinate of the mouse.

## Example

Print the button and the coordinates whenever the mouse is dragged.

```lua
while true do
 local event, button, x, y = os.pullEvent("mouse_drag")
 print(("The mouse button %s was dragged at %d, %d"):format(button, x, y))
end
```

### See also

- `mouse_click` For when a mouse button is initially pressed.
