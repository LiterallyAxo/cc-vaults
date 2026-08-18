<!-- fetched from https://tweaked.cc/module/commands.html -->
# module / commands

# commands

Execute Minecraft commands and gather data from the results from a command computer.

##### 🛈 note

This API is only available on Command computers. It is not accessible to normal players.

While one may use `commands.exec` directly to execute a command, the commands API also provides helper methods to execute every command. For instance, `commands.say("Hi!")` is equivalent to `commands.exec("say Hi!")`.

`commands.async` provides a similar interface to execute asynchronous commands. `commands.async.say("Hi!")` is equivalent to `commands.execAsync("say Hi!")`.

### Usage

-

Set the block above this computer to stone:

```lua
commands.setblock("~", "~1", "~", "minecraft:stone")
```

### Changes

- New in version 1.7

| exec(command) | Execute a specific command. |
| execAsync(command) | Asynchronously execute a command. |
| list(...) | List all available commands which the computer has permission to execute. |
| getDimension() | Get the name of the dimension the current command computer is in, such as `minecraft:overworld`. |
| getBlockPosition() | Get the position of the current command computer. |
| getBlockInfos(minX, minY, minZ, maxX, maxY, maxZ [, dimension]) | Get information about a range of blocks. |
| getBlockInfo(x, y, z [, dimension]) | Get some basic information about a block. |
| getEntities(selector) | Get all entities matching the given selector. |
| native | The builtin commands API, without any generated command helper functions |
| async | A table containing asynchronous wrappers for all commands. |

### exec(command)
Execute a specific command.

### Parameters

- command `string` The command to execute.

### Returns

- `boolean` Whether the command executed successfully.
- { `string`... } The output of this command, as a list of lines.
- `number` | nil The number of "affected" objects, or `nil` if the command failed. The definition of this varies from command to command.

### Usage

-

Set the block above the command computer to stone.

```lua
commands.exec("setblock ~ ~1 ~ minecraft:stone")
```

### Changes

- Changed in version 1.71: Added return value with command output.
- Changed in version 1.85.0: Added return value with the number of affected objects.

### execAsync(command)
Asynchronously execute a command.

Unlike `exec`, this will immediately return, instead of waiting for the command to execute. This allows you to run multiple commands at the same time.

When this command has finished executing, it will queue a `task_complete` event containing the result of executing this command (what `exec` would return).

### Parameters

- command `string` The command to execute.

### Returns

- `number` The "task id". When this command has been executed, it will queue a `task_complete` event with a matching id.

### Usage

-

Asynchronously sets the block above the computer to stone.

```lua
commands.execAsync("setblock ~ ~1 ~ minecraft:stone")
```

### See also

- `parallel` One may also use the parallel API to run multiple commands at once.

### list(...)
List all available commands which the computer has permission to execute.

### Parameters

- ... `string` The sub-command to complete.

### Returns

- { `string`... } A list of all available commands

### getDimension()
Get the name of the dimension the current command computer is in, such as `minecraft:overworld`.

### Returns

- `string` The dimension the computer is in.

### See also

- `getBlockPosition`

### Changes

- New in version 1.119.0

### getBlockPosition()
Get the position of the current command computer.

### Returns

- `number` This computer's x position.
- `number` This computer's y position.
- `number` This computer's z position.

### See also

- `gps.locate` To get the position of a non-command computer.
- `getDimension`

### getBlockInfos(minX, minY, minZ, maxX, maxY, maxZ [, dimension])
Get information about a range of blocks.

This returns the same information as `getBlockInfo`, just for multiple blocks at once.

Blocks are traversed by ascending y level, followed by z and x - the returned table may be indexed using `x + z*width + y*width*depth + 1`.

### Parameters

- minX `number` The start x coordinate of the range to query.
- minY `number` The start y coordinate of the range to query.
- minZ `number` The start z coordinate of the range to query.
- maxX `number` The end x coordinate of the range to query.
- maxY `number` The end y coordinate of the range to query.
- maxZ `number` The end z coordinate of the range to query.
- dimension? `string` The dimension to query (e.g. "minecraft:overworld"). Defaults to the current dimension.

### Returns

- { `table`... } A list of information about each block.

### Throws

-

If the coordinates are not within the world.

-

If trying to get information about more than 4096 blocks.

### Usage

-

Print out all blocks in a cube around the computer.

```lua
-- Get a 3x3x3 cube around the computer
local x, y, z = commands.getBlockPosition()
local min_x, min_y, min_z, max_x, max_y, max_z = x - 1, y - 1, z - 1, x + 1, y + 1, z + 1
local blocks = commands.getBlockInfos(min_x, min_y, min_z, max_x, max_y, max_z)

-- Then loop over all blocks and print them out.
local width, height, depth = max_x - min_x + 1, max_y - min_y + 1, max_z - min_z + 1
for x = min_x, max_x do
 for y = min_y, max_y do
 for z = min_z, max_z do
 print(("%d, %d %d => %s"):format(x, y, z, blocks[(x - min_x) + (z - min_z) * width + (y - min_y) * width * depth + 1].name))
 end
 end
end
```

### Changes

- New in version 1.76
- Changed in version 1.99: Added `dimension` argument.

### getBlockInfo(x, y, z [, dimension])
Get some basic information about a block.

The returned table contains the the same information as listed in Block details. If there is a block entity for that block, its NBT will also be returned.

### Parameters

- x `number` The x position of the block to query.
- y `number` The y position of the block to query.
- z `number` The z position of the block to query.
- dimension? `string` The dimension to query (e.g. "minecraft:overworld"). Defaults to the current dimension.

### Returns

- `table` The given block's information.

### Throws

-

If the coordinates are not within the world, or are not currently loaded.

### Changes

- Changed in version 1.76: Added block state info to return value
- Changed in version 1.99: Added `dimension` argument.

### getEntities(selector)
Get all entities matching the given selector.

### Parameters

- selector `string` An entity selector, such as `@p` or `@a`.

### Returns

- { `table`... } A list of information about all matching entities.

### Throws

-

If the entity selector canont be parsed.

### Usage

-

Print the name of all entities within 10 blocks of the command computer.

```lua
for _, entity in ipairs(commands.getEntities("@e[distance=..10]")) do
 print(entity.displayName)
end
```

### See also

- `Entity details`

### Changes

- New in version 1.118.0

### native
The builtin commands API, without any generated command helper functions

This may be useful if a built-in function (such as `commands.list`) has been overwritten by a command.

### async
A table containing asynchronous wrappers for all commands.

As with `commands.execAsync`, this returns the "task id" of the enqueued command.

### Usage

-

Asynchronously sets the block above the computer to stone.

```lua
commands.async.setblock("~", "~1", "~", "minecraft:stone")
```

### See also

- `execAsync`
