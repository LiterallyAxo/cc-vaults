<!-- fetched from https://tweaked.cc/event/disk.html -->
# event / disk

# disk

The `disk` event is fired when a disk is inserted into an adjacent or networked disk drive.

## Return Values

- `string`: The event name.
- `string`: The side of the disk drive that had a disk inserted.

## Example

Prints a message when a disk is inserted:

```lua
while true do
 local event, side = os.pullEvent("disk")
 print("Inserted a disk on side " .. side)
end
```

### See also

- `disk_eject` For the event sent when a disk is removed.
