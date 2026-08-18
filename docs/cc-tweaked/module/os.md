<!-- fetched from https://tweaked.cc/module/os.html -->
# module / os

# os

The `os` API allows interacting with the current computer.

| loadAPI(path) | Loads the given API into the global environment. |
| unloadAPI(name) | Unloads an API which was loaded by `os.loadAPI`. |
| pullEvent([filter]) | Pause execution of the current thread and waits for any events matching `filter`. |
| pullEventRaw([filter]) | Pause execution of the current thread and waits for events, including the `terminate` event. |
| sleep([time=0]) | Pauses execution for the specified number of seconds, alias of `_G.sleep`. |
| version() | Get the current CraftOS version (for example, `CraftOS 1.9`). |
| run(env, path, ...) | Run the program at the given path with the specified environment and arguments. |
| queueEvent(name, ...) | Adds an event to the event queue. |
| startTimer(time) | Starts a timer that will run for the specified number of seconds. |
| cancelTimer(token) | Cancels a timer previously started with `startTimer`. |
| setAlarm(time) | Sets an alarm that will fire at the specified in-game time. |
| cancelAlarm(token) | Cancels an alarm previously started with setAlarm. |
| shutdown() | Shuts down the computer immediately. |
| reboot() | Reboots the computer immediately. |
| getComputerID() | Returns the ID of the computer. |
| computerID() | Returns the ID of the computer. |
| getComputerLabel() | Returns the label of the computer, or `nil` if none is set. |
| computerLabel() | Returns the label of the computer, or `nil` if none is set. |
| setComputerLabel([label]) | Set the label of this computer. |
| clock() | Returns the number of seconds that the computer has been running. |
| time([locale]) | Returns the current time depending on the string passed in. |
| day([locale]) | Returns the day depending on the locale specified. |
| epoch([locale]) | Returns the number of milliseconds since an epoch depending on the locale. |
| date([format [, time]]) | Returns a date string (or table) using a specified format string and optional time to format. |

### loadAPI(path)
##### 🛈 Deprecated

When possible it's best to avoid using this function. It pollutes the global table and can mask errors.

`require` should be used to load libraries instead.

Loads the given API into the global environment.

This function loads and executes the file at the given path, and all global variables and functions exported by it will by available through the use of `myAPI.<function name>`, where `myAPI` is the base name of the API file.

### Parameters

- path `string` The path of the API to load.

### Returns

- `boolean` Whether or not the API was successfully loaded.

### Changes

- New in version 1.2

### unloadAPI(name)
##### 🛈 Deprecated

See `os.loadAPI` for why.

Unloads an API which was loaded by `os.loadAPI`.

This effectively removes the specified table from `_G`.

### Parameters

- name `string` The name of the API to unload.

### Changes

- New in version 1.2

### pullEvent([filter])
Pause execution of the current thread and waits for any events matching `filter`.

This function yields the current process and waits for it to be resumed with a vararg list where the first element matches `filter`. If no `filter` is supplied, this will match all events.

Unlike `os.pullEventRaw`, it will stop the application upon a "terminate" event, printing the error "Terminated".

### Parameters

- filter? `string` Event to filter for.

### Returns

- `string` event The name of the event that fired.
- `any` param... Optional additional parameters of the event.

### Usage

-

Listen for `mouse_click` events.

```lua
while true do
 local event, button, x, y = os.pullEvent("mouse_click")
 print("Button", button, "was clicked at", x, ",", y)
end
```

-

Listen for multiple events.

```lua
while true do
 local eventData = {os.pullEvent()}
 local event = eventData[1]

 if event == "mouse_click" then
 print("Button", eventData[2], "was clicked at", eventData[3], ",", eventData[4])
 elseif event == "key" then
 print("Key code", eventData[2], "was pressed")
 end
end
```

### See also

- `os.pullEventRaw` To pull the terminate event.

### Changes

- Changed in version 1.3: Added filter argument.

### pullEventRaw([filter])
Pause execution of the current thread and waits for events, including the `terminate` event.

This behaves almost the same as `os.pullEvent`, except it allows you to handle the `terminate` event yourself - the program will not stop execution when Ctrl+T is pressed.

### Parameters

- filter? `string` Event to filter for.

### Returns

- `string` event The name of the event that fired.
- `any` param... Optional additional parameters of the event.

### Usage

-

Listen for `terminate` events.

```lua
while true do
 local event = os.pullEventRaw()
 if event == "terminate" then
 print("Caught terminate event!")
 end
end
```

### See also

- `os.pullEvent` To pull events normally.

### sleep([time=0])
Pauses execution for the specified number of seconds, alias of `_G.sleep`.

### Parameters

- time? `number` = `0` The number of seconds to sleep for, rounded up to the nearest multiple of 0.05.

### version()
Get the current CraftOS version (for example, `CraftOS 1.9`).

This is defined by `bios.lua`. For the current version of CC:Tweaked, this should return `CraftOS 1.9`.

If you need to check for the presence of a feature, it is usually better to rely on feature detection, rather than comparing CraftOS versions.

### Returns

- `string` The current CraftOS version.

### Usage

-

```lua
os.version()
```

### See also

- `_G._HOST`

### run(env, path, ...)
Run the program at the given path with the specified environment and arguments.

This function does not resolve program names like the shell does. This means that, for example, `os.run("edit")` will not work. As well as this, it does not provide access to the `shell` API in the environment. For this behaviour, use `shell.run` instead.

If the program cannot be found, or failed to run, it will print the error and return `false`. If you want to handle this more gracefully, use an alternative such as `loadfile`.

### Parameters

- env `table` The environment to run the program with.
- path `string` The exact path of the program to run.
- ... The arguments to pass to the program.

### Returns

- `boolean` Whether or not the program ran successfully.

### Usage

-

Run the default shell from within your program:

```lua
os.run({}, "/rom/programs/shell.lua")
```

### See also

- `shell.run`
- `loadfile`

### queueEvent(name, ...)
Adds an event to the event queue. This event can later be pulled with os.pullEvent.

### Parameters

- name `string` The name of the event to queue.
- ... The parameters of the event. These can be any primitive type (boolean, number, string) as well as tables. Other types (like functions), as well as metatables, will not be preserved.

### See also

- `os.pullEvent` To pull the event queued

### startTimer(time)
Starts a timer that will run for the specified number of seconds. Once the timer fires, a `timer` event will be added to the queue with the ID returned from this function as the first parameter.

As with sleep, the time will automatically be rounded up to the nearest multiple of 0.05 seconds, as it waits for a fixed amount of world ticks.

### Parameters

- time `number` The number of seconds until the timer fires.

### Returns

- `number` The ID of the new timer. This can be used to filter the `timer` event, or cancel the timer.

### Throws

-

If the time is below zero.

### See also

- `cancelTimer` To cancel a timer.

### cancelTimer(token)
Cancels a timer previously started with `startTimer`. This will stop the timer from firing.

### Parameters

- token `number` The ID of the timer to cancel.

### See also

- `startTimer` To start a timer.

### Changes

- New in version 1.6

### setAlarm(time)
Sets an alarm that will fire at the specified in-game time. When it fires, an `alarm` event will be added to the event queue with the ID returned from this function as the first parameter.

### Parameters

- time `number` The time at which to fire the alarm, in the range [0.0, 24.0).

### Returns

- `number` The ID of the new alarm. This can be used to filter the `alarm` event, or cancel the alarm.

### Throws

-

If the time is out of range.

### See also

- `cancelAlarm` To cancel an alarm.

### Changes

- New in version 1.2

### cancelAlarm(token)
Cancels an alarm previously started with setAlarm. This will stop the alarm from firing.

### Parameters

- token `number` The ID of the alarm to cancel.

### See also

- `setAlarm` To set an alarm.

### Changes

- New in version 1.6

### shutdown()
Shuts down the computer immediately.

### reboot()
Reboots the computer immediately.

### getComputerID()
Returns the ID of the computer.

### Returns

- `number` The ID of the computer.

### computerID()
Returns the ID of the computer.

### Returns

- `number` The ID of the computer.

### getComputerLabel()
Returns the label of the computer, or `nil` if none is set.

### Returns

- `string` | nil The label of the computer.

### Changes

- New in version 1.3

### computerLabel()
Returns the label of the computer, or `nil` if none is set.

### Returns

- `string` | nil The label of the computer.

### Changes

- New in version 1.3

### setComputerLabel([label])
Set the label of this computer.

### Parameters

- label? `string` The new label. May be `nil` in order to clear it.

### Changes

- New in version 1.3

### clock()
Returns the number of seconds that the computer has been running.

### Returns

- `number` The computer's uptime.

### Changes

- New in version 1.2

### time([locale])
Returns the current time depending on the string passed in. This will always be in the range [0.0, 24.0).

- If called with `ingame`, the current world time will be returned. This is the default if nothing is passed.
- If called with `utc`, returns the hour of the day in UTC time.
- If called with `local`, returns the hour of the day in the timezone the server is located in.

This function can also be called with a table returned from `date`, which will convert the date fields into a UNIX timestamp (number of seconds since 1 January 1970).

### Parameters

- locale? `string` | `table` The locale of the time, or a table filled by `os.date("*t")` to decode. Defaults to `ingame` locale if not specified.

### Returns

- `any` The hour of the selected locale, or a UNIX timestamp from the table, depending on the argument passed in.

### Throws

-

If an invalid locale is passed.

### Usage

-

Print the current in-game time.

```lua
textutils.formatTime(os.time())
```

### See also

- `textutils.formatTime` To convert times into a user-readable string.
- `date` To get a date table that can be converted with this function.

### Changes

- New in version 1.2
- Changed in version 1.80pr1: Add support for getting the local and UTC time.
- Changed in version 1.82.0: Arguments are now case insensitive.
- Changed in version 1.83.0: `time` now accepts table arguments and converts them to UNIX timestamps.

### day([locale])
Returns the day depending on the locale specified.

- If called with `ingame`, returns the number of days since the world was created. This is the default.
- If called with `utc`, returns the number of days since 1 January 1970 in the UTC timezone.
- If called with `local`, returns the number of days since 1 January 1970 in the server's local timezone.

### Parameters

- locale? `string` The locale to get the day for. Defaults to `ingame` if not set.

### Returns

- `number` The day depending on the selected locale.

### Throws

-

If an invalid locale is passed.

### Changes

- New in version 1.48
- Changed in version 1.82.0: Arguments are now case insensitive.

### epoch([locale])
Returns the number of milliseconds since an epoch depending on the locale.

- If called with `ingame`, returns the number of in-game milliseconds since the world was created. This is the default.
- If called with `utc`, returns the number of milliseconds since 1 January 1970 in the UTC timezone.
- If called with `local`, returns the number of milliseconds since 1 January 1970 in the server's local timezone.

##### 🛈 info

The `ingame` time zone assumes that one Minecraft day consists of 86,400,000 milliseconds. Since one in-game day is much faster than a real day (20 minutes), this will change quicker than real time - one real second is equal to 72000 in-game milliseconds. If you wish to convert this value to real time, divide by 72000; to convert to ticks (where a day is 24000 ticks), divide by 3600.

### Parameters

- locale? `string` The locale to get the milliseconds for. Defaults to `ingame` if not set.

### Returns

- `number` The milliseconds since the epoch depending on the selected locale.

### Throws

-

If an invalid locale is passed.

### Usage

-

Get the current time and use `date` to convert it to a table.

```lua
-- Dividing by 1000 converts it from milliseconds to seconds.
local time = os.epoch("local") / 1000
local time_table = os.date("*t", time)
print(textutils.serialize(time_table))
```

### Changes

- New in version 1.80pr1

### date([format [, time]])
Returns a date string (or table) using a specified format string and optional time to format.

The format string takes the same formats as C's strftime function. The format string can also be prefixed with an exclamation mark (`!`) to use UTC time instead of the server's local timezone.

If the format is exactly `"*t"` (or `"!*t"` ), a table representation of the timestamp will be returned instead. This table has fields for the year, month, day, hour, minute, second, day of the week, day of the year, and whether Daylight Savings Time is in effect. This table can be converted back to a timestamp with `time`.

### Parameters

- format? `string` The format of the string to return. This defaults to `%c`, which expands to a string similar to "Sat Dec 24 16:58:00 2011".
- time? `number` The timestamp to convert to a string. This defaults to the current time.

### Returns

- `any` The resulting formated string, or table.

### Throws

-

If an invalid format is passed.

### Usage

-

Print the current date in a user-friendly string.

```lua
os.date("%A %d %B %Y") -- See the reference above!
```

-

Convert a timestamp to a table.

```lua
os.date("!*t", 1242534247)
--[=[ {
 -- Date
 year = 2009,
 month = 5,
 day = 17,
 yday = 137,
 wday = 1,
 -- Time
 hour = 4,
 min = 24,
 sec = 7,
 isdst = false,
} ]=]
```

### Changes

- New in version 1.83.0
