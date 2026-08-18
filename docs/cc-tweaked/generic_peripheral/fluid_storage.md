<!-- fetched from https://tweaked.cc/generic_peripheral/fluid_storage.html -->
# generic peripheral / fluid storage

# fluid_storage

Methods for interacting with tanks and other fluid storage blocks.

### Changes

- New in version 1.94.0

| tanks() | Get all "tanks" in this fluid storage. |
| pushFluid(toName [, limit [, fluidName]]) | Move a fluid from one fluid container to another connected one. |
| pullFluid(fromName [, limit [, fluidName]]) | Move a fluid from a connected fluid container into this one. |

### tanks()
Get all "tanks" in this fluid storage.

Each tank either contains some amount of fluid or is empty. Tanks with fluids inside will return some basic information about the fluid, including its name and amount.

The returned table is sparse, and so empty tanks will be `nil` - it is recommended to loop over using `pairs` rather than `ipairs`.

### Returns

- { `table` | nil... } Basic information about all fluids in this fluid storage.

### pushFluid(toName [, limit [, fluidName]])
Move a fluid from one fluid container to another connected one.

This allows you to pull fluid in the current fluid container to another container on the same wired network. Both containers must attached to wired modems which are connected via a cable.

### Parameters

- toName `string` The name of the peripheral/container to push to. This is the string given to `peripheral.wrap`, and displayed by the wired modem.
- limit? `number` The maximum amount of fluid to move.
- fluidName? `string` The fluid to move. If not given, an arbitrary fluid will be chosen.

### Returns

- `number` The amount of moved fluid.

### Throws

-

If the peripheral to transfer to doesn't exist or isn't an fluid container.

### See also

- `peripheral.getName` Allows you to get the name of a wrapped peripheral.

### pullFluid(fromName [, limit [, fluidName]])
Move a fluid from a connected fluid container into this one.

This allows you to pull fluid in the current fluid container from another container on the same wired network. Both containers must be attached to wired modems which are connected via a cable.

### Parameters

- fromName `string` The name of the peripheral/container to push to. This is the string given to `peripheral.wrap`, and displayed by the wired modem.
- limit? `number` The maximum amount of fluid to move.
- fluidName? `string` The fluid to move. If not given, an arbitrary fluid will be chosen.

### Returns

- `number` The amount of moved fluid.

### Throws

-

If the peripheral to transfer to doesn't exist or isn't an fluid container.

### See also

- `peripheral.getName` Allows you to get the name of a wrapped peripheral.
