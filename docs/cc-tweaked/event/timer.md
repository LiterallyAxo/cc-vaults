<!-- fetched from https://tweaked.cc/event/timer.html -->
# event / timer

# timer

The `timer` event is fired when a timer started with `os.startTimer` completes.

## Return Values

- `string`: The event name.
- `number`: The ID of the timer that finished.

## Example

Start and wait for a timer to finish.

```lua
local timer_id = os.startTimer(2)
local event, id
repeat
 event, id = os.pullEvent("timer")
until id == timer_id
print("Timer with ID " .. id .. " was fired")
```

### See also

- `os.startTimer` To start a timer.
