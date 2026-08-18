<!-- fetched from https://cccbridge.kleinbox.dev/peripherals/RedRouterBlockPeripheral/ -->
# CC:C Bridge / peripherals-RedRouterBlockPeripheral

# RedRouter Block

The RedRouter can be used to control redstone signals from further away without needing multiple computers or an bundled cables mod.

The API is almost identical to the Redstone API with some exceptions like missing bundled cable support. The sides are configured similarly to the turtle, where `"left"` is relative to the blocks facing.

Info

While the RedRouter is not marked as deprecated, it is recommended to check out the Redstone Relay instead, which CC: Tweaked introduced on their own in newer versions.

## Example

Using the RedRouter is straight forward, if one already knows how to use the redstone API:

```lua
local redrouter = peripheral.find("redrouter")

-- Make the RedRouter emit a redstone signal on full strength
-- from its left side.
redrouter.setOutput("left", true)

os.pullEvent("redstone") -- Wait until a redstone signal changed

-- Print a status update of the back sides redstone strength:
local strength = redrouter.getAnalogInput("back")
print("Something is sending an redstone signal with the strength "..strength.." from the redrouters back.")

```

Notice how it not only can send redstone outputs but also read inputs, both through booleans or analog values from 0 to 15.

Info

`redrouter.getInput` returns the current value in the world, which might be an external source. `redrouter.getOutput` on the other hand returns what the redrouter got told to emit.

## Metadata

 | | |
 | Peripheral | v1 |
 | Attach name | `"redrouter"` |
 | Attach side | all |

### Events

The RedRouter can send the following event:

 | Name | Description | Parameter 1 |
 | `"redstone"` | Whenever a redstone signal has changed. | `string`: attached_name |

## Functions

### `setOutput(side, on)`

Set a redstone signal for a specific side.

Parameters

- `side` : string The side to set.
- `on`: boolean The signals state `true` (power 15) or `false` (power 0)

### `setAnalogOutput(side, value)`

Set a redstone signal strength for a specific side.

Parameters

- `side` : string The side to set.
- `value` : number The signal strength between 0 and 15.

Throws

- Whenever `value` is not between 0 and 15.

### `getOutput(side)`

Get the current redstone output of a specific side. (see `setOutput`)

Parameters

- `side`: string The side to get.

Returns

- `boolean` Whether the redstone output is on or off.

### `getInput(side)`

Get the current redstone input of a specific side.

Parameters

- `side`: string The side to get.

Returns

- `boolean` Whether the redstone input is on or off.

### `getAnalogOutput(side)`

Get the redstone output signal strength for a specific side. (see `setAnalogOutput`)

Parameters

- `side`: string The side to get.

Returns

- number The output signal strength, between 0 and 15.

### `getAnalogInput(side)`

Get the redstone input signal strength for a specific side.

Parameters

- `side`: string The side to get.

Returns

- number The input signal strength, between 0 and 15.
