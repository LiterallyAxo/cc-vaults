<!-- fetched from https://tweaked.cc/event/peripheral.html -->
# event / peripheral

# peripheral

The `peripheral` event is fired when a peripheral is attached on a side or to a modem.

## Return Values

- `string`: The event name.
- `string`: The side the peripheral was attached to.

## Example

Prints a message when a peripheral is attached:

```lua
while true do
 local event, side = os.pullEvent("peripheral")
 print("A peripheral was attached on side " .. side)
end
```

### See also

- `peripheral_detach` For the event fired when a peripheral is detached.
