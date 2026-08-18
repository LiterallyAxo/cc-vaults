<!-- fetched from https://tweaked.cc/event/key_up.html -->
# event / key up

# key_up

Fired whenever a key is released (or the terminal is closed while a key was being pressed).

This event returns a numerical "key code" (for instance, F1 is 290). This value may vary between versions and so it is recommended to use the constants in the `keys` API rather than hard coding numeric values.

## Return values

- `string`: The event name.
- `number`: The numerical key value of the key pressed.

## Example

Prints each key released on the keyboard whenever a `key_up` event is fired.

```lua
while true do
 local event, key = os.pullEvent("key_up")
 local name = keys.getName(key) or "unknown key"
 print(name .. " was released.")
end
```

### See also

- `keys` For a lookup table of the given keys.
