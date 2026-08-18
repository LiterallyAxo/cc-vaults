<!-- fetched from https://tweaked.cc/event/monitor_resize.html -->
# event / monitor resize

# monitor_resize

The `monitor_resize` event is fired when an adjacent or networked monitor's size is changed.

## Return Values

- `string`: The event name.
- `string`: The side or network ID of the monitor that was resized.

## Example

Prints a message when a monitor is resized:

```lua
while true do
 local event, side = os.pullEvent("monitor_resize")
 print("The monitor on side " .. side .. " was resized.")
end
```
