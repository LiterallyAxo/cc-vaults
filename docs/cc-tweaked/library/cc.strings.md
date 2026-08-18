<!-- fetched from https://tweaked.cc/library/cc.strings.html -->
# library / cc.strings

# cc.strings

Various utilities for working with strings and text.

### See also

- `textutils` For additional string related utilities.

### Changes

- New in version 1.95.0

| wrap(text [, width]) | Wraps a block of text, so that each line fits within the given width. |
| ensure_width(line [, width]) | Makes the input string a fixed width. |
| split(str, deliminator [, plain=false [, limit]]) | Split a string into parts, each separated by a deliminator. |

### wrap(text [, width])
Wraps a block of text, so that each line fits within the given width.

This may be useful if you want to wrap text before displaying it to a `monitor` or `printer` without using print.

### Parameters

- text `string` The string to wrap.
- width? `number` The width to constrain to, defaults to the width of the terminal.

### Returns

- { `string`... } The wrapped input string as a list of lines.

### Usage

-

Wrap a string and write it to the terminal.

```lua
term.clear()
local lines = require "cc.strings".wrap("This is a long piece of text", 10)
for i = 1, #lines do
 term.setCursorPos(1, i)
 term.write(lines[i])
end
```

### ensure_width(line [, width])
Makes the input string a fixed width. This either truncates it, or pads it with spaces.

### Parameters

- line `string` The string to normalise.
- width? `number` The width to constrain to, defaults to the width of the terminal.

### Returns

- `string` The string with a specific width.

### Usage

-

```lua
require "cc.strings".ensure_width("a short string", 20)
```

-

```lua
require "cc.strings".ensure_width("a rather long string which is truncated", 20)
```

### split(str, deliminator [, plain=false [, limit]])
Split a string into parts, each separated by a deliminator.

For instance, splitting the string `"a b c"` with the deliminator `" "`, would return a table with three strings: `"a"`, `"b"`, and `"c"`.

By default, the deliminator is given as a Lua pattern. Passing `true` to the `plain` argument will cause the deliminator to be treated as a litteral string.

### Parameters

- str `string` The string to split.
- deliminator `string` The pattern to split this string on.
- plain? `boolean` = `false` Treat the deliminator as a plain string, rather than a pattern.
- limit? `number` The maximum number of elements in the returned list.

### Returns

- { `string`... } The list of split strings.

### Usage

-

Split a string into words.

```lua
require "cc.strings".split("This is a sentence.", "%s+")
```

-

Split a string by "-" into at most 3 elements.

```lua
require "cc.strings".split("a-separated-string-of-sorts", "-", true, 3)
```

### See also

- `table.concat` To join strings together.

### Changes

- New in version 1.112.0
