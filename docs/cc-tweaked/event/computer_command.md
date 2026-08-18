<!-- fetched from https://tweaked.cc/event/computer_command.html -->
# event / computer command

# computer_command

The `computer_command` event is fired when the `/computercraft queue` command is run for the current command computer.

## Return Values

- `string`: The event name.
- `string`…: The arguments passed to the command.

## Example

Prints the contents of messages sent:

```lua
while true do
 local event = {os.pullEvent("computer_command")}
 print("Received message:", table.unpack(event, 2))
end
```
