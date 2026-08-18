<!-- fetched from https://cccbridge.kleinbox.dev/peripherals/AnimatronicPeripheral/ -->
# CC:C Bridge / peripherals-AnimatronicPeripheral

# Animatronic

The Animatronic is a puppet which can be positioned or animated. By default, the animations will be looking rusty. This can however be changed.

The maximum rotation of every body part is 180° positive or negative.

## Example

In order to use the Animatronic, a modem needs to be placed below it. Said modem can then be connected as usual.

Once connected, it can directly be called and used in the code:

```lua
local animatronic = peripheral.find("animatronic")

-- Make it stand normally rather than hanging,
-- like it does by default.
animatronic.setHeadRot(0,0,0)
animatronic.setLeftArmRot(0,0,0)
animatronic.setRightArmRot(0,0,0)

-- We also need to apply the changes,
-- after we configured it like above.
animatronic.push()

```

Note that transitioning from the previous pose to the new one takes about 1 second, with the exception if the transition type is set to none, where it instead will be switching instant:

```lua
local animatronic = peripheral.find("animatronic")

animatronic.setTransition("none")

-- ...

```

## Metadata

 | | |
 | Peripheral | v1.1 |
 | Attach name | `"animatronic"` |
 | Attach side | only `"top"` |

## API

### `setFace(face)`

Changes the face of the Animatronic.

Parameters

- `face`: string The new face. Must be either `"normal"`, `"happy"`, `"question"` or `"sad"`.

Throws

- Whenever the given string is not one of those types.

### `setTransition(kind)`

Sets the Animatronic's animation transition mode.

Parameters

- `kind`: string The new transition mode. Must be either `"linear"`, `"none"` or `"rusty"`.

Throws

- Whenever the given string is not one of those types.

### `push()`

Pushes the stored rotation values to the Animatronic. After pushing them, every rotation gets reset to `0`.

### `setHeadRot(x, y, z)`

Sets the head rotation. Can only be set within the bounds -180° to 180° for `x`, `y` and `z`.

Parameters

- `x`: number The `x` rotation.
- `y`: number The `y` rotation.
- `z`: number The `z` rotation.

### `setBodyRot(x, y, z)`

Sets the body rotation. Can only be set within the bounds -180° to 180° for `y` and `z`.

Info

`x` can be set to any number within 360°.

Parameters

- `x`: number The `x` rotation.
- `y`: number The `y` rotation.
- `z`: number The `z` rotation.

### `setLeftArmRot(x, y, z)`

Sets the left arm rotation. Can only be set within the bounds -180° to 180° for `x`, `y` and `z`.

Parameters

- `x`: number The `x` rotation.
- `y`: number The `y` rotation.
- `z`: number The `z` rotation.

### `setRightArmRot(x, y, z)`

Sets the right arm rotation. Can only be set within the bounds -180° to 180° for `x`, `y` and `z`.

Parameters

- `x`: number The `x` rotation.
- `y`: number The `y` rotation.
- `z`: number The `z` rotation.

### `getStoredHeadRot()`

Returns the current stored head rotation.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getStoredBodyRot()`

Returns the current stored body rotation.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getStoredLeftArmRot()`

Returns the current stored left arm rotation.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getStoredRightArmRot()`

Returns the current stored right arm rotation.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getAppliedHeadRot()`

Returns the rotation of the head.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getAppliedBodyRot()`

Returns the rotation of the body.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getAppliedLeftArmRot()`

Returns the rotation of the left arm.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation

### `getAppliedRightArmRot()`

Returns the rotation of the right arm.

Returns 1. `number` The `x` rotation 2. `number` The `y` rotation 3. `number` The `z` rotation
