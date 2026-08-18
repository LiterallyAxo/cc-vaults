<!-- fetched from https://tweaked.cc/module/gps.html -->
# module / gps

# gps

Use modems to locate the position of the current turtle or computers.

This works by communicating with other computers (called GPS hosts) that already know their position, finding the distance to those computers (with `modem_message`), and using that to derive its position from theirs (with a process known as trilateration.

### See also

- `Setting up GPS`

### Changes

- New in version 1.31

| CHANNEL_GPS = 65534 | The channel which GPS requests and responses are broadcast on. |
| locate([timeout=2 [, debug=false]]) | Tries to retrieve the computer or turtles own location. |

### CHANNEL_GPS = 65534
The channel which GPS requests and responses are broadcast on.

### locate([timeout=2 [, debug=false]])
Tries to retrieve the computer or turtles own location.

### Parameters

- timeout? `number` = `2` The maximum time in seconds taken to establish our position.
- debug? `boolean` = `false` Print debugging messages

### Returns

- `number` This computer's `x` position.
- `number` This computer's `y` position.
- `number` This computer's `z` position.

#### Or

- nil If the position could not be established.
