<!-- fetched from https://tweaked.cc/event/monitor_touch.html -->
# event / monitor touch

# monitor_touch

The `monitor_touch` event is fired when an adjacent or networked Advanced Monitor is right-clicked.

## Return Values

- `string`: The event name.
- `string`: The side or network ID of the monitor that was touched.
- `number`: The X coordinate of the touch, in characters.
- `number`: The Y coordinate of the touch, in characters.

## Example

Prints a message when a monitor is touched:

```lua
while true do
 local event, side, x, y = os.pullEvent("monitor_touch")
 print("The monitor on side " .. side .. " was touched at (" .. x .. ", " .. y .. ")")
end
```
