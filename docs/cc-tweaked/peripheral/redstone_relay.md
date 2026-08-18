<!-- fetched from https://tweaked.cc/peripheral/redstone_relay.html -->
# peripheral / redstone relay

# redstone_relay

The redstone relay is a peripheral that allows reading and outputting redstone signals. While this is not very useful on its own (as computers have the same functionality built-in), this can be used with wired modems to interact with multiple redstone signals from the same computer.

The peripheral provides largely identical methods to a computer's built-in `redstone` API, allowing setting signals on all six sides of the block ("top", "bottom", "left", "right", "front" and "back").

## Recipe
 Redstone Relay

### Usage

-

Toggle the redstone signal above the computer every 0.5 seconds.

```lua
local relay = peripheral.find("redstone_relay")
while true do
 relay.setOutput("top", not relay.getOutput("top"))
 sleep(0.5)
end
```

### Changes

- New in version 1.114.0

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
