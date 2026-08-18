<!-- fetched from https://tweaked.cc/library/cc.expect.html -->
# library / cc.expect

# cc.expect

The `cc.expect` library provides helper functions for verifying that function arguments are well-formed and of the correct type.

### Usage

-

Define a basic function and check it has the correct arguments.

```lua
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local function add_person(name, info)
 expect(1, name, "string")
 expect(2, info, "table", "nil")

 if info then
 print("Got age=", field(info, "age", "number"))
 print("Got gender=", field(info, "gender", "string", "nil"))
 end
end

add_person("Anastazja") -- `info' is optional
add_person("Kion", { age = 23 }) -- `gender' is optional
add_person("Caoimhin", { age = 23, gender = true }) -- error!
```

### Changes

- New in version 1.84.0
- Changed in version 1.96.0: The module can now be called directly as a function, which wraps around `expect.expect`.

| expect(index, value, ...) | Expect an argument to have a specific type. |
| field(tbl, index, ...) | Expect an field to have a specific type. |
| range(num [, min=-math.huge [, max=math.huge]]) | Expect a number to be within a specific range. |

### expect(index, value, ...)
Expect an argument to have a specific type.

### Parameters

- index `number` The 1-based argument index.
- value The argument's value.
- ... `string` The allowed types of the argument.

### Returns

- The given `value`.

### Throws

-

If the value is not one of the allowed types.

### field(tbl, index, ...)
Expect an field to have a specific type.

### Parameters

- tbl `table` The table to index.
- index `string` The field name to check.
- ... `string` The allowed types of the argument.

### Returns

- The contents of the given field.

### Throws

-

If the field is not one of the allowed types.

### range(num [, min=-math.huge [, max=math.huge]])
Expect a number to be within a specific range.

### Parameters

- num `number` The value to check.
- min? `number` = `-math.huge` The minimum value.
- max? `number` = `math.huge` The maximum value.

### Returns

- The given `value`.

### Throws

-

If the value is outside of the allowed range.

### Changes

- New in version 1.96.0
