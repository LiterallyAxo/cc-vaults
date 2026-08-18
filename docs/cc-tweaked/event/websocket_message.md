<!-- fetched from https://tweaked.cc/event/websocket_message.html -->
# event / websocket message

# websocket_message

The `websocket_message` event is fired when a message is received on an open WebSocket connection.

This event is normally handled by `http.Websocket.receive`, but it can also be pulled manually.

## Return Values

- `string`: The event name.
- `string`: The URL of the WebSocket.
- `string`: The contents of the message.
- `boolean`: Whether this is a binary message.

## Example

Prints a message sent by a WebSocket:

```lua
local myURL = "wss://example.tweaked.cc/echo"
local ws = http.websocket(myURL)
ws.send("Hello!")
local event, url, message
repeat
 event, url, message = os.pullEvent("websocket_message")
until url == myURL
print("Received message from " .. url .. " with contents " .. message)
ws.close()
```
