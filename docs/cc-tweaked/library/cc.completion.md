<!-- fetched from https://tweaked.cc/library/cc.completion.html -->
# library / cc.completion

# cc.completion

A collection of helper methods for working with input completion, such as that require by `_G.read`.

### See also

- `cc.shell.completion` For additional helpers to use with `shell.setCompletionFunction`.

### Changes

- New in version 1.85.0

| choice(text, choices [, add_space]) | Complete from a choice of one or more strings. |
| peripheral(text [, add_space]) | Complete the name of a currently attached peripheral. |
| side(text [, add_space]) | Complete the side of a computer. |
| setting(text [, add_space]) | Complete a setting. |
| command(text [, add_space]) | Complete the name of a Minecraft command. |

### choice(text, choices [, add_space])
Complete from a choice of one or more strings.

### Parameters

- text `string` The input string to complete.
- choices { `string`... } The list of choices to complete from.
- add_space? `boolean` Whether to add a space after the completed item.

### Returns

- { `string`... } A list of suffixes of matching strings.

### Usage

-

Call `_G.read`, completing the names of various animals.

```lua
local completion = require "cc.completion"
local animals = { "dog", "cat", "lion", "unicorn" }
read(nil, nil, function(text) return completion.choice(text, animals) end)
```

### peripheral(text [, add_space])
Complete the name of a currently attached peripheral.

### Parameters

- text `string` The input string to complete.
- add_space? `boolean` Whether to add a space after the completed name.

### Returns

- { `string`... } A list of suffixes of matching peripherals.

### Usage

-

```lua
local completion = require "cc.completion"
read(nil, nil, completion.peripheral)
```

### side(text [, add_space])
Complete the side of a computer.

### Parameters

- text `string` The input string to complete.
- add_space? `boolean` Whether to add a space after the completed side.

### Returns

- { `string`... } A list of suffixes of matching sides.

### Usage

-

```lua
local completion = require "cc.completion"
read(nil, nil, completion.side)
```

### setting(text [, add_space])
Complete a setting.

### Parameters

- text `string` The input string to complete.
- add_space? `boolean` Whether to add a space after the completed settings.

### Returns

- { `string`... } A list of suffixes of matching settings.

### Usage

-

```lua
local completion = require "cc.completion"
read(nil, nil, completion.setting)
```

### command(text [, add_space])
Complete the name of a Minecraft command.

### Parameters

- text `string` The input string to complete.
- add_space? `boolean` Whether to add a space after the completed command.

### Returns

- { `string`... } A list of suffixes of matching commands.

### Usage

-

```lua
local completion = require "cc.completion"
read(nil, nil, completion.command)
```
