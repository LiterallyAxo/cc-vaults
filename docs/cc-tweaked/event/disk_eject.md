<!-- fetched from https://tweaked.cc/event/disk_eject.html -->
# event / disk eject

# disk_eject

The `disk_eject` event is fired when a disk is removed from an adjacent or networked disk drive.

## Return Values

- `string`: The event name.
- `string`: The side of the disk drive that had a disk removed.

## Example

Prints a message when a disk is removed:

```lua
while true do
 local event, side = os.pullEvent("disk_eject")
 print("Removed a disk on side " .. side)
end
```

### See also

- `disk` For the event sent when a disk is inserted.
