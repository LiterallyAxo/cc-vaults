<!-- fetched from https://tweaked.cc/module/redstone.html -->
# module / redstone

# redstone

Get and set redstone signals adjacent to this computer.

The `redstone` library exposes three "types" of redstone control:

- Binary input/output (`setOutput`/`getInput`): These simply check if a redstone wire has any input or output. A signal strength of 1 and 15 are treated the same.
- Analogue input/output (`setAnalogOutput`/`getAnalogInput`): These work with the actual signal strength of the redstone wired, from 0 to 15.
- Bundled cables (`setBundledOutput`/`getBundledInput`): These interact with "bundled" cables, such as those from Project:Red. These allow you to send 16 separate on/off signals. Each channel corresponds to a colour, with the first being `colors.white` and the last `colors.black`.

Whenever a redstone input changes, a `redstone` event will be fired. This may be used instead of repeativly polling.

This module may also be referred to as `rs`. For example, one may call `rs.getSides()` instead of `getSides`.

### Usage

-

Toggle the redstone signal above the computer every 0.5 seconds.

```lua
while true do
 redstone.setOutput("top", not redstone.getOutput("top"))
 sleep(0.5)
end
```

-

Mimic a redstone comparator in subtraction mode.

```lua
while true do
 local rear = rs.getAnalogueInput("back")
 local sides = math.max(rs.getAnalogueInput("left"), rs.getAnalogueInput("right"))
 rs.setAnalogueOutput("front", math.max(rear - sides, 0))

 os.pullEvent("redstone") -- Wait for a change to inputs.
end
```

| getSides() | Returns a table containing the six sides of the computer. |
| setOutput(side, on) | Turn the redstone signal of a specific side on or off. |
| getOutput(side) | Get the current redstone output of a specific side. |
| getInput(side) | Get the current redstone input of a specific side. |
| setAnalogOutput(side, value) | Set the redstone signal strength for a specific side. |
| setAnalogueOutput(side, value) | Set the redstone signal strength for a specific side. |
| getAnalogOutput(side) | Get the redstone output signal strength for a specific side. |
| getAnalogueOutput(side) | Get the redstone output signal strength for a specific side. |
| getAnalogInput(side) | Get the redstone input signal strength for a specific side. |
| getAnalogueInput(side) | Get the redstone input signal strength for a specific side. |
| setBundledOutput(side, output) | Set the bundled cable output for a specific side. |
| getBundledOutput(side) | Get the bundled cable output for a specific side. |
| getBundledInput(side) | Get the bundled cable input for a specific side. |
| testBundledInput(side, mask) | Determine if a specific combination of colours are on for the given side. |

### getSides()
Returns a table containing the six sides of the computer. Namely, "top", "bottom", "left", "right", "front" and "back".

### Returns

- { `string`... } A table of valid sides.

### Changes

- New in version 1.2

### setOutput(side, on)
Turn the redstone signal of a specific side on or off.

### Parameters

- side `string` The side to set.
- on `boolean` Whether the redstone signal should be on or off. When on, a signal strength of 15 is emitted.

### getOutput(side)
Get the current redstone output of a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `boolean` Whether the redstone output is on or off.

### See also

- `setOutput`

### getInput(side)
Get the current redstone input of a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `boolean` Whether the redstone input is on or off.

### setAnalogOutput(side, value)
Set the redstone signal strength for a specific side.

### Parameters

- side `string` The side to set.
- value `number` The signal strength between 0 and 15.

### Throws

-

If `value` is not between 0 and 15.

### Changes

- New in version 1.51

### setAnalogueOutput(side, value)
Set the redstone signal strength for a specific side.

### Parameters

- side `string` The side to set.
- value `number` The signal strength between 0 and 15.

### Throws

-

If `value` is not between 0 and 15.

### Changes

- New in version 1.51

### getAnalogOutput(side)
Get the redstone output signal strength for a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `number` The output signal strength, between 0 and 15.

### See also

- `setAnalogOutput`

### Changes

- New in version 1.51

### getAnalogueOutput(side)
Get the redstone output signal strength for a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `number` The output signal strength, between 0 and 15.

### See also

- `setAnalogOutput`

### Changes

- New in version 1.51

### getAnalogInput(side)
Get the redstone input signal strength for a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `number` The input signal strength, between 0 and 15.

### Changes

- New in version 1.51

### getAnalogueInput(side)
Get the redstone input signal strength for a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `number` The input signal strength, between 0 and 15.

### Changes

- New in version 1.51

### setBundledOutput(side, output)
Set the bundled cable output for a specific side.

### Parameters

- side `string` The side to set.
- output `number` The colour bitmask to set.

### See also

- `colors.subtract` For removing a colour from the bitmask.
- `colors.combine` For adding a color to the bitmask.

### getBundledOutput(side)
Get the bundled cable output for a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `number` The bundle cable's output.

### getBundledInput(side)
Get the bundled cable input for a specific side.

### Parameters

- side `string` The side to get.

### Returns

- `number` The bundle cable's input.

### See also

- `testBundledInput` To determine if a specific colour is set.

### testBundledInput(side, mask)
Determine if a specific combination of colours are on for the given side.

### Parameters

- side `string` The side to test.
- mask `number` The mask to test.

### Returns

- `boolean` If the colours are on.

### Usage

-

Check if `colors.white` and `colors.black` are on above this block.

```lua
print(redstone.testBundledInput("top", colors.combine(colors.white, colors.black)))
```

### See also

- `getBundledInput`
