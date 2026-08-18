<!-- fetched from https://tweaked.cc/library/cc.require.html -->
# library / cc.require

# cc.require

A pure Lua implementation of the builtin `require` function and `package` library.

Generally you do not need to use this module - it is injected into the every program's environment. However, it may be useful when building a custom shell or when running programs yourself.

### Usage

-

Construct the package and require function, and insert them into a custom environment.

```lua
local r = require "cc.require"
local env = setmetatable({}, { __index = _ENV })
env.require, env.package = r.make(env, "/")

-- Now we have our own require function, separate to the original.
local r2 = env.require "cc.require"
print(r, r2)
```

### See also

- `Reusing code with require` For an introduction on how to use `require`.

### Changes

- New in version 1.88.0

| make(env, dir) | Build an implementation of Lua's `package` library, and a `require` function to load modules within it. |

### make(env, dir)
Build an implementation of Lua's `package` library, and a `require` function to load modules within it.

### Parameters

- env `table` The environment to load packages into.
- dir `string` The directory that relative packages are loaded from.

### Returns

- `function` The new `require` function.
- `table` The new `package` library.
