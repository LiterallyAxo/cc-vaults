<!-- fetched from https://tweaked.cc/event/alarm.html -->
# event / alarm

# alarm

The `alarm` event is fired when an alarm started with `os.setAlarm` completes.

## Return Values

- `string`: The event name.
- `number`: The ID of the alarm that finished.

## Example

Starts a timer and then waits for it to complete.

```lua
local alarm_id = os.setAlarm(os.time() + 0.05)
local event, id
repeat
 event, id = os.pullEvent("alarm")
until id == alarm_id
print("Alarm with ID " .. id .. " was fired")
```

### See also

- `os.setAlarm` To start an alarm.
