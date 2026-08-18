<!-- fetched from https://tweaked.cc/library/cc.shell.completion.html -->
# library / cc.shell.completion

# cc.shell.completion

A collection of helper methods for working with shell completion.

Most programs may be completed using the `build` helper method, rather than manually switching on the argument index.

Note, the helper functions within this module do not accept an argument index, and so are not directly usable with the `shell.setCompletionFunction`. Instead, wrap them using `build`, or your own custom function.

### Usage

-

Register a completion handler for example.lua which prompts for a choice of options, followed by a directory, and then multiple files.

```lua
local completion = require "cc.shell.completion"
local complete = completion.build(
 { completion.choice, { "get", "put" } },
 completion.dir,
 { completion.file, many = true }
)
shell.setCompletionFunction("example.lua", complete)
read(nil, nil, shell.complete, "example ")
```

### See also

- `cc.completion` For more general helpers, suitable for use with `_G.read`.
- `shell.setCompletionFunction`

### Changes

- New in version 1.85.0

| file(shell, text) | Complete the name of a file relative to the current working directory. |
| dir(shell, text) | Complete the name of a directory relative to the current working directory. |
| dirOrFile(shell, text, previous [, add_space]) | Complete the name of a file or directory relative to the current working directory. |
| program(shell, text) | Complete the name of a program. |
| programWithArgs(shell, text, previous, starting) | Complete arguments of a program. |
| help | Wraps `help.completeTopic` as a `build` compatible function. |
| choice | Wraps `cc.completion.choice` as a `build` compatible function. |
| peripheral | Wraps `cc.completion.peripheral` as a `build` compatible function. |
| side | Wraps `cc.completion.side` as a `build` compatible function. |
| setting | Wraps `cc.completion.setting` as a `build` compatible function. |
| command | Wraps `cc.completion.command` as a `build` compatible function. |
| build(...) | A helper function for building shell completion arguments. |

### file(shell, text)
Complete the name of a file relative to the current working directory.

### Parameters

- shell `table` The shell we're completing in.
- text `string` Current text to complete.

### Returns

- { `string`... } A list of suffixes of matching files.

### dir(shell, text)
Complete the name of a directory relative to the current working directory.

### Parameters

- shell `table` The shell we're completing in.
- text `string` Current text to complete.

### Returns

- { `string`... } A list of suffixes of matching directories.

### dirOrFile(shell, text, previous [, add_space])
Complete the name of a file or directory relative to the current working directory.

### Parameters

- shell `table` The shell we're completing in.
- text `string` Current text to complete.
- previous { `string`... } The shell arguments before this one.
- add_space? `boolean` Whether to add a space after the completed item.

### Returns

- { `string`... } A list of suffixes of matching files and directories.

### program(shell, text)
Complete the name of a program.

### Parameters

- shell `table` The shell we're completing in.
- text `string` Current text to complete.

### Returns

- { `string`... } A list of suffixes of matching programs.

### See also

- `shell.completeProgram`

### programWithArgs(shell, text, previous, starting)
Complete arguments of a program.

### Parameters

- shell `table` The shell we're completing in.
- text `string` Current text to complete.
- previous { `string`... } The shell arguments before this one.
- starting `number` Which argument index this program and args start at.

### Returns

- { `string`... } A list of suffixes of matching programs or arguments.

### Changes

- New in version 1.97.0

### help
Wraps `help.completeTopic` as a `build` compatible function.

### choice
Wraps `cc.completion.choice` as a `build` compatible function.

### peripheral
Wraps `cc.completion.peripheral` as a `build` compatible function.

### side
Wraps `cc.completion.side` as a `build` compatible function.

### setting
Wraps `cc.completion.setting` as a `build` compatible function.

### command
Wraps `cc.completion.command` as a `build` compatible function.

### build(...)
A helper function for building shell completion arguments.

This accepts a series of single-argument completion functions, and combines them into a function suitable for use with `shell.setCompletionFunction`.

### Parameters

- ... nil | `table` | `function`

Every argument to `build` represents an argument to the program you wish to complete. Each argument can be one of three types:

 -

`nil`: This argument will not be completed.

 -

A function: This argument will be completed with the given function. It is called with the `shell` object, the string to complete and the arguments before this one.

 -

A table: This acts as a more powerful version of the function case. The table must have a function as the first item - this will be called with the shell, string and preceding arguments as above, but also followed by any additional items in the table. This provides a more convenient interface to pass options to your completion functions.

If this table is the last argument, it may also set the `many` key to true, which states this function should be used to complete any remaining arguments.
