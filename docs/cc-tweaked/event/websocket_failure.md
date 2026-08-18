<!-- fetched from https://tweaked.cc/event/websocket_failure.html -->
# event / websocket failure

# websocket_failure

The `websocket_failure` event is fired when a WebSocket connection request fails.

This event is normally handled inside `http.websocket`, but it can still be seen when using `http.websocketAsync`.

## Return Values

- `string`: The event name.
- `string`: The URL of the site requested.
- `string`: An error describing the failure.

## Example

Prints an error why the website cannot be contacted:

```lua
local myURL = "wss://example.tweaked.cc/not-a-websocket"
http.websocketAsync(myURL)
local event, url, err
repeat
 event, url, err = os.pullEvent("websocket_failure")
until url == myURL
print("The URL " .. url .. " could not be reached: " .. err)
```

### See also

- `http.websocketAsync` To send an HTTP request.
