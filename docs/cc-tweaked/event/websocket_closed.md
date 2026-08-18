<!-- fetched from https://tweaked.cc/event/websocket_closed.html -->
# event / websocket closed

# websocket_closed

The `websocket_closed` event is fired when an open WebSocket connection is closed.

## Return Values

- `string`: The event name.
- `string`: The URL of the WebSocket that was closed.
- `string`|`nil`: The server-provided reason the websocket was closed. This will be `nil` if the connection was closed abnormally.
- `number`|`nil`: The connection close code, indicating why the socket was closed. This will be `nil` if the connection was closed abnormally.

## Example

Prints a message when a WebSocket is closed (this may take a minute):

```lua
local myURL = "wss://example.tweaked.cc/echo"
local ws = http.websocket(myURL)
local event, url
repeat
 event, url = os.pullEvent("websocket_closed")
until url == myURL
print("The WebSocket at " .. url .. " was closed.")
```
