<!-- fetched from https://tweaked.cc/event/modem_message.html -->
# event / modem message

# modem_message

The `modem_message` event is fired when a message is received on an open channel on any `modem`.

## Return Values

- `string`: The event name.
- `string`: The side of the modem that received the message.
- `number`: The channel that the message was sent on.
- `number`: The reply channel set by the sender.
- `any`: The message as sent by the sender.
- `number`|`nil`: The distance between the sender and the receiver in blocks, or `nil` if the message was sent between dimensions.

## Example

Wraps a `modem` peripheral, opens channel 0 for listening, and prints all received messages.

```lua
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open(0)

while true do
 local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
 print(("Message received on side %s on channel %d (reply to %d) from %f blocks away with message %s"):format(
 side, channel, replyChannel, distance, tostring(message)
 ))
end
```
