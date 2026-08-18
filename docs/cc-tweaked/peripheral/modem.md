<!-- fetched from https://tweaked.cc/peripheral/modem.html -->
# peripheral / modem

# modem

Modems allow you to send messages between computers over long distances.

##### tip

Modems provide a fairly basic set of methods, which makes them very flexible but often hard to work with. The `rednet` API is built on top of modems, and provides a more user-friendly interface.

## Sending and receiving messages

Modems operate on a series of channels, a bit like frequencies on a radio. Any modem can send a message on a particular channel, but only those which have opened the channel and are "listening in" can receive messages.

Channels are represented as an integer between 0 and 65535 inclusive. These channels don't have any defined meaning, though some APIs or programs will assign a meaning to them. For instance, the `gps` module sends all its messages on channel 65534 (`gps.CHANNEL_GPS`), while `rednet` uses channels equal to the computer's ID.

- Sending messages is done with the `transmit` message.
- Receiving messages is done by listening to the `modem_message` event.

## Types of modem

CC: Tweaked comes with three kinds of modem, with different capabilities.

-

Wireless modems: Wireless modems can send messages to any other wireless modem. They can be placed next to a computer, or equipped as a pocket computer or turtle upgrade.

Wireless modems have a limited range, only sending messages to modems within 64 blocks. This range increases linearly once the modem is above y=96, to a maximum of 384 at world height.

-

Ender modems: These are upgraded versions of normal wireless modems. They do not have a distance limit, and can send messages between dimensions.

-

Wired modems: These send messages to other any other wired modems connected to the same network (using Networking Cable). They also can be used to attach additional peripherals to a computer.

## Recipes
 Wireless Modem

 Ender Modem

 Wired Modem

 Networking Cable

6

 Wired Modem

### Usage

-

Wrap a modem and a message on channel 15, requesting a response on channel 43. Then wait for a message to arrive on channel 43 and print it.

```lua
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open(43) -- Open 43 so we can receive replies

-- Send our message
modem.transmit(15, 43, "Hello, world!")

-- And wait for a reply
local event, side, channel, replyChannel, message, distance
repeat
 event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
until channel == 43

print("Received a reply: " .. tostring(message))
```

### See also

- `modem_message` Queued when a modem receives a message on an open channel.
- `rednet` A networking API built on top of the modem peripheral.

| open(channel) | Open a channel on a modem. |
| isOpen(channel) | Check if a channel is open. |
| close(channel) | Close an open channel, meaning it will no longer receive messages. |
| closeAll() | Close all open channels. |
| transmit(channel, replyChannel, payload) | Sends a modem message on a certain channel. |
| isWireless() | Determine if this is a wired or wireless modem. |
| getNamesRemote() | List all remote peripherals on the wired network. |
| isPresentRemote(name) | Determine if a peripheral is available on this wired network. |
| getTypeRemote(name) | Get the type of a peripheral is available on this wired network. |
| hasTypeRemote(name, type) | Check a peripheral is of a particular type. |
| getMethodsRemote(name) | Get all available methods for the remote peripheral with the given name. |
| callRemote(remoteName, method, ...) | Call a method on a peripheral on this wired network. |
| getNameLocal() | Returns the network name of the current computer, if the modem is on. |

### open(channel)
Open a channel on a modem. A channel must be open in order to receive messages. Modems can have up to 128 channels open at one time.

### Parameters

- channel `number` The channel to open. This must be a number between 0 and 65535.

### Throws

-

If the channel is out of range.

-

If there are too many open channels.

### isOpen(channel)
Check if a channel is open.

### Parameters

- channel `number` The channel to check.

### Returns

- `boolean` Whether the channel is open.

### Throws

-

If the channel is out of range.

### close(channel)
Close an open channel, meaning it will no longer receive messages.

### Parameters

- channel `number` The channel to close.

### Throws

-

If the channel is out of range.

### closeAll()
Close all open channels.

### transmit(channel, replyChannel, payload)
Sends a modem message on a certain channel. Modems listening on the channel will queue a `modem_message` event on adjacent computers.

##### 🛈 note

The channel does not need be open to send a message.

### Parameters

- channel `number` The channel to send messages on.
- replyChannel `number` The channel that responses to this message should be sent on. This can be the same as `channel` or entirely different. The channel must have been opened on the sending computer in order to receive the replies.
- payload `any` The object to send. This can be any primitive type (boolean, number, string) as well as tables. Other types (like functions), as well as metatables, will not be transmitted.

### Throws

-

If the channel is out of range.

### Usage

-

Wrap a modem and a message on channel 15, requesting a response on channel 43.

```lua
local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.transmit(15, 43, "Hello, world!")
```

### isWireless()
Determine if this is a wired or wireless modem.

Some methods (namely those dealing with wired networks and remote peripherals) are only available on wired modems.

### Returns

- `boolean` `true` if this is a wireless modem.

### getNamesRemote()
List all remote peripherals on the wired network.

If this computer is attached to the network, it will not be included in this list.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Returns

- { `string`... } Remote peripheral names on the network.

### isPresentRemote(name)
Determine if a peripheral is available on this wired network.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Parameters

- name `string` The peripheral's name.

### Returns

- `boolean` boolean If a peripheral is present with the given name.

### See also

- `peripheral.isPresent`

### getTypeRemote(name)
Get the type of a peripheral is available on this wired network.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Parameters

- name `string` The peripheral's name.

### Returns

- `string` | nil The peripheral's type, or `nil` if it is not present.

### See also

- `peripheral.getType`

### Changes

- Changed in version 1.99: Peripherals can have multiple types - this function returns multiple values.

### hasTypeRemote(name, type)
Check a peripheral is of a particular type.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Parameters

- name `string` The peripheral's name.
- type `string` The type to check.

### Returns

- `boolean` | nil If a peripheral has a particular type, or `nil` if it is not present.

### See also

- `peripheral.getType`

### Changes

- New in version 1.99

### getMethodsRemote(name)
Get all available methods for the remote peripheral with the given name.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Parameters

- name `string` The peripheral's name.

### Returns

- { `string`... } | nil A list of methods provided by this peripheral, or `nil` if it is not present.

### See also

- `peripheral.getMethods`

### callRemote(remoteName, method, ...)
Call a method on a peripheral on this wired network.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Parameters

- remoteName `string` The name of the peripheral to invoke the method on.
- method `string` The name of the method
- ... Additional arguments to pass to the method

### Returns

- `string` The return values of the peripheral method.

### See also

- `peripheral.call`

### getNameLocal()
Returns the network name of the current computer, if the modem is on. This may be used by other computers on the network to wrap this computer as a peripheral.

##### 🛈 note

This function only appears on wired modems. Check `isWireless` returns false before calling it.

### Returns

- `string` | nil The current computer's name on the wired network.

### Changes

- New in version 1.80pr1.7
