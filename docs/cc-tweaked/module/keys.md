<!-- fetched from https://tweaked.cc/module/keys.html -->
# module / keys

# keys

Constants for all keyboard "key codes", as queued by the `key` event.

These values are not guaranteed to remain the same between versions. It is recommended that you use the constants provided by this file, rather than the underlying numerical values.

### Changes

- New in version 1.4

| getName(code) | Translates a numerical key code to a human-readable name. |

### getName(code)
Translates a numerical key code to a human-readable name. The human-readable name is one of the constants in the keys API.

### Parameters

- code `number` The key code to look up.

### Returns

- `string` | nil The name of the key, or `nil` if not a valid key code.

### Usage

-

```lua
keys.getName(keys.enter)
```
