<!-- fetched from https://tweaked.cc/library/cc.base64.html -->
# library / cc.base64

# cc.base64

The `cc.base64` module provides functions for converting binary data to and from Base64.

### Usage

-

Encode and decode a string from Base64.

```lua
local base64 = require "cc.base64"
print(base64.encode("Hello, world"))
print(base64.decode("SGVsbG8sIHdvcmxk"))
```

### Changes

- New in version 1.119.0

| encode(str [, alt_chars="+/"]) | Encode a binary string to Base64. |
| decode(str [, alt_chars="+/"]) | Decode a Base64-encoded string back to its original data. |

### encode(str [, alt_chars="+/"])
Encode a binary string to Base64.

### Parameters

- str `string` The binary data to encode.
- alt_chars? `string` = `"+/"` A string of length 2, used to encode the 62nd and 63rd bit.

### Returns

- `string` The Base64 encoded data.

### Usage

-

Convert a string to Base64

```lua
local base64 = require "cc.base64"
print(base64.encode("Hello, world!"))
```

-

Convert a string to base64url. This is an alternative form of Base64, where the string is encoded with `"-_"` instead of `"+/"`. This allows the string to be more easily used in URLs, though the padding `=` will still need escaping with `textutils.urlEncode`.

```lua
local base64 = require "cc.base64"
print(base64.encode("Test: \255\230", "-_"))
```

### decode(str [, alt_chars="+/"])
Decode a Base64-encoded string back to its original data.

This function requires the data to be valid Base64 with the trailing padding bytes.

### Parameters

- str `string` The Base64-encoded data to decode.
- alt_chars? `string` = `"+/"` A string of length 2, used to encode the 62nd and 63rd bit.

### Returns

- `string` The decoded data.

#### Or

- nil If the data is not valid Base64, or is missing the trailing padding.
- `string` The reason the data failed to decode.

### Usage

-

Decode a string from Base64

```lua
local base64 = require "cc.base64"
print(base64.decode("SGVsbG8sIHdvcmxk"))
```

-

Decode base64url-encoded data.

```lua
local base64 = require "cc.base64"
print(base64.decode("VGVzdDog_-Y=", "-_"))
```
