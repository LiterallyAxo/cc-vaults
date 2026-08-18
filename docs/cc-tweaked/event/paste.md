<!-- fetched from https://tweaked.cc/event/paste.html -->
# event / paste

# paste

The `paste` event is fired when text is pasted into the computer through Ctrl-V (or ⌘V on Mac).

## Return values

- `string`: The event name.
- `string` The text that was pasted.

## Example

Prints pasted text:

```lua
while true do
 local event, text = os.pullEvent("paste")
 print('"' .. text .. '" was pasted')
end
```
