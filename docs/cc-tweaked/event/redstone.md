<!-- fetched from https://tweaked.cc/event/redstone.html -->
# event / redstone

# redstone

The `redstone` event is fired whenever any redstone inputs on the computer or relay change.

## Return values

- `string`: The event name.

## Example

Prints a message when a redstone input changes:

```lua
while true do
 os.pullEvent("redstone")
 print("A redstone input has changed!")
end
```

## See also

- The `redstone` API on computers
- The `redstone_relay` peripheral
