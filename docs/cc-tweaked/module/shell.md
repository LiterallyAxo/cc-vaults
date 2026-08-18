<!-- fetched from https://tweaked.cc/module/shell.html -->
# module / shell

# shell

The shell API provides access to CraftOS's command line interface.

It allows you to start programs, add completion for a program, and much more.

`shell` is not a "true" API. Instead, it is a standard program, which injects its API into the programs that it launches. This allows for multiple shells to run at the same time, but means that the API is not available in the global environment, and so is unavailable to other APIs.

## Programs and the program path

When you run a command with the shell, either from the prompt or from Lua code, the shell API performs several steps to work out which program to run:

-

Firstly, the shell attempts to resolve aliases. This allows us to use multiple names for a single command. For example, the `list` program has two aliases: `ls` and `dir`. When you write `ls /rom`, that's expanded to `list /rom`.

-

Next, the shell attempts to find where the program actually is. For this, it uses the program path. This is a colon separated list of directories, each of which is checked to see if it contains the program.

`list` or `list.lua` doesn't exist in `.` (the current directory), so the shell now looks in `/rom/programs`, where `list.lua` can be found!

-

Finally, the shell reads the file and checks if the file starts with a `#!`. This is a hashbang, which says that this file shouldn't be treated as Lua, but instead passed to another program, the name of which should follow the `#!`.

### Changes

- Changed in version 1.103.0: Added support for hashbangs.

| execute(command, ...) | Run a program with the supplied arguments. |
| run(...) | Run a program with the supplied arguments. |
| exit() | Exit the current shell. |
| dir() | Return the current working directory. |
| setDir(dir) | Set the current working directory. |
| path() | Get the path where programs are located. |
| setPath(path) | Set the current program path. |
| resolve(path) | Resolve a relative path to an absolute path. |
| resolveProgram(command) | Resolve a program, using the program path and list of aliases. |
| programs([include_hidden]) | Return a list of all programs on the path. |
| complete(sLine) | Complete a shell command line. |
| completeProgram(program) | Complete the name of a program. |
| setCompletionFunction(program, complete) | Set the completion function for a program. |
| getCompletionInfo() | Get a table containing all completion functions. |
| getRunningProgram() | Returns the path to the currently running program. |
| setAlias(command, program) | Add an alias for a program. |
| clearAlias(command) | Remove an alias. |
| aliases() | Get the current aliases for this shell. |
| openTab(...) | Open a new `multishell` tab running a command. |
| switchTab(id) | Switch to the `multishell` tab with the given index. |

### execute(command, ...)
Run a program with the supplied arguments.

Unlike `shell.run`, each argument is passed to the program verbatim. While `shell.run("echo", "b c")` runs `echo` with `b` and `c`, `shell.execute("echo", "b c")` runs `echo` with a single argument `b c`.

### Parameters

- command `string` The program to execute.
- ... `string` Arguments to this program.

### Returns

- `boolean` Whether the program exited successfully.

### Usage

-

Run `paint my-image` from within your program:

```lua
shell.execute("paint", "my-image")
```

### Changes

- New in version 1.88.0

### run(...)
Run a program with the supplied arguments.

All arguments are concatenated together and then parsed as a command line. As a result, `shell.run("program a b")` is the same as `shell.run("program", "a", "b")`.

### Parameters

- ... `string` The program to run and its arguments.

### Returns

- `boolean` Whether the program exited successfully.

### Usage

-

Run `paint my-image` from within your program:

```lua
shell.run("paint", "my-image")
```

### See also

- `shell.execute` Run a program directly without parsing the arguments.

### Changes

- Changed in version 1.80pr1: Programs now get their own environment instead of sharing the same one.
- Changed in version 1.83.0: `arg` is now added to the environment.

### exit()
Exit the current shell.

This does not terminate your program, it simply makes the shell terminate after your program has finished. If this is the toplevel shell, then the computer will be shutdown.

### dir()
Return the current working directory. This is what is displayed before the `> ` of the shell prompt, and is used by `shell.resolve` to handle relative paths.

### Returns

- `string` The current working directory.

### See also

- `setDir` To change the working directory.

### setDir(dir)
Set the current working directory.

### Parameters

- dir `string` The new working directory.

### Throws

-

If the path does not exist or is not a directory.

### Usage

-

Set the working directory to "rom"

```lua
shell.setDir("rom")
```

### path()
Get the path where programs are located.

The path is composed of a list of directory names in a string, each separated by a colon (`:`). On normal turtles will look in the current directory (`.`), `/rom/programs` and `/rom/programs/turtle` folder, making the path `.:/rom/programs:/rom/programs/turtle`.

### Returns

- `string` The current shell's path.

### See also

- `setPath` To change the current path.

### setPath(path)
Set the current program path.

Be careful to prefix directories with a `/`. Otherwise they will be searched for from the current directory, rather than the computer's root.

### Parameters

- path `string` The new program path.

### Changes

- New in version 1.2

### resolve(path)
Resolve a relative path to an absolute path.

The `fs` and `io` APIs work using absolute paths, and so we must convert any paths relative to the current directory to absolute ones. This does nothing when the path starts with `/`.

### Parameters

- path `string` The path to resolve.

### Usage

-

Resolve `startup.lua` when in the `rom` folder.

```lua
shell.setDir("rom")
print(shell.resolve("startup.lua"))
-- => rom/startup.lua
```

### resolveProgram(command)
Resolve a program, using the program path and list of aliases.

### Parameters

- command `string` The name of the program

### Returns

- `string` | nil The absolute path to the program, or `nil` if it could not be found.

### Usage

-

Locate the `hello` program.

```lua
 shell.resolveProgram("hello")
 -- => rom/programs/fun/hello.lua
```

### Changes

- New in version 1.2
- Changed in version 1.80pr1: Now searches for files with and without the `.lua` extension.

### programs([include_hidden])
Return a list of all programs on the path.

### Parameters

- include_hidden? `boolean` Include hidden files. Namely, any which start with `.`.

### Returns

- { `string` } A list of available programs.

### Usage

-

```lua
textutils.tabulate(shell.programs())
```

### Changes

- New in version 1.2

### complete(sLine)
Complete a shell command line.

This accepts an incomplete command, and completes the program name or arguments. For instance, `l` will be completed to `ls`, and `ls ro` will be completed to `ls rom/`.

Completion handlers for your program may be registered with `shell.setCompletionFunction`.

### Parameters

- sLine `string` The input to complete.

### Returns

- { `string` } | nil The list of possible completions.

### See also

- `_G.read` For more information about completion.
- `shell.completeProgram`
- `shell.setCompletionFunction`
- `shell.getCompletionInfo`

### Changes

- New in version 1.74

### completeProgram(program)
Complete the name of a program.

### Parameters

- program `string` The name of a program to complete.

### Returns

- { `string` } A list of possible completions.

### See also

- `cc.shell.completion.program`

### setCompletionFunction(program, complete)
Set the completion function for a program. When the program is entered on the command line, this program will be called to provide auto-complete information.

The completion function accepts four arguments:

- The current shell. As completion functions are inherited, this is not guaranteed to be the shell you registered this function in.
- The index of the argument currently being completed.
- The current argument. This may be the empty string.
- A list of the previous arguments.

For instance, when completing `pastebin put rom/st` our pastebin completion function will receive the shell API, an index of 2, `rom/st` as the current argument, and a "previous" table of `{ "put" }`. This function may then wish to return a table containing `artup.lua`, indicating the entire command should be completed to `pastebin put rom/startup.lua`.

You completion entries may also be followed by a space, if you wish to indicate another argument is expected.

### Parameters

- program `string` The path to the program. This should be an absolute path without the leading `/`.
- complete function(shell: `table`, index: `number`, argument: `string`, previous: { `string` }):{ `string` } | nil The completion function.

### See also

- `cc.shell.completion` Various utilities to help with writing completion functions.
- `shell.complete`
- `_G.read` For more information about completion.

### Changes

- New in version 1.74

### getCompletionInfo()
Get a table containing all completion functions.

This should only be needed when building custom shells. Use `setCompletionFunction` to add a completion function.

### Returns

- { [`string`] = { fnComplete = `function` } } A table mapping the absolute path of programs, to their completion functions.

### getRunningProgram()
Returns the path to the currently running program.

### Returns

- `string` The absolute path to the running program.

### Changes

- New in version 1.3

### setAlias(command, program)
Add an alias for a program.

### Parameters

- command `string` The name of the alias to add.
- program `string` The name or path to the program.

### Usage

-

Alias `vim` to the `edit` program

```lua
shell.setAlias("vim", "edit")
```

### Changes

- New in version 1.2

### clearAlias(command)
Remove an alias.

### Parameters

- command `string` The alias name to remove.

### aliases()
Get the current aliases for this shell.

Aliases are used to allow multiple commands to refer to a single program. For instance, the `list` program is aliased to `dir` or `ls`. Running `ls`, `dir` or `list` in the shell will all run the `list` program.

### Returns

- { [`string`] = `string` } A table, where the keys are the names of aliases, and the values are the path to the program.

### See also

- `shell.setAlias`
- `shell.resolveProgram` This uses aliases when resolving a program name to an absolute path.

### openTab(...)
Open a new `multishell` tab running a command.

This behaves similarly to `shell.run`, but instead returns the process index.

This function is only available if the `multishell` API is.

### Parameters

- ... `string` The command line to run.

### Returns

- `number` The ID of the new tab that was opened.

### Usage

-

Launch the Lua interpreter and switch to it.

```lua
local id = shell.openTab("lua")
shell.switchTab(id)
```

### See also

- `shell.run`
- `multishell.launch`

### Changes

- New in version 1.6

### switchTab(id)
Switch to the `multishell` tab with the given index.

### Parameters

- id `number` The tab to switch to.

### See also

- `multishell.setFocus`

### Changes

- New in version 1.6
