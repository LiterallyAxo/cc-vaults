<!-- fetched from https://tweaked.cc/module/multishell.html -->
# module / multishell

# multishell

Multishell allows multiple programs to be run at the same time.

When multiple programs are running, it displays a tab bar at the top of the screen, which allows you to switch between programs. New programs can be launched using the `fg` or `bg` programs, or using the `shell.openTab` and `multishell.launch` functions.

Each process is identified by its ID, which corresponds to its position in the tab list. As tabs may be opened and closed, this ID is not constant over a program's run. As such, be careful not to use stale IDs.

As with `shell`, `multishell` is not a "true" API. Instead, it is a standard program, which launches a shell and injects its API into the shell's environment. This API is not available in the global environment, and so is not available to APIs.

### Changes

- New in version 1.6

| getFocus() | Get the currently visible process. |
| setFocus(n) | Change the currently visible process. |
| getTitle(n) | Get the title of the given tab. |
| setTitle(n, title) | Set the title of the given process. |
| getCurrent() | Get the index of the currently running process. |
| launch(tProgramEnv, sProgramPath, ...) | Start a new process, with the given environment, program and arguments. |
| getCount() | Get the number of processes within this multishell. |

### getFocus()
Get the currently visible process. This will be the one selected on the tab bar.

Note, this is different to `getCurrent`, which returns the process which is currently executing.

### Returns

- `number` The currently visible process's index.

### See also

- `setFocus`

### setFocus(n)
Change the currently visible process.

### Parameters

- n `number` The process index to switch to.

### Returns

- `boolean` If the process was changed successfully. This will return `false` if there is no process with this id.

### See also

- `getFocus`

### getTitle(n)
Get the title of the given tab.

This starts as the name of the program, but may be changed using `multishell.setTitle`.

### Parameters

- n `number` The process index.

### Returns

- `string` | nil The current process title, or `nil` if the process doesn't exist.

### setTitle(n, title)
Set the title of the given process.

### Parameters

- n `number` The process index.
- title `string` The new process title.

### Usage

-

Change the title of the current process

```lua
multishell.setTitle(multishell.getCurrent(), "Hello")
```

### See also

- `getTitle`

### getCurrent()
Get the index of the currently running process.

### Returns

- `number` The currently running process.

### launch(tProgramEnv, sProgramPath, ...)
Start a new process, with the given environment, program and arguments.

The returned process index is not constant over the program's run. It can be safely used immediately after launching (for instance, to update the title or switch to that tab). However, after your program has yielded, it may no longer be correct.

### Parameters

- tProgramEnv `table` The environment to load the path under.
- sProgramPath `string` The path to the program to run.
- ... Additional arguments to pass to the program.

### Returns

- `number` The index of the created process.

### Usage

-

Run the "hello" program, and set its title to "Hello!"

```lua
local id = multishell.launch({}, "/rom/programs/fun/hello.lua")
multishell.setTitle(id, "Hello!")
```

### See also

- `os.run`

### getCount()
Get the number of processes within this multishell.

### Returns

- `number` The number of processes.
