<!-- fetched from https://tweaked.cc/event/task_complete.html -->
# event / task complete

# task_complete

The `task_complete` event is fired when an asynchronous task completes. This is usually handled inside the function call that queued the task; however, functions such as `commands.execAsync` return immediately so the user can wait for completion.

## Return Values

- `string`: The event name.
- `number`: The ID of the task that completed.
- `boolean`: Whether the command succeeded.
- `string`: If the command failed, an error message explaining the failure. (This is not present if the command succeeded.)
- …: Any parameters returned from the command.

## Example

Prints the results of an asynchronous command:

```lua
local taskID = commands.execAsync("say Hello")
local event
repeat
 event = {os.pullEvent("task_complete")}
until event[2] == taskID
if event[3] == true then
 print("Task " .. event[2] .. " succeeded:", table.unpack(event, 4))
else
 print("Task " .. event[2] .. " failed: " .. event[4])
end
```

### See also

- `commands.execAsync` To run a command which fires a task_complete event.
